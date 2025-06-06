extends Node

# Input states
var game_input_enabled: bool = false
var combat_input_enabled: bool = false
var dialog_input_enabled: bool = false

# Action groups
const GAME_ACTIONS = [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"interact",
	"inventory",
	"quest_log",
	"map",
	"pause"
]

const COMBAT_ACTIONS = [
	"attack",
	"block",
	"dodge",
	"skill_1",
	"skill_2",
	"skill_3",
	"skill_4"
]

const DIALOG_ACTIONS = [
	"dialog_next",
	"dialog_choice_1",
	"dialog_choice_2",
	"dialog_choice_3",
	"dialog_choice_4"
]

# Default key bindings
var default_bindings: Dictionary = {
	"move_up": KEY_W,
	"move_down": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"interact": KEY_E,
	"inventory": KEY_I,
	"quest_log": KEY_L,
	"map": KEY_M,
	"pause": KEY_ESCAPE,
	"attack": KEY_SPACE,
	"block": KEY_SHIFT,
	"dodge": KEY_CTRL,
	"skill_1": KEY_1,
	"skill_2": KEY_2,
	"skill_3": KEY_3,
	"skill_4": KEY_4,
	"dialog_next": KEY_SPACE,
	"dialog_choice_1": KEY_1,
	"dialog_choice_2": KEY_2,
	"dialog_choice_3": KEY_3,
	"dialog_choice_4": KEY_4
}

# Current key bindings
var current_bindings: Dictionary = {}

# Signals
signal action_pressed(action: String)
signal action_released(action: String)
signal bindings_changed

func _ready():
	# Initialize bindings
	_load_bindings()
	
	# Connect input events
	_connect_input_events()

func _load_bindings() -> void:
	"""
	Load key bindings from config or use defaults
	"""
	# TODO: Load from config file
	current_bindings = default_bindings.duplicate()

func _save_bindings() -> void:
	"""
	Save current key bindings to config
	"""
	# TODO: Save to config file
	pass

func _connect_input_events() -> void:
	"""
	Connect input events for all actions
	"""
	for action in current_bindings.keys():
		var event = InputEventKey.new()
		event.keycode = current_bindings[action]
		
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		
		InputMap.action_add_event(action, event)

func set_game_input_enabled(enabled: bool) -> void:
	"""
	Enable or disable game input
	"""
	game_input_enabled = enabled
	_update_input_state()

func set_combat_input_enabled(enabled: bool) -> void:
	"""
	Enable or disable combat input
	"""
	combat_input_enabled = enabled
	_update_input_state()

func set_dialog_input_enabled(enabled: bool) -> void:
	"""
	Enable or disable dialog input
	"""
	dialog_input_enabled = enabled
	_update_input_state()

func _update_input_state() -> void:
	"""
	Update the enabled state of all input actions
	"""
	for action in GAME_ACTIONS:
		InputMap.action_set_enabled(action, game_input_enabled)
	
	for action in COMBAT_ACTIONS:
		InputMap.action_set_enabled(action, combat_input_enabled)
	
	for action in DIALOG_ACTIONS:
		InputMap.action_set_enabled(action, dialog_input_enabled)

func rebind_action(action: String, keycode: int) -> void:
	"""
	Rebind an action to a new key
	"""
	if not current_bindings.has(action):
		return
	
	# Remove old binding
	var old_event = InputEventKey.new()
	old_event.keycode = current_bindings[action]
	InputMap.action_erase_event(action, old_event)
	
	# Add new binding
	current_bindings[action] = keycode
	var new_event = InputEventKey.new()
	new_event.keycode = keycode
	InputMap.action_add_event(action, new_event)
	
	# Save changes
	_save_bindings()
	
	emit_signal("bindings_changed")

func reset_bindings() -> void:
	"""
	Reset all bindings to defaults
	"""
	current_bindings = default_bindings.duplicate()
	_connect_input_events()
	_save_bindings()
	
	emit_signal("bindings_changed")

func _input(event: InputEvent) -> void:
	"""
	Handle input events
	"""
	if event is InputEventKey:
		if event.pressed:
			_handle_key_press(event)
		else:
			_handle_key_release(event)

func _handle_key_press(event: InputEventKey) -> void:
	"""
	Handle key press events
	"""
	for action in current_bindings.keys():
		if event.keycode == current_bindings[action]:
			emit_signal("action_pressed", action)

func _handle_key_release(event: InputEventKey) -> void:
	"""
	Handle key release events
	"""
	for action in current_bindings.keys():
		if event.keycode == current_bindings[action]:
			emit_signal("action_released", action) 