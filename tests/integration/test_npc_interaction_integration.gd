extends GutTest

# Test NPC gifting and relationship system

var flower_item: ItemData
var npc_loves_flowers = {&"rose": 10, &"sunflower": 8}
var player_id = 333
var npc_id = &"marie"

# Instance variables for signal testing
var _gift_received = false
var _gift_player_id = -1
var _gift_npc_id = &""
var _gift_item_id = &""

func before_each():
	# Reset test variables
	_gift_received = false
	_gift_player_id = -1
	_gift_npc_id = &""
	_gift_item_id = &""
	
	flower_item = ItemData.new()
	flower_item.item_id = &"rose"
	flower_item.display_name = "Rose"
	flower_item.value = 20

func test_gift_giving_triggers_relationship_event():
	EventBus.server_npc_gifted.connect(_on_npc_gifted)
	
	# Give flower to NPC
	EventBus.server_npc_gifted.emit(player_id, npc_id, flower_item.item_id)
	
	assert_true(_gift_received)
	assert_eq(_gift_player_id, player_id)
	assert_eq(_gift_npc_id, npc_id)
	assert_eq(_gift_item_id, &"rose")
	
	EventBus.server_npc_gifted.disconnect(_on_npc_gifted)

func _on_npc_gifted(pid, nid, iid):
	_gift_received = true
	_gift_player_id = pid
	_gift_npc_id = nid
	_gift_item_id = iid

func test_gift_preferences():
	# This would be part of an NPC data resource in practice
	assert_has(npc_loves_flowers, &"rose")
	assert_eq(npc_loves_flowers[&"rose"], 10)  # Max affection points
