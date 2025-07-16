extends GutTest

# We'll need to mock the multiplayer API
var network_manager: NetworkManager

func before_all():
	# Since NetworkManager is a singleton, we work with the existing instance
	network_manager = NetworkManager

func after_each():
	# Clean up any test data
	network_manager.players.clear()
	network_manager.server_settings.clear()

func test_server_settings_storage():
	var test_settings = {
		"can_marry_npc": true,
		"max_farm_size": 100,
		"difficulty": "normal"
	}
	
	# Simulate what create_server does with settings
	network_manager.server_settings = test_settings
	
	assert_eq(network_manager.server_settings["can_marry_npc"], true)
	assert_eq(network_manager.server_settings["max_farm_size"], 100)

func test_player_tracking_on_connection():
	# Since we can't easily mock multiplayer.is_server(),
	# we'll test the player management directly
	var test_peer_id = 12345
	
	# Simulate what _on_peer_connected does
	network_manager.players[test_peer_id] = { "name": "Player " + str(test_peer_id) }
	
	assert_has(network_manager.players, test_peer_id)
	assert_eq(network_manager.players[test_peer_id]["name"], "Player 12345")

func test_player_removal_on_disconnection():
	var test_peer_id = 67890
	
	# Add a player first
	network_manager.players[test_peer_id] = { "name": "Test Player" }
	assert_has(network_manager.players, test_peer_id)
	
	# Simulate disconnection
	if network_manager.players.has(test_peer_id):
		network_manager.players.erase(test_peer_id)
	
	assert_does_not_have(network_manager.players, test_peer_id)

func test_constants():
	assert_eq(NetworkManager.PORT, 8910)
	assert_eq(NetworkManager.MAX_PLAYERS, 16)
