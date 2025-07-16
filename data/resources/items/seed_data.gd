# data/resources/items/seed_data.gd
# Defines properties for seeds, linking the seed item to the crop it grows.
# Inherits from ItemData.
class_name SeedData
extends ItemData

# A direct link to the CropData resource that defines the plant's lifecycle.
@export var crop_to_grow: CropData

# An array of integers representing the seasons (e.g., 0=Spring, 1=Summer)
# in which this seed can be successfully planted.
@export var valid_seasons: Array[int]
