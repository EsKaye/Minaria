extends Panel

# UI references
@onready var title: Label = $VBoxContainer/Title
@onready var message: Label = $VBoxContainer/Message

# Colors for different notification types
const COLORS = {
	"INFO": Color(0.2, 0.6, 1.0, 0.9),
	"SUCCESS": Color(0.2, 0.8, 0.2, 0.9),
	"WARNING": Color(1.0, 0.8, 0.2, 0.9),
	"ERROR": Color(1.0, 0.2, 0.2, 0.9)
}

# Titles for different notification types
const TITLES = {
	"INFO": "Information",
	"SUCCESS": "Success",
	"WARNING": "Warning",
	"ERROR": "Error"
}

func _ready():
	# Set default style
	theme_override_styles/panel = StyleBoxFlat.new()
	var style = theme_override_styles/panel as StyleBoxFlat
	style.bg_color = COLORS["INFO"]
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

func set_message(text: String):
	"""
	Set the notification message
	"""
	message.text = text

func set_type(type: int):
	"""
	Set the notification type and update appearance
	"""
	var type_name = ""
	match type:
		0: type_name = "INFO"
		1: type_name = "SUCCESS"
		2: type_name = "WARNING"
		3: type_name = "ERROR"
	
	# Update title and color
	title.text = TITLES[type_name]
	var style = theme_override_styles/panel as StyleBoxFlat
	style.bg_color = COLORS[type_name] 