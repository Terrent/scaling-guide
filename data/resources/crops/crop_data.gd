# data/resources/crops/crop_data.gd
# Defines the complete growth cycle, visual stages, and harvest yield
# for a single type of crop. This is a pure data container.
class_name CropData
extends Resource

# An array of textures for the crop's visual appearance at each stage.
# The final texture in the array should be the fully grown, harvestable state.
@export var growth_stages: Array

# An array of integers defining how many in-game days the crop spends in each stage.
# The size of this array must match the size of the growth_stages array.
@export var days_per_stage: Array[int]

# A link to the ItemData resource for the item produced upon harvest.
@export var yields_item: ItemData

# A Vector2i representing the minimum (x) and maximum (y) number of items
# yielded upon a single harvest.
@export var yield_amount: Vector2i = Vector2i(1, 1)
