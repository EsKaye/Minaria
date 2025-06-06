extends Node

# UI scenes
@export var main_menu_scene: PackedScene
@export var inventory_scene: PackedScene
@export var crafting_scene: PackedScene
@export var pause_menu_scene: PackedScene

# UI instances
var current_menu = null
var inventory_ui = null
var crafting_ui = null
var pause_menu = null

# UI state
var is_menu_open = false
var is_inventory_open = false
var is_crafting_open = false
var is_paused = false

# UI signals
signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)
signal inventory_toggled(is_open: bool)
signal crafting_toggled(is_open: bool)
signal game_paused(is_paused: bool)

func _ready():
	# Initialize UI
	pass

func _input(event):
	# Handle UI input
	if event.is_action_pressed("inventory"):
		toggle_inventory()
	elif event.is_action_pressed("crafting"):
		toggle_crafting()
	elif event.is_action_pressed("pause"):
		toggle_pause()

func open_menu(menu_name: String) -> bool:
	"""
	Open a menu by name
	Returns true if successful, false if menu not found
	"""
	if is_menu_open:
		close_current_menu()
		
	var menu_scene = null
	match menu_name:
		"main":
			menu_scene = main_menu_scene
		"inventory":
			menu_scene = inventory_scene
		"crafting":
			menu_scene = crafting_scene
		"pause":
			menu_scene = pause_menu_scene
			
	if !menu_scene:
		return false
		
	current_menu = menu_scene.instantiate()
	add_child(current_menu)
	is_menu_open = true
	menu_opened.emit(menu_name)
	return true

func close_current_menu():
	"""
	Close the currently open menu
	"""
	if current_menu:
		var menu_name = current_menu.name
		current_menu.queue_free()
		current_menu = null
		is_menu_open = false
		menu_closed.emit(menu_name)

func toggle_inventory():
	"""
	Toggle the inventory UI
	"""
	if is_inventory_open:
		close_current_menu()
		is_inventory_open = false
	else:
		if open_menu("inventory"):
			is_inventory_open = true
			
	inventory_toggled.emit(is_inventory_open)

func toggle_crafting():
	"""
	Toggle the crafting UI
	"""
	if is_crafting_open:
		close_current_menu()
		is_crafting_open = false
	else:
		if open_menu("crafting"):
			is_crafting_open = true
			
	crafting_toggled.emit(is_crafting_open)

func toggle_pause():
	"""
	Toggle the pause menu and game state
	"""
	if is_paused:
		close_current_menu()
		is_paused = false
		get_tree().paused = false
	else:
		if open_menu("pause"):
			is_paused = true
			get_tree().paused = true
			
	game_paused.emit(is_paused)

func show_notification(message: String, duration: float = 2.0):
	"""
	Show a temporary notification message
	"""
	# TODO: Implement notification system
	pass

func update_health_bar(current: float, maximum: float):
	"""
	Update the health bar display
	"""
	# TODO: Implement health bar update
	pass

func update_resource_display(resources: Dictionary):
	"""
	Update the resource counter display
	"""
	# TODO: Implement resource display update
	pass

func show_dialog(text: String, options: Array = []):
	"""
	Show a dialog box with optional choices
	"""
	# TODO: Implement dialog system
	pass

func show_tooltip(text: String, position: Vector2):
	"""
	Show a tooltip at the specified position
	"""
	# TODO: Implement tooltip system
	pass

func hide_tooltip():
	"""
	Hide the current tooltip
	"""
	# TODO: Implement tooltip hiding
	pass

func update_minimap(player_position: Vector2, discovered_areas: Array):
	"""
	Update the minimap display
	"""
	# TODO: Implement minimap update
	pass

func show_loading_screen(progress: float = 0.0):
	"""
	Show the loading screen with optional progress
	"""
	# TODO: Implement loading screen
	pass

func hide_loading_screen():
	"""
	Hide the loading screen
	"""
	# TODO: Implement loading screen hiding
	pass 