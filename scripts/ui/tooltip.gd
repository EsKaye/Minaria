extends Control

# UI references
@onready var panel = $Panel
@onready var title = $Panel/VBoxContainer/Title
@onready var description = $Panel/VBoxContainer/Description
@onready var stats = $Panel/VBoxContainer/Stats

# Tooltip state
var target_position = Vector2.ZERO
var margin = 10
var is_visible = false

func _ready():
	# Hide tooltip initially
	hide()

func show_tooltip(data: Dictionary, position: Vector2):
	"""
	Show tooltip with given data at position
	"""
	# Set content
	title.text = data.get("name", "")
	description.text = data.get("description", "")
	
	# Clear and update stats
	for child in stats.get_children():
		child.queue_free()
		
	if data.has("stats"):
		for stat in data.stats:
			var label = Label.new()
			label.text = stat + ": " + str(data.stats[stat])
			stats.add_child(label)
	
	# Update position
	target_position = position
	update_position()
	
	# Show tooltip
	show()
	is_visible = true

func hide_tooltip():
	"""
	Hide the tooltip
	"""
	hide()
	is_visible = false

func update_position():
	"""
	Update tooltip position based on target and screen bounds
	"""
	var viewport_size = get_viewport_rect().size
	var tooltip_size = panel.size
	
	# Calculate base position
	var pos = target_position + Vector2(margin, margin)
	
	# Adjust if tooltip would go off screen
	if pos.x + tooltip_size.x > viewport_size.x:
		pos.x = target_position.x - tooltip_size.x - margin
		
	if pos.y + tooltip_size.y > viewport_size.y:
		pos.y = target_position.y - tooltip_size.y - margin
	
	# Set position
	position = pos

func _process(_delta):
	"""
	Update tooltip position if visible
	"""
	if is_visible:
		update_position()

func _input(event):
	"""
	Handle input events
	"""
	if event is InputEventMouseMotion:
		# Update target position to follow mouse
		target_position = event.position 