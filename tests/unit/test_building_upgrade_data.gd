# tests/unit/test_building_upgrade_data.gd
extends GutTest

var upgrade: BuildingUpgradeData
var wood_item: ItemData
var stone_item: ItemData

func before_each():
	upgrade = BuildingUpgradeData.new()
	wood_item = ItemData.new()
	wood_item.item_id = &"wood"
	stone_item = ItemData.new()
	stone_item.item_id = &"stone"

func test_default_values():
	assert_eq(upgrade.upgrade_id, &"")
	assert_eq(upgrade.title, "")
	assert_eq(upgrade.description, "")
	assert_eq(upgrade.material_costs.size(), 0)
	assert_eq(upgrade.unlocks_feature, &"")

func test_basic_bridge_repair():
	# Simple community project
	upgrade.upgrade_id = &"repair_bridge"
	upgrade.title = "Repair the Old Bridge"
	upgrade.description = "Fix the bridge to access the eastern forest. The whole community will benefit!"
	
	upgrade.material_costs = {
		wood_item: 100,
		stone_item: 50
	}
	
	upgrade.unlocks_feature = &"eastern_forest_access"
	
	assert_eq(upgrade.upgrade_id, &"repair_bridge")
	assert_eq(upgrade.material_costs[wood_item], 100)
	assert_eq(upgrade.unlocks_feature, &"eastern_forest_access")

func test_community_center_room():
	# Larger project with multiple resources
	upgrade.upgrade_id = &"community_center_kitchen"
	upgrade.title = "Restore Community Kitchen"
	upgrade.description = "Build a shared kitchen where players can cook together and share recipes."
	
	var iron_bar = ItemData.new()
	iron_bar.item_id = &"iron_bar"
	
	upgrade.material_costs = {
		wood_item: 200,
		stone_item: 150,
		iron_bar: 25
	}
	
	upgrade.unlocks_feature = &"community_cooking"
	
	assert_eq(upgrade.material_costs.size(), 3)
	assert_has(upgrade.material_costs, iron_bar)

func test_unlock_new_merchant():
	# Upgrade that brings new NPCs
	upgrade.upgrade_id = &"traveling_merchant_post"
	upgrade.title = "Build Merchant Stall"
	upgrade.description = "Construct a permanent stall to attract traveling merchants with rare goods."
	
	var gold = ItemData.new()
	gold.item_id = &"gold"
	
	upgrade.material_costs = {
		wood_item: 300,
		stone_item: 200,
		gold: 1000  # Expensive!
	}
	
	upgrade.unlocks_feature = &"traveling_merchant"
	
	# Check it requires money
	assert_has(upgrade.material_costs, gold)
	assert_eq(upgrade.material_costs[gold], 1000)

func test_mine_cart_system():
	# Infrastructure upgrade
	upgrade.upgrade_id = &"mine_cart_rails"
	upgrade.title = "Install Mine Cart System"
	upgrade.description = "Build rails in the mine for faster travel between levels."
	
	var iron_bar = ItemData.new()
	iron_bar.item_id = &"iron_bar"
	var coal = ItemData.new()
	coal.item_id = &"coal"
	
	upgrade.material_costs = {
		iron_bar: 50,
		wood_item: 100,
		coal: 25
	}
	
	upgrade.unlocks_feature = &"mine_fast_travel"
	
	# Industrial upgrade needs metal
	assert_gt(upgrade.material_costs[iron_bar], 0)

func test_festival_grounds():
	# Social space upgrade
	upgrade.upgrade_id = &"festival_plaza"
	upgrade.title = "Create Festival Plaza"
	upgrade.description = "Build a beautiful plaza for seasonal festivals and community gatherings."
	
	var marble = ItemData.new()
	marble.item_id = &"marble"
	var flower = ItemData.new()
	flower.item_id = &"flower_bundle"
	
	upgrade.material_costs = {
		stone_item: 500,  # Lots of stone for plaza
		marble: 20,       # Decorative elements
		flower: 50        # Beautification
	}
	
	upgrade.unlocks_feature = &"enhanced_festivals"
	
	# Expensive community project
	assert_gte(upgrade.material_costs[stone_item], 500)

func test_greenhouse_community():
	# Shared farming space
	upgrade.upgrade_id = &"community_greenhouse"
	upgrade.title = "Build Community Greenhouse"
	upgrade.description = "A shared greenhouse where all players can grow crops year-round."
	
	var glass = ItemData.new()
	glass.item_id = &"glass"
	var refined_quartz = ItemData.new()
	refined_quartz.item_id = &"refined_quartz"
	
	upgrade.material_costs = {
		wood_item: 150,
		glass: 100,
		refined_quartz: 50,
		stone_item: 200
	}
	
	upgrade.unlocks_feature = &"community_greenhouse"
	
	assert_eq(upgrade.material_costs.size(), 4)
	assert_eq(upgrade.material_costs[glass], 100)

func test_upgrade_tiers():
	# Some upgrades might have prerequisites
	var upgrades = [
		{
			"id": &"bridge_basic",
			"title": "Basic Bridge Repair",
			"wood": 50,
			"stone": 25,
			"tier": 1
		},
		{
			"id": &"bridge_reinforced",
			"title": "Reinforce Bridge",
			"wood": 100,
			"stone": 75,
			"iron": 20,
			"tier": 2
		},
		{
			"id": &"bridge_decorative",
			"title": "Beautify Bridge", 
			"stone": 50,
			"marble": 10,
			"paint": 5,
			"tier": 2  # Same tier, different purpose
		}
	]
	
	# Group by tier and check costs within tiers
	var tier1_cost = 0
	var tier2_costs = []
	
	for upgrade_data in upgrades:
		var total_cost = 0
		if upgrade_data.has("wood"):
			total_cost += upgrade_data["wood"]
		if upgrade_data.has("stone"):
			total_cost += upgrade_data["stone"]
		
		gut.p("%s (Tier %d): %d total base materials" % 
			[upgrade_data["title"], upgrade_data["tier"], total_cost])
		
		if upgrade_data["tier"] == 1:
			tier1_cost = total_cost
		else:
			tier2_costs.append(total_cost)
	
	# Tier 2 upgrades should generally cost more than tier 1
	for cost in tier2_costs:
		assert_gte(cost, tier1_cost - 25, "Tier 2 should be comparable or more than Tier 1")


func test_special_event_upgrades():
	# Limited time community goals
	upgrade.upgrade_id = &"winter_preparation"
	upgrade.title = "Prepare for Winter Festival"
	upgrade.description = "Help prepare the town for the upcoming Winter Festival!"
	
	var hot_chocolate = ItemData.new()
	hot_chocolate.item_id = &"hot_chocolate"
	
	upgrade.material_costs = {
		wood_item: 200,  # For bonfire
		hot_chocolate: 50,  # For guests
		stone_item: 100  # For fire pit
	}
	
	upgrade.unlocks_feature = &"winter_festival_enhanced"
	
	# Requires event-specific items
	assert_has(upgrade.material_costs, hot_chocolate)

func test_unlock_types():
	# Different things upgrades can unlock
	var unlock_examples = [
		{
			"feature": &"new_area_access",
			"type": "Map Expansion"
		},
		{
			"feature": &"new_npc_vendor",
			"type": "NPC Unlock"
		},
		{
			"feature": &"fast_travel_system",
			"type": "QoL Feature"
		},
		{
			"feature": &"community_storage",
			"type": "Shared Resource"
		},
		{
			"feature": &"weekly_event",
			"type": "Recurring Event"
		}
	]
	
	for unlock in unlock_examples:
		upgrade.unlocks_feature = unlock["feature"]
		gut.p("%s unlocks: %s" % [unlock["type"], unlock["feature"]])
		assert_ne(upgrade.unlocks_feature, &"")

func test_material_cost_scaling():
	# Test that costs scale with benefit
	var upgrades_by_impact = [
		{
			"title": "Fix Mailbox",
			"impact": "low",
			"total_cost": 25
		},
		{
			"title": "Build Bus Stop",
			"impact": "medium", 
			"total_cost": 250
		},
		{
			"title": "Restore Train Station",
			"impact": "high",
			"total_cost": 2500
		}
	]
	
	var previous_cost = 0
	for upgrade_data in upgrades_by_impact:
		gut.p("%s impact: %d materials" % [upgrade_data["impact"], upgrade_data["total_cost"]])
		assert_gt(upgrade_data["total_cost"], previous_cost)
		previous_cost = upgrade_data["total_cost"]

# Parameterized test for different upgrade categories
func test_upgrade_categories(params=use_parameters([
	{
		"category": "Infrastructure",
		"id": &"road_paving",
		"materials": 3,
		"expensive": true
	},
	{
		"category": "Commerce",
		"id": &"market_square",
		"materials": 4,
		"expensive": true
	},
	{
		"category": "Agriculture", 
		"id": &"irrigation_system",
		"materials": 2,
		"expensive": false
	},
	{
		"category": "Defense",
		"id": &"town_walls",
		"materials": 3,
		"expensive": true
	},
	{
		"category": "Culture",
		"id": &"museum",
		"materials": 5,
		"expensive": true
	}
])):
	upgrade.upgrade_id = params.id
	
	# Add materials based on count
	for i in range(params.materials):
		var item = ItemData.new()
		item.item_id = StringName("material_%d" % i)
		upgrade.material_costs[item] = 100 * (i + 1)
	
	gut.p("%s upgrade '%s': %d material types, expensive: %s" % 
		[params.category, params.id, params.materials, params.expensive])
	
	assert_eq(upgrade.upgrade_id, params.id)
	assert_eq(upgrade.material_costs.size(), params.materials)
	
	if params.expensive:
		# Expensive upgrades need 300+ total materials
		var total = 0
		for cost in upgrade.material_costs.values():
			total += cost
		assert_gte(total, 300)

func test_collaborative_requirements():
	# Some upgrades need diverse materials to encourage trading
	upgrade.upgrade_id = &"lighthouse"
	upgrade.title = "Restore the Lighthouse"
	upgrade.description = "Light the way for ships and unlock sea trading routes."
	
	# Diverse materials from different skills
	var materials = {
		stone_item: 300,        # Mining
		wood_item: 200,         # Foraging/Farming
		&"iron_bar": 50,        # Mining + Processing
		&"glass": 25,           # Smelting
		&"battery_pack": 5,     # Crafting
		&"solar_essence": 10    # Combat
	}
	
	# Convert to ItemData
	upgrade.material_costs = {}
	for mat_id in materials:
		var item = ItemData.new()
		if mat_id is String or mat_id is StringName:
			item.item_id = StringName(mat_id)
		else:
			item = mat_id  # Already ItemData
		upgrade.material_costs[item] = materials[mat_id]
	
	# Requires materials from multiple sources
	assert_gte(upgrade.material_costs.size(), 5)
	
	# No single player can easily complete alone
	gut.p("Lighthouse requires %d different material types" % upgrade.material_costs.size())

func test_complete_upgrade_configuration():
	# Fully configured community upgrade
	upgrade.upgrade_id = &"community_center_complete"
	upgrade.title = "Complete Community Center Restoration"
	upgrade.description = "The final push to fully restore our beloved community center. This will unlock weekly gatherings, shared storage, and bring the community together!"
	
	# Major project with many resources
	var gold = ItemData.new()
	gold.item_id = &"gold"
	var hardwood = ItemData.new()
	hardwood.item_id = &"hardwood"
	var prismatic_shard = ItemData.new()
	prismatic_shard.item_id = &"prismatic_shard"
	
	upgrade.material_costs = {
		wood_item: 500,
		stone_item: 500,
		gold: 10000,
		hardwood: 100,
		prismatic_shard: 1  # Rare item requirement
	}
	
	upgrade.unlocks_feature = &"community_center_full"
	
	# Verify complete setup
	assert_ne(upgrade.upgrade_id, &"")
	assert_ne(upgrade.title, "")
	assert_gt(upgrade.description.length(), 100)  # Detailed description
	assert_gt(upgrade.material_costs.size(), 4)
	assert_ne(upgrade.unlocks_feature, &"")
	
	# Has rare item requirement
	assert_has(upgrade.material_costs, prismatic_shard)
	assert_eq(upgrade.material_costs[prismatic_shard], 1)
