# data/resources/items/tool_data.gd
# Defines the data schema for all tools. It inherits from ItemData and adds
# tool-specific properties and logic.
class_name ToolData
extends ItemData

# An enumeration to categorize different tool types. This helps managers
# quickly identify what kind of tool is being used.
enum ToolType { HOE, AXE, PICKAXE, WATERING_CAN, SCYTHE }

@export var tool_type: ToolType

# The effectiveness or power level of the tool.
@export var power: int = 1

# The amount of stamina consumed on the server when the tool is used.
@export var stamina_cost: float = 2.0

# The area of effect for the tool, in grid tiles (e.g., 1x1, 3x1).
@export var area_of_effect: Vector2i = Vector2i.ONE

# The current upgrade level of the tool.
@export var upgrade_level: int = 0


# This is a virtual function intended to be overridden by specific tool
# resources. It contains the server-side, authoritative logic for what
# happens when the tool is used.
# 'user' is the node that used the tool (the player).
# 'target_position' is the world coordinate of the action.
func execute_use(user, target_position: Vector2) -> void:
	# The base implementation does nothing. Specific tool resources, such as
	# an "iron_axe.tres" with its own attached script, will override this
	# method to define its unique function (e.g., chopping a tree).
	pass
