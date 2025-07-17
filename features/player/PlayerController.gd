# features/player/PlayerController.gd
# This script runs on all peers but only processes logic for the local player.
# It handles client-side prediction for immediate responsiveness and sends
# inputs to the server for authoritative processing and reconciliation.
class_name PlayerController
extends CharacterBody2D

# The speed at which the player moves.
@export var speed: float = 300.0

# A reference to the server-side "brain" of this player.
@onready var authoritative_node = $PlayerAuthoritative
# A reference to the player's camera.
@onready var camera = $Camera2D

# A sequence number for our inputs. This is crucial for reconciliation.
var sequence_id: int = 0
# A buffer of inputs that we have sent to the server but have not yet
# received confirmation for. This is the core of reconciliation.
var pending_inputs: Array = []


func _ready() -> void:
	# The camera should only be active for the player who owns this character.
	camera.enabled = is_multiplayer_authority()


func _physics_process(delta: float) -> void:
	# This entire function is the heart of Client-Side Prediction.
	# We only execute this logic if we have multiplayer authority over this node.
	if not is_multiplayer_authority():
		return

	# 1. Get Input and package it with a sequence number and delta time.
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var input_packet: Dictionary = {
		"sequence": sequence_id,
		"input_vector": input_vector,
		"delta": delta
	}

	# 2. Client-Side Prediction: Move the character locally, immediately.
	# This provides instant feedback to the player.
	_process_movement(input_packet)

	# 3. Buffer the input for potential re-simulation during reconciliation.
	pending_inputs.append(input_packet)

	# 4. Send the input to the server for authoritative processing.
	# --- REMEDIAL STEP ---
	# The correct method is rpc(). The 'unreliable' nature is handled by the
	# @rpc annotation on the receiving function in PlayerAuthoritative.gd.
	authoritative_node.rpc("receive_client_input", input_packet)

	# Increment the sequence ID for the next frame's input.
	sequence_id += 1


# A helper function to apply movement based on an input packet.
# This is separated so it can be reused by the reconciliation logic.
func _process_movement(input_packet: Dictionary) -> void:
	velocity = input_packet["input_vector"] * speed
	move_and_slide()


# This is a Remote Procedure Call that ONLY the server can invoke on this client.
# It is the "Reconciliation" part of our networking model.
@rpc("call_local", "reliable")
func client_rpc_reconcile_state(server_state: Dictionary) -> void:
	# This function is called by the server to force-correct our state if it
	# has detected a discrepancy (a "misprediction").
	if not is_multiplayer_authority():
		return

	# 1. Snap to the server's authoritative state.
	global_position = server_state["position"]
	velocity = server_state["velocity"]

	# 2. Get the sequence number of the last input the server processed.
	var last_processed_sequence: int = server_state["sequence"]

	# 3. Discard all inputs from our buffer that the server has already
	# acknowledged and processed.
	var i := 0
	while i < pending_inputs.size():
		if pending_inputs[i]["sequence"] <= last_processed_sequence:
			pending_inputs.remove_at(i)
		else:
			# This input is newer than the server state, so keep it.
			i += 1

	# 4. Re-apply all remaining "pending" inputs on top of the corrected state.
	# This re-simulates the frames that happened since the server's last update,
	# smoothly catching our predicted position up to where it should be without
	# a jarring visual teleport.
	for input_packet in pending_inputs:
		_process_movement(input_packet)
