# data/resources/player/skill_data.gd
# Defines a player skill, its XP progression curve, and available profession choices.
class_name SkillData
extends Resource

# The unique, non-human-readable identifier for this skill.
@export var skill_id: StringName = &""

# The player-facing name of the skill as it appears in the UI.
@export var display_name: String = ""

# An array defining the total experience required to reach each level (e.g., index 0 = level 1).
@export var xp_per_level: Array[int] = []

# A dictionary defining the profession choices available at level 5 and 10.
# Example: { 5: [&"profession_a", &"profession_b"] }
@export var professions: Dictionary = {}
