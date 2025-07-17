# scenes/main/World.gd
# Now contains the custom spawn function used by the MultiplayerSpawner.
extends Node

# We preload the scene here, where it's needed.
var player_scene: PackedScene = preload("res://scenes/entities/Player.tscn")

@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner

# Track spawn count to position players differently
var spawn_count: int = 0

func _ready() -> void:
	print("World _ready() called on peer: ", multiplayer.get_unique_id())
	
	# CRITICAL: Set up the spawn function for the MultiplayerSpawner
	# This MUST be done before any spawn attempts
	player_spawner.spawn_function = _spawn_player_custom
	
	# Debug: Check if we're server or client
	if multiplayer.is_server():
		print("This is the SERVER/HOST")
	else:
		print("This is a CLIENT")
	
	# Now request spawn
	NetworkManager.rpc("server_rpc_request_spawn")


# This is our custom spawn function. The MultiplayerSpawner will call this.
func _spawn_player_custom(peer_id: int) -> Node:
	print("_spawn_player_custom called for peer: ", peer_id)
	
	# This function is called by the spawner at the correct time in the lifecycle.
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id)
	
	# Set spawn position so players don't overlap
	player.position = Vector2(spawn_count * 100, 0)
	spawn_count += 1
	
	print("Player spawned with name: ", player.name, " and authority: ", player.get_multiplayer_authority())
	print("  - Spawn position: ", player.position)
	
	# We return the configured node, and the spawner handles the rest.
	return player
