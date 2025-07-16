# data/resources/processing/machine_recipe_data.gd
# Defines a recipe for a processing machine (e.g., Keg, Preserves Jar, Furnace).
class_name MachineRecipeData
extends Resource

# The ItemData resource required as input for the machine.
@export var input_item: ItemData

# The ItemData resource produced as output.
@export var output_item: ItemData

# The time in in-game hours required for the machine to process the item.
@export var processing_time_hours: int = 24
