extends Node

# System references
@onready var world_generator = $WorldGenerator
@onready var player = $Player
@onready var ui_manager = $UIManager
@onready var inventory_system = $InventorySystem
@onready var crafting_system = $CraftingSystem

# Game state
var is_game_started = false
var is_game_paused = false
var current_biome = "plains"
var game_time = 0.0
var day_length = 600.0  # 10 minutes per day

# Game signals
signal game_started
signal game_paused(is_paused: bool)
signal game_saved(save_slot: int)
signal game_loaded(save_slot: int)
signal biome_changed(new_biome: String)
signal day_changed(day: int)
signal time_changed(time: float)

func _ready():
	# Initialize game systems
	initialize_systems()
	connect_signals()

func _process(delta):
	if is_game_started and !is_game_paused:
		update_game_time(delta)
		update_world_state()

func initialize_systems():
	"""
	Initialize all game systems
	"""
	# Initialize world generation
	world_generator.initialize_noise()
	
	# Initialize player
	player.initialize()
	
	# Initialize UI
	ui_manager.initialize()
	
	# Initialize inventory
	inventory_system.initialize()
	
	# Initialize crafting
	crafting_system.initialize()

func connect_signals():
	"""
	Connect all necessary signals between systems
	"""
	# UI signals
	ui_manager.menu_opened.connect(_on_menu_opened)
	ui_manager.menu_closed.connect(_on_menu_closed)
	ui_manager.game_paused.connect(_on_game_paused)
	
	# Player signals
	player.position_changed.connect(_on_player_position_changed)
	player.interaction_started.connect(_on_player_interaction_started)
	
	# Inventory signals
	inventory_system.inventory_changed.connect(_on_inventory_changed)
	
	# Crafting signals
	crafting_system.recipe_crafted.connect(_on_recipe_crafted)
	crafting_system.crafting_failed.connect(_on_crafting_failed)

func start_game():
	"""
	Start a new game
	"""
	is_game_started = true
	game_started.emit()
	
	# Generate initial world
	world_generator.generate_initial_chunks()
	
	# Spawn player
	player.spawn()

func save_game(save_slot: int):
	"""
	Save the current game state
	"""
	var save_data = {
		"player": {
			"position": player.position,
			"health": player.health,
			"inventory": inventory_system.get_inventory_contents(),
			"equipped_items": inventory_system.get_equipped_items()
		},
		"world": {
			"seed": world_generator.seed_value,
			"time": game_time,
			"biome": current_biome
		}
	}
	
	# TODO: Implement save file handling
	game_saved.emit(save_slot)

func load_game(save_slot: int):
	"""
	Load a saved game
	"""
	# TODO: Implement save file loading
	game_loaded.emit(save_slot)

func update_game_time(delta: float):
	"""
	Update the game time and day/night cycle
	"""
	game_time += delta
	if game_time >= day_length:
		game_time = 0.0
		day_changed.emit(floor(game_time / day_length))
	
	time_changed.emit(game_time)

func update_world_state():
	"""
	Update the world state based on current conditions
	"""
	# Update biome based on player position
	var new_biome = world_generator.get_biome_at(player.position.x, player.position.y)
	if new_biome != current_biome:
		current_biome = new_biome
		biome_changed.emit(current_biome)
	
	# Update world chunks
	world_generator.update_chunks(player.position)

func _on_menu_opened(menu_name: String):
	"""
	Handle menu opening
	"""
	match menu_name:
		"pause":
			is_game_paused = true
		"inventory":
			# Update inventory UI
			pass
		"crafting":
			# Update crafting UI
			pass

func _on_menu_closed(menu_name: String):
	"""
	Handle menu closing
	"""
	match menu_name:
		"pause":
			is_game_paused = false
		"inventory":
			# Clean up inventory UI
			pass
		"crafting":
			# Clean up crafting UI
			pass

func _on_game_paused(is_paused: bool):
	"""
	Handle game pause state
	"""
	is_game_paused = is_paused
	game_paused.emit(is_paused)

func _on_player_position_changed(new_position: Vector2):
	"""
	Handle player position changes
	"""
	# Update minimap
	ui_manager.update_minimap(new_position, [])
	
	# Update world generation
	world_generator.update_chunks(new_position)

func _on_player_interaction_started(target: Node):
	"""
	Handle player interactions
	"""
	if target.is_in_group("interactable"):
		target.interact()

func _on_inventory_changed():
	"""
	Handle inventory changes
	"""
	# Update UI
	ui_manager.update_resource_display(inventory_system.get_inventory_contents())

func _on_recipe_crafted(recipe_name: String, result: Dictionary):
	"""
	Handle successful crafting
	"""
	# Add crafted item to inventory
	inventory_system.add_item(result.name)
	
	# Show notification
	ui_manager.show_notification("Crafted: " + result.properties.name)

func _on_crafting_failed(recipe_name: String, reason: String):
	"""
	Handle failed crafting attempts
	"""
	# Show error notification
	ui_manager.show_notification("Crafting failed: " + reason) 