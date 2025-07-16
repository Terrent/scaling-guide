extends GutTest

# Test combat flow: weapon -> enemy -> loot -> quest progress

var sword: EquipmentData
var slime: EnemyData
var slime_quest: QuestData
var player_id = 123

# Instance variables for signal testing
var _signal_received = false
var _received_player_id = -1
var _received_enemy = null

func before_each():
	# Reset test variables
	_signal_received = false
	_received_player_id = -1
	_received_enemy = null
	
	# Set up weapon
	sword = EquipmentData.new()
	sword.item_id = &"iron_sword"
	sword.display_name = "Iron Sword"
	sword.equip_slot = EquipmentData.EquipSlot.WEAPON
	sword.stat_bonuses = {
		&"attack": 15,
		&"crit_chance": 0.05
	}
	
	# Set up enemy
	slime = EnemyData.new()
	slime.enemy_id = &"green_slime"
	slime.display_name = "Green Slime"
	slime.health = 20
	slime.damage = 2
	slime.xp_value = 10
	slime.loot_table = {
		&"slime_ball": 0.75,
		&"rare_slime_core": 0.05
	}
	
	# Set up quest
	slime_quest = QuestData.new()
	slime_quest.quest_id = &"slime_hunter"
	slime_quest.title = "Slime Hunter"
	slime_quest.objectives = [
		{"type": "slay", "enemy_id": &"green_slime", "amount": 10}
	]
	slime_quest.rewards = {
		"money": 100,
		"items": {&"health_potion": 3}
	}

func test_weapon_affects_combat_stats():
	var base_attack = 10  # Assume player base attack
	var total_attack = base_attack + sword.stat_bonuses[&"attack"]
	assert_eq(total_attack, 25)

func test_enemy_defeat_triggers_event():
	EventBus.server_enemy_defeated.connect(_on_enemy_defeated)
	
	EventBus.server_enemy_defeated.emit(player_id, slime)
	
	assert_true(_signal_received)
	assert_eq(_received_player_id, player_id)
	assert_eq(_received_enemy, slime)
	
	EventBus.server_enemy_defeated.disconnect(_on_enemy_defeated)

func _on_enemy_defeated(pid, enemy):
	_signal_received = true
	_received_player_id = pid
	_received_enemy = enemy

func test_quest_objective_matching():
	var objective = slime_quest.objectives[0]
	assert_eq(objective["type"], "slay")
	assert_eq(objective["enemy_id"], slime.enemy_id)  # Quest targets this enemy type

func test_loot_probability_validation():
	var total_probability = 0.0
	for item in slime.loot_table:
		total_probability += slime.loot_table[item]
	
	# Total should be <= 1.0 (not everything has to drop)
	assert_true(total_probability <= 1.0, "Total probability should be <= 1.0")
	gut.p("Total loot probability: %.2f" % total_probability)
