# core/singletons/SaveManager.gd
extends Node

const DEFAULT_SAVE_DIR = "user://saves/"
const SAVE_FILE = "farm_save.tres"
const BACKUP_FILE = "farm_save.backup.tres"
const AUTOSAVE_FILE = "farm_autosave.tres"
const SAVE_VERSION = 1
const MAX_BACKUPS = 3
const AUTOSAVE_INTERVAL = 300.0  # 5 minutes

# Make this a variable so tests can override it
var save_directory: String = DEFAULT_SAVE_DIR
var current_save: SaveData = null
var is_saving: bool = false
var is_loading: bool = false
var autosave_timer: Timer = null
var autosave_enabled: bool = true

# For testing - allows overriding multiplayer checks
var _test_mode: bool = false
var _test_is_server: bool = true
var _test_is_multiplayer: bool = false
var _initialized: bool = false

func _ready():
	if not _initialized:
		_ensure_save_directory()
		_setup_autosave_timer()
		
		# Only connect signals if EventBus exists (might not in tests)
		if EventBus:
			if not EventBus.server_save_requested.is_connected(_on_save_requested):
				EventBus.server_save_requested.connect(_on_save_requested)
			if not EventBus.server_load_requested.is_connected(_on_load_requested):
				EventBus.server_load_requested.connect(_on_load_requested)
			if not EventBus.server_day_ended.is_connected(_on_day_ended):
				EventBus.server_day_ended.connect(_on_day_ended)
		
		_initialized = true
		print("[SaveManager] Initialized with save directory: %s" % save_directory)

func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if not dir:
		push_error("[SaveManager] Failed to access user directory")
		return
	
	# Extract just the folder name from the path
	var folder_name = save_directory.replace("user://", "").trim_suffix("/")
	
	if not dir.dir_exists(folder_name):
		var error = dir.make_dir(folder_name)
		if error != OK:
			push_error("[SaveManager] Failed to create saves directory: %s" % error)
		else:
			print("[SaveManager] Created saves directory: %s" % folder_name)

# Helper function to check if we're the server
func _is_server() -> bool:
	if _test_mode:
		return _test_is_server
	
	# Check if multiplayer exists and we're the server
	if multiplayer == null:
		# If no multiplayer, assume we're in single player mode (server)
		return true
	
	return multiplayer.is_server()

# NEW: Check if we're in multiplayer mode
func _is_multiplayer() -> bool:
	if _test_mode:
		return _test_is_multiplayer
	
	# No multiplayer object = single player
	if multiplayer == null:
		return false
	
	# Check if we have other players connected
	if NetworkManager and NetworkManager.players.size() > 1:
		return true
	
	# Also check if we're connected to a server (as client)
	return multiplayer.has_multiplayer_peer() and not multiplayer.is_server()

func _setup_autosave_timer() -> void:
	if autosave_timer:
		return  # Already setup
		
	autosave_timer = Timer.new()
	autosave_timer.wait_time = AUTOSAVE_INTERVAL
	autosave_timer.timeout.connect(_on_autosave_timer_timeout)
	add_child(autosave_timer)
	
	if autosave_enabled:
		autosave_timer.start()

func save_game(is_autosave: bool = false) -> Result:
	if is_saving:
		return Result.err("Save already in progress", Result.ErrorCode.INVALID_STATE)
	
	if is_loading:
		return Result.err("Cannot save while loading", Result.ErrorCode.INVALID_STATE)
	
	if not _is_server():
		return Result.err("Only host can save", Result.ErrorCode.PERMISSION_DENIED)
	
	is_saving = true
	
	# Only emit if EventBus exists
	if EventBus:
		EventBus.server_save_started.emit()
	
	# Create backup of existing save first (only in single-player)
	if not is_autosave and has_save_file() and not _is_multiplayer():
		_create_backup()
	
	# Use the existing SaveData Resource!
	var save_data = SaveData.new()
	
	# Initialize world_state if it's somehow null
	if not save_data.world_state:
		save_data.world_state = {}
	
	# Add metadata to world_state
	save_data.world_state["save_version"] = SAVE_VERSION
	save_data.world_state["timestamp"] = Time.get_datetime_string_from_system()
	save_data.world_state["play_time"] = Time.get_ticks_msec() / 1000.0  # Total seconds played
	save_data.world_state["is_autosave"] = is_autosave
	save_data.world_state["is_multiplayer_save"] = _is_multiplayer()
	
	# Let systems populate it
	if EventBus:
		EventBus.server_gather_save_data.emit(save_data)
	
	# Validate save data before writing
	var validation_result = _validate_save_data(save_data)
	if validation_result.is_err():
		is_saving = false
		if EventBus:
			EventBus.server_save_failed.emit(validation_result.get_error())
		return validation_result
	
	# Save as Resource
	var save_path = save_directory + (AUTOSAVE_FILE if is_autosave else SAVE_FILE)
	
	# For testing, we'll use a simple dictionary save instead of ResourceSaver
	if _test_mode:
		# Mock save for tests
		current_save = save_data
		is_saving = false
		if EventBus:
			EventBus.server_save_completed.emit(save_path)
		print("[SaveManager] Game saved to: %s (test mode)" % save_path)
		return Result.ok(save_path)
	
	var error = ResourceSaver.save(save_data, save_path)
	
	if error == OK:
		current_save = save_data
		is_saving = false
		if EventBus:
			EventBus.server_save_completed.emit(save_path)
		print("[SaveManager] Game saved to: %s" % save_path)
		return Result.ok(save_path)
	else:
		is_saving = false
		var error_msg = "Failed to save resource: %s" % error_string(error)
		if EventBus:
			EventBus.server_save_failed.emit(error_msg)
		return Result.err(error_msg, Result.ErrorCode.IO_ERROR)

func load_game(use_autosave: bool = false) -> Result:
	if is_loading:
		return Result.err("Load already in progress", Result.ErrorCode.INVALID_STATE)
		
	if is_saving:
		return Result.err("Cannot load while saving", Result.ErrorCode.INVALID_STATE)
	
	if not _is_server():
		return Result.err("Only host can load", Result.ErrorCode.PERMISSION_DENIED)
	
	# NEW: Prevent loading in multiplayer
	if _is_multiplayer():
		return Result.err("Cannot load saved games in multiplayer mode", Result.ErrorCode.INVALID_STATE)
	
	is_loading = true
	if EventBus:
		EventBus.server_load_started.emit()
	
	var save_path = save_directory + (AUTOSAVE_FILE if use_autosave else SAVE_FILE)
	
	# In test mode, check if we have a mock save
	if _test_mode:
		if not current_save:
			is_loading = false
			if EventBus:
				EventBus.server_load_failed.emit("File not found")
			return Result.err("Save file not found: %s" % save_path, Result.ErrorCode.NOT_FOUND)
		else:
			# Mock successful load
			is_loading = false
			if EventBus:
				EventBus.server_restore_from_save.emit(current_save)
				EventBus.server_load_completed.emit()
			return Result.ok(current_save)
	
	if not ResourceLoader.exists(save_path):
		is_loading = false
		if EventBus:
			EventBus.server_load_failed.emit("File not found")
		return Result.err("Save file not found: %s" % save_path, Result.ErrorCode.NOT_FOUND)
	
	var save_data = ResourceLoader.load(save_path) as SaveData
	if not save_data:
		is_loading = false
		if EventBus:
			EventBus.server_load_failed.emit("Invalid save file")
		return Result.err("Failed to load save", Result.ErrorCode.DATA_LOSS)
	
	# Validate loaded data
	var validation_result = _validate_save_data(save_data)
	if validation_result.is_err():
		is_loading = false
		if EventBus:
			EventBus.server_load_failed.emit(validation_result.get_error())
		return validation_result
	
	# Check save version compatibility
	var save_version = save_data.world_state.get("save_version", 0)
	if save_version > SAVE_VERSION:
		is_loading = false
		var error_msg = "Save file is from a newer version (%d > %d)" % [save_version, SAVE_VERSION]
		if EventBus:
			EventBus.server_load_failed.emit(error_msg)
		return Result.err(error_msg, Result.ErrorCode.INVALID_INPUT)
	
	# NEW: Warn if loading a multiplayer save in single-player
	if save_data.world_state.get("is_multiplayer_save", false):
		push_warning("[SaveManager] Loading a multiplayer save in single-player mode")
	
	current_save = save_data
	
	# Distribute to systems
	if EventBus:
		EventBus.server_restore_from_save.emit(save_data)
		EventBus.server_load_completed.emit()
	
	is_loading = false
	print("[SaveManager] Game loaded from: %s" % save_path)
	
	return Result.ok(save_data)

func quick_save() -> Result:
	# NEW: Disabled in multiplayer
	if _is_multiplayer():
		return Result.err("Quick save not available in multiplayer", Result.ErrorCode.INVALID_STATE)
	
	return save_game(false)

func quick_load() -> Result:
	# NEW: Disabled in multiplayer
	if _is_multiplayer():
		return Result.err("Quick load not available in multiplayer", Result.ErrorCode.INVALID_STATE)
	
	return load_game(false)

func _create_backup() -> void:
	var main_save_path = save_directory + SAVE_FILE
	
	if not ResourceLoader.exists(main_save_path):
		return  # No save to backup
	
	# Rotate existing backups
	for i in range(MAX_BACKUPS - 1, 0, -1):
		var old_backup = save_directory + "backup_%d.tres" % (i - 1)
		var new_backup = save_directory + "backup_%d.tres" % i
		
		if ResourceLoader.exists(old_backup):
			var dir = DirAccess.open(save_directory)
			if dir:
				dir.rename(old_backup.replace(save_directory, ""), new_backup.replace(save_directory, ""))
	
	# Copy current save to backup_0
	var dir = DirAccess.open(save_directory)
	if dir:
		var err = dir.copy(SAVE_FILE, "backup_0.tres")
		if err != OK:
			push_warning("[SaveManager] Failed to create backup: %s" % error_string(err))
		else:
			print("[SaveManager] Created backup")

func _validate_save_data(save_data: SaveData) -> Result:
	if not save_data:
		return Result.err("Save data is null", Result.ErrorCode.INVALID_INPUT)
	
	# SaveData should always have world_state initialized
	if not save_data.world_state:
		save_data.world_state = {}
	
	# Check if world state has any data
	if save_data.world_state.is_empty():
		return Result.err("World state is empty", Result.ErrorCode.INVALID_INPUT)
	
	# Add more validation as needed
	# - Check player data integrity
	# - Verify farm tile data
	# - Validate inventory items exist in database
	
	return Result.ok(null)

func get_save_files() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	var dir = DirAccess.open(save_directory)
	
	if not dir:
		push_error("[SaveManager] Cannot access save directory")
		return saves
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var full_path = save_directory + file_name
			var file_info = {
				"name": file_name,
				"path": full_path,
				"modified_time": dir.get_modified_time(full_path),
				"is_autosave": file_name == AUTOSAVE_FILE,
				"is_backup": file_name.begins_with("backup_")
			}
			saves.append(file_info)
		file_name = dir.get_next()
	
	# Sort by modified time, newest first
	saves.sort_custom(func(a, b): return a.modified_time > b.modified_time)
	
	return saves

func delete_save(file_name: String) -> Result:
	if file_name == SAVE_FILE and current_save != null:
		return Result.err("Cannot delete active save", Result.ErrorCode.INVALID_STATE)
	
	var dir = DirAccess.open(save_directory)
	if not dir:
		return Result.err("Cannot access save directory", Result.ErrorCode.IO_ERROR)
	
	var error = dir.remove(file_name)
	if error != OK:
		return Result.err("Failed to delete save: %s" % error_string(error), Result.ErrorCode.IO_ERROR)
	
	print("[SaveManager] Deleted save: %s" % file_name)
	return Result.ok(null)

func has_save_file() -> bool:
	if _test_mode and current_save:
		return true
	return ResourceLoader.exists(save_directory + SAVE_FILE)

func has_autosave() -> bool:
	if _test_mode and current_save and current_save.world_state.get("is_autosave", false):
		return true
	return ResourceLoader.exists(save_directory + AUTOSAVE_FILE)

func set_autosave_enabled(enabled: bool) -> void:
	autosave_enabled = enabled
	
	if autosave_timer:
		if enabled:
			autosave_timer.start()
		else:
			autosave_timer.stop()

func set_autosave_interval(minutes: float) -> void:
	var seconds = minutes * 60.0
	if autosave_timer:
		autosave_timer.wait_time = seconds
		if autosave_timer.is_stopped() and autosave_enabled:
			autosave_timer.start()

# Signal handlers
func _on_save_requested(is_autosave: bool) -> void:
	save_game(is_autosave)

func _on_load_requested(use_autosave: bool) -> void:
	load_game(use_autosave)

func _on_day_ended() -> void:
	# Auto-save at end of day if enabled
	if autosave_enabled and _is_server():
		print("[SaveManager] Day ended, performing autosave...")
		save_game(true)

func _on_autosave_timer_timeout() -> void:
	if autosave_enabled and _is_server():
		print("[SaveManager] Autosave timer triggered")
		save_game(true)

# Debug helpers
func get_save_info() -> Dictionary:
	if not current_save:
		return {}
	
	return {
		"version": current_save.world_state.get("save_version", 0),
		"timestamp": current_save.world_state.get("timestamp", "Unknown"),
		"play_time": current_save.world_state.get("play_time", 0),
		"player_count": current_save.players.size(),
		"farm_tiles": current_save.farm_grids.size(),
		"objects": current_save.placed_objects.size(),
		"is_multiplayer_save": current_save.world_state.get("is_multiplayer_save", false)
	}

func _exit_tree() -> void:
	# Cleanup
	if autosave_timer:
		autosave_timer.queue_free()
