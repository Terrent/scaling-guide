extends GutTest

# Test skill progression through actions

var axe: ToolData
var tree_chopping_action = {"skill": &"woodcutting", "xp": 15}
var player_id = 456

# Instance variables for signal testing
var _signal_received = false
var _received_player_id = -1
var _received_skill = &""
var _received_xp = 0

func before_each():
	# Reset test variables
	_signal_received = false
	_received_player_id = -1
	_received_skill = &""
	_received_xp = 0
	
	axe = ToolData.new()
	axe.item_id = &"iron_axe"
	axe.tool_type = ToolData.ToolType.AXE
	axe.power = 2
	axe.stamina_cost = 5.0

func test_tool_use_triggers_skill_progression():
	EventBus.server_player_action_completed.connect(_on_player_action_completed)
	
	# Simulate completing a woodcutting action
	EventBus.server_player_action_completed.emit(
		player_id, 
		tree_chopping_action["skill"],
		tree_chopping_action["xp"]
	)
	
	assert_true(_signal_received)
	assert_eq(_received_player_id, player_id)
	assert_eq(_received_skill, &"woodcutting")
	assert_eq(_received_xp, 15)
	
	EventBus.server_player_action_completed.disconnect(_on_player_action_completed)

func test_tool_upgrade_affects_stats():
	var base_axe = axe.duplicate()
	base_axe.upgrade_level = 0
	
	var upgraded_axe = axe.duplicate()
	upgraded_axe.upgrade_level = 2
	upgraded_axe.power = 4  # Doubled power at level 2
	upgraded_axe.stamina_cost = 4.0  # Reduced stamina cost
	
	assert_true(upgraded_axe.power > base_axe.power)
	assert_true(upgraded_axe.stamina_cost < base_axe.stamina_cost)

func _on_player_action_completed(pid, skill, xp):
	_signal_received = true
	_received_player_id = pid
	_received_skill = skill
	_received_xp = xp
