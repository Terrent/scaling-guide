# core/singletons/SaveManager.gd - Using existing SaveData
extends Node

const SAVE_DIR = "user://saves/"
const SAVE_FILE = "farm_save.tres"  # .tres for Resources!
const BACKUP_FILE = "farm_save.backup.tres"
const AUTOSAVE_FILE = "farm_autosave.tres"
const SAVE_VERSION = 1

var current_save: SaveData = null
var is_saving: bool = false

func _ready():
	_ensure_save_directory()
	
	EventBus.server_save_requested.connect(_on_save_requested)
	EventBus.server_load_requested.connect(_on_load_requested)
	
	print("[SaveManager] Initialized")

func save_game(is_autosave: bool = false) -> Result:
	if is_saving:
		return Result.err("Save already in progress", Result.ErrorCode.INVALID_STATE)
	
	if not multiplayer.is_server():
		return Result.err("Only host can save", Result.ErrorCode.PERMISSION_DENIED)
	
	is_saving = true
	EventBus.server_save_started.emit()
	
	# Use the existing SaveData Resource!
	var save_data = SaveData.new()
	
	# Add metadata to world_state
	save_data.world_state["save_version"] = SAVE_VERSION
	save_data.world_state["timestamp"] = Time.get_datetime_string_from_system()
	
	# Let systems populate it
	EventBus.server_gather_save_data.emit(save_data)
	
	# Save as Resource
	var save_path = SAVE_DIR + (AUTOSAVE_FILE if is_autosave else SAVE_FILE)
	var error = ResourceSaver.save(save_data, save_path)
	
	if error == OK:
		current_save = save_data
		is_saving = false
		EventBus.server_save_completed.emit(save_path)
		return Result.ok(save_path)
	else:
		is_saving = false
		EventBus.server_save_failed.emit("Failed to save resource")
		return Result.err("Failed to save", Result.ErrorCode.IO_ERROR)

func load_game(use_autosave: bool = false) -> Result:
	if not multiplayer.is_server():
		return Result.err("Only host can load", Result.ErrorCode.PERMISSION_DENIED)
	
	EventBus.server_load_started.emit()
	
	var save_path = SAVE_DIR + (AUTOSAVE_FILE if use_autosave else SAVE_FILE)
	
	if not ResourceLoader.exists(save_path):
		EventBus.server_load_failed.emit("File not found")
		return Result.err("Save file not found", Result.ErrorCode.NOT_FOUND)
	
	var save_data = ResourceLoader.load(save_path) as SaveData
	if not save_data:
		EventBus.server_load_failed.emit("Invalid save file")
		return Result.err("Failed to load save", Result.ErrorCode.DATA_LOSS)
	
	current_save = save_data
	
	# Distribute to systems
	EventBus.server_restore_from_save.emit(save_data)
	EventBus.server_load_completed.emit()
	
	return Result.ok(save_data)
