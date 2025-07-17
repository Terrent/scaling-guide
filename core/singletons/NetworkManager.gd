# core/singletons/NetworkManager.gd
extends Node

const PORT = 8910
const MAX_PLAYERS = 16

var peer = ENetMultiplayerPeer.new()
var players: Dictionary = {}
var server_settings: Dictionary = {}

var player_spawner: MultiplayerSpawner

func _ready():
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func create_server(settings: Dictionary) -> void:
	server_settings = settings
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		printerr("Failed to create server. Error code: ", error)
		return

	multiplayer.multiplayer_peer = peer
	
	_on_peer_connected(multiplayer.get_unique_id())
	print("Server created successfully. Waiting for players...")

func join_server(ip_address: String) -> void:
	var error = peer.create_client(ip_address, PORT)
	if error != OK:
		printerr("Failed to create client. Error code: ", error)
		return
	
	multiplayer.multiplayer_peer = peer
	print("Attempting to join server at ", ip_address)

@rpc("any_peer", "reliable")
func server_rpc_request_spawn():
	var peer_id = multiplayer.get_remote_sender_id()
	print("Received spawn request from peer: ", peer_id)
	_spawn_player(peer_id)

@rpc("authority", "call_local", "reliable")
func client_rpc_load_world(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func _on_connected_to_server():
	print("Connected to server successfully")
	EventBus.connection_succeeded.emit()

func _on_connection_failed():
	print("Failed to connect to server")
	EventBus.connection_failed.emit("Connection attempt failed")

func _on_server_disconnected():
	print("Server disconnected")
	EventBus.server_disconnected.emit()

func _on_peer_connected(id: int) -> void:
	if not multiplayer.is_server():
		return

	print("Player connected: ", id)
	players[id] = { "name": "Player " + str(id) }
	EventBus.peer_connected.emit(id)
	
	rpc_id(id, "client_rpc_load_world", "res://scenes/main/World.tscn")

func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return

	print("Player disconnected: ", id)
	if players.has(id):
		players.erase(id)
	
	EventBus.peer_disconnected.emit(id)
	
	var player_node = get_tree().get_root().find_child(str(id), true, false)
	if player_node:
		player_node.queue_free()

func _spawn_player(peer_id: int):
	if not multiplayer.is_server():
		return

	if not is_instance_valid(player_spawner):
		player_spawner = get_tree().get_root().find_child("PlayerSpawner", true, false)

	if not is_instance_valid(player_spawner):
		printerr("CRITICAL: PlayerSpawner not found in the scene tree!")
		return

	print("Requesting spawner to spawn player for peer: ", peer_id)
	player_spawner.spawn(peer_id)
