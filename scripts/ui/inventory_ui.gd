extends Control

# UI references
@onready var weapon_slot: TextureRect = $Panel/MarginContainer/VBoxContainer/HBoxContainer/EquipmentPanel/VBoxContainer/WeaponSlot
@onready var armor_slot: TextureRect = $Panel/MarginContainer/VBoxContainer/HBoxContainer/EquipmentPanel/VBoxContainer/ArmorSlot
@onready var accessory_slot: TextureRect = $Panel/MarginContainer/VBoxContainer/HBoxContainer/EquipmentPanel/VBoxContainer/AccessorySlot
@onready var inventory_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/InventoryPanel/GridContainer
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

# Inventory reference
var inventory: Node

# Item slot scene
var item_slot_scene: PackedScene

# Dragging state
var is_dragging: bool = false
var dragged_item: Dictionary
var dragged_slot: int = -1
var dragged_slot_type: String = ""

# Signals
signal item_clicked(item: Dictionary, slot: int, slot_type: String)
signal item_dragged(item: Dictionary, from_slot: int, from_type: String, to_slot: int, to_type: String)
signal item_dropped(item: Dictionary, slot: int, slot_type: String)

func _ready() -> void:
	"""
	Initialize inventory UI
	"""
	# Load item slot scene
	item_slot_scene = preload("res://scenes/ui/item_slot.tscn")
	
	# Connect signals
	close_button.pressed.connect(_on_close_pressed)
	
	# Create inventory slots
	_create_inventory_slots()
	
	# Hide by default
	hide()

func _create_inventory_slots() -> void:
	"""
	Create inventory slot UI elements
	"""
	# Clear existing slots
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# Create new slots
	for i in range(inventory.max_slots):
		var slot = item_slot_scene.instantiate()
		slot.slot_index = i
		slot.slot_type = "inventory"
		slot.item_clicked.connect(_on_item_slot_clicked)
		slot.item_dragged.connect(_on_item_slot_dragged)
		slot.item_dropped.connect(_on_item_slot_dropped)
		inventory_grid.add_child(slot)

func _update_equipment_slots() -> void:
	"""
	Update equipment slot displays
	"""
	# Update weapon slot
	var weapon = inventory.get_equipped_item("weapon")
	if weapon != null:
		weapon_slot.texture = weapon["icon"]
	else:
		weapon_slot.texture = null
	
	# Update armor slot
	var armor = inventory.get_equipped_item("armor")
	if armor != null:
		armor_slot.texture = armor["icon"]
	else:
		armor_slot.texture = null
	
	# Update accessory slot
	var accessory = inventory.get_equipped_item("accessory")
	if accessory != null:
		accessory_slot.texture = accessory["icon"]
	else:
		accessory_slot.texture = null

func _update_inventory_slots() -> void:
	"""
	Update inventory slot displays
	"""
	for i in range(inventory.max_slots):
		var slot = inventory_grid.get_child(i)
		var item = inventory.get_item(i)
		
		if item["id"] != "":
			slot.set_item(item)
		else:
			slot.clear_item()

func _on_item_slot_clicked(item: Dictionary, slot: int, slot_type: String) -> void:
	"""
	Handle item slot click
	"""
	emit_signal("item_clicked", item, slot, slot_type)

func _on_item_slot_dragged(item: Dictionary, slot: int, slot_type: String) -> void:
	"""
	Handle item slot drag start
	"""
	is_dragging = true
	dragged_item = item
	dragged_slot = slot
	dragged_slot_type = slot_type
	
	emit_signal("item_dragged", item, slot, slot_type)

func _on_item_slot_dropped(slot: int, slot_type: String) -> void:
	"""
	Handle item slot drop
	"""
	if is_dragging:
		emit_signal("item_dropped", dragged_item, slot, slot_type)
		
		is_dragging = false
		dragged_item = {}
		dragged_slot = -1
		dragged_slot_type = ""

func _on_close_pressed() -> void:
	"""
	Handle close button press
	"""
	hide()

func show_inventory() -> void:
	"""
	Show inventory UI
	"""
	show()
	_update_equipment_slots()
	_update_inventory_slots()

func _on_inventory_changed() -> void:
	"""
	Handle inventory changes
	"""
	_update_equipment_slots()
	_update_inventory_slots()

func set_inventory(inv: Node) -> void:
	"""
	Set inventory reference
	"""
	inventory = inv
	inventory.inventory_changed.connect(_on_inventory_changed)
	
	# Update UI
	_update_equipment_slots()
	_update_inventory_slots() 