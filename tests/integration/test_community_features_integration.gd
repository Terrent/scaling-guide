extends GutTest

var community_quest: QuestData
var player1_id = 111
var player2_id = 222

# Instance variables for signal testing
var _progress_tracked = false
var _quest_id_received = &""
var _player_id_received = -1
var _data_received = {}

func before_each():
	# Reset test variables
	_progress_tracked = false
	_quest_id_received = &""
	_player_id_received = -1
	_data_received = {}
	
	community_quest = QuestData.new()
	community_quest.quest_id = &"rebuild_bridge"
	community_quest.title = "Rebuild the Bridge"
	community_quest.is_communal = true
	community_quest.objectives = [
		{"type": "gather", "item_id": &"wood", "amount": 500},
		{"type": "gather", "item_id": &"stone", "amount": 200}
	]

func test_community_quest_progress_tracking():
	EventBus.server_community_quest_progress.connect(_on_quest_progress)
	
	var wood_contribution = {"item_id": &"wood", "amount": 50}
	EventBus.server_community_quest_progress.emit(
		community_quest.quest_id,
		player1_id,
		wood_contribution
	)
	
	assert_true(_progress_tracked)
	assert_eq(_quest_id_received, &"rebuild_bridge")
	assert_eq(_data_received.get("amount", 0), 50)
	
	EventBus.server_community_quest_progress.disconnect(_on_quest_progress)

func _on_quest_progress(qid, pid, data):
	_progress_tracked = true
	_quest_id_received = qid
	_player_id_received = pid
	_data_received = data
