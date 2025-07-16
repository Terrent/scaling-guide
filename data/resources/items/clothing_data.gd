# data/resources/items/clothing_data.gd
# Defines properties for wearable items that alter player appearance.
# Inherits from ItemData.
class_name ClothingData
extends ItemData

enum EquipSlot { HAT, SHIRT, PANTS }

# The slot where this item can be equipped.
@export var equip_slot: EquipSlot

# A dictionary mapping the sprite layer name (e.g., "ShirtSprite")
# to the texture that should be applied.
@export var sprite_sheets: Dictionary
