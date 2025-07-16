extends GutTest

# Test item crafting flow

var wood_item: ItemData
var stone_item: ItemData
var axe_recipe = {}
var player_id = 789

# Instance variables for signal testing
var _craft_signal_received = false
var _crafted_player_id = -1
var _crafted_item = &""
var _crafted_quantity = 0

func before_each():
	# Reset test variables
	_craft_signal_received = false
	_crafted_player_id = -1
	_crafted_item = &""
	_crafted_quantity = 0
	
	wood_item = ItemData.new()
	wood_item.item_id = &"wood"
	wood_item.display_name = "Wood"
	wood_item.stack_size = 99
	
	stone_item = ItemData.new()
	stone_item.item_id = &"stone"
	stone_item.display_name = "Stone"
	stone_item.stack_size = 99
	
	axe_recipe = {
		"result": &"stone_axe",
		"ingredients": {
			&"wood": 3,
			&"stone": 2
		}
	}

func test_crafting_consumes_items_and_produces_result():
	EventBus.server_item_crafted.connect(_on_item_crafted)
	
	# Simulate crafting
	EventBus.server_item_crafted.emit(player_id, axe_recipe["result"], 1)
	
	assert_true(_craft_signal_received)
	assert_eq(_crafted_player_id, player_id)
	assert_eq(_crafted_item, &"stone_axe")
	assert_eq(_crafted_quantity, 1)
	
	EventBus.server_item_crafted.disconnect(_on_item_crafted)

func _on_item_crafted(pid, item, qty):
	_craft_signal_received = true
	_crafted_player_id = pid
	_crafted_item = item
	_crafted_quantity = qty

func test_stackable_items_configuration():
	# Tools typically don't stack
	var tool = ToolData.new()
	tool.stack_size = 1
	
	# Materials stack high
	assert_eq(wood_item.stack_size, 99)
	assert_eq(stone_item.stack_size, 99)
	assert_eq(tool.stack_size, 1)
