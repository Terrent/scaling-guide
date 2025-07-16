extends GutTest

var enemy: EnemyData

func before_each():
	enemy = EnemyData.new()

func test_default_values():
	assert_eq(enemy.enemy_id, &"")
	assert_eq(enemy.display_name, "")
	assert_eq(enemy.health, 10)
	assert_eq(enemy.damage, 1)
	assert_eq(enemy.xp_value, 5)

func test_loot_table_dictionary():
	enemy.loot_table = {
		&"slime_ball": 0.5,
		&"rare_gem": 0.01
	}
	
	assert_eq(enemy.loot_table[&"slime_ball"], 0.5)
	assert_eq(enemy.loot_table[&"rare_gem"], 0.01)

func test_can_configure_enemy():
	enemy.enemy_id = &"goblin"
	enemy.display_name = "Forest Goblin"
	enemy.health = 25
	enemy.damage = 3
	enemy.xp_value = 15
	
	assert_eq(enemy.enemy_id, &"goblin")
	assert_eq(enemy.health, 25)
