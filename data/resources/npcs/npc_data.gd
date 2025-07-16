# data/resources/npcs/npc_data.gd
# Defines the static properties and preferences for a Non-Player Character.
class_name NpcData
extends Resource

# The unique, non-human-readable identifier for this NPC.
@export var npc_id: StringName = &""

# The NPC's name as it appears in dialogue and UI.
@export var display_name: String = ""

# A Texture2D for the NPC's portrait shown during dialogue.
@export var portrait: Texture2D

# A dictionary defining the NPC's gift preferences.
# Key: item_id (StringName) or category (String), Value: preference_level (Enum: LOVE, LIKE, DISLIKE)
@export var gift_preferences: Dictionary = {}

# A resource link to the NPC's default daily schedule.
@export var base_schedule: Resource
