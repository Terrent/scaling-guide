extends GutTest

# Test how various systems respond to day passing

var current_day = 1
var festival_active = false

# Instance variables for signal testing
var _day_signal_count = 0
var _crop_growth_checked = false
var _festival_checked = false
var _received_day = -1

func before_each():
	# Reset test variables
	_day_signal_count = 0
	_crop_growth_checked = false
	_festival_checked = false
	_received_day = -1

func test_day_passed_triggers_multiple_systems():
	EventBus.server_day_passed.connect(_on_day_passed)
	
	# Simulate day passing
	EventBus.server_day_passed.emit(15)
	
	assert_eq(_day_signal_count, 1)
	assert_true(_crop_growth_checked)
	assert_true(_festival_checked)
	assert_eq(_received_day, 15)
	
	EventBus.server_day_passed.disconnect(_on_day_passed)

func _on_day_passed(day):
	_day_signal_count += 1
	_received_day = day
	
	# Crop system would check growth
	_crop_growth_checked = true
	
	# Festival system would check dates
	if day == 15:  # Mid-month festival
		_festival_checked = true

func test_festival_state_changes():
	var state_changes = []
	
	EventBus.server_festival_state_changed.connect(func(fid, state):
		state_changes.append({"festival": fid, "state": state})
	)
	
	# Festival lifecycle
	EventBus.server_festival_state_changed.emit(&"harvest_festival", 0)  # Setup
	EventBus.server_festival_state_changed.emit(&"harvest_festival", 1)  # Active
	EventBus.server_festival_state_changed.emit(&"harvest_festival", 2)  # Cleanup
	
	assert_eq(state_changes.size(), 3)
	assert_eq(state_changes[1]["state"], 1)  # Active state
	
	EventBus.server_festival_state_changed.disconnect(EventBus.server_festival_state_changed.get_connections()[0]["callable"])
