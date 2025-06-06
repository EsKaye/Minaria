extends Node2D

# World generation parameters
@export var chunk_size = 16
@export var world_width = 100
@export var world_height = 100
@export var seed_value = 0

# Biome parameters
@export var biome_scale = 50.0
@export var biome_blend = 0.5

# Noise generators
var height_noise: FastNoiseLite
var biome_noise: FastNoiseLite
var detail_noise: FastNoiseLite

# Chunk management
var active_chunks = {}
var chunk_scene = preload("res://scenes/world/chunk.tscn")

func _ready():
	initialize_noise()
	generate_initial_chunks()

func initialize_noise():
	"""
	Initialize noise generators for terrain and biome generation
	"""
	# Height map noise
	height_noise = FastNoiseLite.new()
	height_noise.seed = seed_value
	height_noise.frequency = 0.01
	
	# Biome noise
	biome_noise = FastNoiseLite.new()
	biome_noise.seed = seed_value + 1
	biome_noise.frequency = 0.005
	
	# Detail noise
	detail_noise = FastNoiseLite.new()
	detail_noise.seed = seed_value + 2
	detail_noise.frequency = 0.05

func generate_initial_chunks():
	"""
	Generate the initial set of chunks around the player
	"""
	var center_x = world_width / 2
	var center_y = world_height / 2
	
	for x in range(center_x - 2, center_x + 3):
		for y in range(center_y - 2, center_y + 3):
			generate_chunk(x, y)

func generate_chunk(chunk_x: int, chunk_y: int):
	"""
	Generate a single chunk at the specified coordinates
	"""
	var chunk_key = Vector2(chunk_x, chunk_y)
	if active_chunks.has(chunk_key):
		return
		
	var chunk = chunk_scene.instantiate()
	chunk.position = Vector2(chunk_x * chunk_size, chunk_y * chunk_size)
	chunk.initialize(chunk_x, chunk_y, self)
	add_child(chunk)
	active_chunks[chunk_key] = chunk

func get_height_at(x: float, y: float) -> float:
	"""
	Get the terrain height at the specified world coordinates
	"""
	var height = height_noise.get_noise_2d(x, y)
	height = (height + 1) / 2  # Normalize to 0-1
	return height * world_height

func get_biome_at(x: float, y: float) -> String:
	"""
	Get the biome type at the specified world coordinates
	"""
	var biome_value = biome_noise.get_noise_2d(x, y)
	biome_value = (biome_value + 1) / 2  # Normalize to 0-1
	
	if biome_value < 0.3:
		return "forest"
	elif biome_value < 0.6:
		return "plains"
	else:
		return "mountains"

func get_detail_at(x: float, y: float) -> float:
	"""
	Get the detail noise value at the specified world coordinates
	"""
	return detail_noise.get_noise_2d(x, y)

func update_chunks(player_position: Vector2):
	"""
	Update active chunks based on player position
	"""
	var player_chunk_x = floor(player_position.x / chunk_size)
	var player_chunk_y = floor(player_position.y / chunk_size)
	
	# Remove chunks that are too far away
	var chunks_to_remove = []
	for chunk_key in active_chunks:
		var distance = Vector2(chunk_key).distance_to(Vector2(player_chunk_x, player_chunk_y))
		if distance > 4:  # Keep chunks within 4 chunks of player
			chunks_to_remove.append(chunk_key)
	
	for chunk_key in chunks_to_remove:
		var chunk = active_chunks[chunk_key]
		chunk.queue_free()
		active_chunks.erase(chunk_key)
	
	# Generate new chunks around player
	for x in range(player_chunk_x - 3, player_chunk_x + 4):
		for y in range(player_chunk_y - 3, player_chunk_y + 4):
			generate_chunk(x, y) 