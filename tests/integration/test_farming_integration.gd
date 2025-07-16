extends GutTest

# Test the full farming cycle: planting seeds -> growing crops -> harvesting

var carrot_seed: SeedData
var carrot_crop: CropData
var carrot_item: ItemData

func before_each():
	# Set up a complete farming item chain
	carrot_item = ItemData.new()
	carrot_item.item_id = &"carrot"
	carrot_item.display_name = "Carrot"
	carrot_item.stack_size = 50
	carrot_item.value = 15
	
	carrot_crop = CropData.new()
	carrot_crop.growth_stages = [preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg")]  # 4 growth stages
	carrot_crop.days_per_stage = [1, 2, 2, 3]  # 8 days total
	carrot_crop.yields_item = carrot_item
	carrot_crop.yield_amount = Vector2i(1, 3)  # 1-3 carrots
	
	carrot_seed = SeedData.new()
	carrot_seed.item_id = &"carrot_seed"
	carrot_seed.display_name = "Carrot Seeds"
	carrot_seed.stack_size = 99
	carrot_seed.value = 5
	carrot_seed.crop_to_grow = carrot_crop
	carrot_seed.valid_seasons = [0, 1, 2]  # Spring, Summer, Fall

func test_seed_produces_correct_crop():
	assert_eq(carrot_seed.crop_to_grow, carrot_crop)
	assert_eq(carrot_seed.crop_to_grow.yields_item, carrot_item)

func test_crop_growth_cycle_timing():
	var total_days = 0
	for days in carrot_crop.days_per_stage:
		total_days += days
	assert_eq(total_days, 8)  # Total growth time
	assert_eq(carrot_crop.growth_stages.size(), carrot_crop.days_per_stage.size())

func test_seasonal_planting_restrictions():
	# Can plant in Spring (0), Summer (1), Fall (2)
	assert_has(carrot_seed.valid_seasons, 0)
	assert_has(carrot_seed.valid_seasons, 1)
	assert_has(carrot_seed.valid_seasons, 2)
	# Cannot plant in Winter (3)
	assert_does_not_have(carrot_seed.valid_seasons, 3)

func test_crop_value_chain():
	# Seeds should be cheaper than the crops they produce
	var min_harvest_value = carrot_item.value * carrot_crop.yield_amount.x
	var max_harvest_value = carrot_item.value * carrot_crop.yield_amount.y
	
	assert_lt(carrot_seed.value, min_harvest_value)
	gut.p("Seed value: %d, Min harvest value: %d, Max harvest value: %d" % 
		[carrot_seed.value, min_harvest_value, max_harvest_value])
