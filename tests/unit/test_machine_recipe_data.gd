# tests/unit/test_machine_recipe_data.gd
extends GutTest

var recipe: MachineRecipeData
var input_item: ItemData
var output_item: ItemData

func before_each():
	recipe = MachineRecipeData.new()
	input_item = ItemData.new()
	output_item = ItemData.new()

func test_default_values():
	assert_null(recipe.input_item)
	assert_null(recipe.output_item)
	assert_eq(recipe.processing_time_hours, 24)

func test_basic_machine_recipe():
	# Milk -> Cheese recipe
	input_item.item_id = &"milk"
	input_item.display_name = "Milk"
	input_item.value = 125
	
	output_item.item_id = &"cheese"
	output_item.display_name = "Cheese"
	output_item.value = 200
	
	recipe.input_item = input_item
	recipe.output_item = output_item
	recipe.processing_time_hours = 3  # 3 hours to make cheese
	
	assert_eq(recipe.input_item, input_item)
	assert_eq(recipe.output_item, output_item)
	assert_eq(recipe.processing_time_hours, 3)

func test_value_increase_from_processing():
	# Processing should increase value
	input_item.value = 100
	output_item.value = 150
	
	recipe.input_item = input_item
	recipe.output_item = output_item
	
	var value_multiplier = float(output_item.value) / float(input_item.value)
	assert_gt(value_multiplier, 1.0, "Output should be worth more than input")
	assert_eq(value_multiplier, 1.5)

func test_keg_recipes():
	# Different fruits process at different speeds
	var fruit_recipes = [
		{
			"input": "grape",
			"output": "wine",
			"hours": 168,  # 7 days
			"value_mult": 3.0
		},
		{
			"input": "wheat",
			"output": "beer", 
			"hours": 36,   # 1.5 days
			"value_mult": 2.5
		},
		{
			"input": "coffee_bean",
			"output": "coffee",
			"hours": 2,    # 2 hours
			"value_mult": 2.0
		},
		{
			"input": "apple",
			"output": "juice",
			"hours": 96,   # 4 days
			"value_mult": 2.5
		}
	]
	
	for recipe_data in fruit_recipes:
		var keg_recipe = MachineRecipeData.new()
		
		var fruit = ItemData.new()
		fruit.item_id = StringName(recipe_data["input"])
		fruit.value = 100  # Base value
		
		var beverage = ItemData.new()
		beverage.item_id = StringName(recipe_data["output"])
		beverage.value = int(100 * recipe_data["value_mult"])
		
		keg_recipe.input_item = fruit
		keg_recipe.output_item = beverage
		keg_recipe.processing_time_hours = recipe_data["hours"]
		
		gut.p("%s -> %s: %d hours, %.1fx value" % 
			[recipe_data["input"], recipe_data["output"], 
			 recipe_data["hours"], recipe_data["value_mult"]])
		
		assert_eq(keg_recipe.processing_time_hours, recipe_data["hours"])

func test_preserves_jar_recipes():
	# Fruit -> Jam, Vegetable -> Pickles
	
	# Strawberry Jam
	input_item.item_id = &"strawberry"
	input_item.value = 120
	
	output_item.item_id = &"strawberry_jam"
	output_item.value = 290  # 50 + (2 * fruit_value)
	
	recipe.input_item = input_item
	recipe.output_item = output_item
	recipe.processing_time_hours = 50  # ~2 days
	
	# Verify jam formula
	var expected_jam_value = 50 + (2 * input_item.value)
	assert_eq(output_item.value, expected_jam_value)

func test_furnace_smelting():
	# Ore -> Bar recipes with different times
	var smelting_recipes = [
		{"ore": "copper_ore", "bar": "copper_bar", "hours": 0.5},
		{"ore": "iron_ore", "bar": "iron_bar", "hours": 2},
		{"ore": "gold_ore", "bar": "gold_bar", "hours": 5},
		{"ore": "iridium_ore", "bar": "iridium_bar", "hours": 8}
	]
	
	for smelt_data in smelting_recipes:
		recipe = MachineRecipeData.new()
		
		input_item = ItemData.new()
		input_item.item_id = StringName(smelt_data["ore"])
		
		output_item = ItemData.new()
		output_item.item_id = StringName(smelt_data["bar"])
		
		recipe.input_item = input_item
		recipe.output_item = output_item
		recipe.processing_time_hours = smelt_data["hours"]
		
		# Higher tier ores take longer
		if smelt_data["ore"] == "iridium_ore":
			assert_gt(recipe.processing_time_hours, 5)

func test_cheese_press_quality_handling():
	# Different quality milk makes different quality cheese
	# (This might be handled by a different system, but testing the concept)
	
	var milk_normal = ItemData.new()
	milk_normal.item_id = &"milk"
	milk_normal.value = 125
	
	var cheese_normal = ItemData.new()
	cheese_normal.item_id = &"cheese"
	cheese_normal.value = 200
	
	recipe.input_item = milk_normal
	recipe.output_item = cheese_normal
	recipe.processing_time_hours = 3
	
	# The recipe itself doesn't handle quality
	# That would be handled by the machine implementation
	assert_eq(recipe.output_item.item_id, &"cheese")

func test_loom_processing():
	# Wool -> Cloth
	input_item.item_id = &"wool"
	input_item.value = 340
	
	output_item.item_id = &"cloth"  
	output_item.value = 470
	
	recipe.input_item = input_item
	recipe.output_item = output_item
	recipe.processing_time_hours = 4
	
	# Cloth is valuable processed good
	assert_gt(output_item.value, input_item.value)
	assert_eq(recipe.processing_time_hours, 4)

func test_recycling_machine():
	# Trash -> Resources (random output in game, but recipe is fixed)
	input_item.item_id = &"trash"
	input_item.value = 0
	
	output_item.item_id = &"refined_quartz"
	output_item.value = 50
	
	recipe.input_item = input_item
	recipe.output_item = output_item
	recipe.processing_time_hours = 1
	
	# Recycling creates value from nothing
	assert_eq(input_item.value, 0)
	assert_gt(output_item.value, 0)

func test_processing_time_ranges():
	# Test various processing times
	var time_categories = [
		{"name": "instant", "hours": 0},      # No time (maybe for testing)
		{"name": "quick", "hours": 0.5},      # 30 minutes
		{"name": "short", "hours": 2},        # 2 hours
		{"name": "medium", "hours": 12},      # Half day
		{"name": "long", "hours": 24},        # Full day
		{"name": "very_long", "hours": 168}   # Full week
	]
	
	for category in time_categories:
		recipe.processing_time_hours = category["hours"]
		gut.p("%s processing: %d hours" % [category["name"], category["hours"]])
		assert_gte(recipe.processing_time_hours, 0)

func test_oil_maker_recipes():
	# Different seeds produce oil at different rates
	var oil_recipes = [
		{"seed": "sunflower", "hours": 60},      # 2.5 days
		{"seed": "sunflower_seeds", "hours": 1}, # 1 hour from seeds
		{"seed": "corn", "hours": 54},           # 2.25 days
		{"seed": "truffle", "hours": 6}          # 6 hours for truffle oil
	]
	
	for oil_data in oil_recipes:
		input_item.item_id = StringName(oil_data["seed"])
		output_item.item_id = &"oil"
		
		recipe.input_item = input_item
		recipe.output_item = output_item
		recipe.processing_time_hours = oil_data["hours"]
		
		# Truffle oil is special
		if oil_data["seed"] == "truffle":
			output_item.item_id = &"truffle_oil"
			output_item.value = 1065  # Very valuable
		
		assert_eq(recipe.processing_time_hours, oil_data["hours"])

# Parameterized test for different machine types
func test_all_machine_types(params=use_parameters([
	{
		"machine": "Cheese Press",
		"input": "milk",
		"output": "cheese",
		"hours": 3,
		"value_increase": 1.6
	},
	{
		"machine": "Mayonnaise Machine",
		"input": "egg",
		"output": "mayonnaise",
		"hours": 3,
		"value_increase": 3.8
	},
	{
		"machine": "Preserves Jar",
		"input": "blueberry",
		"output": "blueberry_jam",
		"hours": 50,
		"value_increase": 2.4
	},
	{
		"machine": "Keg",
		"input": "hops",
		"output": "pale_ale",
		"hours": 36,
		"value_increase": 2.5
	},
	{
		"machine": "Furnace",
		"input": "iron_ore",
		"output": "iron_bar",
		"hours": 2,
		"value_increase": 2.0
	}
])):
	input_item.item_id = StringName(params.input)
	input_item.value = 100  # Base value for comparison
	
	output_item.item_id = StringName(params.output)
	output_item.value = int(100 * params.value_increase)
	
	recipe.input_item = input_item
	recipe.output_item = output_item
	recipe.processing_time_hours = params.hours
	
	gut.p("%s: %s -> %s in %d hours (%.1fx value)" % 
		[params.machine, params.input, params.output, 
		 params.hours, params.value_increase])
	
	assert_eq(recipe.processing_time_hours, params.hours)
	assert_almost_eq(float(output_item.value) / float(input_item.value), 
		params.value_increase, 0.1)

func test_efficiency_calculation():
	# Calculate gold per hour efficiency
	var recipes_to_compare = []
	
	# Coffee: Fast but lower multiplier
	var coffee_recipe = MachineRecipeData.new()
	coffee_recipe.processing_time_hours = 2
	var coffee_in = ItemData.new()
	coffee_in.value = 15
	var coffee_out = ItemData.new()
	coffee_out.value = 150
	coffee_recipe.input_item = coffee_in
	coffee_recipe.output_item = coffee_out
	recipes_to_compare.append({"name": "Coffee", "recipe": coffee_recipe})
	
	# Wine: Slow but high multiplier
	var wine_recipe = MachineRecipeData.new()
	wine_recipe.processing_time_hours = 168  # 7 days
	var grape = ItemData.new()
	grape.value = 80
	var wine = ItemData.new()
	wine.value = 240
	wine_recipe.input_item = grape
	wine_recipe.output_item = wine
	recipes_to_compare.append({"name": "Wine", "recipe": wine_recipe})
	
	# Compare efficiency
	for recipe_data in recipes_to_compare:
		var r = recipe_data["recipe"]
		var profit = r.output_item.value - r.input_item.value
		var gold_per_hour = float(profit) / float(r.processing_time_hours)
		
		gut.p("%s: %.1f gold/hour" % [recipe_data["name"], gold_per_hour])
		assert_gt(gold_per_hour, 0)

func test_complete_processing_chain():
	# Egg -> Mayo -> Mayo quality goods (theoretical)
	var egg = ItemData.new()
	egg.item_id = &"egg"
	egg.value = 50
	
	var mayo = ItemData.new()
	mayo.item_id = &"mayonnaise"
	mayo.value = 190
	
	recipe.input_item = egg
	recipe.output_item = mayo
	recipe.processing_time_hours = 3
	
	# Verify complete setup
	assert_not_null(recipe.input_item)
	assert_not_null(recipe.output_item)
	assert_gt(recipe.processing_time_hours, 0)
	assert_ne(recipe.input_item.item_id, recipe.output_item.item_id)
	
	# Calculate ROI
	var profit = recipe.output_item.value - recipe.input_item.value
	var roi_percent = (float(profit) / float(recipe.input_item.value)) * 100
	gut.p("Mayo ROI: %.0f%%" % roi_percent)
	assert_gt(roi_percent, 100)  # More than 100% return
