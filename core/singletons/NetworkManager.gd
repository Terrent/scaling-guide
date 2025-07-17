# core/singletons/NetworkManager.gd
# --- FINAL CORRECTED SCRIPT ---
extends Node

const PORT = 8910
const MAX_PLAYERS = 16

var peer = ENetMultiplayerPeer.new()
var players: Dictionary = {}
var server_settings: Dictionary = {}

# We no longer need to track spawned players here. The spawner handles it.

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
	get_tree().change_scene_to_file("res://scenes/main/World.tscn")

func join_server(ip_address: String) -> void:
	var error = peer.create_client(ip_address, PORT)
	if error != OK:
		printerr("Failed to create client. Error code: ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("Attempting to join server at ", ip_address)


# This RPC is called by clients on the server to request to be spawned.
@rpc("authority", "call_local", "reliable")
func server_rpc_request_spawn():
	if not multiplayer.is_server():
		return
		
	var peer_id = multiplayer.get_remote_sender_id()
	if peer_id == 0:
		# This can happen if the host calls this on itself, though our logic avoids this.
		# It's good practice to handle it anyway.
		peer_id = 1 
	
	print("[RPC_SPAWN_REQUEST] Received spawn request from peer: ", peer_id)
	
	# Find the world's spawner and tell it to spawn the player for the requesting peer.
	var world = get_tree().get_root().get_node("World")
	if world and world.has_node("PlayerSpawner"):
		var spawner = world.get_node("PlayerSpawner")
		print("[RPC_SPAWN_REQUEST] Requesting spawner to spawn player for peer: ", peer_id)
		spawner.spawn(peer_id)
	else:
		printerr("CRITICAL: PlayerSpawner not found in the scene tree!")


func _on_connected_to_server():
	print("Connected to server successfully")
	# EventBus.connection_succeeded.emit()

func _on_connection_failed():
	print("Failed to connect to server")
	# EventBus.connection_failed.emit("Connection attempt failed")

func _on_server_disconnected():
	print("Server disconnected")
	# EventBus.server_disconnected.emit()

func _on_peer_connected(id: int) -> void:
	if not multiplayer.is_server():
		return

	print("Player connected: ", id)
	players[id] = { "name": "Player " + str(id) }
	# EventBus.peer_connected.emit(id)
	
	# Note: We no longer tell the client to load the world here.
	# The client joins and then loads the world on its own.

func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return

	print("Player disconnected: ", id)
	if players.has(id):
		players.erase(id)
	# EventBus.peer_disconnected.emit(id)
	
	# The spawner will automatically handle despawning the player node,
	# but we should still clean up our own player list.
