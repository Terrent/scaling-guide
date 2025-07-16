# data/resources/items/item_data.gd
# The base class for all items in the game. Defines the common properties
# shared by every item, from tools to seeds to crafted goods.
# This script acts as a data container schema.
class_name ItemData
extends Resource

# The unique, non-human-readable identifier for this item. Used for lookups.
@export var item_id: StringName = &""

# The player-facing name of the item as it appears in the UI.
@export var display_name: String = ""

# The "flavor text" or description shown in tooltips and item menus.
@export_multiline var description: String = ""

# The 2D texture used to represent the item in the inventory UI.
@export var icon: Texture2D

# The maximum number of this item that can fit in a single inventory slot.
@export_range(1, 999) var stack_size: int = 1

# The base monetary value of the item when sold.
@export var value: int = 0
