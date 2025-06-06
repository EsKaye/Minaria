extends Panel

# Item slot properties
var slot_index: int = -1
var item: Dictionary = {}
var item_count: int = 0

# UI references
@onready var item_icon = $ItemIcon
@onready var item_count_label = $ItemCount

# Signals
signal item_selected(slot: Node)
signal item_dragged(slot: Node, event: InputEvent)

func _ready():
	# Connect input events
	gui_input.connect(_on_gui_input)

func set_item(item_name: String, count: int = 1):
	"""
	Set the item in this slot
	"""
	if item_name.is_empty():
		clear_slot()
		return
		
	item = {
		"name": item_name,
		"count": count
	}
	item_count = count
	
	# TODO: Load item icon from resources
	# item_icon.texture = load("res://assets/items/" + item_name + ".png")
	
	update_display()

func clear_slot():
	"""
	Clear the slot
	"""
	item = {}
	item_count = 0
	item_icon.texture = null
	update_display()

func update_display():
	"""
	Update the slot display
	"""
	if item_count > 1:
		item_count_label.text = str(item_count)
		item_count_label.show()
	else:
		item_count_label.hide()

func _on_gui_input(event: InputEvent):
	"""
	Handle input events
	"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				item_selected.emit(self)
				
	item_dragged.emit(self, event)

func _get_drag_data(_position):
	"""
	Handle drag start
	"""
	if item.is_empty():
		return null
		
	var preview = TextureRect.new()
	preview.texture = item_icon.texture
	preview.custom_minimum_size = Vector2(32, 32)
	preview.expand_mode = TextureRect.EXPAND_FILL
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var control = Control.new()
	control.add_child(preview)
	preview.position = -preview.size / 2
	
	set_drag_preview(control)
	return item

func _can_drop_data(_position, data):
	"""
	Check if data can be dropped in this slot
	"""
	return data is Dictionary and data.has("name")

func _drop_data(_position, data):
	"""
	Handle drop data
	"""
	if data is Dictionary and data.has("name"):
		# TODO: Handle item swap logic
		pass 