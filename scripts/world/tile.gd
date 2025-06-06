extends Node2D

# Tile properties
var height: float
var biome: String
var detail: float
var is_solid: bool = true
var is_interactable: bool = false

# Visual properties
@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D
@export var interaction_area: Area2D

# Biome-specific properties
var biome_properties = {
	"forest": {
		"color": Color(0.2, 0.6, 0.2),
		"texture": preload("res://assets/sprites/tiles/forest.png"),
		"resources": ["wood", "berries", "mushrooms"]
	},
	"plains": {
		"color": Color(0.4, 0.8, 0.4),
		"texture": preload("res://assets/sprites/tiles/plains.png"),
		"resources": ["grass", "flowers", "stones"]
	},
	"mountains": {
		"color": Color(0.6, 0.6, 0.6),
		"texture": preload("res://assets/sprites/tiles/mountains.png"),
		"resources": ["stone", "iron", "crystals"]
	}
}

func initialize(h: float, b: String, d: float):
	"""
	Initialize the tile with its properties
	"""
	height = h
	biome = b
	detail = d
	update_visuals()
	setup_collision()
	setup_interaction()

func update_visuals():
	"""
	Update the visual appearance of the tile based on its properties
	"""
	if sprite:
		var properties = biome_properties.get(biome, biome_properties["plains"])
		sprite.texture = properties.texture
		sprite.modulate = properties.color
		
		# Apply height-based shading
		var height_factor = (height + 1) / 2  # Normalize to 0-1
		sprite.modulate = sprite.modulate.darkened(height_factor)
		
		# Apply detail-based variation
		var detail_factor = (detail + 1) / 2  # Normalize to 0-1
		sprite.modulate = sprite.modulate.lightened(detail_factor * 0.2)

func setup_collision():
	"""
	Set up the collision properties of the tile
	"""
	if collision_shape:
		# Set collision based on height and biome
		is_solid = height > 0.5  # Example threshold
		collision_shape.disabled = !is_solid

func setup_interaction():
	"""
	Set up the interaction properties of the tile
	"""
	if interaction_area:
		# Set interaction based on biome and resources
		var properties = biome_properties.get(biome, biome_properties["plains"])
		is_interactable = properties.resources.size() > 0
		interaction_area.monitoring = is_interactable
		interaction_area.monitorable = is_interactable

func get_resources() -> Array:
	"""
	Get the available resources for this tile
	"""
	var properties = biome_properties.get(biome, biome_properties["plains"])
	return properties.resources

func interact() -> Dictionary:
	"""
	Handle interaction with the tile
	Returns a dictionary of gathered resources
	"""
	if !is_interactable:
		return {}
		
	var resources = {}
	var properties = biome_properties.get(biome, biome_properties["plains"])
	
	# Randomly select resources based on biome
	for resource in properties.resources:
		if randf() < 0.3:  # 30% chance for each resource
			resources[resource] = randi() % 3 + 1  # 1-3 of each resource
			
	return resources

func _ready():
	# Initialize any additional tile properties
	pass

func _process(_delta):
	# Update tile state if needed
	pass 