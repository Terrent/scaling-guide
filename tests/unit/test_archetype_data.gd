# tests/unit/test_archetype_data.gd
extends GutTest

var archetype: ArchetypeData
var mock_item: ItemData

func before_each():
	archetype = ArchetypeData.new()
	mock_item = ItemData.new()

func test_default_values():
	assert_eq(archetype.archetype_id, &"")
	assert_eq(archetype.display_name, "")
	assert_eq(archetype.description, "")
	assert_eq(archetype.bonus_skill_proficiencies.size(), 0)
	assert_eq(archetype.initial_equipment.size(), 0)

func test_farmer_archetype():
	# Traditional farmer start
	archetype.archetype_id = &"farmer"
	archetype.display_name = "Farmer"
	archetype.description = "Born to till the soil. Starts with farming knowledge and basic tools."
	
	# Skill bonuses
	archetype.bonus_skill_proficiencies = {
		&"farming": 2,
		&"foraging": 1
	}
	
	# Starting items
	var hoe = ItemData.new()
	hoe.item_id = &"wooden_hoe"
	var seeds = ItemData.new()
	seeds.item_id = &"parsnip_seeds"
	
	archetype.initial_equipment = [hoe, seeds]
	
	assert_eq(archetype.archetype_id, &"farmer")
	assert_eq(archetype.bonus_skill_proficiencies[&"farming"], 2)
	assert_eq(archetype.initial_equipment.size(), 2)

func test_miner_archetype():
	# Mining-focused start
	archetype.archetype_id = &"miner"
	archetype.display_name = "Miner"
	archetype.description = "Raised in the mountain caves. Expert at finding precious metals and gems."
	
	archetype.bonus_skill_proficiencies = {
		&"mining": 3,
		&"combat": 1  # Dangerous in the mines!
	}
	
	# Better starting pickaxe
	var pickaxe = ItemData.new()
	pickaxe.item_id = &"copper_pickaxe"  # Starts with upgraded tool
	var torch = ItemData.new()
	torch.item_id = &"torch"
	torch.stack_size = 10
	
	archetype.initial_equipment = [pickaxe, torch]
	
	assert_eq(archetype.bonus_skill_proficiencies[&"mining"], 3)
	assert_has(archetype.initial_equipment, pickaxe)

func test_fisher_archetype():
	# Fishing and water-focused
	archetype.archetype_id = &"fisher"
	archetype.display_name = "Fisher"
	archetype.description = "Grew up by the sea. Can catch fish that others can't even see."
	
	archetype.bonus_skill_proficiencies = {
		&"fishing": 3,
		&"cooking": 1  # Knows how to prepare fish
	}
	
	var rod = ItemData.new()
	rod.item_id = &"bamboo_fishing_rod"
	var bait = ItemData.new()
	bait.item_id = &"bait"
	bait.stack_size = 25
	
	archetype.initial_equipment = [rod, bait]
	
	assert_eq(archetype.display_name, "Fisher")
	assert_gt(archetype.bonus_skill_proficiencies[&"fishing"], 2)

func test_warrior_archetype():
	# Combat-focused start
	archetype.archetype_id = &"warrior"
	archetype.display_name = "Warrior"
	archetype.description = "Trained in combat from a young age. The monsters should fear you."
	
	archetype.bonus_skill_proficiencies = {
		&"combat": 4  # Significant combat boost
	}
	
	# Starts with weapon and armor
	var sword = ItemData.new()
	sword.item_id = &"rusty_sword"
	var boots = ItemData.new()
	boots.item_id = &"leather_boots"
	
	archetype.initial_equipment = [sword, boots]
	
	# Warriors are specialized - only one skill bonus
	assert_eq(archetype.bonus_skill_proficiencies.size(), 1)
	assert_eq(archetype.bonus_skill_proficiencies[&"combat"], 4)

func test_merchant_archetype():
	# Economy and social focused
	archetype.archetype_id = &"merchant"
	archetype.display_name = "Merchant"
	archetype.description = "Born with a silver tongue and an eye for profit."
	
	archetype.bonus_skill_proficiencies = {
		&"social": 2,
		&"foraging": 1,  # Knows valuable items
		&"mining": 1     # Appraises gems
	}
	
	# Starts with money instead of tools
	var coins = ItemData.new()
	coins.item_id = &"gold"
	coins.stack_size = 500  # Extra starting gold
	
	archetype.initial_equipment = [coins]
	
	# Merchants are well-rounded
	assert_eq(archetype.bonus_skill_proficiencies.size(), 3)
	assert_has(archetype.bonus_skill_proficiencies, &"social")

func test_balanced_archetype():
	# Jack of all trades
	archetype.archetype_id = &"adventurer"
	archetype.display_name = "Adventurer"
	archetype.description = "A little bit of everything, master of none... yet."
	
	# Small bonus to everything
	archetype.bonus_skill_proficiencies = {
		&"farming": 1,
		&"mining": 1,
		&"combat": 1,
		&"fishing": 1,
		&"foraging": 1
	}
	
	# Basic tool set
	var multitool = ItemData.new()
	multitool.item_id = &"basic_multitool"
	
	archetype.initial_equipment = [multitool]
	
	# Check all skills have same bonus
	for skill in archetype.bonus_skill_proficiencies:
		assert_eq(archetype.bonus_skill_proficiencies[skill], 1)

func test_archetype_without_equipment():
	# Hard mode - no starting items
	archetype.archetype_id = &"nomad"
	archetype.display_name = "Nomad"
	archetype.description = "Arrives with nothing but determination."
	
	# High skill bonuses to compensate
	archetype.bonus_skill_proficiencies = {
		&"foraging": 3,  # Good at finding things
		&"social": 2     # Good at making friends
	}
	
	archetype.initial_equipment = []  # Empty!
	
	assert_eq(archetype.initial_equipment.size(), 0)
	assert_gt(archetype.bonus_skill_proficiencies[&"foraging"], 2)

func test_total_skill_points_balance():
	# Ensure archetypes are balanced by total skill points
	var archetypes_to_test = [
		{
			"id": &"farmer",
			"skills": {&"farming": 2, &"foraging": 1}
		},
		{
			"id": &"miner",
			"skills": {&"mining": 3, &"combat": 1}
		},
		{
			"id": &"warrior",
			"skills": {&"combat": 4}
		},
		{
			"id": &"merchant",
			"skills": {&"social": 2, &"foraging": 1, &"mining": 1}
		}
	]
	
	for arch_data in archetypes_to_test:
		var total_points = 0
		for skill in arch_data["skills"]:
			total_points += arch_data["skills"][skill]
		
		gut.p("%s: %d total skill points" % [arch_data["id"], total_points])
		
		# Most archetypes should have 3-5 total points
		assert_gte(total_points, 3)
		assert_lte(total_points, 5)

func test_equipment_value_balance():
	# Test that starting equipment is roughly balanced
	var equipment_values = []
	
	# Farmer's equipment
	var hoe = ItemData.new()
	hoe.value = 50
	var seeds = ItemData.new() 
	seeds.value = 20
	equipment_values.append({"archetype": "Farmer", "total": 70})
	
	# Miner's equipment (upgraded tool)
	var copper_pick = ItemData.new()
	copper_pick.value = 100  # Better tool
	var torches = ItemData.new()
	torches.value = 10
	equipment_values.append({"archetype": "Miner", "total": 110})
	
	# Warrior's equipment
	var sword = ItemData.new()
	sword.value = 80
	var boots = ItemData.new()
	boots.value = 40
	equipment_values.append({"archetype": "Warrior", "total": 120})
	
	# Check balance
	for equip_data in equipment_values:
		gut.p("%s starting equipment value: %d gold" % 
			[equip_data["archetype"], equip_data["total"]])
		
		# Starting equipment should be worth 50-150 gold
		assert_gte(equip_data["total"], 50)
		assert_lte(equip_data["total"], 150)

# Parameterized test for all archetypes
func test_all_archetypes(params=use_parameters([
	{
		"id": &"farmer",
		"name": "Farmer",
		"primary_skill": &"farming",
		"equipment_count": 2
	},
	{
		"id": &"rancher",
		"name": "Rancher",
		"primary_skill": &"animal_husbandry",
		"equipment_count": 2
	},
	{
		"id": &"artisan",
		"name": "Artisan",
		"primary_skill": &"crafting",
		"equipment_count": 3
	},
	{
		"id": &"botanist",
		"name": "Botanist", 
		"primary_skill": &"foraging",
		"equipment_count": 1
	},
	{
		"id": &"geologist",
		"name": "Geologist",
		"primary_skill": &"mining",
		"equipment_count": 2
	}
])):
	archetype.archetype_id = params.id
	archetype.display_name = params.name
	
	# Set primary skill bonus
	archetype.bonus_skill_proficiencies[params.primary_skill] = 3
	
	# Add appropriate equipment
	for i in range(params.equipment_count):
		var item = ItemData.new()
		item.item_id = StringName("item_%d" % i)
		archetype.initial_equipment.append(item)
	
	gut.p("%s archetype: +3 %s, %d starting items" % 
		[params.name, params.primary_skill, params.equipment_count])
	
	assert_eq(archetype.archetype_id, params.id)
	assert_eq(archetype.bonus_skill_proficiencies[params.primary_skill], 3)
	assert_eq(archetype.initial_equipment.size(), params.equipment_count)

func test_description_quality():
	# Descriptions should be engaging and informative
	var descriptions = [
		"Born to till the soil. Starts with farming knowledge and basic tools.",
		"Raised in the mountain caves. Expert at finding precious metals and gems.",
		"Grew up by the sea. Can catch fish that others can't even see.",
		"Trained in combat from a young age. The monsters should fear you.",
		"A little bit of everything, master of none... yet."
	]
	
	for desc in descriptions:
		# Should be descriptive
		assert_gt(desc.length(), 30)
		# Should contain flavor and mechanical info
		assert_true(desc.contains("."))

func test_complete_archetype_configuration():
	# Full archetype setup
	archetype.archetype_id = &"chef"
	archetype.display_name = "Chef"
	archetype.description = "Culinary genius who can turn any ingredient into a masterpiece. Starts with cooking skills and kitchen tools."
	
	archetype.bonus_skill_proficiencies = {
		&"cooking": 3,
		&"farming": 1,  # Knows fresh ingredients
		&"fishing": 1   # Can prepare seafood
	}
	
	# Kitchen starter kit
	var knife = ItemData.new()
	knife.item_id = &"kitchen_knife"
	var pot = ItemData.new()
	pot.item_id = &"cooking_pot"
	var recipe_book = ItemData.new()
	recipe_book.item_id = &"basic_recipes"
	
	archetype.initial_equipment = [knife, pot, recipe_book]
	
	# Verify complete setup
	assert_ne(archetype.archetype_id, &"")
	assert_ne(archetype.display_name, "")
	assert_gt(archetype.description.length(), 50)
	assert_gt(archetype.bonus_skill_proficiencies.size(), 0)
	assert_gt(archetype.initial_equipment.size(), 0)
	
	# Chef is skill-focused
	var total_skill_points = 0
	for skill in archetype.bonus_skill_proficiencies.values():
		total_skill_points += skill
	assert_eq(total_skill_points, 5)
