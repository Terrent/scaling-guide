extends GutTest

# Since EventBus is a singleton, we need to be careful
var signal_received = false
var signal_params = []

func before_each():
	signal_received = false
	signal_params = []

func test_server_signals_exist():
	assert_has_signal(EventBus, "server_day_passed")
	assert_has_signal(EventBus, "server_player_action_completed")
	assert_has_signal(EventBus, "server_item_crafted")
	assert_has_signal(EventBus, "server_npc_gifted")
	assert_has_signal(EventBus, "server_enemy_defeated")
	assert_has_signal(EventBus, "server_cooperative_action_completed")
	assert_has_signal(EventBus, "server_festival_state_changed")
	assert_has_signal(EventBus, "server_global_discovery_unlocked")
	assert_has_signal(EventBus, "server_community_quest_progress")
	assert_has_signal(EventBus, "server_community_quest_completed")
	assert_has_signal(EventBus, "server_player_assigned_room")

func test_client_signals_exist():
	assert_has_signal(EventBus, "client_player_data_updated")
	assert_has_signal(EventBus, "client_inventory_changed")
	assert_has_signal(EventBus, "client_quest_log_updated")
	assert_has_signal(EventBus, "client_dialogue_started")
	assert_has_signal(EventBus, "client_dialogue_ended")

func test_can_emit_and_receive_server_day_passed():
	EventBus.server_day_passed.connect(_on_signal_with_one_param)
	EventBus.server_day_passed.emit(5)
	
	assert_true(signal_received)
	assert_eq(signal_params[0], 5)
	
	EventBus.server_day_passed.disconnect(_on_signal_with_one_param)

func test_can_emit_and_receive_server_item_crafted():
	EventBus.server_item_crafted.connect(_on_signal_with_three_params)
	EventBus.server_item_crafted.emit(123, &"iron_sword", 1)
	
	assert_true(signal_received)
	assert_eq(signal_params[0], 123)
	assert_eq(signal_params[1], &"iron_sword")
	assert_eq(signal_params[2], 1)
	
	EventBus.server_item_crafted.disconnect(_on_signal_with_three_params)

# Helper functions for signal testing
func _on_signal_with_one_param(param1):
	signal_received = true
	signal_params = [param1]

func _on_signal_with_three_params(param1, param2, param3):
	signal_received = true
	signal_params = [param1, param2, param3]
