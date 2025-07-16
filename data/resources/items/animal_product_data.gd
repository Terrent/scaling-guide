# data/resources/items/animal_product_data.gd
# Defines artisan goods and animal products, which can have varying quality levels.
class_name AnimalProductData
extends ItemData

# An enumeration for the quality level of the product, which affects its sale value.
enum Quality { NORMAL, SILVER, GOLD }

@export var quality: Quality = Quality.NORMAL

# A link to the base ItemData resource from which this product was derived (e.g., Wool -> Cloth).
@export var base_item: ItemData
