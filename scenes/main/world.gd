# scenes/main/World.gd
# --- FINAL CORRECTED SCRIPT ---
extends Node

var player_scene: PackedScene = preload("res://scenes/entities/Player.tscn")
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner

func _ready() -> void:
	# This tracer is important. It runs on every peer when they load the world.
	print("[TRACER] World _ready on peer %d. Is server? %s" % [multiplayer.get_unique_id(), multiplayer.is_server()])

	# The spawner needs to know HOW to create a player when it's told to.
	# This function will be called on every peer (including the server) when a player is spawned.
	player_spawner.spawn_function = Callable(self, "_create_player_node")
	
	if multiplayer.is_server():
		# The server spawns its own player character immediately.
		# The MultiplayerSpawner will automatically replicate this to clients when they join.
		print("[TRACER] Server is spawning itself (peer 1).")
		player_spawner.spawn(1)
	else:
		# This is a client. After loading the world, it must ask the server to spawn its character.
		# We send the request via an RPC to the server.
		# Note: We are calling an RPC on the NetworkManager singleton, as it's guaranteed to exist.
		print("[TRACER] Client (peer %d) is ready, requesting spawn from server." % multiplayer.get_unique_id())
		NetworkManager.server_rpc_request_spawn.rpc_id(1)

# This function is called BY THE SPAWNER on all peers to create the actual player node.
# The spawner handles the replication; this function just defines the object to be created.
func _create_player_node(peer_id: int) -> Node:
	print("[SPAWNER] Machine %d is creating instance for player %d" % [multiplayer.get_unique_id(), peer_id])
	
	var player = player_scene.instantiate()
	player.name = str(peer_id) # The spawner requires unique names for its children.
	
	# We MUST set the authority here, before the node's _ready() is called.
	player.set_multiplayer_authority(peer_id)
	
	return player
