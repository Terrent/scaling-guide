# features/player/PlayerController.gd
# --- WITH DEBUG TRACES ---
class_name PlayerController
extends CharacterBody2D

@export var speed: float = 300.0

@onready var authoritative_node = $PlayerAuthoritative
@onready var camera = $Camera2D
@onready var area_of_interest: Area2D = $AreaOfInterest
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
var sequence_id: int = 0
var pending_inputs: Array = []
var debug_reconciliation: bool = true
var position_error_threshold: float = 5.0  # Don't reconcile tiny differences
var last_server_position: Vector2 = Vector2.ZERO
var smoothing_factor: float = 0.2  # For interpolation
func _ready() -> void:
	print("[PLAYER] ========== PLAYER READY START ==========")
	print("[PLAYER] Name: %s" % name)
	print("[PLAYER] Peer ID: %d" % multiplayer.get_unique_id())
	print("[PLAYER] Authority: %d" % get_multiplayer_authority())
	print("[PLAYER] Is Authority: %s" % is_multiplayer_authority())
	print("[PLAYER] Area monitoring: %s" % area_of_interest.monitoring)
	print("[PLAYER] Area monitorable: %s" % area_of_interest.monitorable)
	print("[PLAYER] Body collision layer: %d, mask: %d" % [collision_layer, collision_mask])
	print("[PLAYER] Area collision layer: %d, mask: %d" % [area_of_interest.collision_layer, area_of_interest.collision_mask])
	camera.enabled = is_multiplayer_authority()
	print("[PLAYER] Camera enabled: %s" % camera.enabled)
	
	var label = $SpriteLayers/Label
	if label:
		label.text = "Player " + name
		print("[PLAYER] Label set to: %s" % label.text)
	
	if is_multiplayer_authority():
		modulate = Color.GREEN
		if label:
			label.text += "\n(YOU)"
		print("[PLAYER] This is MY player - colored GREEN")
	else:
		modulate = Color.RED
		print("[PLAYER] This is REMOTE player - colored RED")
	
	print("[PLAYER] ========== PLAYER READY END ==========")
	add_to_group("players")
	
	# CRITICAL: Server-only visibility logic
	if multiplayer.is_server():
		area_of_interest.body_entered.connect(_on_area_of_interest_body_entered)
		area_of_interest.body_exited.connect(_on_area_of_interest_body_exited)

func _on_area_of_interest_body_exited(body: Node2D) -> void:
	if not body.is_in_group("players") or body == self:
		return
	
	# Remove visibility both ways
	body.synchronizer.set_visibility_for(name.to_int(), false)
	synchronizer.set_visibility_for(body.name.to_int(), false)
	
	print("[AoI] %s can no longer see %s" % [name, body.name])

func _on_area_of_interest_body_entered(body: Node2D) -> void:
	if not body.is_in_group("players") or body == self:
		return
	
	# THE SYMMETRIC HANDSHAKE
	# Make other player visible to me
	body.synchronizer.set_visibility_for(name.to_int(), true)
	# Make me visible to other player
	synchronizer.set_visibility_for(body.name.to_int(), true)
	
	print("[AoI] %s can now see %s" % [name, body.name])
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# CRITICAL FIX: Only send inputs when there's actual movement OR when stopping
	var has_input = input_vector.length() > 0.01
	var was_moving = velocity.length() > 0.01
	
	if not has_input and not was_moving:
		return  # Don't send anything if we're idle
	
	var input_packet: Dictionary = {
		"sequence": sequence_id,
		"input_vector": input_vector,
		"delta": delta,
		"timestamp": Time.get_ticks_msec()
	}

	_process_movement(input_packet)
	
	# Only track inputs that matter
	if has_input or was_moving:
		pending_inputs.append(input_packet)
	if pending_inputs.size() > 30:  # Half second at 60fps
	# Keep only recent inputs
		var cutoff_sequence = sequence_id - 30
		pending_inputs = pending_inputs.filter(func(input):
			return input["sequence"] > cutoff_sequence
	)
	
	if debug_reconciliation:
		print("[CLEANUP] Trimmed old inputs, kept %d" % pending_inputs.size())
	if multiplayer.is_server():
		authoritative_node.receive_client_input(input_packet)
	else:
		authoritative_node.rpc("receive_client_input", input_packet)

	sequence_id += 1

func _process_movement(input_packet: Dictionary) -> void:
	velocity = input_packet["input_vector"] * speed
	move_and_slide()

@rpc("any_peer", "call_remote", "reliable")
func receive_server_state(server_state: Dictionary) -> void:
	if is_multiplayer_authority():
		var position_error = global_position.distance_to(server_state["position"])
		
		if debug_reconciliation and position_error > 0.1:
			print("[RECONCILE] Error: %.2f pixels, Seq: %d, Pending: %d" % [
				position_error, 
				server_state["sequence"],
				pending_inputs.size()
			])
		
		# Only reconcile if error is significant
		if position_error > position_error_threshold:
			if debug_reconciliation:
				print("[RECONCILE] CORRECTING! Error too large: %.2f" % position_error)
			
			# Smooth the correction instead of snapping
			global_position = global_position.lerp(server_state["position"], smoothing_factor)
			velocity = server_state["velocity"]
			
			# Clear old inputs
			var last_processed_sequence: int = server_state["sequence"]
			pending_inputs = pending_inputs.filter(func(input): 
				return input["sequence"] > last_processed_sequence
			)
			
			# Re-apply pending inputs
			for input_packet in pending_inputs:
				_process_movement(input_packet)
		else:
			# Just update the sequence without changing position
			var last_processed_sequence: int = server_state["sequence"]
			pending_inputs = pending_inputs.filter(func(input): 
				return input["sequence"] > last_processed_sequence
			)
	else:
		# Remote players - just update directly
		global_position = server_state["position"]
		velocity = server_state["velocity"]
