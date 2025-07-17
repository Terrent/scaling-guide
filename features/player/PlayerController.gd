# features/player/PlayerController.gd
# --- WITH DEBUG TRACES ---
class_name PlayerController
extends CharacterBody2D

@export var speed: float = 300.0

@onready var authoritative_node = $PlayerAuthoritative
@onready var camera = $Camera2D

var sequence_id: int = 0
var pending_inputs: Array = []

func _ready() -> void:
	print("[PLAYER] ========== PLAYER READY START ==========")
	print("[PLAYER] Name: %s" % name)
	print("[PLAYER] Peer ID: %d" % multiplayer.get_unique_id())
	print("[PLAYER] Authority: %d" % get_multiplayer_authority())
	print("[PLAYER] Is Authority: %s" % is_multiplayer_authority())
	
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

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Only print if there's actual input
	if input_vector.length() > 0.01:
		print("[PLAYER] Input detected for %s: %s" % [name, input_vector])
	
	var input_packet: Dictionary = {
		"sequence": sequence_id,
		"input_vector": input_vector,
		"delta": delta
	}

	_process_movement(input_packet)
	pending_inputs.append(input_packet)

	if multiplayer.is_server():
		# Direct call for host
		authoritative_node.receive_client_input(input_packet)
	else:
		# RPC for clients
		authoritative_node.rpc("receive_client_input", input_packet)

	sequence_id += 1

func _process_movement(input_packet: Dictionary) -> void:
	velocity = input_packet["input_vector"] * speed
	move_and_slide()

@rpc("any_peer", "call_remote", "reliable")
func receive_server_state(server_state: Dictionary) -> void:
	# Only log every 10th update to reduce spam
	if server_state["sequence"] % 10 == 0:
		print("[PLAYER] State update for %s from server. Authority: %s" % [name, is_multiplayer_authority()])

	if is_multiplayer_authority():
		# Reconciliation for our player
		global_position = server_state["position"]
		velocity = server_state["velocity"]

		var last_processed_sequence: int = server_state["sequence"]
		
		var i := 0
		while i < pending_inputs.size():
			if pending_inputs[i]["sequence"] <= last_processed_sequence:
				pending_inputs.remove_at(i)
			else:
				i += 1

		for input_packet in pending_inputs:
			_process_movement(input_packet)
			
	else:
		# Direct state update for remote players
		global_position = server_state["position"]
		velocity = server_state["velocity"]
