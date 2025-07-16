# data/resources/npcs/dialogue_data.gd
# Defines a tree of dialogue lines, speakers, and player choices.
class_name DialogueData
extends Resource

# The unique, non-human-readable identifier for this dialogue sequence.
@export var dialogue_id: StringName = &""

# An array of dictionaries, where each dictionary represents a line of dialogue or a choice.
# Example: [ { "speaker": "npc_id", "text": "Hello!" }, { "choice": ["Hi!", "Bye!"] } ]
@export var lines: Array[Dictionary] = []
