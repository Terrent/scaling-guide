# data/resources/quests/quest_data.gd
# Defines a quest's structure, objectives, and rewards.
class_name QuestData
extends Resource

@export var quest_id: StringName = &""
@export var title: String = ""
@export_multiline var description: String = ""

# An array of objective dictionaries.
# Example: [{"type": "gather", "item_id": &"wood", "amount": 50}]
# Example: [{"type": "slay", "enemy_id": &"slime", "amount": 10}]
@export var objectives: Array

# A dictionary of rewards.
# Example: {"money": 500, "items": {&"iron_axe": 1}}
@export var rewards: Dictionary

# If true, this quest's progress is tracked globally by the CommunityQuestManager.
@export var is_communal: bool = false
