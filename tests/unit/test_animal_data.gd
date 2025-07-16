# tests/unit/test_animal_data.gd
extends GutTest

var animal: AnimalData
var product: ItemData

func before_each():
	animal = AnimalData.new()
	product = ItemData.new()

func test_default_values():
	assert_eq(animal.animal_id, &"")
	assert_null(animal.produces_item)
	assert_eq(animal.days_to_produce, 1)
	# habitat_type has no default, it's an enum

func test_habitat_types():
	# Test both habitat types
	animal.habitat_type = AnimalData.HabitatType.COOP
	assert_eq(animal.habitat_type, AnimalData.HabitatType.COOP)
	
	animal.habitat_type = AnimalData.HabitatType.BARN
	assert_eq(animal.habitat_type, AnimalData.HabitatType.BARN)

func test_chicken_configuration():
	# Classic coop animal
	animal.animal_id = &"chicken"
	animal.habitat_type = AnimalData.HabitatType.COOP
	
	product.item_id = &"egg"
	product.display_name = "Egg"
	product.value = 50
	
	animal.produces_item = product
	animal.days_to_produce = 1  # Daily eggs
	
	assert_eq(animal.animal_id, &"chicken")
	assert_eq(animal.habitat_type, AnimalData.HabitatType.COOP)
	assert_eq(animal.produces_item.item_id, &"egg")
	assert_eq(animal.days_to_produce, 1)

func test_cow_configuration():
	# Classic barn animal
	animal.animal_id = &"cow"
	animal.habitat_type = AnimalData.HabitatType.BARN
	
	product.item_id = &"milk"
	product.display_name = "Milk"
	product.value = 125
	
	animal.produces_item = product
	animal.days_to_produce = 1  # Daily milk
	
	assert_eq(animal.habitat_type, AnimalData.HabitatType.BARN)
	assert_eq(animal.produces_item.value, 125)

func test_sheep_wool_production():
	# Sheep produce less frequently
	animal.animal_id = &"sheep"
	animal.habitat_type = AnimalData.HabitatType.BARN
	
	product.item_id = &"wool"
	product.display_name = "Wool"
	product.value = 340
	
	animal.produces_item = product
	animal.days_to_produce = 3  # Every 3 days
	
	assert_eq(animal.days_to_produce, 3)
	assert_gt(animal.produces_item.value, 300)  # Wool is valuable

func test_duck_special_products():
	# Ducks have regular and rare products
	animal.animal_id = &"duck"
	animal.habitat_type = AnimalData.HabitatType.COOP
	
	# Regular product
	product.item_id = &"duck_egg"
	product.display_name = "Duck Egg"
	product.value = 95
	
	animal.produces_item = product
	animal.days_to_produce = 2  # Every other day
	
	# Note: Duck feather would be handled by a separate chance system
	assert_eq(animal.produces_item.item_id, &"duck_egg")
	assert_eq(animal.days_to_produce, 2)

func test_rabbit_valuable_product():
	# Rabbits produce high-value items slowly
	animal.animal_id = &"rabbit"
	animal.habitat_type = AnimalData.HabitatType.COOP
	
	product.item_id = &"rabbit_foot"
	product.display_name = "Rabbit's Foot"
	product.value = 565
	
	animal.produces_item = product
	animal.days_to_produce = 4  # Rare product
	
	assert_gt(animal.produces_item.value, 500)
	assert_gte(animal.days_to_produce, 4)

func test_goat_milk_variant():
	# Goats produce different milk
	animal.animal_id = &"goat"
	animal.habitat_type = AnimalData.HabitatType.BARN
	
	product.item_id = &"goat_milk"
	product.display_name = "Goat Milk"
	product.value = 225  # More valuable than cow milk
	
	animal.produces_item = product
	animal.days_to_produce = 2
	
	assert_eq(animal.habitat_type, AnimalData.HabitatType.BARN)
	assert_gt(product.value, 200)

func test_pig_special_case():
	# Pigs don't produce items, they find truffles
	animal.animal_id = &"pig"
	animal.habitat_type = AnimalData.HabitatType.BARN
	
	# Pigs might not have a produces_item
	# They find items outside instead
	animal.produces_item = null
	animal.days_to_produce = 1  # Daily truffle hunting
	
	assert_null(animal.produces_item)

func test_production_efficiency():
	# Compare value per day for different animals
	var animals_data = [
		{
			"name": "Chicken",
			"value": 50,
			"days": 1,
			"efficiency": 50.0
		},
		{
			"name": "Duck",
			"value": 95,
			"days": 2,
			"efficiency": 47.5
		},
		{
			"name": "Cow",
			"value": 125,
			"days": 1,
			"efficiency": 125.0
		},
		{
			"name": "Goat",
			"value": 225,
			"days": 2,
			"efficiency": 112.5
		},
		{
			"name": "Sheep",
			"value": 340,
			"days": 3,
			"efficiency": 113.3
		}
	]
	
	for data in animals_data:
		var efficiency = float(data["value"]) / float(data["days"])
		gut.p("%s: %.1f gold/day" % [data["name"], efficiency])
		assert_almost_eq(efficiency, data["efficiency"], 0.5)

func test_coop_animals():
	# All coop animals
	var coop_animals = [&"chicken", &"duck", &"rabbit", &"dinosaur"]
	
	for animal_id in coop_animals:
		animal.animal_id = animal_id
		animal.habitat_type = AnimalData.HabitatType.COOP
		
		assert_eq(animal.habitat_type, AnimalData.HabitatType.COOP)

func test_barn_animals():
	# All barn animals
	var barn_animals = [&"cow", &"goat", &"sheep", &"pig", &"ostrich"]
	
	for animal_id in barn_animals:
		animal.animal_id = animal_id
		animal.habitat_type = AnimalData.HabitatType.BARN
		
		assert_eq(animal.habitat_type, AnimalData.HabitatType.BARN)

func test_rare_animals():
	# Special/rare animals
	
	# Dinosaur (from hatching dino egg)
	animal.animal_id = &"dinosaur"
	animal.habitat_type = AnimalData.HabitatType.COOP
	
	product.item_id = &"dinosaur_egg"
	product.value = 350
	
	animal.produces_item = product
	animal.days_to_produce = 7  # Weekly
	
	assert_eq(animal.days_to_produce, 7)
	assert_eq(animal.produces_item.item_id, &"dinosaur_egg")

func test_golden_chicken():
	# Ultra rare animal
	animal.animal_id = &"golden_chicken"
	animal.habitat_type = AnimalData.HabitatType.COOP
	
	product.item_id = &"golden_egg"
	product.value = 500
	
	animal.produces_item = product
	animal.days_to_produce = 1  # Daily but very valuable
	
	assert_eq(animal.produces_item.value, 500)
	gut.p("Golden chicken efficiency: %d gold/day" % product.value)

# Parameterized test for all animals
func test_all_farm_animals(params=use_parameters([
	{
		"id": &"chicken",
		"habitat": AnimalData.HabitatType.COOP,
		"product": &"egg",
		"days": 1
	},
	{
		"id": &"cow",
		"habitat": AnimalData.HabitatType.BARN,
		"product": &"milk",
		"days": 1
	},
	{
		"id": &"sheep",
		"habitat": AnimalData.HabitatType.BARN,
		"product": &"wool",
		"days": 3
	},
	{
		"id": &"rabbit",
		"habitat": AnimalData.HabitatType.COOP,
		"product": &"rabbit_foot",
		"days": 4
	},
	{
		"id": &"duck",
		"habitat": AnimalData.HabitatType.COOP,
		"product": &"duck_egg",
		"days": 2
	}
])):
	animal.animal_id = params.id
	animal.habitat_type = params.habitat
	
	product = ItemData.new()
	product.item_id = params.product
	animal.produces_item = product
	animal.days_to_produce = params.days
	
	var habitat_name = "Coop" if params.habitat == AnimalData.HabitatType.COOP else "Barn"
	gut.p("%s (%s): %s every %d days" % 
		[params.id, habitat_name, params.product, params.days])
	
	assert_eq(animal.animal_id, params.id)
	assert_eq(animal.habitat_type, params.habitat)
	assert_eq(animal.produces_item.item_id, params.product)
	assert_eq(animal.days_to_produce, params.days)

func test_animal_happiness_affects_quality():
	# While AnimalData doesn't store happiness,
	# it's good to test the concept
	animal.animal_id = &"cow"
	
	# Base product
	product.item_id = &"milk"
	product.value = 125
	
	animal.produces_item = product
	
	# In the game, happiness would affect whether
	# the cow produces normal/silver/gold milk
	# This would be handled by the game logic, not AnimalData
	assert_eq(animal.produces_item.item_id, &"milk")

func test_complete_animal_configuration():
	# Fully configured animal
	animal.animal_id = &"alpaca"
	animal.habitat_type = AnimalData.HabitatType.BARN
	
	product.item_id = &"alpaca_wool"
	product.display_name = "Alpaca Wool"
	product.description = "Soft, luxurious wool from an alpaca"
	product.value = 450
	product.stack_size = 999
	
	animal.produces_item = product
	animal.days_to_produce = 4  # Every 4 days
	
	# Verify complete setup
	assert_ne(animal.animal_id, &"")
	assert_not_null(animal.produces_item)
	assert_gt(animal.days_to_produce, 0)
	
	# Alpaca wool is premium
	assert_gt(animal.produces_item.value, 400)
	
	# Calculate weekly income
	var weekly_income = (7.0 / animal.days_to_produce) * animal.produces_item.value
	gut.p("Alpaca weekly income: %.0f gold" % weekly_income)
	assert_gt(weekly_income, 700)
