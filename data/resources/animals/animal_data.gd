# data/resources/animals/animal_data.gd
# Defines a type of farm animal, its habitat, products, and lifecycle.
class_name AnimalData
extends Resource

# An enumeration to categorize different animal habitats.
enum HabitatType { COOP, BARN }

# The unique, non-human-readable identifier for this animal type.
@export var animal_id: StringName = &""

# The type of habitat this animal lives in, which determines where it can be housed.
@export var habitat_type: HabitatType

# The ItemData resource for the product this animal generates.
@export var produces_item: ItemData

# The number of in-game days required for the animal to generate one product.
@export var days_to_produce: int = 1
