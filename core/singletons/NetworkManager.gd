# core/singletons/NetworkManager.gd
# Manages the multiplayer session with a robust, unified connection flow.
extends Node

const PORT = 8910
const MAX_PLAYERS = 16

var peer = ENetMultiplayerPeer.new()
var player_scene: PackedScene = preload("res://scenes/entities/Player.tscn")

var players: Dictionary = {}
var server_settings: Dictionary = {}


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

	# --- REMEDIAL STEP ---
	# The server now treats itself like any other client. It connects and
	# immediately gets the command to load the world in _on_peer_connected.
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

# This RPC is called by a peer from World.gd once it has loaded the scene.
@rpc("any_peer", "reliable")
func server_rpc_request_spawn():
	var peer_id = multiplayer.get_remote_sender_id()
	print("Received spawn request from peer: ", peer_id)
	_spawn_player(peer_id)


# --- REMEDIAL STEP ---
# This new RPC is called by the server on a specific client to tell it to load the world.
@rpc("authority", "reliable")
func client_rpc_load_world(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


# --- Signal Callbacks (Server-Side Logic) ---

func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	print("Player connected: ", peer_id)
	players[peer_id] = { "name": "Player " + str(peer_id) }

	# --- REMEDIAL STEP ---
	# Command the newly connected peer (whether it's the host or a client)
	# to load the main world scene.
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

	print("Spawning player for peer: ", peer_id)
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id)

	var player_container = get_tree().get_root().find_child("PlayerContainer", true, false)
	if player_container:
		player_container.add_child(player)
	else:
		printerr("CRITICAL: Could not find PlayerContainer to spawn player!")
