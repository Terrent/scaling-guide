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
	print("User children: ", user.get_children())
	# Use get_node instead of find_child
	var health_component = user.get_node("PlayerHealth")
	print("Found health component: ", health_component)
	if health_component:
		health_component.heal(health_restore)
		health_component.restore_stamina(stamina_restore)
