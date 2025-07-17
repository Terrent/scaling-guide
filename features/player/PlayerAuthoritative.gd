# features/player/PlayerAuthoritative.gd
# This script runs ONLY on the server instance of the player. It is the
# "brain" or "arbiter" of the player character. It receives inputs from the
# client, validates them, processes them against the authoritative game state,
# and sends back state corrections to the client for reconciliation.
class_name PlayerAuthoritative
extends Node

# A reference to the parent Player node, which contains the CharacterBody2D.
@onready var player_controller: PlayerController = get_parent()

# The sequence number of the last input packet we processed from the client.
# Initialized to -1 so the first packet (sequence 0) is always processed.
var last_processed_sequence: int = -1

# A timer to control how often we send state updates back to the client.
# Sending updates every single frame is unnecessary and wastes bandwidth.
@onready var state_update_timer: Timer = Timer.new()


func _ready() -> void:
	# This script's logic should only ever run on the server.
	if not multiplayer.is_server():
		# Disable processing if we are not the server to save resources.
		set_physics_process(false)
		return
	
	# Configure the timer to fire 10 times per second (0.1s interval).
	# This is a good balance between responsiveness and network efficiency.
	state_update_timer.wait_time = 0.1
	state_update_timer.timeout.connect(_on_state_update_timer_timeout)
	add_child(state_update_timer)
	state_update_timer.start()


# This RPC is called by the client's PlayerController.gd script.
# The 'any_peer' keyword allows any client to call this function on the server.
@rpc("any_peer", "unreliable")
func receive_client_input(input_packet: Dictionary) -> void:
	# --- Security and Validation ---
	# 1. Security Check: Ensure the RPC is from the peer that actually owns
	#    the parent Player node. This prevents one client from sending inputs
	#    for another client's character.
	if multiplayer.get_remote_sender_id() != player_controller.get_multiplayer_authority():
		return # Ignore input from non-authoritative peers.

	# 2. Validation Check: Ensure we don't process old or out-of-order packets.
	if input_packet["sequence"] <= last_processed_sequence:
		return

	# Debug: Print when we receive input (only if there's actual movement)
	if input_packet["input_vector"].length() > 0:
		print("Server received input from player ", player_controller.name, ": ", input_packet["input_vector"])

	# --- Authoritative Processing ---
	# If the checks pass, we trust the input. The server now runs the exact
	# same movement logic as the client did for its prediction.
	player_controller._process_movement(input_packet)
	
	# Update the last processed sequence number.
	last_processed_sequence = input_packet["sequence"]


# This function runs on the server at a fixed interval (10x per second).
func _on_state_update_timer_timeout() -> void:
	# Package the server's true, authoritative state into a dictionary.
	var state_snapshot: Dictionary = {
		"position": player_controller.global_position,
		"velocity": player_controller.velocity,
		"sequence": last_processed_sequence
	}
	
	# Send this state snapshot back to the owning client via a reliable RPC.
	# The client's PlayerController will use this to reconcile its state.
	var target_peer_id = player_controller.get_multiplayer_authority()
	player_controller.rpc_id(target_peer_id, "client_rpc_reconcile_state", state_snapshot)
