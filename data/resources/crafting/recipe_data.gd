# data/resources/crafting/recipe_data.gd
# Defines a single crafting or cooking recipe, including ingredients and output.
class_name RecipeData
extends Resource

# An enumeration for the different types of crafting stations.
enum CraftingStation { WORKBENCH, KITCHEN, FORGE }

# The unique, non-human-readable identifier for this recipe.
@export var recipe_id: StringName = &""

# The required crafting station to create this item.
@export var crafting_station: CraftingStation

# A dictionary of required ingredients.
# Key: ItemData resource, Value: required_quantity (int)
@export var ingredients: Dictionary = {}

# A link to the ItemData resource for the resulting item.
@export var output_item: ItemData

# The number of items produced from one craft.
@export var output_quantity: int = 1
