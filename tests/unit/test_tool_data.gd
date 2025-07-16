extends GutTest

var tool: ToolData

func before_each():
	tool = ToolData.new()

func test_default_values():
	assert_eq(tool.power, 1)
	assert_eq(tool.stamina_cost, 2.0)
	assert_eq(tool.area_of_effect, Vector2i.ONE)
	assert_eq(tool.upgrade_level, 0)

func test_execute_use_exists_and_accepts_parameters():
	# This tests that the virtual method exists and can be called
	var mock_user = Node.new()
	add_child_autofree(mock_user)
	var target_pos = Vector2(100, 200)
	
	# Should not crash - base implementation does nothing
	tool.execute_use(mock_user, target_pos)
	assert_true(true) # If we get here, it didn't crash

func test_tool_type_enum_values():
	tool.tool_type = ToolData.ToolType.HOE
	assert_eq(tool.tool_type, ToolData.ToolType.HOE)
	
	tool.tool_type = ToolData.ToolType.WATERING_CAN
	assert_eq(tool.tool_type, ToolData.ToolType.WATERING_CAN)
