extends Control

# UI references
@onready var save_slots: VBoxContainer = $Panel/MarginContainer/VBoxContainer/SaveSlots
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

# Save system reference
var save_system: Node

# Signals
signal save_completed(slot: int)
signal load_completed(slot: int)
signal menu_closed

func _ready():
	# Connect signals
	close_button.pressed.connect(_on_close_pressed)
	
	# Connect slot buttons
	for i in range(save_slots.get_child_count()):
		var slot = save_slots.get_child(i)
		var buttons = slot.get_node("MarginContainer/HBoxContainer/Buttons")
		
		buttons.get_node("SaveButton").pressed.connect(_on_save_pressed.bind(i))
		buttons.get_node("LoadButton").pressed.connect(_on_load_pressed.bind(i))
		buttons.get_node("DeleteButton").pressed.connect(_on_delete_pressed.bind(i))
	
	# Hide initially
	visible = false

func set_save_system(system: Node):
	"""
	Set the save system reference
	"""
	save_system = system
	
	# Connect save system signals
	save_system.save_completed.connect(_on_save_system_save_completed)
	save_system.load_completed.connect(_on_save_system_load_completed)
	save_system.save_failed.connect(_on_save_system_save_failed)
	save_system.load_failed.connect(_on_save_system_load_failed)

func show_save_load_menu():
	"""
	Show the save/load menu and update slot information
	"""
	visible = true
	_update_slot_info()

func _update_slot_info():
	"""
	Update information for all save slots
	"""
	if not save_system:
		return
	
	var slots = save_system.get_save_slots()
	
	for i in range(save_slots.get_child_count()):
		var slot = save_slots.get_child(i)
		var info = slot.get_node("MarginContainer/HBoxContainer/VBoxContainer/SlotInfo")
		var date = slot.get_node("MarginContainer/HBoxContainer/VBoxContainer/SaveDate")
		var buttons = slot.get_node("MarginContainer/HBoxContainer/Buttons")
		
		if i < slots.size() and not slots[i].is_empty():
			# Slot has save data
			info.text = "%s - Level %d %s" % [
				slots[i]["player_name"],
				slots[i]["player_level"],
				slots[i]["player_class"]
			]
			date.text = "Saved: %s" % slots[i]["save_date"]
			
			buttons.get_node("SaveButton").disabled = false
			buttons.get_node("LoadButton").disabled = false
			buttons.get_node("DeleteButton").disabled = false
		else:
			# Empty slot
			info.text = "Empty Slot"
			date.text = ""
			
			buttons.get_node("SaveButton").disabled = false
			buttons.get_node("LoadButton").disabled = true
			buttons.get_node("DeleteButton").disabled = true

func _on_save_pressed(slot: int):
	"""
	Handle save button press
	"""
	if save_system:
		save_system.save_game(slot)

func _on_load_pressed(slot: int):
	"""
	Handle load button press
	"""
	if save_system:
		save_system.load_game(slot)

func _on_delete_pressed(slot: int):
	"""
	Handle delete button press
	"""
	if save_system:
		save_system.delete_save(slot)
		_update_slot_info()

func _on_close_pressed():
	"""
	Handle close button press
	"""
	visible = false
	emit_signal("menu_closed")

func _on_save_system_save_completed(slot: int):
	"""
	Handle save completion
	"""
	_update_slot_info()
	emit_signal("save_completed", slot)

func _on_save_system_load_completed(slot: int):
	"""
	Handle load completion
	"""
	visible = false
	emit_signal("load_completed", slot)

func _on_save_system_save_failed(slot: int, error: String):
	"""
	Handle save failure
	"""
	# TODO: Show error message
	print("Save failed: ", error)

func _on_save_system_load_failed(slot: int, error: String):
	"""
	Handle load failure
	"""
	# TODO: Show error message
	print("Load failed: ", error) 