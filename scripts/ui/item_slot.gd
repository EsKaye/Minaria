extends TextureRect

# UI references
@onready var item_icon: TextureRect = $ItemIcon
@onready var stack_label: Label = $StackLabel

# Slot properties
var slot_index: int = -1
var slot_type: String = "inventory"
var current_item: Dictionary = {}

# Signals
signal item_clicked(item: Dictionary, slot: int, slot_type: String)
signal item_dragged(item: Dictionary, slot: int, slot_type: String)
signal item_dropped(slot: int, slot_type: String)

func _ready() -> void:
	"""
	Initialize item slot
	"""
	# Connect input events
	gui_input.connect(_on_gui_input)
	
	# Clear slot
	clear_item()

func _on_gui_input(event: InputEvent) -> void:
	"""
	Handle input events
	"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start drag
				if current_item.has("id") and current_item["id"] != "":
					emit_signal("item_dragged", current_item, slot_index, slot_type)
			else:
				# End drag
				emit_signal("item_dropped", slot_index, slot_type)
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Right click
			if current_item.has("id") and current_item["id"] != "":
				emit_signal("item_clicked", current_item, slot_index, slot_type)

func set_item(item: Dictionary) -> void:
	"""
	Set item in slot
	"""
	current_item = item
	
	if item.has("id") and item["id"] != "":
		# Set item icon
		if item.has("icon"):
			item_icon.texture = item["icon"]
			item_icon.show()
		else:
			item_icon.texture = null
			item_icon.hide()
		
		# Set stack count
		if item.has("stackable") and item["stackable"] and item.has("stack_size"):
			stack_label.text = str(item["stack_size"])
			stack_label.show()
		else:
			stack_label.text = ""
			stack_label.hide()
	else:
		clear_item()

func clear_item() -> void:
	"""
	Clear slot
	"""
	current_item = {
		"id": "",
		"name": "",
		"description": "",
		"type": "",
		"stack_size": 0,
		"max_stack": 0,
		"stats": {},
		"icon": null
	}
	
	item_icon.texture = null
	stack_label.text = ""

func get_item() -> Dictionary:
	"""
	Get current item
	"""
	return current_item

func is_empty() -> bool:
	"""
	Check if slot is empty
	"""
	return current_item["id"] == "" 