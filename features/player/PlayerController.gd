# features/player/PlayerController.gd
# --- FINAL CORRECTED SCRIPT ---
class_name PlayerController
extends CharacterBody2D

@export var speed: float = 300.0

@onready var authoritative_node = $PlayerAuthoritative
@onready var camera = $Camera2D

var sequence_id: int = 0
var pending_inputs: Array = []

func _ready() -> void:
	print("[TRACER] PC _ready for player '%s' on peer %d. Authority is %d. Is this my player? %s" % [name, multiplayer.get_unique_id(), get_multiplayer_authority(), is_multiplayer_authority()])
	
	camera.enabled = is_multiplayer_authority()
	
	var label = $SpriteLayers/Label
	if label:
		label.text = "Player " + name
	
	if is_multiplayer_authority():
		modulate = Color.GREEN
		if label:
			label.text += "\n(YOU)"
	else:
		modulate = Color.RED

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input_vector.length() > 0:
		print("Player ", name, " input: ", input_vector)
	
	var input_packet: Dictionary = {
		"sequence": sequence_id,
		"input_vector": input_vector,
		"delta": delta
	}

	_process_movement(input_packet)
	pending_inputs.append(input_packet)

	# --- THE FIX IS HERE: RESTORING THE HOST vs CLIENT LOGIC ---
	# This avoids the "Node not found" error by preventing the host from sending an RPC to itself.
	if multiplayer.is_server():
		# If we are the server (and we must be, to have authority over player 1),
		# call the function directly. No RPC needed.
		authoritative_node.receive_client_input(input_packet)
	else:
		# If we are a client, send the input to the server via RPC.
		authoritative_node.rpc("receive_client_input", input_packet)

	sequence_id += 1

func _process_movement(input_packet: Dictionary) -> void:
	velocity = input_packet["input_vector"] * speed
	move_and_slide()

@rpc("any_peer", "call_remote", "reliable")
func receive_server_state(server_state: Dictionary) -> void:
	# --- DEBUG TRACER 2: Did this machine receive a state update? For which player? ---
	print("[STATE_RECEIVE] Machine %d received a state update for player %s. Is it mine? %s" % [multiplayer.get_unique_id(), name, is_multiplayer_authority()])

	if is_multiplayer_authority():
		# This update is for OUR player. We need to reconcile.
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
		# This update is for a REMOTE player. Just snap their state.
		global_position = server_state["position"]
		velocity = server_state["velocity"]
