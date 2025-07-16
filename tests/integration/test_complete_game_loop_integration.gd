extends GutTest

# Test a complete gameplay loop

var _events_triggered = []
var _room_player_id = -1
var _room_id = -1
var _player_data = {}
var _day_number = -1

func before_each():
	_events_triggered = []
	_room_player_id = -1
	_room_id = -1
	_player_data = {}
	_day_number = -1

func test_new_player_first_day_experience():
	var player_id = 999
	
	# Connect all signals
	EventBus.server_player_assigned_room.connect(_on_room_assigned)
	EventBus.client_player_data_updated.connect(_on_data_updated)
	EventBus.client_inventory_changed.connect(_on_inventory_changed)
	EventBus.server_day_passed.connect(_on_day_passed)
	
	# Simulate first day
	EventBus.server_player_assigned_room.emit(player_id, 101)
	EventBus.client_player_data_updated.emit({"level": 1, "skills": {}})
	EventBus.client_inventory_changed.emit()
	EventBus.server_day_passed.emit(1)
	
	# Verify sequence
	assert_has(_events_triggered, "room_assigned")
	assert_has(_events_triggered, "data_updated") 
	assert_has(_events_triggered, "inventory_changed")
	assert_has(_events_triggered, "day_passed")
	
	assert_eq(_room_player_id, player_id)
	assert_eq(_room_id, 101)
	assert_eq(_day_number, 1)
	
	gut.p("First day events: " + str(_events_triggered))
	
	# Cleanup connections
	EventBus.server_player_assigned_room.disconnect(_on_room_assigned)
	EventBus.client_player_data_updated.disconnect(_on_data_updated)
	EventBus.client_inventory_changed.disconnect(_on_inventory_changed)
	EventBus.server_day_passed.disconnect(_on_day_passed)

func _on_room_assigned(pid, rid):
	_events_triggered.append("room_assigned")
	_room_player_id = pid
	_room_id = rid

func _on_data_updated(data):
	_events_triggered.append("data_updated")
	_player_data = data

func _on_inventory_changed():
	_events_triggered.append("inventory_changed")

func _on_day_passed(day):
	_events_triggered.append("day_passed")
	_day_number = day
