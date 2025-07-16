extends GutTest

var crop: CropData
var mock_item: ItemData

func before_each():
	crop = CropData.new()
	mock_item = ItemData.new()

func test_growth_stages_array():
	var tex1 = preload("res://icon.svg")
	var tex2 = preload("res://icon.svg")
	crop.growth_stages = [tex1, tex2]
	
	assert_eq(crop.growth_stages.size(), 2)
	assert_eq(crop.growth_stages[0], tex1)

func test_days_per_stage_typed_array():
	crop.days_per_stage = [1, 2, 3]
	assert_eq(crop.days_per_stage.size(), 3)
	assert_eq(crop.days_per_stage[1], 2)

func test_yield_configuration():
	crop.yields_item = mock_item
	crop.yield_amount = Vector2i(2, 5) # 2-5 items
	
	assert_eq(crop.yields_item, mock_item)
	assert_eq(crop.yield_amount.x, 2)
	assert_eq(crop.yield_amount.y, 5)

func test_default_yield_amount():
	assert_eq(crop.yield_amount, Vector2i(1, 1))
