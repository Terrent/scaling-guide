extends GutTest

# Test that our inheritance chain works correctly

func test_consumable_is_item():
	var consumable = ConsumableData.new()
	assert_true(consumable is ItemData)
	assert_true(consumable is ConsumableData)

func test_tool_is_item():
	var tool = ToolData.new()
	assert_true(tool is ItemData)
	assert_true(tool is ToolData)

func test_seed_is_item():
	var seed = SeedData.new()
	assert_true(seed is ItemData)
	assert_true(seed is SeedData)

func test_clothing_is_item():
	var clothing = ClothingData.new()
	assert_true(clothing is ItemData)
	assert_true(clothing is ClothingData)

func test_equipment_is_item():
	var equipment = EquipmentData.new()
	assert_true(equipment is ItemData)
	assert_true(equipment is EquipmentData)
