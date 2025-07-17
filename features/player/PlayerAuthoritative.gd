# features/player/PlayerAuthoritative.gd
# --- CORRECTED SCRIPT ---
class_name PlayerAuthoritative
extends Node

@onready var player_controller: PlayerController = get_parent()
var last_processed_sequence: int = -1
@onready var state_update_timer: Timer = Timer.new()

func _ready() -> void:
	if not multiplayer.is_server():
		set_physics_process(false)
		return
	
	state_update_timer.wait_time = 0.1 # Send updates 10 times per second
	state_update_timer.timeout.connect(_on_state_update_timer_timeout)
	add_child(state_update_timer)
	state_update_timer.start()

@rpc("any_peer", "call_local", "unreliable")
func receive_client_input(input_packet: Dictionary) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	
	if sender_id != player_controller.get_multiplayer_authority():
		push_warning("Rejected input from non-authoritative peer %d for player %s" % [sender_id, player_controller.name])
		return

	if input_packet["sequence"] <= last_processed_sequence:
		return

	player_controller._process_movement(input_packet)
	last_processed_sequence = input_packet["sequence"]

func _on_state_update_timer_timeout() -> void:
	var state_snapshot: Dictionary = {
		"position": player_controller.global_position,
		"velocity": player_controller.velocity,
		"sequence": last_processed_sequence
	}
	
	# --- DEBUG TRACER 1: Is the server broadcasting this player's state? ---
	print("[STATE_BROADCAST] Server (peer %d) is broadcasting state for player %s" % [multiplayer.get_unique_id(), player_controller.name])
	
	player_controller.rpc("receive_server_state", state_snapshot)
