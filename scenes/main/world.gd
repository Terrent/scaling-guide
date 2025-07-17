# scenes/main/World.gd
# --- ULTRA SIMPLE - LET GODOT'S MULTIPLAYER SPAWNER DO ITS JOB ---
extends Node

var player_scene: PackedScene = preload("res://scenes/entities/Player.tscn")
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner

func _ready() -> void:
	# Just set the spawn function - that's it!
	player_spawner.spawn_function = func(peer_id: int) -> Node:
		var player = player_scene.instantiate()
		player.name = str(peer_id)
		player.set_multiplayer_authority(peer_id)
		return player
	
	if multiplayer.is_server():
		# Server spawns its player
		player_spawner.spawn(1)
	else:
		# Client requests spawn
		NetworkManager.server_rpc_request_spawn.rpc_id(1)
