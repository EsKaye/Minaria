extends Node2D
class_name WorldGenerator

## World Generator - Advanced procedural world generation system for Minaria
## Provides comprehensive world generation with multiple biomes, advanced noise algorithms, and efficient chunk management
## Implements modern procedural generation patterns with performance optimization and extensible design

# World configuration
@export_group("World Configuration")
@export var world_seed: int = 0
@export var world_name: String = "Minaria"
@export var world_size: Vector2i = Vector2i(1000, 1000)
@export var chunk_size: int = 32
@export var render_distance: int = 8
@export var max_chunks: int = 256

# Generation parameters
@export_group("Generation Parameters")
@export var height_scale: float = 100.0
@export var temperature_scale: float = 50.0
@export var moisture_scale: float = 50.0
@export var biome_blend: float = 0.3
@export var detail_scale: float = 20.0

# Biome configuration
@export_group("Biome Configuration")
@export var biomes: Array[Dictionary] = [
	{"name": "ocean", "height_range": [0.0, 0.3], "temperature_range": [0.0, 1.0], "moisture_range": [0.0, 1.0]},
	{"name": "beach", "height_range": [0.3, 0.35], "temperature_range": [0.0, 1.0], "moisture_range": [0.0, 1.0]},
	{"name": "plains", "height_range": [0.35, 0.5], "temperature_range": [0.3, 0.7], "moisture_range": [0.2, 0.8]},
	{"name": "forest", "height_range": [0.35, 0.6], "temperature_range": [0.2, 0.8], "moisture_range": [0.6, 1.0]},
	{"name": "desert", "height_range": [0.35, 0.6], "temperature_range": [0.7, 1.0], "moisture_range": [0.0, 0.3]},
	{"name": "mountains", "height_range": [0.6, 1.0], "temperature_range": [0.0, 1.0], "moisture_range": [0.0, 1.0]},
	{"name": "snow", "height_range": [0.7, 1.0], "temperature_range": [0.0, 0.3], "moisture_range": [0.0, 1.0]}
]

# Noise generators
var height_noise: FastNoiseLite
var temperature_noise: FastNoiseLite
var moisture_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var cave_noise: FastNoiseLite
var structure_noise: FastNoiseLite

# Chunk management
var active_chunks: Dictionary = {}
var chunk_scene: PackedScene
var chunk_pool: Array[Node] = []
var max_pool_size: int = 50

# World state
var world_data: Dictionary = {}
var generation_progress: float = 0.0
var is_generating: bool = false
var generation_thread: Thread

# Performance tracking
var chunk_generation_time: float = 0.0
var chunk_update_time: float = 0.0
var memory_usage: int = 0

# World features
var structures: Array[Dictionary] = []
var resources: Array[Dictionary] = []
var spawn_points: Array[Vector2] = []

# Signals
signal chunk_generated(chunk_position: Vector2i, chunk_data: Dictionary)
signal chunk_removed(chunk_position: Vector2i)
signal generation_progress_updated(progress: float)
signal generation_completed
signal world_loaded
signal biome_changed(position: Vector2, biome: String)

func _ready() -> void:
	"""
	Initialize the world generator system
	"""
	_initialize_noise_generators()
	_load_chunk_scene()
	_setup_chunk_pool()
	_connect_signals()

func _process(delta: float) -> void:
	"""
	Main world generation update loop
	"""
	_update_chunk_management(delta)
	_update_performance_tracking(delta)

func _initialize_noise_generators() -> void:
	"""
	Initialize all noise generators with proper configuration
	"""
	# Height noise for terrain generation
	height_noise = FastNoiseLite.new()
	height_noise.seed = world_seed
	height_noise.frequency = 0.01
	height_noise.fractal_octaves = 4
	height_noise.fractal_lacunarity = 2.0
	height_noise.fractal_gain = 0.5
	
	# Temperature noise for climate
	temperature_noise = FastNoiseLite.new()
	temperature_noise.seed = world_seed + 1
	temperature_noise.frequency = 0.005
	temperature_noise.fractal_octaves = 3
	
	# Moisture noise for precipitation
	moisture_noise = FastNoiseLite.new()
	moisture_noise.seed = world_seed + 2
	moisture_noise.frequency = 0.008
	moisture_noise.fractal_octaves = 3
	
	# Detail noise for terrain features
	detail_noise = FastNoiseLite.new()
	detail_noise.seed = world_seed + 3
	detail_noise.frequency = 0.05
	detail_noise.fractal_octaves = 2
	
	# Cave noise for underground features
	cave_noise = FastNoiseLite.new()
	cave_noise.seed = world_seed + 4
	cave_noise.frequency = 0.02
	cave_noise.fractal_octaves = 3
	
	# Structure noise for building placement
	structure_noise = FastNoiseLite.new()
	structure_noise.seed = world_seed + 5
	structure_noise.frequency = 0.001
	structure_noise.fractal_octaves = 2

func _load_chunk_scene() -> void:
	"""
	Load the chunk scene for instantiation
	"""
	chunk_scene = preload("res://scenes/world/chunk.tscn")

func _setup_chunk_pool() -> void:
	"""
	Setup the chunk object pool for performance optimization
	"""
	for i in range(max_pool_size):
		var chunk = chunk_scene.instantiate()
		chunk.visible = false
		chunk_pool.append(chunk)
		add_child(chunk)

func _connect_signals() -> void:
	"""
	Connect world generation signals
	"""
	# Connect to game manager signals
	if GameManager:
		GameManager.game_state_changed.connect(_on_game_state_changed)

func generate_world() -> void:
	"""
	Generate the entire world
	"""
	if is_generating:
		return
	
	is_generating = true
	generation_progress = 0.0
	
	# Start generation in a separate thread
	generation_thread = Thread.new()
	generation_thread.start(_generate_world_thread.bind())

func _generate_world_thread() -> void:
	"""
	Generate world in a separate thread
	"""
	var start_time = Time.get_time_dict_from_system()
	
	# Generate initial chunks
	var center_chunk = Vector2i(world_size.x / 2, world_size.y / 2)
	var chunks_to_generate = []
	
	for x in range(center_chunk.x - render_distance, center_chunk.x + render_distance + 1):
		for y in range(center_chunk.y - render_distance, center_chunk.y + render_distance + 1):
			chunks_to_generate.append(Vector2i(x, y))
	
	# Generate chunks with progress updates
	for i in range(chunks_to_generate.size()):
		var chunk_pos = chunks_to_generate[i]
		_generate_chunk_data(chunk_pos)
		
		generation_progress = float(i + 1) / chunks_to_generate.size()
		generation_progress_updated.emit(generation_progress)
	
	# Signal completion
	call_deferred("_on_generation_completed")

func _on_generation_completed() -> void:
	"""
	Handle world generation completion
	"""
	is_generating = false
	generation_completed.emit()
	world_loaded.emit()
	
	if generation_thread:
		generation_thread.wait_to_finish()

func generate_chunk(chunk_position: Vector2i) -> void:
	"""
	Generate a single chunk at the specified position
	
	Args:
		chunk_position: The chunk position to generate
	"""
	if active_chunks.has(chunk_position):
		return
	
	var chunk_data = _generate_chunk_data(chunk_position)
	var chunk = _get_chunk_from_pool()
	
	if chunk:
		chunk.initialize(chunk_position, chunk_data, self)
		chunk.visible = true
		chunk.position = Vector2(chunk_position.x * chunk_size, chunk_position.y * chunk_size)
		
		active_chunks[chunk_position] = chunk
		chunk_generated.emit(chunk_position, chunk_data)

func _generate_chunk_data(chunk_position: Vector2i) -> Dictionary:
	"""
	Generate data for a chunk at the specified position
	
	Args:
		chunk_position: The chunk position
		
	Returns:
		Dictionary containing chunk generation data
	"""
	var chunk_data = {
		"position": chunk_position,
		"tiles": {},
		"biomes": {},
		"structures": [],
		"resources": [],
		"height_map": {},
		"temperature_map": {},
		"moisture_map": {}
	}
	
	var chunk_world_pos = Vector2(chunk_position.x * chunk_size, chunk_position.y * chunk_size)
	
	# Generate tile data
	for x in range(chunk_size):
		for y in range(chunk_size):
			var world_x = chunk_world_pos.x + x
			var world_y = chunk_world_pos.y + y
			var tile_pos = Vector2i(x, y)
			
			# Generate height, temperature, and moisture
			var height = _get_height_at(world_x, world_y)
			var temperature = _get_temperature_at(world_x, world_y)
			var moisture = _get_moisture_at(world_x, world_y)
			
			# Determine biome
			var biome = _get_biome_at(height, temperature, moisture)
			
			# Generate tile type
			var tile_type = _get_tile_type_at(world_x, world_y, height, biome)
			
			# Store data
			chunk_data.tiles[tile_pos] = tile_type
			chunk_data.biomes[tile_pos] = biome
			chunk_data.height_map[tile_pos] = height
			chunk_data.temperature_map[tile_pos] = temperature
			chunk_data.moisture_map[tile_pos] = moisture
	
	# Generate structures and resources
	_generate_structures_for_chunk(chunk_data)
	_generate_resources_for_chunk(chunk_data)
	
	return chunk_data

func _get_height_at(x: float, y: float) -> float:
	"""
	Get the terrain height at the specified world coordinates
	
	Args:
		x: World X coordinate
		y: World Y coordinate
		
	Returns:
		Height value between 0 and 1
	"""
	var height = height_noise.get_noise_2d(x, y)
	height = (height + 1) / 2  # Normalize to 0-1
	
	# Add detail noise
	var detail = detail_noise.get_noise_2d(x, y) * 0.1
	height = clamp(height + detail, 0.0, 1.0)
	
	return height

func _get_temperature_at(x: float, y: float) -> float:
	"""
	Get the temperature at the specified world coordinates
	
	Args:
		x: World X coordinate
		y: World Y coordinate
		
	Returns:
		Temperature value between 0 and 1
	"""
	var temperature = temperature_noise.get_noise_2d(x, y)
	temperature = (temperature + 1) / 2  # Normalize to 0-1
	
	# Add latitude-based temperature variation
	var latitude_factor = abs(y / world_size.y - 0.5) * 2  # 0 at equator, 1 at poles
	temperature = temperature * (1 - latitude_factor * 0.5)
	
	return clamp(temperature, 0.0, 1.0)

func _get_moisture_at(x: float, y: float) -> float:
	"""
	Get the moisture at the specified world coordinates
	
	Args:
		x: World X coordinate
		y: World Y coordinate
		
	Returns:
		Moisture value between 0 and 1
	"""
	var moisture = moisture_noise.get_noise_2d(x, y)
	moisture = (moisture + 1) / 2  # Normalize to 0-1
	
	# Add distance from water influence
	var height = _get_height_at(x, y)
	if height < 0.4:  # Near water
		moisture = moisture * 0.5 + 0.5
	
	return clamp(moisture, 0.0, 1.0)

func _get_biome_at(height: float, temperature: float, moisture: float) -> String:
	"""
	Determine the biome based on height, temperature, and moisture
	
	Args:
		height: Terrain height (0-1)
		temperature: Temperature (0-1)
		moisture: Moisture (0-1)
		
	Returns:
		Biome name
	"""
	var best_biome = "plains"
	var best_score = 0.0
	
	for biome in biomes:
		var score = _calculate_biome_score(biome, height, temperature, moisture)
		if score > best_score:
			best_score = score
			best_biome = biome.name
	
	return best_biome

func _calculate_biome_score(biome: Dictionary, height: float, temperature: float, moisture: float) -> float:
	"""
	Calculate how well a biome matches the given conditions
	
	Args:
		biome: Biome configuration
		height: Terrain height
		temperature: Temperature
		moisture: Moisture
		
	Returns:
		Biome match score (0-1)
	"""
	var height_score = _calculate_range_score(height, biome.height_range)
	var temperature_score = _calculate_range_score(temperature, biome.temperature_range)
	var moisture_score = _calculate_range_score(moisture, biome.moisture_range)
	
	return (height_score + temperature_score + moisture_score) / 3.0

func _calculate_range_score(value: float, range_array: Array) -> float:
	"""
	Calculate how well a value fits within a range
	
	Args:
		value: Value to check
		range_array: Array with [min, max] values
		
	Returns:
		Range fit score (0-1)
	"""
	if range_array.size() < 2:
		return 0.0
	
	var min_val = range_array[0]
	var max_val = range_array[1]
	
	if value < min_val or value > max_val:
		return 0.0
	
	# Calculate how centered the value is within the range
	var range_center = (min_val + max_val) / 2.0
	var range_width = max_val - min_val
	var distance_from_center = abs(value - range_center)
	
	return 1.0 - (distance_from_center / (range_width / 2.0))

func _get_tile_type_at(x: float, y: float, height: float, biome: String) -> String:
	"""
	Get the tile type at the specified world coordinates
	
	Args:
		x: World X coordinate
		y: World Y coordinate
		height: Terrain height
		biome: Biome type
		
	Returns:
		Tile type name
	"""
	# Base tile type on biome
	var tile_type = "grass"  # Default
	
	match biome:
		"ocean":
			tile_type = "water"
		"beach":
			tile_type = "sand"
		"plains":
			tile_type = "grass"
		"forest":
			tile_type = "grass"  # Could be forest floor
		"desert":
			tile_type = "sand"
		"mountains":
			tile_type = "stone"
		"snow":
			tile_type = "snow"
	
	# Add cave generation
	if height > 0.3:  # Only generate caves above water level
		var cave_value = cave_noise.get_noise_2d(x, y)
		if cave_value > 0.7:
			tile_type = "cave"
	
	return tile_type

func _generate_structures_for_chunk(chunk_data: Dictionary) -> void:
	"""
	Generate structures for a chunk
	
	Args:
		chunk_data: Chunk data to add structures to
	"""
	var chunk_world_pos = Vector2(chunk_data.position.x * chunk_size, chunk_data.position.y * chunk_size)
	
	# Check for structure placement
	for x in range(0, chunk_size, 8):  # Check every 8 tiles
		for y in range(0, chunk_size, 8):
			var world_x = chunk_world_pos.x + x
			var world_y = chunk_world_pos.y + y
			
			var structure_value = structure_noise.get_noise_2d(world_x, world_y)
			if structure_value > 0.8:
				var structure = _generate_structure_at(world_x, world_y)
				if structure:
					chunk_data.structures.append(structure)

func _generate_structure_at(x: float, y: float) -> Dictionary:
	"""
	Generate a structure at the specified world coordinates
	
	Args:
		x: World X coordinate
		y: World Y coordinate
		
	Returns:
		Structure data dictionary
	"""
	var height = _get_height_at(x, y)
	var biome = _get_biome_at(height, _get_temperature_at(x, y), _get_moisture_at(x, y))
	
	# Determine structure type based on biome and height
	var structure_type = "house"  # Default
	
	if biome == "forest":
		structure_type = "tree"
	elif biome == "mountains":
		structure_type = "cave_entrance"
	elif biome == "desert":
		structure_type = "cactus"
	
	return {
		"type": structure_type,
		"position": Vector2(x, y),
		"biome": biome,
		"height": height
	}

func _generate_resources_for_chunk(chunk_data: Dictionary) -> void:
	"""
	Generate resources for a chunk
	
	Args:
		chunk_data: Chunk data to add resources to
	"""
	var chunk_world_pos = Vector2(chunk_data.position.x * chunk_size, chunk_data.position.y * chunk_size)
	
	# Generate resources based on biome and height
	for x in range(0, chunk_size, 4):  # Check every 4 tiles
		for y in range(0, chunk_size, 4):
			var world_x = chunk_world_pos.x + x
			var world_y = chunk_world_pos.y + y
			var tile_pos = Vector2i(x, y)
			
			var biome = chunk_data.biomes.get(tile_pos, "plains")
			var height = chunk_data.height_map.get(tile_pos, 0.5)
			
			var resource = _generate_resource_at(world_x, world_y, biome, height)
			if resource:
				chunk_data.resources.append(resource)

func _generate_resource_at(x: float, y: float, biome: String, height: float) -> Dictionary:
	"""
	Generate a resource at the specified world coordinates
	
	Args:
		x: World X coordinate
		y: World Y coordinate
		biome: Biome type
		height: Terrain height
		
	Returns:
		Resource data dictionary
	"""
	var resource_type = ""
	var resource_chance = 0.0
	
	match biome:
		"forest":
			resource_type = "wood"
			resource_chance = 0.1
		"mountains":
			resource_type = "ore"
			resource_chance = 0.05
		"desert":
			resource_type = "crystal"
			resource_chance = 0.03
		"plains":
			resource_type = "herb"
			resource_chance = 0.08
	
	# Check if resource should be generated
	if randf() < resource_chance:
		return {
			"type": resource_type,
			"position": Vector2(x, y),
			"biome": biome,
			"quantity": randi_range(1, 5)
		}
	
	return {}

func _get_chunk_from_pool() -> Node:
	"""
	Get a chunk from the object pool
	
	Returns:
		Chunk node or null if pool is empty
	"""
	if chunk_pool.size() > 0:
		return chunk_pool.pop_back()
	return null

func _return_chunk_to_pool(chunk: Node) -> void:
	"""
	Return a chunk to the object pool
	
	Args:
		chunk: Chunk node to return to pool
	"""
	if chunk_pool.size() < max_pool_size:
		chunk.visible = false
		chunk_pool.append(chunk)

func update_chunks(player_position: Vector2) -> void:
	"""
	Update active chunks based on player position
	
	Args:
		player_position: Current player position
	"""
	var start_time = Time.get_time_dict_from_system()
	
	var player_chunk = Vector2i(floor(player_position.x / chunk_size), floor(player_position.y / chunk_size))
	
	# Remove chunks that are too far away
	var chunks_to_remove: Array[Vector2i] = []
	for chunk_pos in active_chunks:
		var distance = chunk_pos.distance_to(player_chunk)
		if distance > render_distance:
			chunks_to_remove.append(chunk_pos)
	
	for chunk_pos in chunks_to_remove:
		var chunk = active_chunks[chunk_pos]
		_return_chunk_to_pool(chunk)
		active_chunks.erase(chunk_pos)
		chunk_removed.emit(chunk_pos)
	
	# Generate new chunks around player
	for x in range(player_chunk.x - render_distance, player_chunk.x + render_distance + 1):
		for y in range(player_chunk.y - render_distance, player_chunk.y + render_distance + 1):
			var chunk_pos = Vector2i(x, y)
			if not active_chunks.has(chunk_pos):
				generate_chunk(chunk_pos)
	
	chunk_update_time = Time.get_time_dict_from_system() - start_time

func _update_chunk_management(delta: float) -> void:
	"""
	Update chunk management systems
	"""
	# Update chunk loading based on player position
	if GameManager and GameManager.player:
		var player_pos = GameManager.player.position
		update_chunks(player_pos)

func _update_performance_tracking(delta: float) -> void:
	"""
	Update performance tracking metrics
	"""
	memory_usage = OS.get_static_memory_usage()

func get_biome_at_position(world_position: Vector2) -> String:
	"""
	Get the biome at a specific world position
	
	Args:
		world_position: World position to check
		
	Returns:
		Biome name at the position
	"""
	var height = _get_height_at(world_position.x, world_position.y)
	var temperature = _get_temperature_at(world_position.x, world_position.y)
	var moisture = _get_moisture_at(world_position.x, world_position.y)
	
	return _get_biome_at(height, temperature, moisture)

func get_height_at_position(world_position: Vector2) -> float:
	"""
	Get the height at a specific world position
	
	Args:
		world_position: World position to check
		
	Returns:
		Height value at the position
	"""
	return _get_height_at(world_position.x, world_position.y)

func get_world_data() -> Dictionary:
	"""
	Get comprehensive world data
	
	Returns:
		Dictionary containing world information
	"""
	return {
		"seed": world_seed,
		"name": world_name,
		"size": world_size,
		"chunk_size": chunk_size,
		"active_chunks": active_chunks.size(),
		"structures": structures.size(),
		"resources": resources.size(),
		"generation_progress": generation_progress,
		"is_generating": is_generating
	}

func get_performance_data() -> Dictionary:
	"""
	Get performance data for the world generator
	
	Returns:
		Dictionary containing performance metrics
	"""
	return {
		"active_chunks": active_chunks.size(),
		"chunk_pool_size": chunk_pool.size(),
		"chunk_generation_time": chunk_generation_time,
		"chunk_update_time": chunk_update_time,
		"memory_usage": memory_usage
	}

func _on_game_state_changed(new_state: GameManager.GameState, old_state: GameManager.GameState) -> void:
	"""
	Handle game state changes
	"""
	match new_state:
		GameManager.GameState.PLAYING:
			# Start chunk management when playing
			pass
		GameManager.GameState.PAUSED:
			# Pause chunk updates when paused
			pass 