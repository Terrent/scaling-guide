# tests/unit/test_crop_data_regrowth.gd
extends GutTest

var crop: CropData
var mock_item: ItemData

func before_each():
	crop = CropData.new()
	mock_item = ItemData.new()
	mock_item.item_id = &"blueberry"
	mock_item.display_name = "Blueberry"

func test_regrowth_defaults():
	# By default, crops should not regrow
	assert_false(crop.can_regrow)
	assert_eq(crop.regrow_stage_index, 0)
	assert_eq(crop.max_regrows, -1)

func test_single_harvest_crop():
	# Traditional crop like wheat - harvest once and done
	crop.can_regrow = false
	crop.growth_stages =[preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg")]  # 4 growth stages
	crop.days_per_stage = [1, 2, 2, 1]
	
	assert_false(crop.can_regrow)
	# Other regrow properties shouldn't matter when can_regrow is false

func test_infinite_regrowth_crop():
	# Berry bush - regrows forever
	crop.can_regrow = true
	crop.growth_stages = [preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg")]  # 5 growth stages  # 5 stages
	crop.regrow_stage_index = 3  # Goes back to stage 3 after harvest
	crop.max_regrows = -1  # Infinite
	
	assert_true(crop.can_regrow)
	assert_eq(crop.max_regrows, -1)
	assert_eq(crop.regrow_stage_index, 3)
	
	# Verify regrow stage is valid
	assert_lt(crop.regrow_stage_index, crop.growth_stages.size())

func test_limited_regrowth_crop():
	# Coffee plant - can be harvested 3 additional times
	crop.can_regrow = true
	crop.growth_stages = [preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg")] 
	crop.regrow_stage_index = 4
	crop.max_regrows = 3
	
	assert_eq(crop.max_regrows, 3)
	# This means: 1 initial harvest + 3 regrowth harvests = 4 total

func test_regrow_stage_validation():
	# Test edge cases for regrow_stage_index
	crop.can_regrow = true
	crop.growth_stages = [preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg")]  # 4 stages (0-3)
	
	# Valid cases
	crop.regrow_stage_index = 0  # Goes back to beginning
	assert_eq(crop.regrow_stage_index, 0)
	
	crop.regrow_stage_index = 2  # Goes back to stage 2
	assert_eq(crop.regrow_stage_index, 2)
	
	crop.regrow_stage_index = 3  # Goes back to last stage (unusual but valid)
	assert_eq(crop.regrow_stage_index, 3)

func test_no_regrowth_allowed():
	# Edge case: max_regrows = 0 means no regrowth even if can_regrow is true
	crop.can_regrow = true
	crop.max_regrows = 0
	
	assert_true(crop.can_regrow)  # Flag is still true
	assert_eq(crop.max_regrows, 0)  # But no regrowths allowed

func test_regrowth_with_different_yields():
	# Some crops might yield different amounts on regrowth
	crop.can_regrow = true
	crop.yields_item = mock_item
	crop.yield_amount = Vector2i(3, 5)  # 3-5 berries per harvest
	crop.max_regrows = -1
	
	# The yield amount stays the same for each harvest
	# (unless you implement a separate regrowth_yield_amount)
	assert_eq(crop.yield_amount, Vector2i(3, 5))

func test_growth_and_regrowth_timing():
	# Test a realistic berry bush growth cycle
	crop.growth_stages = [
		preload("res://icon.svg"),  # 0: Planted
		preload("res://icon.svg"),  # 1: Sprouting
		preload("res://icon.svg"),  # 2: Growing
		preload("res://icon.svg"),  # 3: Flowering
		preload("res://icon.svg"),  # 4: Unripe berries
		preload("res://icon.svg")   # 5: Ripe berries (harvestable)
	]
	crop.days_per_stage = [1, 2, 3, 2, 2, 1]  # 11 days to first harvest
	crop.can_regrow = true
	crop.regrow_stage_index = 3  # Goes back to flowering
	crop.max_regrows = -1
	
	# Calculate initial growth time
	var initial_growth_days = 0
	for days in crop.days_per_stage:
		initial_growth_days += days
	assert_eq(initial_growth_days, 11)
	
	# Calculate regrowth time (from stage 3 to 5)
	var regrowth_days = 0
	for i in range(crop.regrow_stage_index, crop.days_per_stage.size()):
		regrowth_days += crop.days_per_stage[i]
	assert_eq(regrowth_days, 5)  # 2 + 2 + 1
	
	gut.p("Initial growth: %d days, Regrowth: %d days" % [initial_growth_days, regrowth_days])

func test_typed_array_growth_stages():
	# The growth_stages is now Array[Texture2D] - test that it's typed
	var tex1 = preload("res://icon.svg")
	var tex2 = preload("res://icon.svg")
	
	crop.growth_stages = [tex1, tex2]
	
	# This should work
	assert_eq(crop.growth_stages.size(), 2)
	assert_true(crop.growth_stages[0] is Texture2D)
	
	# Note: In actual usage, trying to add non-Texture2D would fail
	# but we can't easily test that in GUT without runtime errors

func test_complete_crop_configuration():
	# Test a fully configured regrowing crop
	var strawberry = ItemData.new()
	strawberry.item_id = &"strawberry"
	strawberry.display_name = "Strawberry"
	strawberry.value = 25
	
	crop.yields_item = strawberry
	crop.yield_amount = Vector2i(2, 4)
	crop.growth_stages = [preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg"), preload("res://icon.svg")]
	crop.days_per_stage = [2, 3, 3, 2, 1]
	crop.can_regrow = true
	crop.regrow_stage_index = 3
	crop.max_regrows = 5  # Can harvest 6 times total
	
	# Verify all properties
	assert_eq(crop.yields_item.item_id, &"strawberry")
	assert_eq(crop.yield_amount, Vector2i(2, 4))
	assert_eq(crop.growth_stages.size(), 5)
	assert_eq(crop.days_per_stage.size(), 5)
	assert_true(crop.can_regrow)
	assert_eq(crop.regrow_stage_index, 3)
	assert_eq(crop.max_regrows, 5)

# Parameterized test for different crop types
func test_various_crop_types(params=use_parameters([
	{"name": "Wheat", "can_regrow": false, "max_regrows": -1},
	{"name": "Blueberry Bush", "can_regrow": true, "max_regrows": -1},
	{"name": "Coffee Plant", "can_regrow": true, "max_regrows": 4},
	{"name": "Ancient Fruit", "can_regrow": true, "max_regrows": -1},
	{"name": "Seasonal Berry", "can_regrow": true, "max_regrows": 2}
])):
	crop.can_regrow = params.can_regrow
	crop.max_regrows = params.max_regrows
	
	if params.can_regrow:
		if params.max_regrows == -1:
			gut.p("%s: Infinite regrowth crop" % params.name)
		else:
			gut.p("%s: Limited regrowth crop (%d regrowths)" % [params.name, params.max_regrows])
	else:
		gut.p("%s: Single harvest crop" % params.name)
	
	assert_eq(crop.can_regrow, params.can_regrow)
	assert_eq(crop.max_regrows, params.max_regrows)
