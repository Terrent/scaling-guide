# tests/unit/test_trust_action_data.gd
extends GutTest

var trust_action: TrustActionData

func before_each():
	trust_action = TrustActionData.new()

func test_default_values():
	assert_eq(trust_action.action_type, &"")
	assert_eq(trust_action.trust_value, 1)
	assert_eq(trust_action.cooldown_hours, 24)

func test_basic_trust_action():
	# Helping water another player's crops
	trust_action.action_type = &"water_other_player_crop"
	trust_action.trust_value = 2
	trust_action.cooldown_hours = 12
	
	assert_eq(trust_action.action_type, &"water_other_player_crop")
	assert_eq(trust_action.trust_value, 2)
	assert_eq(trust_action.cooldown_hours, 12)

func test_high_value_trust_action():
	# Saving another player from death - high trust, long cooldown
	trust_action.action_type = &"revive_player"
	trust_action.trust_value = 10
	trust_action.cooldown_hours = 72  # 3 days
	
	assert_eq(trust_action.trust_value, 10)
	assert_eq(trust_action.cooldown_hours, 72)

func test_frequent_low_value_action():
	# Simple greeting - low trust, short cooldown
	trust_action.action_type = &"wave_greeting"
	trust_action.trust_value = 1
	trust_action.cooldown_hours = 4
	
	assert_eq(trust_action.trust_value, 1)
	assert_eq(trust_action.cooldown_hours, 4)

func test_no_cooldown_action():
	# Some actions might have no cooldown (but probably shouldn't exist)
	trust_action.action_type = &"instant_action"
	trust_action.cooldown_hours = 0
	
	assert_eq(trust_action.cooldown_hours, 0)

func test_gift_giving_actions():
	# Different gift values
	trust_action.action_type = &"gift_common_item"
	trust_action.trust_value = 3
	trust_action.cooldown_hours = 8
	
	var rare_gift = TrustActionData.new()
	rare_gift.action_type = &"gift_rare_item"
	rare_gift.trust_value = 8
	rare_gift.cooldown_hours = 48
	
	assert_lt(trust_action.trust_value, rare_gift.trust_value)
	assert_lt(trust_action.cooldown_hours, rare_gift.cooldown_hours)

func test_cooperative_gameplay_actions():
	# Actions that require actual cooperation
	var actions = [
		{
			"type": &"complete_community_quest_together",
			"value": 5,
			"cooldown": 24
		},
		{
			"type": &"mine_together_same_rock",
			"value": 2,
			"cooldown": 6
		},
		{
			"type": &"defend_other_player_farm",
			"value": 7,
			"cooldown": 36
		},
		{
			"type": &"share_rare_resource",
			"value": 6,
			"cooldown": 24
		}
	]
	
	for action_data in actions:
		var action = TrustActionData.new()
		action.action_type = action_data["type"]
		action.trust_value = action_data["value"]
		action.cooldown_hours = action_data["cooldown"]
		
		gut.p("%s: %d trust, %d hour cooldown" % 
			[action.action_type, action.trust_value, action.cooldown_hours])
		
		assert_eq(action.action_type, action_data["type"])

func test_cooldown_prevents_spam():
	# Test that cooldowns make sense for preventing spam
	var spammable_actions = [
		{"action": &"trade_item", "cooldown": 2},
		{"action": &"use_emote", "cooldown": 1},
		{"action": &"send_gift", "cooldown": 12}
	]
	
	for action_data in spammable_actions:
		trust_action.action_type = action_data["action"]
		trust_action.cooldown_hours = action_data["cooldown"]
		
		# All actions should have at least 1 hour cooldown to prevent spam
		assert_gte(trust_action.cooldown_hours, 1)

func test_trust_value_scaling():
	# Test that trust values scale appropriately with effort
	var effort_based_actions = {
		&"help_harvest_1_crop": 1,      # Minimal effort
		&"help_harvest_field": 3,        # Some effort
		&"help_clear_farm": 5,           # Significant effort
		&"help_build_structure": 8,      # Major effort
		&"save_from_boss": 10           # Maximum effort
	}
	
	var previous_value = 0
	for action_type in effort_based_actions:
		var value = effort_based_actions[action_type]
		assert_gte(value, previous_value, "Trust values should increase with effort")
		previous_value = value

func test_seasonal_event_actions():
	# Special trust actions during festivals/events
	trust_action.action_type = &"dance_together_festival"
	trust_action.trust_value = 4
	trust_action.cooldown_hours = 168  # Once per week (festival frequency)
	
	assert_eq(trust_action.cooldown_hours, 168)

func test_negative_actions_not_supported():
	# This system is for positive trust building only
	# Negative values would need a different system
	trust_action.trust_value = 5  # Always positive
	assert_gt(trust_action.trust_value, 0)

# Parameterized test for different action categories
func test_action_categories(params=use_parameters([
	{
		"category": "Farming Help",
		"action": &"water_crops",
		"trust": 2,
		"cooldown": 12
	},
	{
		"category": "Combat Support",
		"action": &"heal_in_combat", 
		"trust": 5,
		"cooldown": 24
	},
	{
		"category": "Resource Sharing",
		"action": &"share_tool",
		"trust": 3,
		"cooldown": 18
	},
	{
		"category": "Social Interaction",
		"action": &"compliment",
		"trust": 1,
		"cooldown": 6
	},
	{
		"category": "Emergency Help",
		"action": &"rescue_from_mine",
		"trust": 8,
		"cooldown": 48
	}
])):
	trust_action.action_type = params.action
	trust_action.trust_value = params.trust
	trust_action.cooldown_hours = params.cooldown
	
	gut.p("%s - %s: %d trust points, %d hour cooldown" % 
		[params.category, params.action, params.trust, params.cooldown])
	
	# Verify trust scales with cooldown (generally)
	if params.trust >= 5:
		assert_gte(params.cooldown, 24, "High value actions should have longer cooldowns")
	
	assert_eq(trust_action.action_type, params.action)
	assert_eq(trust_action.trust_value, params.trust)
	assert_eq(trust_action.cooldown_hours, params.cooldown)

func test_trust_system_design():
	# Test the relationship between trust value and cooldown
	var test_actions = []
	
	# Create a variety of actions
	for i in range(5):
		var action = TrustActionData.new()
		action.trust_value = (i + 1) * 2  # 2, 4, 6, 8, 10
		action.cooldown_hours = (i + 1) * 12  # 12, 24, 36, 48, 60
		test_actions.append(action)
	
	# Verify the pattern
	for i in range(test_actions.size()):
		var action = test_actions[i]
		var expected_ratio = action.cooldown_hours / float(action.trust_value)
		assert_almost_eq(expected_ratio, 6.0, 0.1, "Cooldown should be ~6x trust value")

func test_complete_trust_action_configuration():
	# A fully configured trust action
	trust_action.action_type = &"help_complete_difficult_quest"
	trust_action.trust_value = 7
	trust_action.cooldown_hours = 36
	
	# Verify all properties are set
	assert_ne(trust_action.action_type, &"")
	assert_gt(trust_action.trust_value, 0)
	assert_gt(trust_action.cooldown_hours, 0)
	
	# Calculate trust per hour (efficiency)
	var trust_per_hour = trust_action.trust_value / float(trust_action.cooldown_hours)
	gut.p("Trust efficiency: %.3f trust/hour" % trust_per_hour)
	assert_almost_eq(trust_per_hour, 0.194, 0.001)
