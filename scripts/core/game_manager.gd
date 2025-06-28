extends Node
class_name GameManager

## Game Manager - Central game state and system coordinator for Minaria
## Manages game flow, state transitions, and system coordination
## Implements modern singleton pattern with comprehensive state management

# Game states
enum GameState {
	MAIN_MENU,
	LOADING,
	PLAYING,
	PAUSED,
	INVENTORY,
	CRAFTING,
	DIALOG,
	COMBAT,
	SAVING,
	LOADING_SAVE
}

# Current game state
var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.MAIN_MENU

# Game session data
var session_data: Dictionary = {
	"start_time": 0.0,
	"play_time": 0.0,
	"save_count": 0,
	"load_count": 0
}

# World state
var world_state: Dictionary = {
	"current_biome": "plains",
	"day_time": 0.0,
	"day_length": 600.0,  # 10 minutes per day
	"current_day": 1,
	"weather": "clear",
	"temperature": 20.0
}

# Game settings
var game_settings: Dictionary = {
	"difficulty": "normal",
	"auto_save": true,
	"auto_save_interval": 300.0,  # 5 minutes
	"show_tutorials": true,
	"language": "en"
}

# System references (will be set by autoload)
var input_manager: InputManager
var save_system: SaveSystem
var audio_manager: AudioManager
var notification_manager: NotificationManager

# Scene references
var current_scene: Node
var ui_manager: Node
var world_generator: Node
var player: Node

# Performance tracking
var frame_times: Array[float] = []
var max_frame_samples: int = 60
var average_fps: float = 60.0

# Debug and development
var debug_mode: bool = false
var show_fps: bool = false
var show_debug_info: bool = false

# Signals
signal game_state_changed(new_state: GameState, old_state: GameState)
signal game_started
signal game_paused(is_paused: bool)
signal game_saved(save_slot: int)
signal game_loaded(save_slot: int)
signal world_state_changed(property: String, value: Variant)
signal session_data_updated(property: String, value: Variant)
signal performance_updated(fps: float, frame_time: float)

func _ready() -> void:
	"""
	Initialize the game manager system
	"""
	# Set up autoload references
	input_manager = InputManager
	save_system = SaveSystem
	audio_manager = AudioManager
	notification_manager = NotificationManager
	
	# Initialize systems
	_initialize_systems()
	_connect_signals()
	_load_game_settings()
	
	# Start in main menu
	change_game_state(GameState.MAIN_MENU)

func _process(delta: float) -> void:
	"""
	Main game loop processing
	"""
	_update_performance_tracking(delta)
	_update_session_data(delta)
	
	match current_state:
		GameState.PLAYING:
			_update_gameplay(delta)
		GameState.LOADING:
			_update_loading(delta)
		GameState.SAVING:
			_update_saving(delta)

func _initialize_systems() -> void:
	"""
	Initialize all game systems
	"""
	# Load game settings
	_load_game_settings()
	
	# Initialize audio
	if audio_manager:
		audio_manager.load_audio_settings(game_settings.get("audio", {}))
	
	# Set up performance tracking
	frame_times.resize(max_frame_samples)
	frame_times.fill(0.0)

func _connect_signals() -> void:
	"""
	Connect signals from various systems
	"""
	# Input manager signals
	if input_manager:
		input_manager.input_action_triggered.connect(_on_input_action_triggered)
	
	# Save system signals
	if save_system:
		save_system.save_completed.connect(_on_save_completed)
		save_system.load_completed.connect(_on_load_completed)
	
	# Audio manager signals
	if audio_manager:
		audio_manager.music_changed.connect(_on_music_changed)
		audio_manager.volume_changed.connect(_on_volume_changed)

func change_game_state(new_state: GameState) -> void:
	"""
	Change the current game state with proper cleanup and initialization
	
	Args:
		new_state: The new game state to transition to
	"""
	if new_state == current_state:
		return
	
	previous_state = current_state
	current_state = new_state
	
	# Handle state transition
	_handle_state_transition(previous_state, new_state)
	
	# Emit signal
	game_state_changed.emit(new_state, previous_state)

func _handle_state_transition(old_state: GameState, new_state: GameState) -> void:
	"""
	Handle specific state transitions with proper cleanup and setup
	"""
	match old_state:
		GameState.PLAYING:
			_cleanup_playing_state()
		GameState.PAUSED:
			_cleanup_paused_state()
		GameState.INVENTORY:
			_cleanup_inventory_state()
		GameState.CRAFTING:
			_cleanup_crafting_state()
	
	match new_state:
		GameState.MAIN_MENU:
			_setup_main_menu_state()
		GameState.LOADING:
			_setup_loading_state()
		GameState.PLAYING:
			_setup_playing_state()
		GameState.PAUSED:
			_setup_paused_state()
		GameState.INVENTORY:
			_setup_inventory_state()
		GameState.CRAFTING:
			_setup_crafting_state()

func start_new_game() -> void:
	"""
	Start a new game session
	"""
	session_data.start_time = Time.get_time_dict_from_system()
	session_data.play_time = 0.0
	session_data.save_count = 0
	session_data.load_count = 0
	
	# Load main game scene
	change_game_state(GameState.LOADING)
	_load_game_scene()

func load_game(save_slot: int) -> void:
	"""
	Load a saved game
	
	Args:
		save_slot: The save slot to load from
	"""
	if save_system:
		change_game_state(GameState.LOADING_SAVE)
		save_system.load_game(save_slot)

func save_game(save_slot: int) -> void:
	"""
	Save the current game
	
	Args:
		save_slot: The save slot to save to
	"""
	if save_system:
		change_game_state(GameState.SAVING)
		save_system.save_game(save_slot)

func pause_game() -> void:
	"""
	Pause the current game
	"""
	if current_state == GameState.PLAYING:
		change_game_state(GameState.PAUSED)
		game_paused.emit(true)

func resume_game() -> void:
	"""
	Resume the current game
	"""
	if current_state == GameState.PAUSED:
		change_game_state(GameState.PLAYING)
		game_paused.emit(false)

func quit_game() -> void:
	"""
	Quit the game with proper cleanup
	"""
	_save_game_settings()
	get_tree().quit()

func _update_gameplay(delta: float) -> void:
	"""
	Update gameplay systems
	"""
	# Update world time
	world_state.day_time += delta
	if world_state.day_time >= world_state.day_length:
		world_state.day_time = 0.0
		world_state.current_day += 1
		world_state_changed.emit("current_day", world_state.current_day)
	
	# Update world state
	_update_world_state(delta)
	
	# Auto-save if enabled
	if game_settings.auto_save and session_data.play_time > 0:
		var time_since_last_save = session_data.play_time - (session_data.save_count * game_settings.auto_save_interval)
		if time_since_last_save >= game_settings.auto_save_interval:
			save_game(0)  # Auto-save to slot 0

func _update_world_state(delta: float) -> void:
	"""
	Update world state based on current conditions
	"""
	# Update weather (simplified)
	if randf() < 0.001:  # 0.1% chance per frame
		var weather_types = ["clear", "cloudy", "rainy", "stormy"]
		world_state.weather = weather_types[randi() % weather_types.size()]
		world_state_changed.emit("weather", world_state.weather)
	
	# Update temperature based on time of day
	var time_ratio = world_state.day_time / world_state.day_length
	var base_temp = 20.0
	var temp_variation = 10.0
	world_state.temperature = base_temp + sin(time_ratio * TAU) * temp_variation

func _update_performance_tracking(delta: float) -> void:
	"""
	Track performance metrics
	"""
	# Update frame times
	frame_times.push_back(delta)
	if frame_times.size() > max_frame_samples:
		frame_times.pop_front()
	
	# Calculate average FPS
	var total_time = 0.0
	for frame_time in frame_times:
		total_time += frame_time
	
	if total_time > 0:
		average_fps = 1.0 / (total_time / frame_times.size())
		performance_updated.emit(average_fps, delta)

func _update_session_data(delta: float) -> void:
	"""
	Update session tracking data
	"""
	if current_state == GameState.PLAYING:
		session_data.play_time += delta
		session_data_updated.emit("play_time", session_data.play_time)

func _load_game_scene() -> void:
	"""
	Load the main game scene
	"""
	var scene_path = "res://scenes/world/main.tscn"
	var scene = load(scene_path)
	if scene:
		current_scene = scene.instantiate()
		get_tree().current_scene.add_child(current_scene)
		change_game_state(GameState.PLAYING)
		game_started.emit()

func _setup_main_menu_state() -> void:
	"""
	Setup main menu state
	"""
	if audio_manager:
		audio_manager.play_music("main_menu", 2.0)

func _setup_loading_state() -> void:
	"""
	Setup loading state
	"""
	# Show loading screen
	pass

func _setup_playing_state() -> void:
	"""
	Setup playing state
	"""
	if audio_manager:
		audio_manager.play_music("gameplay", 1.0)
		audio_manager.play_ambient("forest_ambient", 3.0)

func _setup_paused_state() -> void:
	"""
	Setup paused state
	"""
	get_tree().paused = true

func _setup_inventory_state() -> void:
	"""
	Setup inventory state
	"""
	# Show inventory UI
	pass

func _setup_crafting_state() -> void:
	"""
	Setup crafting state
	"""
	# Show crafting UI
	pass

func _cleanup_playing_state() -> void:
	"""
	Cleanup playing state
	"""
	pass

func _cleanup_paused_state() -> void:
	"""
	Cleanup paused state
	"""
	get_tree().paused = false

func _cleanup_inventory_state() -> void:
	"""
	Cleanup inventory state
	"""
	# Hide inventory UI
	pass

func _cleanup_crafting_state() -> void:
	"""
	Cleanup crafting state
	"""
	# Hide crafting UI
	pass

func _update_loading(delta: float) -> void:
	"""
	Update loading state
	"""
	# Handle loading progress
	pass

func _update_saving(delta: float) -> void:
	"""
	Update saving state
	"""
	# Handle saving progress
	pass

func _on_input_action_triggered(action: String) -> void:
	"""
	Handle input actions from the input manager
	"""
	match action:
		"pause":
			if current_state == GameState.PLAYING:
				pause_game()
			elif current_state == GameState.PAUSED:
				resume_game()
		"inventory":
			if current_state == GameState.PLAYING:
				change_game_state(GameState.INVENTORY)
		"crafting":
			if current_state == GameState.PLAYING:
				change_game_state(GameState.CRAFTING)

func _on_save_completed(save_slot: int) -> void:
	"""
	Handle save completion
	"""
	session_data.save_count += 1
	change_game_state(GameState.PLAYING)
	game_saved.emit(save_slot)
	
	if notification_manager:
		notification_manager.show_notification("Game saved successfully!", 2.0)

func _on_load_completed(save_slot: int) -> void:
	"""
	Handle load completion
	"""
	session_data.load_count += 1
	change_game_state(GameState.PLAYING)
	game_loaded.emit(save_slot)
	
	if notification_manager:
		notification_manager.show_notification("Game loaded successfully!", 2.0)

func _on_music_changed(track_name: String) -> void:
	"""
	Handle music track changes
	"""
	# Update UI or handle music changes
	pass

func _on_volume_changed(bus: AudioManager.AudioBus, volume: float) -> void:
	"""
	Handle volume changes
	"""
	# Update settings
	match bus:
		AudioManager.AudioBus.MASTER:
			game_settings["master_volume"] = volume
		AudioManager.AudioBus.MUSIC:
			game_settings["music_volume"] = volume
		AudioManager.AudioBus.SFX:
			game_settings["sfx_volume"] = volume

func _load_game_settings() -> void:
	"""
	Load game settings from save file
	"""
	if save_system:
		var settings = save_system.load_settings()
		if settings:
			game_settings = settings

func _save_game_settings() -> void:
	"""
	Save game settings to file
	"""
	if save_system:
		save_system.save_settings(game_settings)

func get_game_state() -> GameState:
	"""
	Get the current game state
	"""
	return current_state

func is_game_paused() -> bool:
	"""
	Check if the game is currently paused
	"""
	return current_state == GameState.PAUSED

func get_world_state() -> Dictionary:
	"""
	Get the current world state
	"""
	return world_state.duplicate()

func get_session_data() -> Dictionary:
	"""
	Get the current session data
	"""
	return session_data.duplicate()

func get_performance_data() -> Dictionary:
	"""
	Get current performance data
	"""
	return {
		"fps": average_fps,
		"frame_time": frame_times[-1] if frame_times.size() > 0 else 0.0,
		"memory_usage": OS.get_static_memory_usage()
	} 