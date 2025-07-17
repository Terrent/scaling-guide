# core/singletons/NetworkManager.gd
# Manages the multiplayer session, now correctly delegating spawning to the MultiplayerSpawner.
extends Node

const PORT = 8910
const MAX_PLAYERS = 16

var peer = ENetMultiplayerPeer.new()
# We no longer preload the player scene here; the spawner's custom function will.

var players: Dictionary = {}
var server_settings: Dictionary = {}

# --- REMEDIAL STEP ---
# A variable to hold a reference to the spawner in the world.
var player_spawner: MultiplayerSpawner


# --- Public API ---

func create_server(settings: Dictionary) -> void:
	server_settings = settings
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error!= OK:
		printerr("Failed to create server. Error code: ", error)
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	_on_peer_connected(multiplayer.get_unique_id())
	print("Server created successfully. Waiting for players...")


func join_server(ip_address: String) -> void:
	var error = peer.create_client(ip_address, PORT)
	if error!= OK:
		printerr("Failed to create client. Error code: ", error)
		return
	
	multiplayer.multiplayer_peer = peer
	print("Attempting to join server at ", ip_address)


# --- RPC Handlers (Server-Side Logic) ---

@rpc("any_peer", "reliable")
func server_rpc_request_spawn():
	var peer_id = multiplayer.get_remote_sender_id()
	print("Received spawn request from peer: ", peer_id)
	_spawn_player(peer_id)


@rpc("authority", "call_local", "reliable")
func client_rpc_load_world(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


# --- Signal Callbacks (Server-Side Logic) ---

func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	print("Player connected: ", peer_id)
	players[peer_id] = { "name": "Player " + str(peer_id) }

	rpc_id(peer_id, "client_rpc_load_world", "res://scenes/main/World.tscn")


func _on_peer_disconnected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	print("Player disconnected: ", peer_id)
	if players.has(peer_id):
		players.erase(peer_id)
	
	var player_node = get_tree().get_root().find_child(str(peer_id), true, false)
	if player_node:
		player_node.queue_free()


# --- Internal Logic ---

func _spawn_player(peer_id: int):
	if not multiplayer.is_server():
		return

	# --- REMEDIAL STEP ---
	# If we don't have a reference to the spawner yet, find it.
	# This only happens once, for the host.
	if not is_instance_valid(player_spawner):
		player_spawner = get_tree().get_root().find_child("PlayerSpawner", true, false)

	if not is_instance_valid(player_spawner):
		printerr("CRITICAL: PlayerSpawner not found in the scene tree!")
		return

	print("Requesting spawner to spawn player for peer: ", peer_id)
	# Call the spawner's spawn method. We pass the peer_id as data,
	# which will be given to our custom spawn function.
	player_spawner.spawn(peer_id)
