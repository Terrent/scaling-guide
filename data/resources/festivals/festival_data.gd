# data/resources/festivals/festival_data.gd
# Defines a festival's schedule, map, NPC overrides, and minigames.
class_name FestivalData
extends Resource

# The unique, non-human-readable identifier for this festival.
@export var festival_id: StringName = &""

# The day of the season on which the festival occurs.
@export var day_of_season: int = 1

# A PackedScene file for the special version of the map used during the festival.
@export var festival_village_scene: PackedScene

# A dictionary defining special schedules and dialogue for NPCs on the setup day.
# Key: npc_id (StringName), Value: setup_schedule_resource (Resource)
@export var setup_day_schedules: Dictionary = {}
