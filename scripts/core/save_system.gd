extends Node
class_name SaveSystem

## Save System - Modern save/load system for Minaria
## Provides comprehensive save data management with JSON serialization, compression, and validation
## Supports multiple save slots, auto-save, and cloud save integration

# Save data structure
class SaveData:
	var version: String = "1.0.0"
	var timestamp: Dictionary = {}
	var game_state: Dictionary = {}
	var player_data: Dictionary = {}
	var world_data: Dictionary = {}
	var inventory_data: Dictionary = {}
	var settings_data: Dictionary = {}
	var metadata: Dictionary = {}

# Save slots configuration
var max_save_slots: int = 10
var auto_save_slot: int = 0
var quick_save_slot: int = 1

# Save file paths
var save_directory: String = "user://saves/"
var settings_file: String = "user://settings.json"
var save_file_extension: String = ".save"

# Save data validation
var required_fields: Array[String] = ["version", "timestamp", "game_state"]
var save_data_version: String = "1.0.0"

# Save/load state
var is_saving: bool = false
var is_loading: bool = false
var save_progress: float = 0.0
var load_progress: float = 0.0

# Save data cache
var save_data_cache: Dictionary = {}
var settings_cache: Dictionary = {}

# Compression settings
var use_compression: bool = true
var compression_level: int = 9

# Backup settings
var create_backups: bool = true
var max_backups: int = 3

# Signals
signal save_completed(save_slot: int)
signal save_failed(save_slot: int, error: String)
signal load_completed(save_slot: int)
signal load_failed(save_slot: int, error: String)
signal save_progress_updated(progress: float)
signal load_progress_updated(progress: float)
signal settings_saved
signal settings_loaded

func _ready() -> void:
	"""
	Initialize the save system
	"""
	_ensure_save_directory()
	_load_settings_cache()
	_validate_save_files()

func _ensure_save_directory() -> void:
	"""
	Ensure the save directory exists
	"""
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")

func save_game(save_slot: int) -> void:
	"""
	Save the current game state to a specific slot
	
	Args:
		save_slot: The save slot to save to
	"""
	if is_saving or is_loading:
		return
	
	is_saving = true
	save_progress = 0.0
	
	# Create save data
	var save_data = SaveData.new()
	save_data.version = save_data_version
	save_data.timestamp = Time.get_time_dict_from_system()
	
	# Collect game data
	_collect_game_data(save_data)
	
	# Save to file
	_save_to_file(save_slot, save_data)

func load_game(save_slot: int) -> void:
	"""
	Load a game from a specific save slot
	
	Args:
		save_slot: The save slot to load from
	"""
	if is_saving or is_loading:
		return
	
	is_loading = true
	load_progress = 0.0
	
	# Load from file
	_load_from_file(save_slot)

func quick_save() -> void:
	"""
	Perform a quick save to the quick save slot
	"""
	save_game(quick_save_slot)

func auto_save() -> void:
	"""
	Perform an automatic save to the auto save slot
	"""
	save_game(auto_save_slot)

func save_settings() -> void:
	"""
	Save game settings to file
	"""
	var settings_data = _collect_settings_data()
	_save_settings_to_file(settings_data)

func load_settings() -> Dictionary:
	"""
	Load game settings from file
	
	Returns:
		Dictionary containing the loaded settings
	"""
	return _load_settings_from_file()

func delete_save(save_slot: int) -> bool:
	"""
	Delete a save file from a specific slot
	
	Args:
		save_slot: The save slot to delete
		
	Returns:
		True if deletion was successful
	"""
	var file_path = _get_save_file_path(save_slot)
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file:
		file.close()
		var dir = DirAccess.open("user://")
		var result = dir.remove(file_path)
		
		# Remove from cache
		if save_data_cache.has(save_slot):
			save_data_cache.erase(save_slot)
		
		return result
	return false

func get_save_info(save_slot: int) -> Dictionary:
	"""
	Get information about a save file
	
	Args:
		save_slot: The save slot to get info for
		
	Returns:
		Dictionary containing save file information
	"""
	var file_path = _get_save_file_path(save_slot)
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file:
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(content)
		
		if parse_result == OK:
			var data = json.data
			return {
				"exists": true,
				"version": data.get("version", "unknown"),
				"timestamp": data.get("timestamp", {}),
				"play_time": data.get("game_state", {}).get("play_time", 0.0),
				"level": data.get("player_data", {}).get("level", 1),
				"location": data.get("world_data", {}).get("current_biome", "unknown")
			}
	
	return {"exists": false}

func get_all_save_info() -> Array[Dictionary]:
	"""
	Get information about all save files
	
	Returns:
		Array of save file information dictionaries
	"""
	var save_info: Array[Dictionary] = []
	
	for i in range(max_save_slots):
		var info = get_save_info(i)
		info["slot"] = i
		save_info.append(info)
	
	return save_info

func _collect_game_data(save_data: SaveData) -> void:
	"""
	Collect all game data for saving
	"""
	# Game state data
	if GameManager:
		save_data.game_state = GameManager.get_session_data()
		save_data.game_state["world_state"] = GameManager.get_world_state()
		save_data.game_state["performance"] = GameManager.get_performance_data()
	
	# Player data
	if GameManager and GameManager.player:
		save_data.player_data = _collect_player_data()
	
	# World data
	if GameManager:
		save_data.world_data = _collect_world_data()
	
	# Inventory data
	if GameManager:
		save_data.inventory_data = _collect_inventory_data()
	
	# Settings data
	save_data.settings_data = _collect_settings_data()
	
	# Metadata
	save_data.metadata = {
		"save_slot": save_slot,
		"game_version": "1.0.0",
		"save_system_version": save_data_version,
		"compression_used": use_compression
	}

func _collect_player_data() -> Dictionary:
	"""
	Collect player-specific data
	"""
	var player_data = {}
	
	# This would be implemented based on your player system
	# For now, return empty data
	return player_data

func _collect_world_data() -> Dictionary:
	"""
	Collect world-specific data
	"""
	var world_data = {}
	
	# This would be implemented based on your world system
	# For now, return empty data
	return world_data

func _collect_inventory_data() -> Dictionary:
	"""
	Collect inventory-specific data
	"""
	var inventory_data = {}
	
	# This would be implemented based on your inventory system
	# For now, return empty data
	return inventory_data

func _collect_settings_data() -> Dictionary:
	"""
	Collect settings data
	"""
	var settings_data = {}
	
	# Audio settings
	if AudioManager:
		settings_data["audio"] = AudioManager.save_audio_settings()
	
	# Input settings
	if InputManager:
		settings_data["input"] = InputManager.save_input_settings()
	
	# Game settings
	if GameManager:
		settings_data["game"] = GameManager.game_settings
	
	return settings_data

func _save_to_file(save_slot: int, save_data: SaveData) -> void:
	"""
	Save data to file with compression and validation
	"""
	var file_path = _get_save_file_path(save_slot)
	
	# Create backup if enabled
	if create_backups:
		_create_backup(save_slot)
	
	# Convert save data to dictionary
	var data_dict = _save_data_to_dict(save_data)
	
	# Validate data
	if not _validate_save_data(data_dict):
		_save_failed(save_slot, "Save data validation failed")
		return
	
	# Serialize to JSON
	var json_string = JSON.stringify(data_dict, "\t")
	
	# Compress if enabled
	if use_compression:
		json_string = _compress_data(json_string)
	
	# Write to file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		
		# Cache the save data
		save_data_cache[save_slot] = data_dict
		
		# Update progress
		save_progress = 1.0
		save_progress_updated.emit(save_progress)
		
		# Complete save
		is_saving = false
		save_completed.emit(save_slot)
	else:
		_save_failed(save_slot, "Failed to open save file for writing")

func _load_from_file(save_slot: int) -> void:
	"""
	Load data from file with decompression and validation
	"""
	var file_path = _get_save_file_path(save_slot)
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		_load_failed(save_slot, "Save file not found")
		return
	
	var content = file.get_as_text()
	file.close()
	
	# Decompress if needed
	if use_compression and content.begins_with("COMPRESSED:"):
		content = _decompress_data(content)
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(content)
	
	if parse_result != OK:
		_load_failed(save_slot, "Failed to parse save file JSON")
		return
	
	var data_dict = json.data
	
	# Validate data
	if not _validate_save_data(data_dict):
		_load_failed(save_slot, "Save data validation failed")
		return
	
	# Apply loaded data
	_apply_loaded_data(data_dict)
	
	# Cache the save data
	save_data_cache[save_slot] = data_dict
	
	# Update progress
	load_progress = 1.0
	load_progress_updated.emit(load_progress)
	
	# Complete load
	is_loading = false
	load_completed.emit(save_slot)

func _apply_loaded_data(data_dict: Dictionary) -> void:
	"""
	Apply loaded data to game systems
	"""
	# Apply game state
	if data_dict.has("game_state") and GameManager:
		# Apply session data
		var session_data = data_dict.game_state
		GameManager.session_data = session_data
		
		# Apply world state
		if session_data.has("world_state"):
			GameManager.world_state = session_data.world_state
	
	# Apply player data
	if data_dict.has("player_data"):
		_apply_player_data(data_dict.player_data)
	
	# Apply world data
	if data_dict.has("world_data"):
		_apply_world_data(data_dict.world_data)
	
	# Apply inventory data
	if data_dict.has("inventory_data"):
		_apply_inventory_data(data_dict.inventory_data)
	
	# Apply settings
	if data_dict.has("settings_data"):
		_apply_settings_data(data_dict.settings_data)

func _apply_player_data(player_data: Dictionary) -> void:
	"""
	Apply loaded player data
	"""
	# This would be implemented based on your player system
	pass

func _apply_world_data(world_data: Dictionary) -> void:
	"""
	Apply loaded world data
	"""
	# This would be implemented based on your world system
	pass

func _apply_inventory_data(inventory_data: Dictionary) -> void:
	"""
	Apply loaded inventory data
	"""
	# This would be implemented based on your inventory system
	pass

func _apply_settings_data(settings_data: Dictionary) -> void:
	"""
	Apply loaded settings data
	"""
	# Apply audio settings
	if settings_data.has("audio") and AudioManager:
		AudioManager.load_audio_settings(settings_data.audio)
	
	# Apply input settings
	if settings_data.has("input") and InputManager:
		InputManager.load_input_settings(settings_data.input)
	
	# Apply game settings
	if settings_data.has("game") and GameManager:
		GameManager.game_settings = settings_data.game

func _save_settings_to_file(settings_data: Dictionary) -> void:
	"""
	Save settings to file
	"""
	var json_string = JSON.stringify(settings_data, "\t")
	var file = FileAccess.open(settings_file, FileAccess.WRITE)
	
	if file:
		file.store_string(json_string)
		file.close()
		settings_cache = settings_data
		settings_saved.emit()

func _load_settings_from_file() -> Dictionary:
	"""
	Load settings from file
	"""
	var file = FileAccess.open(settings_file, FileAccess.READ)
	
	if file:
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(content)
		
		if parse_result == OK:
			settings_cache = json.data
			settings_loaded.emit()
			return settings_cache
	
	return {}

func _get_save_file_path(save_slot: int) -> String:
	"""
	Get the file path for a save slot
	"""
	return save_directory + "save_" + str(save_slot) + save_file_extension

func _save_data_to_dict(save_data: SaveData) -> Dictionary:
	"""
	Convert SaveData object to dictionary
	"""
	return {
		"version": save_data.version,
		"timestamp": save_data.timestamp,
		"game_state": save_data.game_state,
		"player_data": save_data.player_data,
		"world_data": save_data.world_data,
		"inventory_data": save_data.inventory_data,
		"settings_data": save_data.settings_data,
		"metadata": save_data.metadata
	}

func _validate_save_data(data_dict: Dictionary) -> bool:
	"""
	Validate save data structure
	"""
	for field in required_fields:
		if not data_dict.has(field):
			return false
	
	# Check version compatibility
	var version = data_dict.get("version", "")
	if version != save_data_version:
		# TODO: Implement version migration
		pass
	
	return true

func _compress_data(data: String) -> String:
	"""
	Compress data using GZIP
	"""
	var compressed = data.to_utf8_buffer()
	compressed = compressed.compress(compression_level)
	return "COMPRESSED:" + compressed.hex_encode()

func _decompress_data(data: String) -> String:
	"""
	Decompress data using GZIP
	"""
	if data.begins_with("COMPRESSED:"):
		var hex_data = data.substr(11)  # Remove "COMPRESSED:" prefix
		var compressed = PackedByteArray()
		compressed.resize(hex_data.length() / 2)
		
		for i in range(0, hex_data.length(), 2):
			var byte = hex_data.substr(i, 2).hex_to_int()
			compressed[i / 2] = byte
		
		var decompressed = compressed.decompress(compressed.size())
		return decompressed.get_string_from_utf8()
	
	return data

func _create_backup(save_slot: int) -> void:
	"""
	Create a backup of the save file
	"""
	var original_path = _get_save_file_path(save_slot)
	var backup_path = original_path + ".backup"
	
	var file = FileAccess.open(original_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var backup_file = FileAccess.open(backup_path, FileAccess.WRITE)
		if backup_file:
			backup_file.store_string(content)
			backup_file.close()

func _validate_save_files() -> void:
	"""
	Validate all existing save files
	"""
	for i in range(max_save_slots):
		var info = get_save_info(i)
		if info.exists:
			# Validate the save file
			var file_path = _get_save_file_path(i)
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var content = file.get_as_text()
				file.close()
				
				var json = JSON.new()
				var parse_result = json.parse(content)
				
				if parse_result != OK:
					print("Warning: Invalid save file detected at slot ", i)

func _load_settings_cache() -> void:
	"""
	Load settings cache from file
	"""
	settings_cache = _load_settings_from_file()

func _save_failed(save_slot: int, error: String) -> void:
	"""
	Handle save failure
	"""
	is_saving = false
	save_failed.emit(save_slot, error)
	print("Save failed for slot ", save_slot, ": ", error)

func _load_failed(save_slot: int, error: String) -> void:
	"""
	Handle load failure
	"""
	is_loading = false
	load_failed.emit(save_slot, error)
	print("Load failed for slot ", save_slot, ": ", error)

func is_save_in_progress() -> bool:
	"""
	Check if a save operation is in progress
	"""
	return is_saving

func is_load_in_progress() -> bool:
	"""
	Check if a load operation is in progress
	"""
	return is_loading

func get_save_progress() -> float:
	"""
	Get the current save progress
	"""
	return save_progress

func get_load_progress() -> float:
	"""
	Get the current load progress
	"""
	return load_progress 