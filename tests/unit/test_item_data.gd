extends GutTest

var item: ItemData

func before_each():
	item = ItemData.new()

func test_default_values():
	assert_eq(item.item_id, &"")
	assert_eq(item.display_name, "")
	assert_eq(item.description, "")
	assert_eq(item.stack_size, 1)
	assert_eq(item.value, 0)
	assert_null(item.icon)

func test_can_set_properties():
	var test_icon = preload("res://icon.svg")
	
	item.item_id = &"test_item"
	item.display_name = "Test Item"
	item.description = "A test item for unit testing"
	item.icon = test_icon
	item.stack_size = 99
	item.value = 250
	
	assert_eq(item.item_id, &"test_item")
	assert_eq(item.display_name, "Test Item")
	assert_eq(item.icon, test_icon)
	assert_eq(item.stack_size, 99)
