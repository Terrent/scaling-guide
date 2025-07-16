extends GutTest

var seed: SeedData
var mock_crop: CropData

func before_each():
	seed = SeedData.new()
	mock_crop = CropData.new()

func test_can_assign_crop_data():
	seed.crop_to_grow = mock_crop
	assert_eq(seed.crop_to_grow, mock_crop)

func test_valid_seasons_array():
	seed.valid_seasons = [0, 1] # Spring and Summer
	assert_eq(seed.valid_seasons.size(), 2)
	assert_has(seed.valid_seasons, 0)
	assert_has(seed.valid_seasons, 1)

func test_inherits_from_item_data():
	# Test that we can access ItemData properties
	seed.item_id = &"carrot_seeds"
	seed.display_name = "Carrot Seeds"
	seed.stack_size = 99
	
	assert_eq(seed.item_id, &"carrot_seeds")
	assert_eq(seed.display_name, "Carrot Seeds")
	assert_eq(seed.stack_size, 99)
