# data/resources/player/archetype_data.gd
# Defines a player's starting archetype, providing bonus skill proficiencies or initial equipment.
class_name ArchetypeData
extends Resource

# The unique, non-human-readable identifier for this archetype.
@export var archetype_id: StringName = &""

# The player-facing name of the archetype.
@export var display_name: String = ""

# A description of the archetype shown during character creation.
@export_multiline var description: String = ""

# A dictionary defining bonus starting skill levels.
# Key: skill_id (StringName), Value: bonus_levels (int)
@export var bonus_skill_proficiencies: Dictionary = {}

# An array of ItemData resources to be added to the player's inventory on creation.
@export var initial_equipment: Array[ItemData]
