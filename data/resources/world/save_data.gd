# data/resources/world/save_data.gd
# A container for the entire serialized world state. This resource is created
# in memory during the save process and is not meant to be edited by hand.
class_name SaveData
extends Resource

# A dictionary for global world state (e.g., from WorldManager, TimeManager).
@export var world_state: Dictionary = {}

# A dictionary containing the state of all farm tiles.
@export var farm_grids: Dictionary = {}

# An array containing the data for all player-placed objects.
@export var placed_objects: Array[Dictionary] = []

# A dictionary containing the serialized data for every player on the server.
@export var players: Dictionary = {}
