extends Panel

# Recipe slot properties
var slot_index: int = -1
var item: Dictionary = {}
var item_count: int = 0

# UI references
@onready var item_icon = $ItemIcon
@onready var item_count_label = $ItemCount

func _ready():
	# Initialize empty slot
	clear_slot()

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