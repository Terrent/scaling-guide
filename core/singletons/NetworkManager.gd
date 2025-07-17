# core/singletons/NetworkManager.gd
# --- FIXED WITH DEBUG TRACES ---
extends Node

const PORT = 8910
const MAX_PLAYERS = 16

var peer = ENetMultiplayerPeer.new()
var players: Dictionary = {}
var server_settings: Dictionary = {}

func _ready():
	print("[NETWORK] NetworkManager _ready")
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func create_server(settings: Dictionary) -> void:
	print("[NETWORK] Creating server...")
	server_settings = settings
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		printerr("[NETWORK] Failed to create server. Error code: ", error)
		return

	multiplayer.multiplayer_peer = peer
	_on_peer_connected(multiplayer.get_unique_id())
	print("[NETWORK] Server created successfully. Transitioning to World scene...")
	get_tree().change_scene_to_file("res://scenes/main/World.tscn")

func join_server(ip_address: String) -> void:
	print("[NETWORK] Creating client to join ", ip_address)
	var error = peer.create_client(ip_address, PORT)
	if error != OK:
		printerr("[NETWORK] Failed to create client. Error code: ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("[NETWORK] Client peer created, attempting connection...")

# This RPC is called by clients on the server to request to be spawned.
@rpc("any_peer", "call_remote", "reliable")
func server_rpc_request_spawn():
	if not multiplayer.is_server():
		print("[NETWORK] Non-server received spawn request, ignoring")
		return
		
	var peer_id = multiplayer.get_remote_sender_id()
	if peer_id == 0:
		peer_id = 1 
	
	print("[NETWORK] Server received spawn request from peer: ", peer_id)
	
	# Find the world's spawner and tell it to spawn the player for the requesting peer.
	var world = get_tree().get_root().get_node("World")
	if world and world.has_node("PlayerSpawner"):
		var spawner = world.get_node("PlayerSpawner")
		print("[NETWORK] Telling spawner to spawn player for peer: ", peer_id)
		spawner.spawn(peer_id)
	else:
		printerr("[NETWORK] CRITICAL: PlayerSpawner not found in the scene tree!")

func _on_connected_to_server():
	print("[NETWORK] Client connected to server! Peer ID: ", multiplayer.get_unique_id())
	print("[NETWORK] Client transitioning to World scene...")
	# THE FIX: Client needs to load the world scene when connected!
	get_tree().change_scene_to_file("res://scenes/main/World.tscn")
	# EventBus.connection_succeeded.emit()

func _on_connection_failed():
	print("[NETWORK] Failed to connect to server")
	# EventBus.connection_failed.emit("Connection attempt failed")

func _on_server_disconnected():
	print("[NETWORK] Server disconnected")
	# EventBus.server_disconnected.emit()

func _on_peer_connected(id: int) -> void:
	print("[NETWORK] Peer connected signal received for ID: ", id)
	
	if not multiplayer.is_server():
		return

	players[id] = { "name": "Player " + str(id) }
	
	# Add this debug check after spawning
	call_deferred("_check_late_join_visibility", id)

func _check_late_join_visibility(peer_id: int) -> void:
	await get_tree().process_frame
	
	print("[NETWORK] Checking late-join visibility for peer %d" % peer_id)
	var new_player = get_tree().get_root().find_child(str(peer_id), true, false)
	if not new_player:
		print("[NETWORK] ERROR: Could not find spawned player %d" % peer_id)
		return
	
	var all_players = get_tree().get_nodes_in_group("players")
	print("[NETWORK] Found %d total players" % all_players.size())
	
	for existing_player in all_players:
		if existing_player == new_player:
			continue
		
		print("[NETWORK] Checking distance between %s and %s" % [
			new_player.name, existing_player.name
		])
		
		if existing_player.area_of_interest.overlaps_body(new_player):
			print("[NETWORK] Players spawned near each other! Setting visibility...")
			new_player.synchronizer.set_visibility_for(existing_player.name.to_int(), true)
			existing_player.synchronizer.set_visibility_for(new_player.name.to_int(), true)
func _on_peer_disconnected(id: int) -> void:
	print("[NETWORK] Peer disconnected signal received for ID: ", id)
	
	if not multiplayer.is_server():
		print("[NETWORK] Not server, ignoring peer disconnection")
		return

	print("[NETWORK] Server removing player: ", id)
	if players.has(id):
		players.erase(id)
	# EventBus.peer_disconnected.emit(id)
