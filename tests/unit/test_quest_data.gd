extends GutTest

var quest: QuestData

func before_each():
	quest = QuestData.new()

func test_default_values():
	assert_eq(quest.quest_id, &"")
	assert_eq(quest.title, "")
	assert_eq(quest.description, "")
	assert_false(quest.is_communal)

func test_objectives_array():
	quest.objectives = [
		{"type": "gather", "item_id": &"wood", "amount": 50},
		{"type": "slay", "enemy_id": &"slime", "amount": 10}
	]
	
	assert_eq(quest.objectives.size(), 2)
	assert_eq(quest.objectives[0]["type"], "gather")
	assert_eq(quest.objectives[0]["amount"], 50)
	assert_eq(quest.objectives[1]["enemy_id"], &"slime")

func test_rewards_dictionary():
	quest.rewards = {
		"money": 500,
		"items": {&"iron_axe": 1, &"health_potion": 3}
	}
	
	assert_eq(quest.rewards["money"], 500)
	assert_eq(quest.rewards["items"][&"iron_axe"], 1)
	assert_eq(quest.rewards["items"][&"health_potion"], 3)

func test_communal_quest_flag():
	quest.is_communal = true
	assert_true(quest.is_communal)
