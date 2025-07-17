# test/TestMultiplayer.gd
# Drop this on any node in your scene to monitor multiplayer state
extends Node

var update_timer: Timer

func _ready():
	print("[MP_TEST] Multiplayer Test Monitor Started")
	
	# Create update timer
	update_timer = Timer.new()
	update_timer.wait_time = 2.0
	update_timer.timeout.connect(_print_multiplayer_state)
	add_child(update_timer)
	update_timer.start()
	
	# Connect to multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _print_multiplayer_state():
	print("\n[MP_TEST] ===== MULTIPLAYER STATE =====")
	print("[MP_TEST] My Peer ID: %d" % multiplayer.get_unique_id())
	print("[MP_TEST] Is Server: %s" % multiplayer.is_server())
	print("[MP_TEST] Has Multiplayer Peer: %s" % (multiplayer.multiplayer_peer != null))
	print("[MP_TEST] Connected Peers: %s" % multiplayer.get_peers())
	print("[MP_TEST] Current Scene: %s" % get_tree().current_scene.name)
	
	# Check for players in scene
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		# Try to find them manually
		var world = get_tree().get_root().get_node_or_null("World")
		if world:
			var player_count = 0
			for child in world.get_children():
				if child.name.is_valid_int():  # Player nodes are named with peer IDs
					player_count += 1
			print("[MP_TEST] Players in World: %d" % player_count)
		else:
			print("[MP_TEST] No World node found")
	else:
		print("[MP_TEST] Players in scene: %d" % players.size())
	
	print("[MP_TEST] =============================\n")

func _on_peer_connected(id):
	print("[MP_TEST] 🟢 Peer connected: %d" % id)

func _on_peer_disconnected(id):
	print("[MP_TEST] 🔴 Peer disconnected: %d" % id)

func _on_connected_to_server():
	print("[MP_TEST] ✅ Connected to server!")

func _on_connection_failed():
	print("[MP_TEST] ❌ Connection failed!")

func _on_server_disconnected():
	print("[MP_TEST] 🔌 Disconnected from server!")
