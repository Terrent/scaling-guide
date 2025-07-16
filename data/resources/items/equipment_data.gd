# data/resources/items/equipment_data.gd
# Defines properties for combat equipment that provide stat bonuses.
# Inherits from ItemData.
class_name EquipmentData
extends ItemData

enum EquipSlot { WEAPON, RING_1, RING_2 }

# The slot where this item can be equipped.
@export var equip_slot: EquipSlot

# A dictionary defining the stat modifications this item provides.
# Key: stat_name (StringName), Value: bonus_amount (float or int).
@export var stat_bonuses: Dictionary
