extends Control

# Inventory references
@onready var inventory_grid = $Panel/VBoxContainer/Content/InventoryGrid
@onready var tool_slot = $Panel/VBoxContainer/Content/EquipmentSlots/ToolSlot
@onready var armor_slot = $Panel/VBoxContainer/Content/EquipmentSlots/ArmorSlot
@onready var accessory_slot = $Panel/VBoxContainer/Content/EquipmentSlots/AccessorySlot
@onready var item_info = $Panel/VBoxContainer/Content/ItemInfo

# Item slot scene
var item_slot_scene = preload("res://scenes/ui/item_slot.tscn")

# Inventory state
var selected_slot = null
var dragged_item = null
var inventory_system = null

# UI signals
signal inventory_closed
signal item_selected(item: Dictionary)
signal item_dragged(item: Dictionary, from_slot: Node, to_slot: Node)
signal item_equipped(item: Dictionary, slot: String)
signal item_unequipped(item: Dictionary, slot: String)

func _ready():
	# Connect signals
	$Panel/VBoxContainer/Header/CloseButton.pressed.connect(_on_close_pressed)
	
	# Initialize inventory grid
	initialize_inventory_grid()
	
	# Initialize equipment slots
	initialize_equipment_slots()

func initialize_inventory_grid():
	"""
	Initialize the inventory grid with empty slots
	"""
	for i in range(20):  # 20 inventory slots
		var slot = item_slot_scene.instantiate()
		slot.slot_index = i
		slot.item_selected.connect(_on_item_slot_selected)
		slot.item_dragged.connect(_on_item_slot_dragged)
		inventory_grid.add_child(slot)

func initialize_equipment_slots():
	"""
	Initialize the equipment slots
	"""
	tool_slot.gui_input.connect(_on_equipment_slot_gui_input.bind("tool"))
	armor_slot.gui_input.connect(_on_equipment_slot_gui_input.bind("armor"))
	accessory_slot.gui_input.connect(_on_equipment_slot_gui_input.bind("accessory"))

func set_inventory_system(system):
	"""
	Set the inventory system reference and connect signals
	"""
	inventory_system = system
	inventory_system.inventory_changed.connect(_on_inventory_changed)
	update_inventory_display()

func update_inventory_display():
	"""
	Update the inventory display with current items
	"""
	if !inventory_system:
		return
		
	# Update inventory grid
	var items = inventory_system.get_inventory_contents()
	for slot in inventory_grid.get_children():
		var item_name = items.keys()[slot.slot_index] if slot.slot_index < items.size() else ""
		slot.set_item(item_name, items.get(item_name, 0))
		
	# Update equipment slots
	var equipped = inventory_system.get_equipped_items()
	tool_slot.set_item(equipped.get("tool", null))
	armor_slot.set_item(equipped.get("armor", null))
	accessory_slot.set_item(equipped.get("accessory", null))

func show_item_info(item: Dictionary):
	"""
	Show item information in the info panel
	"""
	if !item:
		item_info.hide()
		return
		
	item_info.show()
	$Panel/VBoxContainer/Content/ItemInfo/VBoxContainer/ItemName.text = item.name
	$Panel/VBoxContainer/Content/ItemInfo/VBoxContainer/ItemDescription.text = item.description
	
	# Update stats
	var stats = $Panel/VBoxContainer/Content/ItemInfo/VBoxContainer/ItemStats
	for child in stats.get_children():
		child.queue_free()
		
	for stat in item.stats:
		var label = Label.new()
		label.text = stat + ": " + str(item.stats[stat])
		stats.add_child(label)

func _on_close_pressed():
	"""
	Handle close button press
	"""
	inventory_closed.emit()
	queue_free()

func _on_item_slot_selected(slot: Node):
	"""
	Handle item slot selection
	"""
	selected_slot = slot
	show_item_info(slot.item)

func _on_item_slot_dragged(slot: Node, event: InputEvent):
	"""
	Handle item slot drag
	"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragged_item = slot.item
			else:
				dragged_item = null
				
	if event is InputEventMouseMotion and dragged_item:
		# Update drag preview
		pass

func _on_equipment_slot_gui_input(event: InputEvent, slot_type: String):
	"""
	Handle equipment slot interaction
	"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if dragged_item:
				# Try to equip dragged item
				if inventory_system.equip_item(slot_type, dragged_item.name):
					item_equipped.emit(dragged_item, slot_type)
			else:
				# Try to unequip current item
				var current_item = inventory_system.get_equipped_items()[slot_type]
				if current_item and inventory_system.unequip_item(slot_type):
					item_unequipped.emit(current_item, slot_type)

func _on_inventory_changed():
	"""
	Handle inventory changes
	"""
	update_inventory_display()

func _input(event):
	"""
	Handle input events
	"""
	if event.is_action_pressed("inventory"):
		_on_close_pressed() 