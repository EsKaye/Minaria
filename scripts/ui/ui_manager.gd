extends Node
class_name UIManager

## UI Manager - Modern UI system for Minaria
## Provides centralized UI management with state machine, component system, and comprehensive UI controls
## Implements modern UI patterns with proper layering, transitions, and accessibility support

# UI layers for proper rendering order
enum UILayer {
	BACKGROUND = 0,
	WORLD = 1,
	GAME = 2,
	UI = 3,
	OVERLAY = 4,
	MODAL = 5,
	TOOLTIP = 6
}

# UI states
enum UIState {
	MAIN_MENU,
	LOADING,
	GAMEPLAY,
	INVENTORY,
	CRAFTING,
	PAUSE,
	DIALOG,
	SETTINGS,
	SAVE_LOAD
}

# UI scenes and components
@export_group("UI Scenes")
@export var main_menu_scene: PackedScene
@export var loading_screen_scene: PackedScene
@export var inventory_scene: PackedScene
@export var crafting_scene: PackedScene
@export var pause_menu_scene: PackedScene
@export var dialog_scene: PackedScene
@export var settings_scene: PackedScene
@export var save_load_scene: PackedScene
@export var notification_scene: PackedScene
@export var tooltip_scene: PackedScene

# UI components
@export_group("UI Components")
@export var health_bar_scene: PackedScene
@export var mana_bar_scene: PackedScene
@export var minimap_scene: PackedScene
@export var quest_log_scene: PackedScene

# Current UI state
var current_state: UIState = UIState.MAIN_MENU
var previous_state: UIState = UIState.MAIN_MENU
var state_stack: Array[UIState] = []

# UI instances
var ui_instances: Dictionary = {}
var active_ui: Node = null
var ui_root: Control

# UI configuration
var ui_scale: float = 1.0
var ui_opacity: float = 1.0
var ui_animations_enabled: bool = true
var ui_sounds_enabled: bool = true

# UI performance tracking
var ui_update_timer: float = 0.0
var ui_update_interval: float = 0.016  # 60 FPS
var ui_performance_data: Dictionary = {}

# UI accessibility
var accessibility_enabled: bool = false
var high_contrast_mode: bool = false
var text_scaling: float = 1.0
var color_blind_mode: String = "none"

# UI transitions
var transition_in_progress: bool = false
var transition_duration: float = 0.3
var transition_type: String = "fade"

# UI notifications
var notification_queue: Array[Dictionary] = []
var max_notifications: int = 5
var notification_duration: float = 3.0

# UI tooltips
var current_tooltip: Node = null
var tooltip_delay: float = 0.5
var tooltip_timer: float = 0.0

# UI input handling
var input_blocked: bool = false
var input_stack: Array[bool] = []

# Signals
signal ui_state_changed(new_state: UIState, old_state: UIState)
signal ui_opened(ui_name: String)
signal ui_closed(ui_name: String)
signal notification_shown(message: String, type: String)
signal tooltip_shown(text: String, position: Vector2)
signal tooltip_hidden
signal ui_scale_changed(scale: float)
signal accessibility_changed(enabled: bool)

func _ready() -> void:
	"""
	Initialize the UI manager system
	"""
	_setup_ui_root()
	_initialize_ui_components()
	_connect_signals()
	_load_ui_settings()
	_setup_accessibility()

func _process(delta: float) -> void:
	"""
	Main UI update loop
	"""
	_update_ui_performance(delta)
	_update_notifications(delta)
	_update_tooltips(delta)
	_update_ui_components(delta)

func _setup_ui_root() -> void:
	"""
	Setup the main UI root node
	"""
	ui_root = Control.new()
	ui_root.name = "UIRoot"
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui_root)
	
	# Create layer containers
	for layer in UILayer.values():
		var layer_container = Control.new()
		layer_container.name = "Layer_" + UILayer.keys()[layer]
		layer_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer_container.z_index = layer
		ui_root.add_child(layer_container)

func _initialize_ui_components() -> void:
	"""
	Initialize UI components and systems
	"""
	# Initialize notification system
	_initialize_notification_system()
	
	# Initialize tooltip system
	_initialize_tooltip_system()
	
	# Initialize UI components
	_initialize_ui_components()

func _connect_signals() -> void:
	"""
	Connect UI-related signals
	"""
	# Connect to game manager signals
	if GameManager:
		GameManager.game_state_changed.connect(_on_game_state_changed)
		GameManager.game_paused.connect(_on_game_paused)
	
	# Connect to input manager signals
	if InputManager:
		InputManager.input_action_triggered.connect(_on_input_action_triggered)

func change_ui_state(new_state: UIState, push_to_stack: bool = true) -> void:
	"""
	Change the current UI state with proper transitions
	
	Args:
		new_state: The new UI state to transition to
		push_to_stack: Whether to push the current state to the stack
	"""
	if new_state == current_state:
		return
	
	previous_state = current_state
	
	# Handle state transition
	_handle_ui_state_transition(current_state, new_state)
	
	# Update state
	if push_to_stack:
		state_stack.push_back(current_state)
	
	current_state = new_state
	
	# Emit signal
	ui_state_changed.emit(new_state, previous_state)

func push_ui_state(state: UIState) -> void:
	"""
	Push a UI state onto the stack
	"""
	change_ui_state(state, true)

func pop_ui_state() -> UIState:
	"""
	Pop the top UI state from the stack
	
	Returns:
		The popped UI state
	"""
	if state_stack.size() > 0:
		var previous_state = state_stack.pop_back()
		change_ui_state(previous_state, false)
		return previous_state
	return current_state

func open_ui(ui_name: String, layer: UILayer = UILayer.UI) -> Node:
	"""
	Open a UI component
	
	Args:
		ui_name: Name of the UI to open
		layer: UI layer to place the UI on
		
	Returns:
		The opened UI node
	"""
	if ui_instances.has(ui_name):
		close_ui(ui_name)
	
	var ui_scene = _get_ui_scene(ui_name)
	if not ui_scene:
		return null
	
	var ui_instance = ui_scene.instantiate()
	var layer_container = _get_layer_container(layer)
	layer_container.add_child(ui_instance)
	
	ui_instances[ui_name] = ui_instance
	active_ui = ui_instance
	
	# Setup UI instance
	_setup_ui_instance(ui_instance, ui_name)
	
	# Show UI with animation
	_show_ui_with_animation(ui_instance)
	
	ui_opened.emit(ui_name)
	return ui_instance

func close_ui(ui_name: String) -> void:
	"""
	Close a UI component
	
	Args:
		ui_name: Name of the UI to close
	"""
	if not ui_instances.has(ui_name):
		return
	
	var ui_instance = ui_instances[ui_name]
	
	# Hide UI with animation
	_hide_ui_with_animation(ui_instance, func(): _destroy_ui_instance(ui_name))
	
	ui_instances.erase(ui_name)
	
	if active_ui == ui_instance:
		active_ui = null
	
	ui_closed.emit(ui_name)

func show_notification(message: String, type: String = "info", duration: float = -1.0) -> void:
	"""
	Show a notification message
	
	Args:
		message: The notification message
		type: Type of notification (info, warning, error, success)
		duration: Duration to show the notification (-1 for default)
	"""
	var notification_data = {
		"message": message,
		"type": type,
		"duration": duration if duration > 0 else notification_duration,
		"time": 0.0
	}
	
	notification_queue.push_back(notification_data)
	notification_shown.emit(message, type)

func show_tooltip(text: String, position: Vector2, delay: float = -1.0) -> void:
	"""
	Show a tooltip at the specified position
	
	Args:
		text: Tooltip text
		position: Position to show the tooltip
		delay: Delay before showing tooltip (-1 for default)
	"""
	if delay > 0:
		tooltip_timer = delay
	else:
		tooltip_timer = tooltip_delay
	
	# Store tooltip data for delayed display
	# This would be implemented with the actual tooltip system

func hide_tooltip() -> void:
	"""
	Hide the current tooltip
	"""
	if current_tooltip:
		current_tooltip.queue_free()
		current_tooltip = null
		tooltip_hidden.emit()

func update_health_bar(current: float, maximum: float) -> void:
	"""
	Update the health bar display
	
	Args:
		current: Current health value
		maximum: Maximum health value
	"""
	var health_bar = _get_ui_component("health_bar")
	if health_bar and health_bar.has_method("update_values"):
		health_bar.update_values(current, maximum)

func update_mana_bar(current: float, maximum: float) -> void:
	"""
	Update the mana bar display
	
	Args:
		current: Current mana value
		maximum: Maximum mana value
	"""
	var mana_bar = _get_ui_component("mana_bar")
	if mana_bar and mana_bar.has_method("update_values"):
		mana_bar.update_values(current, maximum)

func update_minimap(player_position: Vector2, discovered_areas: Array) -> void:
	"""
	Update the minimap display
	
	Args:
		player_position: Current player position
		discovered_areas: Array of discovered area data
	"""
	var minimap = _get_ui_component("minimap")
	if minimap and minimap.has_method("update_map"):
		minimap.update_map(player_position, discovered_areas)

func update_quest_log(quests: Array) -> void:
	"""
	Update the quest log display
	
	Args:
		quests: Array of quest data
	"""
	var quest_log = _get_ui_component("quest_log")
	if quest_log and quest_log.has_method("update_quests"):
		quest_log.update_quests(quests)

func set_ui_scale(scale: float) -> void:
	"""
	Set the UI scale factor
	
	Args:
		scale: UI scale factor
	"""
	ui_scale = clamp(scale, 0.5, 2.0)
	
	if ui_root:
		ui_root.scale = Vector2(ui_scale, ui_scale)
	
	ui_scale_changed.emit(ui_scale)
	_save_ui_settings()

func set_accessibility(enabled: bool) -> void:
	"""
	Enable or disable accessibility features
	
	Args:
		enabled: Whether to enable accessibility features
	"""
	accessibility_enabled = enabled
	accessibility_changed.emit(enabled)
	_apply_accessibility_settings()
	_save_ui_settings()

func block_input(blocked: bool) -> void:
	"""
	Block or unblock UI input
	
	Args:
		blocked: Whether to block input
	"""
	input_blocked = blocked
	input_stack.push_back(blocked)

func unblock_input() -> void:
	"""
	Unblock UI input
	"""
	if input_stack.size() > 0:
		input_stack.pop_back()
		input_blocked = input_stack.size() > 0 and input_stack[-1]

func _handle_ui_state_transition(old_state: UIState, new_state: UIState) -> void:
	"""
	Handle UI state transitions
	"""
	# Close current UI
	_close_current_ui()
	
	# Setup new UI state
	match new_state:
		UIState.MAIN_MENU:
			_setup_main_menu()
		UIState.LOADING:
			_setup_loading_screen()
		UIState.GAMEPLAY:
			_setup_gameplay_ui()
		UIState.INVENTORY:
			_setup_inventory_ui()
		UIState.CRAFTING:
			_setup_crafting_ui()
		UIState.PAUSE:
			_setup_pause_menu()
		UIState.DIALOG:
			_setup_dialog_ui()
		UIState.SETTINGS:
			_setup_settings_ui()
		UIState.SAVE_LOAD:
			_setup_save_load_ui()

func _setup_main_menu() -> void:
	"""
	Setup the main menu UI
	"""
	open_ui("main_menu", UILayer.UI)

func _setup_loading_screen() -> void:
	"""
	Setup the loading screen UI
	"""
	open_ui("loading_screen", UILayer.OVERLAY)

func _setup_gameplay_ui() -> void:
	"""
	Setup the gameplay UI components
	"""
	# Open gameplay UI components
	open_ui("health_bar", UILayer.GAME)
	open_ui("mana_bar", UILayer.GAME)
	open_ui("minimap", UILayer.GAME)
	open_ui("quest_log", UILayer.GAME)

func _setup_inventory_ui() -> void:
	"""
	Setup the inventory UI
	"""
	open_ui("inventory", UILayer.MODAL)

func _setup_crafting_ui() -> void:
	"""
	Setup the crafting UI
	"""
	open_ui("crafting", UILayer.MODAL)

func _setup_pause_menu() -> void:
	"""
	Setup the pause menu UI
	"""
	open_ui("pause_menu", UILayer.MODAL)

func _setup_dialog_ui() -> void:
	"""
	Setup the dialog UI
	"""
	open_ui("dialog", UILayer.MODAL)

func _setup_settings_ui() -> void:
	"""
	Setup the settings UI
	"""
	open_ui("settings", UILayer.MODAL)

func _setup_save_load_ui() -> void:
	"""
	Setup the save/load UI
	"""
	open_ui("save_load", UILayer.MODAL)

func _close_current_ui() -> void:
	"""
	Close the current UI state
	"""
	# Close all open UIs
	for ui_name in ui_instances.keys():
		close_ui(ui_name)

func _get_ui_scene(ui_name: String) -> PackedScene:
	"""
	Get the UI scene for a given UI name
	"""
	match ui_name:
		"main_menu":
			return main_menu_scene
		"loading_screen":
			return loading_screen_scene
		"inventory":
			return inventory_scene
		"crafting":
			return crafting_scene
		"pause_menu":
			return pause_menu_scene
		"dialog":
			return dialog_scene
		"settings":
			return settings_scene
		"save_load":
			return save_load_scene
		"notification":
			return notification_scene
		"tooltip":
			return tooltip_scene
		"health_bar":
			return health_bar_scene
		"mana_bar":
			return mana_bar_scene
		"minimap":
			return minimap_scene
		"quest_log":
			return quest_log_scene
		_:
			return null

func _get_layer_container(layer: UILayer) -> Control:
	"""
	Get the container for a specific UI layer
	"""
	var layer_name = "Layer_" + UILayer.keys()[layer]
	return ui_root.get_node(layer_name) as Control

func _get_ui_component(component_name: String) -> Node:
	"""
	Get a UI component by name
	"""
	return ui_instances.get(component_name, null)

func _setup_ui_instance(ui_instance: Node, ui_name: String) -> void:
	"""
	Setup a UI instance with proper configuration
	"""
	# Set UI name
	ui_instance.name = ui_name
	
	# Connect UI signals if they exist
	if ui_instance.has_signal("ui_closed"):
		ui_instance.ui_closed.connect(_on_ui_instance_closed.bind(ui_name))
	
	# Apply accessibility settings
	_apply_accessibility_to_ui(ui_instance)

func _show_ui_with_animation(ui_instance: Node) -> void:
	"""
	Show a UI with animation
	"""
	if not ui_animations_enabled:
		ui_instance.show()
		return
	
	# Start hidden
	ui_instance.modulate.a = 0.0
	ui_instance.show()
	
	# Animate in
	var tween = create_tween()
	tween.tween_property(ui_instance, "modulate:a", 1.0, transition_duration)
	tween.tween_callback(func(): transition_in_progress = false)

func _hide_ui_with_animation(ui_instance: Node, callback: Callable) -> void:
	"""
	Hide a UI with animation
	"""
	if not ui_animations_enabled:
		ui_instance.hide()
		callback.call()
		return
	
	# Animate out
	var tween = create_tween()
	tween.tween_property(ui_instance, "modulate:a", 0.0, transition_duration)
	tween.tween_callback(func(): 
		ui_instance.hide()
		callback.call()
	)

func _destroy_ui_instance(ui_name: String) -> void:
	"""
	Destroy a UI instance
	"""
	if ui_instances.has(ui_name):
		var ui_instance = ui_instances[ui_name]
		if ui_instance:
			ui_instance.queue_free()

func _initialize_notification_system() -> void:
	"""
	Initialize the notification system
	"""
	# Create notification container
	var notification_container = VBoxContainer.new()
	notification_container.name = "NotificationContainer"
	notification_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	notification_container.position = Vector2(-20, 20)
	
	var layer_container = _get_layer_container(UILayer.TOOLTIP)
	layer_container.add_child(notification_container)

func _initialize_tooltip_system() -> void:
	"""
	Initialize the tooltip system
	"""
	# Tooltip system would be implemented here
	pass

func _initialize_ui_components() -> void:
	"""
	Initialize UI components
	"""
	# UI components initialization would be implemented here
	pass

func _update_ui_performance(delta: float) -> void:
	"""
	Update UI performance tracking
	"""
	ui_update_timer += delta
	
	if ui_update_timer >= ui_update_interval:
		ui_update_timer = 0.0
		
		# Update performance data
		ui_performance_data = {
			"active_uis": ui_instances.size(),
			"state_stack_size": state_stack.size(),
			"notification_count": notification_queue.size()
		}

func _update_notifications(delta: float) -> void:
	"""
	Update notification system
	"""
	var notifications_to_remove: Array[int] = []
	
	for i in range(notification_queue.size()):
		var notification = notification_queue[i]
		notification.time += delta
		
		if notification.time >= notification.duration:
			notifications_to_remove.push_back(i)
	
	# Remove expired notifications
	for i in range(notifications_to_remove.size() - 1, -1, -1):
		notification_queue.remove_at(notifications_to_remove[i])

func _update_tooltips(delta: float) -> void:
	"""
	Update tooltip system
	"""
	if tooltip_timer > 0:
		tooltip_timer -= delta
		if tooltip_timer <= 0:
			# Show tooltip
			pass

func _update_ui_components(delta: float) -> void:
	"""
	Update UI components
	"""
	# Update UI components that need regular updates
	for ui_instance in ui_instances.values():
		if ui_instance.has_method("_update"):
			ui_instance._update(delta)

func _setup_accessibility() -> void:
	"""
	Setup accessibility features
	"""
	# Accessibility setup would be implemented here
	pass

func _apply_accessibility_settings() -> void:
	"""
	Apply accessibility settings to all UI elements
	"""
	for ui_instance in ui_instances.values():
		_apply_accessibility_to_ui(ui_instance)

func _apply_accessibility_to_ui(ui_instance: Node) -> void:
	"""
	Apply accessibility settings to a specific UI
	"""
	if not accessibility_enabled:
		return
	
	# Apply text scaling
	if ui_instance.has_method("set_text_scale"):
		ui_instance.set_text_scale(text_scaling)
	
	# Apply high contrast mode
	if high_contrast_mode and ui_instance.has_method("set_high_contrast"):
		ui_instance.set_high_contrast(true)
	
	# Apply color blind mode
	if color_blind_mode != "none" and ui_instance.has_method("set_color_blind_mode"):
		ui_instance.set_color_blind_mode(color_blind_mode)

func _load_ui_settings() -> void:
	"""
	Load UI settings from save file
	"""
	if SaveSystem:
		var settings = SaveSystem.load_settings()
		if settings.has("ui"):
			var ui_settings = settings.ui
			
			if ui_settings.has("scale"):
				set_ui_scale(ui_settings.scale)
			
			if ui_settings.has("accessibility"):
				set_accessibility(ui_settings.accessibility)
			
			if ui_settings.has("animations"):
				ui_animations_enabled = ui_settings.animations
			
			if ui_settings.has("sounds"):
				ui_sounds_enabled = ui_settings.sounds

func _save_ui_settings() -> void:
	"""
	Save UI settings to save file
	"""
	if SaveSystem:
		var settings = SaveSystem.load_settings()
		settings["ui"] = {
			"scale": ui_scale,
			"accessibility": accessibility_enabled,
			"animations": ui_animations_enabled,
			"sounds": ui_sounds_enabled,
			"text_scaling": text_scaling,
			"high_contrast": high_contrast_mode,
			"color_blind_mode": color_blind_mode
		}
		SaveSystem.save_settings(settings)

func _on_game_state_changed(new_state: GameManager.GameState, old_state: GameManager.GameState) -> void:
	"""
	Handle game state changes
	"""
	match new_state:
		GameManager.GameState.MAIN_MENU:
			change_ui_state(UIState.MAIN_MENU)
		GameManager.GameState.LOADING:
			change_ui_state(UIState.LOADING)
		GameManager.GameState.PLAYING:
			change_ui_state(UIState.GAMEPLAY)
		GameManager.GameState.INVENTORY:
			change_ui_state(UIState.INVENTORY)
		GameManager.GameState.CRAFTING:
			change_ui_state(UIState.CRAFTING)
		GameManager.GameState.PAUSED:
			change_ui_state(UIState.PAUSE)

func _on_game_paused(is_paused: bool) -> void:
	"""
	Handle game pause state
	"""
	if is_paused:
		push_ui_state(UIState.PAUSE)
	else:
		pop_ui_state()

func _on_input_action_triggered(action: String) -> void:
	"""
	Handle input actions
	"""
	if input_blocked:
		return
	
	match action:
		"inventory":
			if current_state == UIState.GAMEPLAY:
				push_ui_state(UIState.INVENTORY)
		"crafting":
			if current_state == UIState.GAMEPLAY:
				push_ui_state(UIState.CRAFTING)
		"pause":
			if current_state == UIState.GAMEPLAY:
				push_ui_state(UIState.PAUSE)

func _on_ui_instance_closed(ui_name: String) -> void:
	"""
	Handle UI instance closed signal
	"""
	close_ui(ui_name)

func get_ui_performance_data() -> Dictionary:
	"""
	Get UI performance data
	
	Returns:
		Dictionary containing UI performance metrics
	"""
	return ui_performance_data.duplicate()

func get_current_ui_state() -> UIState:
	"""
	Get the current UI state
	
	Returns:
		Current UI state
	"""
	return current_state

func is_ui_open(ui_name: String) -> bool:
	"""
	Check if a specific UI is open
	
	Args:
		ui_name: Name of the UI to check
		
	Returns:
		True if the UI is open
	"""
	return ui_instances.has(ui_name) 