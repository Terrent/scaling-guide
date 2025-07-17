# scenes/main/World.gd
# This script runs on the main world scene for ALL peers (host and clients).
# Its purpose is to notify the server that this peer has loaded the world
# and is ready to have its character spawned.
extends Node

# _ready() is called after the node and all its children have entered the scene tree.
func _ready() -> void:
	# --- REMEDIAL STEP ---
	# All peers, including the host, now use this RPC to request their character.
	# The server will receive this and spawn the player for the sender.
	NetworkManager.rpc("server_rpc_request_spawn")
