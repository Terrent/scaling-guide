# data/resources/items/consumable_data.gd
# Defines properties for edible or drinkable items. Contains logic for its effects.
# Inherits from ItemData.
class_name ConsumableData
extends ItemData

# The amount of health restored upon consumption.
@export var health_restore: int = 0

# The amount of stamina restored upon consumption.
@export var stamina_restore: int = 0

# An array of Buff resources to be applied to the player. (Future implementation)
@export var buffs: Array

# Server-side logic for what happens when the item is consumed.
func execute_consume(user) -> void:
	# This logic will be called by a server-side manager.
	# 'user' will be the authoritative player node.
	var health_component = user.find_child("PlayerHealth")
	if health_component:
		health_component.heal(health_restore)
		health_component.restore_stamina(stamina_restore)
