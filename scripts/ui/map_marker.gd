extends Control

# UI references
@onready var marker: ColorRect = $Marker
@onready var label: Label = $Label

# Marker properties
var marker_type: String = ""
var marker_color: Color = Color.WHITE

func _ready():
	# Set initial appearance
	_update_appearance()

func set_type(type: String):
	"""
	Set the marker type and update appearance
	"""
	marker_type = type
	label.text = type
	_update_appearance()

func set_color(color: Color):
	"""
	Set the marker color
	"""
	marker_color = color
	marker.color = color

func _update_appearance():
	"""
	Update marker appearance based on type
	"""
	match marker_type:
		"quest":
			marker.color = Color(1, 0.8, 0, 1)  # Gold
		"town":
			marker.color = Color(0, 0.8, 1, 1)  # Blue
		"dungeon":
			marker.color = Color(1, 0, 0, 1)  # Red
		"resource":
			marker.color = Color(0, 1, 0, 1)  # Green
		_:
			marker.color = marker_color 