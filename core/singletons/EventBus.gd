# core/singletons/EventBus.gd
# Global event bus for decoupled communication with strict server/client separation.
# All signals are typed for compile-time safety and proper IDE support.
extends Node

# Debug configuration from old system
var debug_mode: bool = false
var verbose_mode: bool = false

# Quiet events that shouldn't spam logs
var quiet_events: Array[String] = [
	"client_inventory_updated",
	"client_time_changed",
	"server_time_ticked"
]

# Critical events that should always log
var critical_events: Array[String] = [
	"server_save_completed",
	"server_save_failed",
	"server_load_completed",
	"server_game_state_changed"
]

#=============================================================================
# SYSTEM & INITIALIZATION SIGNALS
#=============================================================================

## Emitted when the game database has finished loading. Server only.
signal server_database_loaded()
## Emitted when database loading fails. Server only.
signal server_database_load_failed(error_message: String)

#=============================================================================
# GAME STATE MANAGEMENT
#=============================================================================

## Emitted when the game state changes. Server only.
signal server_game_state_changed(old_state: int, new_state: int)
## Emitted to request a game state change. Can be called from anywhere.
signal server_game_state_change_requested(new_state: int)
## Emitted when a client's world scene is ready. Server receives this.
signal server_client_world_ready(peer_id: int)

#=============================================================================
# TIME & CALENDAR SYSTEM
#=============================================================================

## Emitted every time tick. Server only.
signal server_time_ticked(hour: int, minute: int)
## Emitted when time is synced to clients. Server only.
signal server_time_synced(hour: int, minute: int, day: int)
## Emitted when the day starts. Server only.
signal server_day_started(day: int, season: int, year: int)
## Emitted when the day ends. Server only.
signal server_day_ended()
## Request to advance to next day. Can be called from anywhere.
signal server_advance_day_requested()
## Emitted when day advance completes. Server only.
signal server_advance_day_completed(success: bool, error_msg: String)

signal server_day_passed()
## Client receives time updates
signal client_time_changed(hour: int, minute: int)
## Client receives full time sync
signal client_time_synced(hour: int, minute: int, day: int)

#=============================================================================
# SAVE/LOAD SYSTEM
#=============================================================================

# Server-side save events
## Request to save the game. Server only processes this.
signal server_save_requested(is_autosave: bool)
## Emitted when save process begins. Server only.
signal server_save_started()
## Emitted when save completes successfully. Server only.
signal server_save_completed(save_path: String)
## Emitted when save fails. Server only.
signal server_save_failed(reason: String)
## Emitted to gather data from all systems. Server only.
signal server_gather_save_data(save_game_object: Resource)

# Server-side load events
## Request to load a save. Server only.
signal server_load_requested(use_autosave: bool)
## Emitted when load process begins. Server only.
signal server_load_started()
## Emitted when load completes. Server only.
signal server_load_completed()
## Emitted when load fails. Server only.
signal server_load_failed(reason: String)
## Emitted to restore all systems from save data. Server only.
signal server_restore_from_save(save_game_object: Resource)

#=============================================================================
# PLAYER ACTIONS & INTERACTIONS
#=============================================================================

## Client requests an action on a tile. Sent to server.
signal server_player_action_requested(tile_coords: Vector2i, player_id: int, action_type: String)
## Server broadcasts action result to clients.
signal server_action_completed(action_type: String, player_id: int, tile_coords: Vector2i)
## Server notifies client of action failure.
signal server_action_failed(player_id: int, action_type: String, reason: String)

## Client requests item pickup. Sent to server.
signal server_item_pickup_requested(item_path: String, player_id: int)
## Server requests validation of pickup distance.
signal server_validate_pickup_distance_requested(context: Dictionary)
## Server confirms pickup is valid.
signal server_pickup_validated(context: Dictionary)
## Server rejects pickup.
signal server_pickup_validation_failed(context: Dictionary, reason: String)

## Server processes adding item to player.
signal server_item_add_to_player_requested(player_id: int, item_path: String, quantity: int, context: Dictionary)
## Server confirms item was added.
signal server_item_add_to_player_completed(player_id: int, item_path: String, added_quantity: int, remaining_quantity: int, context: Dictionary)
## Server reports item add failure.
signal server_item_add_to_player_failed(player_id: int, item_path: String, reason: String, context: Dictionary)

#=============================================================================
# TILE & FARM STATE SYSTEM
#=============================================================================

## Request to change tile state. Server only.
signal server_state_change_requested(tile_coords: Vector2i, change_type: String, params: Dictionary)
## Tile state has changed. Server broadcasts this.
signal server_farm_tile_state_changed(tile_coords: Vector2i, old_state: Dictionary, new_state: Dictionary)
## Request to sync farm state to specific player. Server only.
signal server_sync_farm_state_to_player_requested(peer_id: int)

## Request tile state query. Server only.
signal server_tile_state_query_requested(request_id: String, tile_coords: Vector2i, requester: Object)
## Response to tile query. Server only.
signal server_tile_state_query_responded(request_id: String, tile_state: Dictionary)
## Tile query failed. Server only.
signal server_tile_state_query_failed(request_id: String, reason: String)

## Crop was harvested. Server only.
signal server_crop_harvested(player_id: int, crop_data: Resource, was_regrown: bool)
## Crop visuals need updating. Broadcast to clients.
signal server_crop_visuals_changed(tile_coords: Vector2i, crop_data: Resource, growth_stage: int)

## Water system
signal server_water_tiles_should_register(water_tilemap_layer: TileMapLayer)
signal server_water_consume_requested(player_id: int, slot_index: int, amount: int, context: Dictionary)
signal server_water_consume_completed(player_id: int, slot_index: int, amount_consumed: int)
signal server_water_consume_failed(player_id: int, reason: String)

#=============================================================================
# INVENTORY SYSTEM
#=============================================================================

# Server-side inventory events
signal server_player_inventory_should_initialize(peer_id: int)
signal server_player_inventory_should_sync(peer_id: int)
signal server_inventory_transaction_requested(transaction: Dictionary)
signal server_inventory_transaction_completed(transaction: Dictionary)
signal server_inventory_transaction_failed(transaction: Dictionary, reason: String)
signal server_player_inventory_state_changed(player_id: int, state: Dictionary)

# Client-side inventory events
signal client_inventory_updated()
signal client_inventory_opened()
signal client_inventory_closed()
signal client_active_hotbar_slot_changed(slot_index: int)
signal client_inventory_changed()
# Item consumption
signal server_item_consumed(player_id: int, item_id: String, item_data: Resource)
signal server_player_health_change_requested(player_id: int, amount: float, change_type: String, source: String)
signal server_player_energy_change_requested(player_id: int, amount: float, change_type: String, source: String)

#=============================================================================
# CRAFTING SYSTEM
#=============================================================================

signal server_item_crafted(player_id: int, item_id: StringName, quantity: int)
signal server_crafting_failed(player_id: int, recipe_id: StringName, reason: String)

#=============================================================================
# COMBAT SYSTEM
#=============================================================================

signal server_enemy_defeated(player_id: int, enemy_data: Resource)
signal server_player_damaged(player_id: int, damage: int, source: String)
signal server_player_died(player_id: int, death_reason: String)

#=============================================================================
# NPC SYSTEM
#=============================================================================

signal server_npc_gifted(player_id: int, npc_id: StringName, item_id: StringName)
signal server_dialogue_started(player_id: int, dialogue_id: StringName)
signal client_dialogue_started(dialogue_data: Resource)
signal client_dialogue_ended()

#=============================================================================
# QUEST SYSTEM
#=============================================================================

signal server_quest_progress_updated(player_id: int, quest_id: StringName, objective_index: int, progress: int)
signal server_quest_completed(player_id: int, quest_id: StringName)
signal server_community_quest_progress(quest_id: StringName, player_id: int, contribution_data: Dictionary)
signal server_community_quest_completed(quest_id: StringName)

signal client_quest_log_updated()

#=============================================================================
# WORLD & ITEMS
#=============================================================================

signal server_spawn_dropped_item_requested(item_id: String, quantity: int, position: Vector2)
signal server_world_node_registered(world_node: Node2D)

#=============================================================================
# MULTIPLAYER & NETWORKING
#=============================================================================

# Connection events
signal connection_succeeded()
signal connection_failed(reason: String)
signal server_disconnected()
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)

# Player management
signal server_player_joined(peer_id: int, player_data: Dictionary)
signal server_player_left(peer_id: int)
signal server_player_spawn_requested(peer_id: int, spawn_position: Vector2)
signal server_player_spawned(peer_id: int, player_node: Node2D)
signal server_player_despawned(peer_id: int)

# Room assignment (barracks)
signal server_player_assigned_room(player_id: int, room_id: int)

#=============================================================================
# SKILL SYSTEM
#=============================================================================

signal server_player_action_completed(player_id: int, skill_type: StringName, xp_value: int)
signal server_player_leveled_up(player_id: int, skill_type: StringName, new_level: int)

signal client_player_data_updated(player_data: Dictionary)

#=============================================================================
# FESTIVAL SYSTEM
#=============================================================================

signal server_festival_state_changed(festival_id: StringName, new_state: int)
signal server_global_discovery_unlocked(discovery_id: StringName, player_id: int)

#=============================================================================
# TRUST SYSTEM
#=============================================================================

signal server_cooperative_action_completed(player1_id: int, player2_id: int, action_type: StringName)
signal server_trust_level_increased(player1_id: int, player2_id: int, new_level: int)

#=============================================================================
# ERROR HANDLING
#=============================================================================

signal server_error_occurred(system: String, error: String, error_code: int)
signal client_error_occurred(error: String)

#=============================================================================
# DEBUG HELPERS
#=============================================================================

func _ready() -> void:
	if debug_mode:
		_connect_debug_listeners()
	
	print("[EventBus] Initialized with %d signals defined" % _count_signals())

func _connect_debug_listeners() -> void:
	# Connect all signals to debug logger
	for sig in get_signal_list():
		var signal_name = sig["name"]
		if signal_name in quiet_events and not verbose_mode:
			continue
			
		if sig["args"].size() == 0:
			get(signal_name).connect(_log_signal.bind(signal_name))
		else:
			get(signal_name).connect(_log_signal_with_args.bind(signal_name))

func _log_signal(signal_name: String) -> void:
	if signal_name in critical_events or debug_mode:
		print("[EVENTBUS] Signal emitted: %s" % signal_name)

func _log_signal_with_args(signal_name: String, args) -> void:
	if signal_name in critical_events or debug_mode:
		print("[EVENTBUS] Signal emitted: %s" % signal_name)
		if verbose_mode:
			print("  Args: %s" % str(args))

func _count_signals() -> int:
	var count = 0
	for sig in get_signal_list():
		if sig["name"] != "tree_exiting" and sig["name"] != "tree_exited":
			count += 1
	return count

## Helper to check if we're on server or client
func is_server() -> bool:
	return multiplayer.is_server()

## Helper to emit server signals only on server
func emit_server_signal(signal_name: String, args: Array = []) -> void:
	if not is_server():
		push_warning("Attempted to emit server signal '%s' on client" % signal_name)
		return
	
	if has_signal(signal_name):
		get(signal_name).emit(args)
	else:
		push_error("Signal '%s' does not exist" % signal_name)

## Helper to emit client signals only on clients  
func emit_client_signal(signal_name: String, args: Array = []) -> void:
	if is_server() and multiplayer.get_unique_id() != 1:
		push_warning("Attempted to emit client signal '%s' on dedicated server" % signal_name)
		return
		
	if has_signal(signal_name):
		get(signal_name).emit(args)
	else:
		push_error("Signal '%s' does not exist" % signal_name)
