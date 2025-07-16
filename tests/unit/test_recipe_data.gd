# tests/unit/test_recipe_data.gd
extends GutTest

var recipe: RecipeData
var output_item: ItemData
var ingredient1: ItemData
var ingredient2: ItemData

func before_each():
	recipe = RecipeData.new()
	output_item = ItemData.new()
	ingredient1 = ItemData.new()
	ingredient2 = ItemData.new()

func test_default_values():
	assert_eq(recipe.recipe_id, &"")
	assert_eq(recipe.ingredients.size(), 0)
	assert_null(recipe.output_item)
	assert_eq(recipe.output_quantity, 1)

func test_crafting_station_types():
	# Test all station types
	recipe.crafting_station = RecipeData.CraftingStation.WORKBENCH
	assert_eq(recipe.crafting_station, RecipeData.CraftingStation.WORKBENCH)
	
	recipe.crafting_station = RecipeData.CraftingStation.KITCHEN
	assert_eq(recipe.crafting_station, RecipeData.CraftingStation.KITCHEN)
	
	recipe.crafting_station = RecipeData.CraftingStation.FORGE
	assert_eq(recipe.crafting_station, RecipeData.CraftingStation.FORGE)

func test_basic_torch_recipe():
	# Simple workbench recipe
	recipe.recipe_id = &"torch"
	recipe.crafting_station = RecipeData.CraftingStation.WORKBENCH
	
	ingredient1.item_id = &"wood"
	var coal = ItemData.new()
	coal.item_id = &"coal"
	
	recipe.ingredients = {
		ingredient1: 1,
		coal: 1
	}
	
	output_item.item_id = &"torch"
	output_item.display_name = "Torch"
	
	recipe.output_item = output_item
	recipe.output_quantity = 5  # Makes 5 torches
	
	assert_eq(recipe.ingredients.size(), 2)
	assert_eq(recipe.output_quantity, 5)
	assert_eq(recipe.crafting_station, RecipeData.CraftingStation.WORKBENCH)

func test_chest_recipe():
	# Furniture crafting
	recipe.recipe_id = &"chest"
	recipe.crafting_station = RecipeData.CraftingStation.WORKBENCH
	
	ingredient1.item_id = &"wood"
	
	recipe.ingredients = {
		ingredient1: 50  # Lots of wood
	}
	
	output_item.item_id = &"chest"
	recipe.output_item = output_item
	recipe.output_quantity = 1
	
	assert_eq(recipe.ingredients[ingredient1], 50)

func test_bread_cooking_recipe():
	# Kitchen recipe
	recipe.recipe_id = &"bread"
	recipe.crafting_station = RecipeData.CraftingStation.KITCHEN
	
	var wheat_flour = ItemData.new()
	wheat_flour.item_id = &"wheat_flour"
	
	recipe.ingredients = {
		wheat_flour: 1
	}
	
	output_item.item_id = &"bread"
	output_item.value = 60
	
	recipe.output_item = output_item
	recipe.output_quantity = 1
	
	assert_eq(recipe.crafting_station, RecipeData.CraftingStation.KITCHEN)
	assert_has(recipe.ingredients, wheat_flour)

func test_complex_meal_recipe():
	# Multi-ingredient cooking
	recipe.recipe_id = &"complete_breakfast"
	recipe.crafting_station = RecipeData.CraftingStation.KITCHEN
	
	var egg = ItemData.new()
	egg.item_id = &"egg"
	var milk = ItemData.new()
	milk.item_id = &"milk"
	var hashbrowns = ItemData.new()
	hashbrowns.item_id = &"hashbrowns"
	var pancakes = ItemData.new()
	pancakes.item_id = &"pancakes"
	
	recipe.ingredients = {
		egg: 1,
		milk: 1,
		hashbrowns: 1,
		pancakes: 1
	}
	
	output_item.item_id = &"complete_breakfast"
	output_item.value = 350
	
	recipe.output_item = output_item
	
	assert_eq(recipe.ingredients.size(), 4)
	assert_gt(recipe.output_item.value, 300)

func test_iron_bar_smelting():
	# Forge recipe
	recipe.recipe_id = &"iron_bar"
	recipe.crafting_station = RecipeData.CraftingStation.FORGE
	
	var iron_ore = ItemData.new()
	iron_ore.item_id = &"iron_ore"
	var coal = ItemData.new()
	coal.item_id = &"coal"
	
	recipe.ingredients = {
		iron_ore: 5,  # 5 ore per bar
		coal: 1       # Fuel
	}
	
	output_item.item_id = &"iron_bar"
	output_item.value = 120
	
	recipe.output_item = output_item
	recipe.output_quantity = 1
	
	assert_eq(recipe.crafting_station, RecipeData.CraftingStation.FORGE)
	assert_eq(recipe.ingredients[iron_ore], 5)

func test_tool_crafting():
	# Crafting upgraded tools
	recipe.recipe_id = &"iron_pickaxe"
	recipe.crafting_station = RecipeData.CraftingStation.FORGE
	
	var iron_bar = ItemData.new()
	iron_bar.item_id = &"iron_bar"
	ingredient1.item_id = &"wood"
	
	recipe.ingredients = {
		iron_bar: 5,
		ingredient1: 10  # Handle
	}
	
	output_item.item_id = &"iron_pickaxe"
	recipe.output_item = output_item
	
	# Tools require processed materials
	assert_has(recipe.ingredients, iron_bar)
	assert_eq(recipe.ingredients[iron_bar], 5)

func test_bomb_crafting():
	# Dangerous items
	recipe.recipe_id = &"bomb"
	recipe.crafting_station = RecipeData.CraftingStation.WORKBENCH
	
	var iron_ore = ItemData.new()
	iron_ore.item_id = &"iron_ore"
	var coal = ItemData.new()
	coal.item_id = &"coal"
	
	recipe.ingredients = {
		iron_ore: 4,
		coal: 1
	}
	
	output_item.item_id = &"bomb"
	recipe.output_item = output_item
	recipe.output_quantity = 5  # Makes multiple
	
	assert_eq(recipe.output_quantity, 5)

func test_fertilizer_recipes():
	# Different quality fertilizers
	var fertilizer_types = [
		{
			"id": &"basic_fertilizer",
			"ingredient": &"sap",
			"amount": 2,
			"output_qty": 5
		},
		{
			"id": &"quality_fertilizer", 
			"ingredient": &"fish",
			"amount": 1,
			"output_qty": 2
		},
		{
			"id": &"deluxe_fertilizer",
			"ingredient": &"iridium_bar",
			"amount": 1,
			"output_qty": 5
		}
	]
	
	for fert_data in fertilizer_types:
		recipe = RecipeData.new()
		recipe.recipe_id = fert_data["id"]
		
		var ingredient = ItemData.new()
		ingredient.item_id = fert_data["ingredient"]
		
		recipe.ingredients = {ingredient: fert_data["amount"]}
		recipe.output_quantity = fert_data["output_qty"]
		
		gut.p("%s: %d %s -> %d fertilizer" % 
			[fert_data["id"], fert_data["amount"], 
			 fert_data["ingredient"], fert_data["output_qty"]])
		
		assert_eq(recipe.output_quantity, fert_data["output_qty"])

func test_recipe_value_calculation():
	# Compare input vs output value
	ingredient1.item_id = &"copper_ore"
	ingredient1.value = 5
	
	var coal = ItemData.new()
	coal.item_id = &"coal"
	coal.value = 15
	
	recipe.ingredients = {
		ingredient1: 5,  # 25 gold worth
		coal: 1         # 15 gold worth
	}
	
	output_item.item_id = &"copper_bar"
	output_item.value = 60
	
	recipe.output_item = output_item
	
	# Calculate profit
	var input_cost = (5 * 5) + (1 * 15)  # 40 gold
	var output_value = 60
	var profit = output_value - input_cost
	
	gut.p("Copper bar profit: %d gold" % profit)
	assert_gt(profit, 0)

func test_mass_production_recipes():
	# Some recipes make many items
	recipe.recipe_id = &"wood_fence"
	recipe.crafting_station = RecipeData.CraftingStation.WORKBENCH
	
	ingredient1.item_id = &"wood"
	recipe.ingredients = {ingredient1: 2}
	
	output_item.item_id = &"wood_fence"
	recipe.output_item = output_item
	recipe.output_quantity = 10  # 2 wood = 10 fences
	
	assert_eq(recipe.output_quantity, 10)
	
	# Efficiency check
	var wood_per_fence = 2.0 / 10.0
	assert_eq(wood_per_fence, 0.2)

# Parameterized test for different recipe types
func test_recipe_categories(params=use_parameters([
	{
		"category": "Building",
		"station": RecipeData.CraftingStation.WORKBENCH,
		"ingredients": 2,
		"output_qty": 1
	},
	{
		"category": "Food",
		"station": RecipeData.CraftingStation.KITCHEN,
		"ingredients": 3,
		"output_qty": 1
	},
	{
		"category": "Equipment",
		"station": RecipeData.CraftingStation.FORGE,
		"ingredients": 2,
		"output_qty": 1
	},
	{
		"category": "Consumable",
		"station": RecipeData.CraftingStation.WORKBENCH,
		"ingredients": 2,
		"output_qty": 5
	},
	{
		"category": "Decoration",
		"station": RecipeData.CraftingStation.WORKBENCH,
		"ingredients": 3,
		"output_qty": 1
	}
])):
	recipe.crafting_station = params.station
	
	# Add ingredients
	recipe.ingredients = {}
	for i in range(params.ingredients):
		var ing = ItemData.new()
		ing.item_id = StringName("ingredient_%d" % i)
		recipe.ingredients[ing] = i + 1
	
	recipe.output_quantity = params.output_qty
	
	gut.p("%s recipe: %d ingredients at %s -> %d items" % 
		[params.category, params.ingredients, 
		 params.station, params.output_qty])
	
	assert_eq(recipe.crafting_station, params.station)
	assert_eq(recipe.ingredients.size(), params.ingredients)
	assert_eq(recipe.output_quantity, params.output_qty)

func test_seasonal_recipes():
	# Some recipes might need seasonal items
	recipe.recipe_id = &"pumpkin_soup"
	recipe.crafting_station = RecipeData.CraftingStation.KITCHEN
	
	var pumpkin = ItemData.new()
	pumpkin.item_id = &"pumpkin"  # Fall crop
	var milk = ItemData.new()
	milk.item_id = &"milk"
	
	recipe.ingredients = {
		pumpkin: 1,
		milk: 1
	}
	
	output_item.item_id = &"pumpkin_soup"
	output_item.value = 300
	
	recipe.output_item = output_item
	
	# Seasonal recipes are often valuable
	assert_gt(recipe.output_item.value, 250)

func test_recipe_unlocking():
	# Some recipes need to be learned
	recipe.recipe_id = &"ancient_seed"
	recipe.crafting_station = RecipeData.CraftingStation.WORKBENCH
	
	var ancient_seed_artifact = ItemData.new()
	ancient_seed_artifact.item_id = &"ancient_seed_artifact"
	
	recipe.ingredients = {
		ancient_seed_artifact: 1
	}
	
	output_item.item_id = &"ancient_seeds"
	recipe.output_item = output_item
	recipe.output_quantity = 1
	
	# Special recipes have unique ingredients
	assert_has(recipe.ingredients, ancient_seed_artifact)

func test_complete_recipe_configuration():
	# Fully configured complex recipe
	recipe.recipe_id = &"life_elixir"
	recipe.crafting_station = RecipeData.CraftingStation.WORKBENCH
	
	var oil = ItemData.new()
	oil.item_id = &"oil"
	oil.value = 100
	
	var red_mushroom = ItemData.new()
	red_mushroom.item_id = &"red_mushroom"
	red_mushroom.value = 75
	
	var purple_mushroom = ItemData.new()
	purple_mushroom.item_id = &"purple_mushroom"
	purple_mushroom.value = 125
	
	var morel = ItemData.new()
	morel.item_id = &"morel"
	morel.value = 150
	
	recipe.ingredients = {
		oil: 1,
		red_mushroom: 1,
		purple_mushroom: 1,
		morel: 1
	}
	
	output_item.item_id = &"life_elixir"
	output_item.display_name = "Life Elixir"
	output_item.description = "Restores health to full"
	output_item.value = 500
	
	recipe.output_item = output_item
	recipe.output_quantity = 1
	
	# Verify complete setup
	assert_ne(recipe.recipe_id, &"")
	assert_eq(recipe.ingredients.size(), 4)
	assert_not_null(recipe.output_item)
	assert_gt(recipe.output_quantity, 0)
	
	# Calculate input cost
	var total_cost = 100 + 75 + 125 + 150  # 450
	var profit = recipe.output_item.value - total_cost
	gut.p("Life Elixir profit: %d gold (%.0f%% markup)" % 
		[profit, (profit / float(total_cost)) * 100])
	assert_gt(profit, 0)
