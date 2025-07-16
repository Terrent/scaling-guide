# tests/unit/test_animal_product_data.gd
extends GutTest

var product: AnimalProductData
var base_item: ItemData

func before_each():
	product = AnimalProductData.new()
	base_item = ItemData.new()

func test_default_values():
	assert_eq(product.quality, AnimalProductData.Quality.NORMAL)
	assert_null(product.base_item)

func test_quality_enum_values():
	# Test all quality levels
	product.quality = AnimalProductData.Quality.NORMAL
	assert_eq(product.quality, AnimalProductData.Quality.NORMAL)
	
	product.quality = AnimalProductData.Quality.SILVER
	assert_eq(product.quality, AnimalProductData.Quality.SILVER)
	
	product.quality = AnimalProductData.Quality.GOLD
	assert_eq(product.quality, AnimalProductData.Quality.GOLD)

func test_basic_animal_product():
	# Set up base milk item
	base_item.item_id = &"milk"
	base_item.display_name = "Milk"
	base_item.value = 125
	
	# Create normal quality milk
	product.item_id = &"milk_normal"
	product.display_name = "Milk"
	product.value = 125
	product.quality = AnimalProductData.Quality.NORMAL
	product.base_item = base_item
	
	assert_eq(product.base_item, base_item)
	assert_eq(product.quality, AnimalProductData.Quality.NORMAL)

func test_quality_affects_value():
	# Base egg item
	base_item.item_id = &"egg"
	base_item.display_name = "Egg"
	base_item.value = 50
	
	# Test different quality eggs
	var normal_egg = AnimalProductData.new()
	normal_egg.base_item = base_item
	normal_egg.quality = AnimalProductData.Quality.NORMAL
	normal_egg.value = 50
	
	var silver_egg = AnimalProductData.new()
	silver_egg.base_item = base_item
	silver_egg.quality = AnimalProductData.Quality.SILVER
	silver_egg.value = 62  # 1.25x multiplier
	
	var gold_egg = AnimalProductData.new()
	gold_egg.base_item = base_item
	gold_egg.quality = AnimalProductData.Quality.GOLD
	gold_egg.value = 75  # 1.5x multiplier
	
	# Verify value scaling
	assert_lt(normal_egg.value, silver_egg.value)
	assert_lt(silver_egg.value, gold_egg.value)
	assert_eq(gold_egg.value, base_item.value * 1.5)

func test_artisan_goods():
	# Cheese made from milk
	var milk = ItemData.new()
	milk.item_id = &"milk"
	milk.display_name = "Milk"
	milk.value = 125
	
	product.item_id = &"cheese"
	product.display_name = "Cheese"
	product.value = 200
	product.quality = AnimalProductData.Quality.NORMAL
	product.base_item = milk
	
	# Artisan goods are worth more than base
	assert_gt(product.value, product.base_item.value)

func test_wool_to_cloth_processing():
	# Wool -> Cloth processing chain
	var wool = ItemData.new()
	wool.item_id = &"wool"
	wool.display_name = "Wool"
	wool.value = 340
	
	product.item_id = &"cloth"
	product.display_name = "Cloth"
	product.value = 470
	product.quality = AnimalProductData.Quality.NORMAL
	product.base_item = wool
	
	# Processed goods increase in value
	var value_increase = float(product.value) / float(product.base_item.value)
	assert_almost_eq(value_increase, 1.38, 0.01)  # ~38% increase

func test_quality_display_names():
	base_item.item_id = &"large_milk"
	base_item.display_name = "Large Milk"
	
	# Different qualities might have different display names
	var qualities = [
		{"quality": AnimalProductData.Quality.NORMAL, "prefix": ""},
		{"quality": AnimalProductData.Quality.SILVER, "prefix": "Silver "},
		{"quality": AnimalProductData.Quality.GOLD, "prefix": "Gold "}
	]
	
	for q in qualities:
		product.quality = q["quality"]
		product.display_name = q["prefix"] + base_item.display_name
		product.base_item = base_item
		
		if q["quality"] == AnimalProductData.Quality.NORMAL:
			assert_eq(product.display_name, "Large Milk")
		else:
			assert_true(product.display_name.begins_with(q["prefix"]))

func test_animal_product_inheritance():
	# Verify it inherits from ItemData
	assert_true(product is ItemData)
	assert_true(product is AnimalProductData)
	
	# Can use ItemData properties
	product.stack_size = 999
	product.description = "Fresh from the farm!"
	product.icon = preload("res://icon.svg")
	
	assert_eq(product.stack_size, 999)
	assert_eq(product.description, "Fresh from the farm!")

func test_mayonnaise_production():
	# Egg -> Mayonnaise
	var egg = ItemData.new()
	egg.item_id = &"egg"
	egg.value = 50
	
	# Different quality mayo from different quality eggs
	var mayo_qualities = [
		{"quality": AnimalProductData.Quality.NORMAL, "value": 190},
		{"quality": AnimalProductData.Quality.SILVER, "value": 237},
		{"quality": AnimalProductData.Quality.GOLD, "value": 285}
	]
	
	for mayo_data in mayo_qualities:
		var mayo = AnimalProductData.new()
		mayo.item_id = &"mayonnaise"
		mayo.display_name = "Mayonnaise"
		mayo.quality = mayo_data["quality"]
		mayo.value = mayo_data["value"]
		mayo.base_item = egg
		
		gut.p("%s quality mayo: %d gold" % [mayo.quality, mayo.value])
		assert_eq(mayo.value, mayo_data["value"])

func test_honey_special_case():
	# Honey might not have quality variants
	var flower = ItemData.new()
	flower.item_id = &"flower"
	flower.value = 50
	
	product.item_id = &"honey"
	product.display_name = "Wild Honey"
	product.value = 100
	product.quality = AnimalProductData.Quality.NORMAL
	product.base_item = flower  # Made from nearby flowers
	
	# Honey is always normal quality in this design
	assert_eq(product.quality, AnimalProductData.Quality.NORMAL)

func test_truffle_oil_high_value():
	# Truffle -> Truffle Oil (high value artisan good)
	var truffle = ItemData.new()
	truffle.item_id = &"truffle"
	truffle.value = 625
	
	product.item_id = &"truffle_oil"
	product.display_name = "Truffle Oil"
	product.value = 1065
	product.quality = AnimalProductData.Quality.NORMAL  # No quality variants
	product.base_item = truffle
	
	# High value multiplier for rare goods
	var multiplier = float(product.value) / float(product.base_item.value)
	assert_almost_eq(multiplier, 1.7, 0.01)  # 70% value increase

# Parameterized test for various animal products
func test_all_animal_products(params=use_parameters([
	{
		"product": "Milk",
		"base_value": 125,
		"quality_multipliers": {"normal": 1.0, "silver": 1.25, "gold": 1.5}
	},
	{
		"product": "Egg",
		"base_value": 50,
		"quality_multipliers": {"normal": 1.0, "silver": 1.25, "gold": 1.5}
	},
	{
		"product": "Wool",
		"base_value": 340,
		"quality_multipliers": {"normal": 1.0, "silver": 1.25, "gold": 1.5}
	},
	{
		"product": "Duck Feather",
		"base_value": 125,
		"quality_multipliers": {"normal": 1.0, "silver": 1.25, "gold": 1.5}
	},
	{
		"product": "Rabbit's Foot",
		"base_value": 565,
		"quality_multipliers": {"normal": 1.0, "silver": 1.25, "gold": 1.5}
	}
])):
	base_item.display_name = params.product
	base_item.value = params.base_value
	
	# Test each quality level
	for quality_name in params.quality_multipliers:
		product = AnimalProductData.new()
		product.base_item = base_item
		
		match quality_name:
			"normal":
				product.quality = AnimalProductData.Quality.NORMAL
			"silver":
				product.quality = AnimalProductData.Quality.SILVER
			"gold":
				product.quality = AnimalProductData.Quality.GOLD
		
		var expected_value = int(params.base_value * params.quality_multipliers[quality_name])
		product.value = expected_value
		
		gut.p("%s %s quality: %d gold" % [params.product, quality_name, expected_value])
		assert_eq(product.value, expected_value)

func test_complete_production_chain():
	# Test a full production chain: Sheep -> Wool -> Cloth
	
	# Step 1: Sheep produces wool
	var wool = AnimalProductData.new()
	wool.item_id = &"wool"
	wool.display_name = "Wool"
	wool.quality = AnimalProductData.Quality.SILVER
	wool.value = 425  # Silver quality wool
	wool.base_item = null  # Direct from animal
	
	# Step 2: Wool processed into cloth
	var cloth = AnimalProductData.new()
	cloth.item_id = &"cloth"
	cloth.display_name = "Cloth"
	cloth.quality = AnimalProductData.Quality.NORMAL  # Processing removes quality
	cloth.value = 470
	cloth.base_item = wool
	
	# Verify the chain
	assert_null(wool.base_item)  # Wool is primary product
	assert_eq(cloth.base_item.item_id, &"wool")  # Cloth comes from wool
	assert_gt(cloth.value, wool.value)  # Processing adds value

func test_stack_size_for_products():
	# Animal products should be stackable
	product.item_id = &"milk"
	product.stack_size = 999
	
	# But some special items might have lower stack
	var special_product = AnimalProductData.new()
	special_product.item_id = &"golden_egg"
	special_product.stack_size = 10  # Rare item, lower stack
	
	assert_eq(product.stack_size, 999)
	assert_eq(special_product.stack_size, 10)
	assert_lt(special_product.stack_size, product.stack_size)
