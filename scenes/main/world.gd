# scenes/main/World.gd
# Now contains the custom spawn function used by the MultiplayerSpawner.
extends Node

# We preload the scene here, where it's needed.
var player_scene: PackedScene = preload("res://scenes/entities/Player.tscn")

func _ready() -> void:
	NetworkManager.rpc("server_rpc_request_spawn")


# --- REMEDIAL STEP ---
# This is our new custom spawn function. It will be assigned to the
# MultiplayerSpawner node in the editor.
func _spawn_player_custom(peer_id: int) -> Node:
	# This function is called by the spawner at the correct time in the lifecycle.
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id)
	# We return the configured node, and the spawner handles the rest.
	return player
