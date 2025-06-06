extends Control

# UI references
@onready var map_texture: TextureRect = $Panel/MarginContainer/VBoxContainer/MapContainer/MapTexture
@onready var player_marker: ColorRect = $Panel/MarginContainer/VBoxContainer/MapContainer/PlayerMarker
@onready var scale_label: Label = $Panel/MarginContainer/VBoxContainer/ScaleLabel

# Map settings
var map_scale: float = 0.01  # 1:100 scale
var map_size: Vector2 = Vector2(1000, 1000)  # World size in units
var map_center: Vector2 = Vector2(500, 500)  # World center in units
var map_rotation: float = 0.0  # Map rotation in radians

# Player tracking
var player_position: Vector2 = Vector2.ZERO
var player_rotation: float = 0.0

# Map markers
var markers: Array[Dictionary] = []
var marker_scene: PackedScene = preload("res://scenes/ui/map_marker.tscn")

# Map texture
var map_image: Image
var map_viewport: SubViewport

func _ready():
	# Initialize map viewport
	map_viewport = SubViewport.new()
	map_viewport.size = Vector2(1000, 1000)
	map_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(map_viewport)
	
	# Create map image
	map_image = Image.create(1000, 1000, false, Image.FORMAT_RGBA8)
	map_image.fill(Color(0, 0, 0, 0))
	
	# Update map texture
	_update_map_texture()
	
	# Set initial scale
	_update_scale_label()

func _process(_delta):
	# Update player marker position
	_update_player_marker()
	
	# Update map rotation
	_update_map_rotation()

func set_player_position(position: Vector2, rotation: float = 0.0):
	"""
	Update player position and rotation
	"""
	player_position = position
	player_rotation = rotation

func add_marker(position: Vector2, type: String, color: Color = Color.WHITE):
	"""
	Add a marker to the map
	"""
	var marker_data = {
		"position": position,
		"type": type,
		"color": color
	}
	markers.append(marker_data)
	_update_markers()

func remove_marker(type: String):
	"""
	Remove all markers of the specified type
	"""
	markers = markers.filter(func(marker): return marker.type != type)
	_update_markers()

func clear_markers():
	"""
	Clear all markers
	"""
	markers.clear()
	_update_markers()

func set_map_scale(scale: float):
	"""
	Set the map scale
	"""
	map_scale = scale
	_update_scale_label()

func _update_map_texture():
	"""
	Update the map texture
	"""
	# Create a new image for the map
	var new_image = Image.create(1000, 1000, false, Image.FORMAT_RGBA8)
	new_image.fill(Color(0, 0, 0, 0))
	
	# Draw terrain and features
	_draw_terrain(new_image)
	_draw_features(new_image)
	
	# Update map image
	map_image = new_image
	
	# Create texture from image
	var texture = ImageTexture.create_from_image(map_image)
	map_texture.texture = texture

func _draw_terrain(image: Image):
	"""
	Draw terrain on the map
	"""
	# TODO: Implement terrain drawing based on world data
	pass

func _draw_features(image: Image):
	"""
	Draw features on the map
	"""
	# TODO: Implement feature drawing based on world data
	pass

func _update_player_marker():
	"""
	Update player marker position and rotation
	"""
	# Calculate marker position
	var map_pos = (player_position - map_center) * map_scale
	var marker_pos = Vector2(100, 100) + map_pos
	
	# Update marker position
	player_marker.position = marker_pos
	
	# Update marker rotation
	player_marker.rotation = player_rotation

func _update_map_rotation():
	"""
	Update map rotation
	"""
	map_texture.rotation = map_rotation

func _update_markers():
	"""
	Update map markers
	"""
	# Clear existing markers
	for child in map_texture.get_children():
		if child != player_marker:
			child.queue_free()
	
	# Add new markers
	for marker_data in markers:
		var marker = marker_scene.instantiate()
		marker.position = (marker_data.position - map_center) * map_scale
		marker.set_type(marker_data.type)
		marker.set_color(marker_data.color)
		map_texture.add_child(marker)

func _update_scale_label():
	"""
	Update the scale label
	"""
	var scale_text = "Scale: 1:%d" % int(1.0 / map_scale)
	scale_label.text = scale_text 