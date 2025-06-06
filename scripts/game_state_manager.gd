extends Node

# Game states
enum GameState {
	MAIN_MENU,
	CHARACTER_CREATION,
	LOADING,
	PLAYING,
	PAUSED,
	DIALOG,
	COMBAT,
	GAME_OVER
}

# Current state
var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.MAIN_MENU

# References
var player: Node
var world: Node
var ui_manager: Node
var save_system: Node
var input_manager: Node
var sound_manager: Node
var animation_manager: Node
var notification_manager: Node
var dialog_manager: Node
var quest_manager: Node
var combat_manager: Node

# Game data
var game_data: Dictionary = {
	"player": null,
	"world": null,
	"quests": [],
	"inventory": [],
	"equipment": {},
	"settings": {},
	"stats": {}
}

# Signals
signal state_changed(new_state: GameState, old_state: GameState)
signal game_initialized
signal game_saved
signal game_loaded
signal game_paused
signal game_resumed
signal game_over

func _ready():
	# Initialize managers
	_initialize_managers()
	
	# Connect signals
	_connect_signals()
	
	# Start in main menu
	change_state(GameState.MAIN_MENU)

func _initialize_managers():
	"""
	Initialize all game managers
	"""
	# TODO: Initialize managers when they are created
	pass

func _connect_signals():
	"""
	Connect signals from various systems
	"""
	# TODO: Connect signals when systems are created
	pass

func change_state(new_state: GameState) -> void:
	"""
	Change the current game state
	"""
	if new_state == current_state:
		return
	
	previous_state = current_state
	current_state = new_state
	
	match new_state:
		GameState.MAIN_MENU:
			_enter_main_menu()
		GameState.CHARACTER_CREATION:
			_enter_character_creation()
		GameState.LOADING:
			_enter_loading()
		GameState.PLAYING:
			_enter_playing()
		GameState.PAUSED:
			_enter_paused()
		GameState.DIALOG:
			_enter_dialog()
		GameState.COMBAT:
			_enter_combat()
		GameState.GAME_OVER:
			_enter_game_over()
	
	emit_signal("state_changed", current_state, previous_state)

func _enter_main_menu() -> void:
	"""
	Enter the main menu state
	"""
	# Show main menu
	ui_manager.show_main_menu()
	
	# Disable game input
	input_manager.set_game_input_enabled(false)
	
	# Play menu music
	sound_manager.play_music("main_menu")

func _enter_character_creation() -> void:
	"""
	Enter the character creation state
	"""
	# Show character creation screen
	ui_manager.show_character_creation()
	
	# Disable game input
	input_manager.set_game_input_enabled(false)

func _enter_loading() -> void:
	"""
	Enter the loading state
	"""
	# Show loading screen
	ui_manager.show_loading_screen()
	
	# Disable input
	input_manager.set_game_input_enabled(false)

func _enter_playing() -> void:
	"""
	Enter the playing state
	"""
	# Hide UI elements
	ui_manager.hide_menus()
	
	# Enable game input
	input_manager.set_game_input_enabled(true)
	
	# Play game music
	sound_manager.play_music("game")

func _enter_paused() -> void:
	"""
	Enter the paused state
	"""
	# Show pause menu
	ui_manager.show_pause_menu()
	
	# Disable game input
	input_manager.set_game_input_enabled(false)
	
	# Pause game
	get_tree().paused = true
	
	emit_signal("game_paused")

func _enter_dialog() -> void:
	"""
	Enter the dialog state
	"""
	# Show dialog UI
	ui_manager.show_dialog()
	
	# Disable game input
	input_manager.set_game_input_enabled(false)

func _enter_combat() -> void:
	"""
	Enter the combat state
	"""
	# Show combat UI
	ui_manager.show_combat()
	
	# Enable combat input
	input_manager.set_combat_input_enabled(true)

func _enter_game_over() -> void:
	"""
	Enter the game over state
	"""
	# Show game over screen
	ui_manager.show_game_over()
	
	# Disable input
	input_manager.set_game_input_enabled(false)
	
	emit_signal("game_over")

func save_game(slot: int) -> void:
	"""
	Save the current game state
	"""
	# Update game data
	_update_game_data()
	
	# Save to slot
	save_system.save_game(slot)
	
	emit_signal("game_saved")

func load_game(slot: int) -> void:
	"""
	Load a game state
	"""
	# Load from slot
	save_system.load_game(slot)
	
	# Apply loaded data
	_apply_game_data()
	
	emit_signal("game_loaded")

func _update_game_data() -> void:
	"""
	Update game data with current state
	"""
	# TODO: Implement data collection from game state
	pass

func _apply_game_data() -> void:
	"""
	Apply loaded game data to current state
	"""
	# TODO: Implement data application to game state
	pass

func _input(event: InputEvent) -> void:
	"""
	Handle global input events
	"""
	if event.is_action_pressed("pause") and current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
	elif event.is_action_pressed("pause") and current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)
		get_tree().paused = false
		emit_signal("game_resumed") 