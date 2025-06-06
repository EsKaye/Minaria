extends Node

# Save file paths
const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".save"
const SAVE_SLOTS = 3

# Save data structure
var save_data: Dictionary = {
	"player": {
		"name": "",
		"class": "",
		"level": 1,
		"experience": 0,
		"appearance": {},
		"stats": {},
		"inventory": [],
		"equipment": {},
		"position": Vector2.ZERO,
		"health": 100,
		"mana": 100
	},
	"world": {
		"quests": [],
		"discovered_locations": [],
		"completed_events": [],
		"game_time": 0
	},
	"settings": {
		"graphics": {},
		"audio": {},
		"controls": {}
	},
	"metadata": {
		"version": "0.1.0",
		"save_date": "",
		"play_time": 0
	}
}

# Signals
signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_failed(slot: int, error: String)
signal load_failed(slot: int, error: String)

func _ready():
	# Create save directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)

func save_game(slot: int) -> void:
	"""
	Save the current game state to a slot
	"""
	if slot < 0 or slot >= SAVE_SLOTS:
		emit_signal("save_failed", slot, "Invalid save slot")
		return
	
	# Update save data
	_update_save_data()
	
	# Add metadata
	save_data["metadata"]["save_date"] = Time.get_datetime_string_from_system()
	
	# Create save file
	var save_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	
	if save_file == null:
		emit_signal("save_failed", slot, "Failed to create save file")
		return
	
	# Save data as JSON
	save_file.store_string(JSON.stringify(save_data))
	save_file.close()
	
	emit_signal("save_completed", slot)

func load_game(slot: int) -> void:
	"""
	Load a game state from a slot
	"""
	if slot < 0 or slot >= SAVE_SLOTS:
		emit_signal("load_failed", slot, "Invalid save slot")
		return
	
	var save_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
	
	if not FileAccess.file_exists(save_path):
		emit_signal("load_failed", slot, "Save file does not exist")
		return
	
	# Read save file
	var save_file = FileAccess.open(save_path, FileAccess.READ)
	
	if save_file == null:
		emit_signal("load_failed", slot, "Failed to open save file")
		return
	
	# Parse JSON data
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		emit_signal("load_failed", slot, "Failed to parse save data")
		return
	
	save_data = json.get_data()
	
	# Apply loaded data
	_apply_save_data()
	
	emit_signal("load_completed", slot)

func delete_save(slot: int) -> void:
	"""
	Delete a save file from a slot
	"""
	if slot < 0 or slot >= SAVE_SLOTS:
		return
	
	var save_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
	
	if FileAccess.file_exists(save_path):
		var dir = DirAccess.open(SAVE_DIR)
		dir.remove(save_path)

func get_save_info(slot: int) -> Dictionary:
	"""
	Get information about a save file
	"""
	if slot < 0 or slot >= SAVE_SLOTS:
		return {}
	
	var save_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
	
	if not FileAccess.file_exists(save_path):
		return {}
	
	var save_file = FileAccess.open(save_path, FileAccess.READ)
	
	if save_file == null:
		return {}
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		return {}
	
	var data = json.get_data()
	
	return {
		"player_name": data["player"]["name"],
		"player_class": data["player"]["class"],
		"player_level": data["player"]["level"],
		"save_date": data["metadata"]["save_date"],
		"play_time": data["metadata"]["play_time"]
	}

func _update_save_data() -> void:
	"""
	Update save data with current game state
	"""
	# TODO: Implement data collection from game state
	# This will be implemented when we have the game state management system
	pass

func _apply_save_data() -> void:
	"""
	Apply loaded save data to game state
	"""
	# TODO: Implement data application to game state
	# This will be implemented when we have the game state management system
	pass

func get_save_slots() -> Array:
	"""
	Get information about all save slots
	"""
	var slots = []
	
	for i in range(SAVE_SLOTS):
		slots.append(get_save_info(i))
	
	return slots 