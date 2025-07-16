# core/singletons/NetworkManager.gd
# Manages the multiplayer session, including server creation, client connection,
# and player object lifecycle. Adheres to the server-authoritative model.
extends Node

const PORT = 8910
const MAX_PLAYERS = 16

var peer = ENetMultiplayerPeer.new()

# Server-side dictionary of connected players.
# Key: peer_id (int), Value: Dictionary of player info (e.g., name).
var players: Dictionary = {}
# Server-side dictionary of host-configured settings (e.g., can_marry_npc).
var server_settings: Dictionary = {}

# --- Public API ---

# Called by the MainMenu UI to create a game server.
func create_server(settings: Dictionary) -> void:
	server_settings = settings
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error!= OK:
		printerr("Failed to create server. Error code: ", error)
		return

	multiplayer.multiplayer_peer = peer
	# Connect signals to handle players joining and leaving.
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	# Manually process the host (server) as the first player.
	# The server always has a unique ID of 1.
	_on_peer_connected(multiplayer.get_unique_id())
	print("Server created successfully. Waiting for players...")

# Called by the MainMenu UI to join an existing game.
func join_server(ip_address: String) -> void:
	var error = peer.create_client(ip_address, PORT)
	if error!= OK:
		printerr("Failed to create client. Error code: ", error)
		return
	
	multiplayer.multiplayer_peer = peer
	print("Attempting to join server at ", ip_address)


# --- Signal Callbacks (Server-Side Logic) ---

# This function executes ONLY on the server when a new peer connects.
func _on_peer_connected(peer_id: int) -> void:
	# Guard clause to ensure this logic only runs on the server instance.
	if not multiplayer.is_server():
		return

	print("Player connected: ", peer_id)
	# Initialize a data structure for the new player.
	# This will later be populated with data from the lobby (name, archetype choice).
	players[peer_id] = { "name": "Player " + str(peer_id) }

	# The GDD specifies that a MultiplayerSpawner will handle the actual
	# instantiation of the player scene. We will create this spawner in a later step.
	# For now, this function's responsibility is to track the connected player.
	# The spawner will later handle spawning a character for the new peer_id. [1, 1]

# This function executes ONLY on the server when a peer disconnects.
func _on_peer_disconnected(peer_id: int) -> void:
	# Guard clause to ensure this logic only runs on the server instance.
	if not multiplayer.is_server():
		return

	print("Player disconnected: ", peer_id)
	if players.has(peer_id):
		players.erase(peer_id)
		# As with spawning, the MultiplayerSpawner will automatically handle
		# despawning the node whose authority (the disconnected peer) is gone.
		# This keeps our manager's logic clean and focused. [1]
