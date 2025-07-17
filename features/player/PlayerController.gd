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
	if multiplayer.is_server():
		# --- NEW DEBUG PRINT ---
		print("[AoI SETUP] Player '%s' (SERVER) is connecting its Area2D signals." % name)
		area_of_interest.body_entered.connect(_on_area_of_interest_body_entered)
		area_of_interest.body_exited.connect(_on_area_of_interest_body_exited)


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

func _on_area_of_interest_body_exited(body: Node2D) -> void:
	# --- NEW DEBUG PRINT ---
	# This is the most important print. It tells us if the signal fired at all.
	print("\n--- AoI EVENT ---")
	print("[AoI] EXIT detected on '%s's Area. Body that exited: '%s'." % [name, body.name])

	# This is your existing guard clause. We'll add a print to see if it's the problem.
	if not body.is_in_group("players") or body == self:
		# --- NEW DEBUG PRINT ---
		print("[AoI] Body '%s' is not a player or is self. Ignoring." % body.name)
		return
	
	# --- NEW DEBUG PRINTS ---
	# These prints confirm we are about to call the functions to hide the players.
	print("[AoI ACTION] HIDING: Telling synchronizer on '%s' to HIDE from peer %d." % [name, body.name.to_int()])
	print("[AoI ACTION] HIDING: Telling synchronizer on '%s' to HIDE from peer %d." % [body.name, name.to_int()])

	# Your existing logic.
	synchronizer.set_visibility_for(body.name.to_int(), false)
	body.synchronizer.set_visibility_for(name.to_int(), false)


func _on_area_of_interest_body_entered(body: Node2D) -> void:
	# --- NEW DEBUG PRINT ---
	print("\n--- AoI EVENT ---")
	print("[AoI] ENTER detected on '%s's Area. Body that entered: '%s'." % [name, body.name])

	if not body.is_in_group("players") or body == self:
		# --- NEW DEBUG PRINT ---
		print("[AoI] Body '%s' is not a player or is self. Ignoring." % body.name)
		return
	
	# --- NEW DEBUG PRINTS ---
	print("[AoI ACTION] SHOWING: Telling synchronizer on '%s' to SHOW to peer %d." % [name, body.name.to_int()])
	print("[AoI ACTION] SHOWING: Telling synchronizer on '%s' to SHOW to peer %d." % [body.name, name.to_int()])

	# Your existing logic.
	synchronizer.set_visibility_for(body.name.to_int(), true)
	body.synchronizer.set_visibility_for(name.to_int(), true)
