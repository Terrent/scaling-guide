class_name PlayerController
extends CharacterBody2D

# --- (Your existing properties are all fine, no changes here) ---
@export var speed: float = 100.0
@onready var authoritative_node = $PlayerAuthoritative
@onready var camera = $Camera2D
@onready var area_of_interest: Area2D = $AreaOfInterest
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
var sequence_id: int = 0
var pending_inputs: Array = []
var position_error_threshold: float = 5.0
var last_input_vector: Vector2 = Vector2.ZERO
var interpolation_buffer: Array = []
const BUFFER_SIZE = 20
const INTERPOLATION_DELAY_MS = 100

func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
		
	# Debug what we can actually see
	if Engine.get_process_frames() % 60 == 0:  # Every second
		var visible_players = []
		for player in get_tree().get_nodes_in_group("players"):
			if player != self and player.visible:
				visible_players.append(player.name)
		
		print("[VISIBILITY] I am %s (peer %d). I can see: %s" % [
			name, 
			multiplayer.get_unique_id(),
			visible_players if visible_players.size() > 0 else "NOBODY"
		])
func _ready() -> void:
	add_to_group("players")
	camera.enabled = is_multiplayer_authority()
	
	var label = $SpriteLayers/Label
	if label:
		label.text = "Player " + name
	
	if is_multiplayer_authority():
		modulate = Color.GREEN
		if label: label.text += "\n(YOU)"
	else:
		modulate = Color.RED
	
	# The server is the only one that cares about AoI signals.
	print("[AoI SETUP] Player '%s' initial visibility state:" % name)
	print("  - Synchronizer public_visibility: %s" % synchronizer.public_visibility)
	print("  - Multiplayer authority: %d" % synchronizer.get_multiplayer_authority())
	
	# CRITICAL: Server-only visibility logic
	if multiplayer.is_server():
		print("[AoI SETUP] Player '%s' (SERVER) is connecting its Area2D signals." % name)
		area_of_interest.body_entered.connect(_on_area_of_interest_body_entered)
		area_of_interest.body_exited.connect(_on_area_of_interest_body_exited)
	if synchronizer:
		print("[FINAL CHECK] Player %s synchronizer:" % name)
		print("  - public_visibility: %s" % synchronizer.public_visibility)
		print("  - replication_interval: %s" % synchronizer.replication_interval)
		print("  - authority: %d" % synchronizer.get_multiplayer_authority())
	else:
		print("[ERROR] Player %s has no synchronizer!" % name)
# --- (Your _physics_process and receive_server_state are fine, no changes needed there) ---
func _physics_process(delta: float):
	if is_multiplayer_authority():
		var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var has_input = input_vector.length_squared() > 0
		var was_moving = velocity.length_squared() > 0
		if not has_input and not was_moving:
			return
		var input_packet: Dictionary = { "sequence": sequence_id, "input_vector": input_vector, "delta": delta }
		_process_movement(input_packet)
		pending_inputs.append(input_packet)
		authoritative_node.rpc_id(1, "receive_client_input", input_packet)
		sequence_id += 1
	else:
		if interpolation_buffer.size() < 2:
			return
		var render_time = Time.get_ticks_msec() - INTERPOLATION_DELAY_MS
		var future_snapshot = null
		var past_snapshot = null
		for snapshot in interpolation_buffer:
			if snapshot.timestamp >= render_time:
				future_snapshot = snapshot
			else:
				past_snapshot = snapshot
				break
		if past_snapshot == null or future_snapshot == null:
			return
		var time_difference = future_snapshot.timestamp - past_snapshot.timestamp
		var t = 0.0
		if time_difference > 0:
			t = float(render_time - past_snapshot.timestamp) / float(time_difference)
		global_position = past_snapshot.position.lerp(future_snapshot.position, t)

@rpc("any_peer", "call_remote", "reliable")
func receive_server_state(server_state: Dictionary):
	if is_multiplayer_authority():
		var position_error = global_position.distance_to(server_state["position"])
		if position_error > position_error_threshold:
			global_position = server_state["position"]
			velocity = server_state["velocity"]
			var last_processed_sequence: int = server_state["sequence"]
			pending_inputs = pending_inputs.filter(func(input): return input["sequence"] > last_processed_sequence)
			for input_packet in pending_inputs:
				_process_movement(input_packet)
		else:
			var last_processed_sequence: int = server_state["sequence"]
			pending_inputs = pending_inputs.filter(func(input): return input["sequence"] > last_processed_sequence)
	else:
		var snapshot = { "timestamp": Time.get_ticks_msec(), "position": server_state["position"], "velocity": server_state["velocity"] }
		interpolation_buffer.push_front(snapshot)
		if interpolation_buffer.size() > BUFFER_SIZE:
			interpolation_buffer.pop_back()

func _process_movement(input_packet: Dictionary):
	velocity = input_packet["input_vector"] * speed
	move_and_slide()


#=============================================================================
# DEBUGGED AREA OF INTEREST CALLBACKS
#=============================================================================

func _on_area_of_interest_body_entered(body: Node2D) -> void:
	print("\n--- AoI EVENT ---")
	print("[AoI] ENTER detected on '%s's Area. Body that entered: '%s'." % [name, body.name])
	
	if not body.is_in_group("players"):
		print("[AoI] Body '%s' is not in 'players' group. Groups: %s" % [body.name, body.get_groups()])
		return
	
	if body == self:
		print("[AoI] Body '%s' is self. Ignoring." % body.name)
		return
	
	# Debug synchronizer state
	print("[AoI DEBUG] Synchronizer states:")
	print("  - My (%s) synchronizer exists: %s" % [name, synchronizer != null])
	print("  - Their (%s) synchronizer exists: %s" % [body.name, body.synchronizer != null])
	print("  - My public_visibility: %s" % synchronizer.public_visibility)
	print("  - Their public_visibility: %s" % body.synchronizer.public_visibility)
	
	# THE SYMMETRIC HANDSHAKE
	print("[AoI ACTION] Setting visibility...")
	body.synchronizer.set_visibility_for(name.to_int(), true)
	synchronizer.set_visibility_for(body.name.to_int(), true)
	print("[AoI ACTION] Visibility set complete.")

func _on_area_of_interest_body_exited(body: Node2D) -> void:
	print("\n--- AoI EVENT ---")
	print("[AoI] EXIT detected on '%s's Area. Body that exited: '%s'." % [name, body.name])
	
	if not body.is_in_group("players") or body == self:
		return
	
	# Remove visibility both ways
	print("[AoI ACTION] Removing visibility...")
	body.synchronizer.set_visibility_for(name.to_int(), false)
	synchronizer.set_visibility_for(body.name.to_int(), false)
	print("[AoI ACTION] Visibility removal complete.")
