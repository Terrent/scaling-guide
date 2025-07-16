# data/resources/world/building_upgrade_data.gd
# Defines the cost and effects of a single community building upgrade.
class_name BuildingUpgradeData
extends Resource

# The unique, non-human-readable identifier for this upgrade.
@export var upgrade_id: StringName = &""

# The player-facing title of the upgrade as it appears on the upgrade board.
@export var title: String = ""

# A description of the upgrade's benefits and lore.
@export_multiline var description: String = ""

# A dictionary defining the material costs for the upgrade.
# Key: ItemData resource, Value: required_quantity (int)
@export var material_costs: Dictionary = {}

# A StringName identifier for a feature or content unlocked by this upgrade.
@export var unlocks_feature: StringName = &""
