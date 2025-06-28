extends Node
class_name InputManager

## Input Manager - Modern input handling system for Minaria
## Provides centralized input management with action mapping, buffering, and input validation
## Supports keyboard, gamepad, and touch input with automatic device switching

# Input action definitions
enum InputAction {
	MOVE_LEFT,
	MOVE_RIGHT,
	MOVE_UP,
	MOVE_DOWN,
	JUMP,
	INTERACT,
	ATTACK,
	INVENTORY,
	CRAFTING,
	PAUSE,
	MENU,
	ACCEPT,
	CANCEL,
	QUICK_SAVE,
	QUICK_LOAD
}

# Input device types
enum InputDevice {
	KEYBOARD,
	GAMEPAD,
	TOUCH
}

# Current input state
var current_device: InputDevice = InputDevice.KEYBOARD
var input_buffer: Array[Dictionary] = []
var max_buffer_size: int = 10
var buffer_time: float = 0.2  # 200ms buffer window

# Input state tracking
var input_states: Dictionary = {}
var action_states: Dictionary = {}
var axis_values: Dictionary = {}

# Input mapping
var input_mappings: Dictionary = {}
var default_mappings: Dictionary = {}

# Input sensitivity and deadzone
var gamepad_deadzone: float = 0.2
var mouse_sensitivity: float = 1.0
var gamepad_sensitivity: float = 1.0

# Input processing flags
var input_enabled: bool = true
var input_consumed: bool = false
var input_blocked: bool = false

# Input history for debugging
var input_history: Array[Dictionary] = []
var max_history_size: int = 100

# Signals
signal input_action_triggered(action: String)
signal input_action_pressed(action: String)
signal input_action_released(action: String)
signal input_device_changed(device: InputDevice)
signal input_mapping_changed(action: String, new_mapping: Dictionary)

func _ready() -> void:
	"""
	Initialize the input manager system
	"""
	_initialize_input_mappings()
	_initialize_input_states()
	_connect_input_events()
	_load_input_settings()

func _input(event: InputEvent) -> void:
	"""
	Process input events
	"""
	if not input_enabled or input_blocked:
		return
	
	_process_input_event(event)
	_update_input_states()
	_check_input_actions()

func _process_input_event(event: InputEvent) -> void:
	"""
	Process individual input events
	"""
	# Detect input device changes
	_detect_device_change(event)
	
	# Add to input history
	_add_to_history(event)
	
	# Process based on event type
	if event is InputEventKey:
		_process_key_event(event)
	elif event is InputEventJoypadButton:
		_process_gamepad_button_event(event)
	elif event is InputEventJoypadMotion:
		_process_gamepad_motion_event(event)
	elif event is InputEventMouseButton:
		_process_mouse_event(event)
	elif event is InputEventMouseMotion:
		_process_mouse_motion_event(event)

func _process_key_event(event: InputEventKey) -> void:
	"""
	Process keyboard input events
	"""
	var action = _get_action_for_key_event(event)
	if action != "":
		var input_data = {
			"action": action,
			"pressed": event.pressed,
			"strength": 1.0 if event.pressed else 0.0,
			"time": Time.get_time_dict_from_system()
		}
		
		_add_to_buffer(input_data)
		_update_action_state(action, event.pressed)

func _process_gamepad_button_event(event: InputEventJoypadButton) -> void:
	"""
	Process gamepad button events
	"""
	var action = _get_action_for_gamepad_button(event)
	if action != "":
		var input_data = {
			"action": action,
			"pressed": event.pressed,
			"strength": event.pressure,
			"time": Time.get_time_dict_from_system()
		}
		
		_add_to_buffer(input_data)
		_update_action_state(action, event.pressed)

func _process_gamepad_motion_event(event: InputEventJoypadMotion) -> void:
	"""
	Process gamepad motion/axis events
	"""
	var action = _get_action_for_gamepad_motion(event)
	if action != "":
		var strength = abs(event.axis_value)
		if strength > gamepad_deadzone:
			strength = (strength - gamepad_deadzone) / (1.0 - gamepad_deadzone)
			strength = clamp(strength, 0.0, 1.0)
			
			var input_data = {
				"action": action,
				"pressed": strength > 0.5,
				"strength": strength,
				"time": Time.get_time_dict_from_system()
			}
			
			_add_to_buffer(input_data)
			_update_axis_state(action, event.axis_value)

func _process_mouse_event(event: InputEventMouseButton) -> void:
	"""
	Process mouse button events
	"""
	var action = _get_action_for_mouse_event(event)
	if action != "":
		var input_data = {
			"action": action,
			"pressed": event.pressed,
			"strength": 1.0 if event.pressed else 0.0,
			"time": Time.get_time_dict_from_system()
		}
		
		_add_to_buffer(input_data)
		_update_action_state(action, event.pressed)

func _process_mouse_motion_event(event: InputEventMouseMotion) -> void:
	"""
	Process mouse motion events
	"""
	# Handle mouse look or other motion-based actions
	pass

func _get_action_for_key_event(event: InputEventKey) -> String:
	"""
	Get the action name for a key event
	"""
	for action in InputAction.values():
		var action_name = InputAction.keys()[action].to_lower()
		if Input.is_action_just_pressed(action_name) or Input.is_action_just_released(action_name):
			return action_name
	return ""

func _get_action_for_gamepad_button(event: InputEventJoypadButton) -> String:
	"""
	Get the action name for a gamepad button event
	"""
	# Map gamepad buttons to actions
	var button_mappings = {
		0: "jump",      # A/X button
		1: "attack",    # B/Circle button
		2: "interact",  # X/Square button
		3: "inventory", # Y/Triangle button
		4: "crafting",  # LB/L1 button
		5: "pause",     # RB/R1 button
		6: "menu",      # Back/Select button
		7: "accept"     # Start button
	}
	
	if button_mappings.has(event.button_index):
		return button_mappings[event.button_index]
	return ""

func _get_action_for_gamepad_motion(event: InputEventJoypadMotion) -> String:
	"""
	Get the action name for a gamepad motion event
	"""
	# Map gamepad axes to actions
	var axis_mappings = {
		0: "move_left",   # Left stick X
		1: "move_up",     # Left stick Y
		2: "move_right",  # Right stick X
		3: "move_down"    # Right stick Y
	}
	
	if axis_mappings.has(event.axis):
		return axis_mappings[event.axis]
	return ""

func _get_action_for_mouse_event(event: InputEventMouseButton) -> String:
	"""
	Get the action name for a mouse event
	"""
	var button_mappings = {
		MOUSE_BUTTON_LEFT: "attack",
		MOUSE_BUTTON_RIGHT: "interact",
		MOUSE_BUTTON_MIDDLE: "inventory"
	}
	
	if button_mappings.has(event.button_index):
		return button_mappings[event.button_index]
	return ""

func _add_to_buffer(input_data: Dictionary) -> void:
	"""
	Add input data to the input buffer
	"""
	input_buffer.push_back(input_data)
	
	# Maintain buffer size
	if input_buffer.size() > max_buffer_size:
		input_buffer.pop_front()

func _update_input_states() -> void:
	"""
	Update current input states
	"""
	# Update action states
	for action in InputAction.values():
		var action_name = InputAction.keys()[action].to_lower()
		var is_pressed = Input.is_action_pressed(action_name)
		
		if action_states.has(action_name):
			if action_states[action_name] != is_pressed:
				action_states[action_name] = is_pressed
				if is_pressed:
					input_action_pressed.emit(action_name)
				else:
					input_action_released.emit(action_name)
		else:
			action_states[action_name] = is_pressed

func _update_action_state(action: String, pressed: bool) -> void:
	"""
	Update the state of a specific action
	"""
	action_states[action] = pressed

func _update_axis_state(action: String, value: float) -> void:
	"""
	Update the state of a specific axis
	"""
	axis_values[action] = value

func _check_input_actions() -> void:
	"""
	Check for triggered input actions
	"""
	# Process buffered inputs
	var current_time = Time.get_time_dict_from_system()
	var buffer_to_remove: Array[int] = []
	
	for i in range(input_buffer.size()):
		var input_data = input_buffer[i]
		var time_diff = current_time - input_data.time
		
		if time_diff > buffer_time:
			buffer_to_remove.push_back(i)
		elif input_data.pressed:
			input_action_triggered.emit(input_data.action)
			buffer_to_remove.push_back(i)
	
	# Remove processed inputs
	for i in range(buffer_to_remove.size() - 1, -1, -1):
		input_buffer.remove_at(buffer_to_remove[i])

func _detect_device_change(event: InputEvent) -> void:
	"""
	Detect and handle input device changes
	"""
	var new_device = current_device
	
	if event is InputEventKey:
		new_device = InputDevice.KEYBOARD
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		new_device = InputDevice.GAMEPAD
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		new_device = InputDevice.KEYBOARD  # Mouse is part of keyboard input
	
	if new_device != current_device:
		current_device = new_device
		input_device_changed.emit(current_device)

func _add_to_history(event: InputEvent) -> void:
	"""
	Add input event to history for debugging
	"""
	var history_entry = {
		"event": event,
		"time": Time.get_time_dict_from_system(),
		"device": current_device
	}
	
	input_history.push_back(history_entry)
	
	# Maintain history size
	if input_history.size() > max_history_size:
		input_history.pop_front()

func _initialize_input_mappings() -> void:
	"""
	Initialize default input mappings
	"""
	default_mappings = {
		"move_left": {"key": KEY_A, "gamepad": 0, "axis": 0, "negative": true},
		"move_right": {"key": KEY_D, "gamepad": 0, "axis": 0, "negative": false},
		"move_up": {"key": KEY_W, "gamepad": 1, "axis": 1, "negative": true},
		"move_down": {"key": KEY_S, "gamepad": 1, "axis": 1, "negative": false},
		"jump": {"key": KEY_SPACE, "gamepad": 0, "button": 0},
		"interact": {"key": KEY_E, "gamepad": 2, "button": 2},
		"attack": {"key": KEY_ENTER, "gamepad": 1, "button": 1},
		"inventory": {"key": KEY_I, "gamepad": 3, "button": 3},
		"crafting": {"key": KEY_C, "gamepad": 4, "button": 4},
		"pause": {"key": KEY_ESCAPE, "gamepad": 5, "button": 5},
		"menu": {"key": KEY_TAB, "gamepad": 6, "button": 6},
		"accept": {"key": KEY_ENTER, "gamepad": 7, "button": 7},
		"cancel": {"key": KEY_ESCAPE, "gamepad": 1, "button": 1}
	}
	
	input_mappings = default_mappings.duplicate(true)

func _initialize_input_states() -> void:
	"""
	Initialize input state tracking
	"""
	for action in InputAction.values():
		var action_name = InputAction.keys()[action].to_lower()
		action_states[action_name] = false
		axis_values[action_name] = 0.0

func _connect_input_events() -> void:
	"""
	Connect input-related signals
	"""
	# Connect to input action signals
	for action in InputAction.values():
		var action_name = InputAction.keys()[action].to_lower()
		# These will be handled in _input()

func _load_input_settings() -> void:
	"""
	Load input settings from save file
	"""
	# TODO: Load custom input mappings from save file
	pass

func get_input_vector() -> Vector2:
	"""
	Get the current input vector for movement
	"""
	var input_vector = Vector2.ZERO
	
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	
	return input_vector.normalized()

func is_action_pressed(action: String) -> bool:
	"""
	Check if an action is currently pressed
	"""
	return action_states.get(action, false)

func is_action_just_pressed(action: String) -> bool:
	"""
	Check if an action was just pressed this frame
	"""
	return Input.is_action_just_pressed(action)

func is_action_just_released(action: String) -> bool:
	"""
	Check if an action was just released this frame
	"""
	return Input.is_action_just_released(action)

func get_axis_value(action: String) -> float:
	"""
	Get the current value of an axis
	"""
	return axis_values.get(action, 0.0)

func set_input_enabled(enabled: bool) -> void:
	"""
	Enable or disable input processing
	"""
	input_enabled = enabled

func block_input(blocked: bool) -> void:
	"""
	Block or unblock input processing
	"""
	input_blocked = blocked

func clear_input_buffer() -> void:
	"""
	Clear the input buffer
	"""
	input_buffer.clear()

func get_input_history() -> Array[Dictionary]:
	"""
	Get the input history for debugging
	"""
	return input_history.duplicate()

func save_input_settings() -> Dictionary:
	"""
	Save current input settings
	"""
	return {
		"mappings": input_mappings,
		"gamepad_deadzone": gamepad_deadzone,
		"mouse_sensitivity": mouse_sensitivity,
		"gamepad_sensitivity": gamepad_sensitivity
	}

func load_input_settings(settings: Dictionary) -> void:
	"""
	Load input settings from saved data
	"""
	if settings.has("mappings"):
		input_mappings = settings.mappings
	
	if settings.has("gamepad_deadzone"):
		gamepad_deadzone = settings.gamepad_deadzone
	
	if settings.has("mouse_sensitivity"):
		mouse_sensitivity = settings.mouse_sensitivity
	
	if settings.has("gamepad_sensitivity"):
		gamepad_sensitivity = settings.gamepad_sensitivity 