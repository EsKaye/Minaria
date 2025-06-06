extends Node2D

# Chunk properties
var chunk_x: int
var chunk_y: int
var world_generator: Node2D
var tiles = {}

# Tile properties
@export var tile_size = 16
@export var tile_scene = preload("res://scenes/world/tile.tscn")

func initialize(x: int, y: int, generator: Node2D):
	"""
	Initialize the chunk with its position and world generator reference
	"""
	chunk_x = x
	chunk_y = y
	world_generator = generator
	generate_tiles()

func generate_tiles():
	"""
	Generate the tiles for this chunk
	"""
	for x in range(world_generator.chunk_size):
		for y in range(world_generator.chunk_size):
			var world_x = chunk_x * world_generator.chunk_size + x
			var world_y = chunk_y * world_generator.chunk_size + y
			
			# Get height and biome information
			var height = world_generator.get_height_at(world_x, world_y)
			var biome = world_generator.get_biome_at(world_x, world_y)
			var detail = world_generator.get_detail_at(world_x, world_y)
			
			# Create tile
			var tile = tile_scene.instantiate()
			tile.position = Vector2(x * tile_size, y * tile_size)
			tile.initialize(height, biome, detail)
			add_child(tile)
			
			# Store tile reference
			tiles[Vector2(x, y)] = tile

func update_tiles():
	"""
	Update the visual state of all tiles in the chunk
	"""
	for tile in tiles.values():
		tile.update_visuals()

func get_tile_at(x: int, y: int) -> Node2D:
	"""
	Get the tile at the specified local coordinates
	"""
	return tiles.get(Vector2(x, y))

func get_world_position() -> Vector2:
	"""
	Get the world position of this chunk
	"""
	return Vector2(chunk_x * world_generator.chunk_size, chunk_y * world_generator.chunk_size)

func get_center_position() -> Vector2:
	"""
	Get the center position of this chunk in world coordinates
	"""
	var half_size = world_generator.chunk_size / 2
	return get_world_position() + Vector2(half_size, half_size)

func is_position_in_chunk(world_pos: Vector2) -> bool:
	"""
	Check if a world position is within this chunk
	"""
	var chunk_pos = get_world_position()
	var chunk_end = chunk_pos + Vector2(world_generator.chunk_size, world_generator.chunk_size)
	
	return world_pos.x >= chunk_pos.x and world_pos.x < chunk_end.x and \
		   world_pos.y >= chunk_pos.y and world_pos.y < chunk_end.y

func get_local_position(world_pos: Vector2) -> Vector2:
	"""
	Convert a world position to local chunk coordinates
	"""
	return world_pos - get_world_position()

func _ready():
	# Initialize any additional chunk properties
	pass

func _process(_delta):
	# Update chunk state if needed
	pass 