extends Node

# Inventory properties
@export var max_slots: int = 20
@export var max_stack_size: int = 99

# Inventory data
var items: Array[Dictionary] = []
var equipped_items: Dictionary = {
	"weapon": null,
	"armor": null,
	"accessory": null
}

# Signals
signal item_added(item: Dictionary, slot: int)
signal item_removed(slot: int)
signal item_used(item: Dictionary, slot: int)
signal item_equipped(slot: String, item: Dictionary)
signal item_unequipped(slot: String, item: Dictionary)
signal inventory_changed

func _ready() -> void:
	"""
	Initialize inventory
	"""
	# Initialize empty inventory
	for i in range(max_slots):
		items.append({
			"id": "",
			"name": "",
			"description": "",
			"type": "",
			"stack_size": 0,
			"max_stack": max_stack_size,
			"stats": {},
			"icon": null
		})

func add_item(item_data: Dictionary) -> bool:
	"""
	Add an item to the inventory
	Returns true if successful, false if inventory is full
	"""
	# Check if item can be stacked
	if item_data.has("stackable") and item_data["stackable"]:
		# Try to find existing stack
		for i in range(items.size()):
			if items[i]["id"] == item_data["id"] and items[i]["stack_size"] < max_stack_size:
				# Add to existing stack
				items[i]["stack_size"] += 1
				emit_signal("item_added", items[i], i)
				emit_signal("inventory_changed")
				return true
	
	# Find empty slot
	for i in range(items.size()):
		if items[i]["id"] == "":
			# Add to empty slot
			items[i] = item_data.duplicate()
			if items[i].has("stackable") and items[i]["stackable"]:
				items[i]["stack_size"] = 1
			emit_signal("item_added", items[i], i)
			emit_signal("inventory_changed")
			return true
	
	return false

func remove_item(slot: int) -> Dictionary:
	"""
	Remove an item from the inventory
	Returns the removed item data
	"""
	if slot < 0 or slot >= items.size():
		return {}
	
	var item = items[slot].duplicate()
	items[slot] = {
		"id": "",
		"name": "",
		"description": "",
		"type": "",
		"stack_size": 0,
		"max_stack": max_stack_size,
		"stats": {},
		"icon": null
	}
	
	emit_signal("item_removed", slot)
	emit_signal("inventory_changed")
	return item

func use_item(slot: int) -> bool:
	"""
	Use an item from the inventory
	Returns true if item was used successfully
	"""
	if slot < 0 or slot >= items.size():
		return false
	
	var item = items[slot]
	if item["id"] == "":
		return false
	
	# Handle different item types
	match item["type"]:
		"consumable":
			# Use consumable item
			if _use_consumable(item):
				if item.has("stackable") and item["stackable"]:
					item["stack_size"] -= 1
					if item["stack_size"] <= 0:
						remove_item(slot)
				else:
					remove_item(slot)
				emit_signal("item_used", item, slot)
				return true
		"equipment":
			# Equip item
			if _equip_item(item):
				remove_item(slot)
				emit_signal("item_used", item, slot)
				return true
		"quest":
			# Handle quest item
			if _use_quest_item(item):
				emit_signal("item_used", item, slot)
				return true
	
	return false

func _use_consumable(item: Dictionary) -> bool:
	"""
	Use a consumable item
	Returns true if item was used successfully
	"""
	# TODO: Implement consumable item effects
	return true

func _equip_item(item: Dictionary) -> bool:
	"""
	Equip an item
	Returns true if item was equipped successfully
	"""
	var slot = item.get("equip_slot", "")
	if slot == "" or not equipped_items.has(slot):
		return false
	
	# Unequip current item if any
	if equipped_items[slot] != null:
		unequip_item(slot)
	
	# Equip new item
	equipped_items[slot] = item
	emit_signal("item_equipped", slot, item)
	return true

func unequip_item(slot: String) -> bool:
	"""
	Unequip an item
	Returns true if item was unequipped successfully
	"""
	if not equipped_items.has(slot) or equipped_items[slot] == null:
		return false
	
	var item = equipped_items[slot]
	equipped_items[slot] = null
	
	# Try to add item back to inventory
	if add_item(item):
		emit_signal("item_unequipped", slot, item)
		return true
	
	return false

func _use_quest_item(item: Dictionary) -> bool:
	"""
	Use a quest item
	Returns true if item was used successfully
	"""
	# TODO: Implement quest item handling
	return true

func get_item(slot: int) -> Dictionary:
	"""
	Get item data from a slot
	"""
	if slot < 0 or slot >= items.size():
		return {}
	return items[slot]

func is_slot_empty(slot: int) -> bool:
	"""
	Check if a slot is empty
	"""
	if slot < 0 or slot >= items.size():
		return true
	return items[slot]["id"] == ""

func get_equipped_item(slot: String) -> Dictionary:
	"""
	Get equipped item data
	"""
	if not equipped_items.has(slot):
		return {}
	return equipped_items[slot] if equipped_items[slot] != null else {}

func clear_inventory() -> void:
	"""
	Clear all items from inventory
	"""
	for i in range(items.size()):
		items[i] = {
			"id": "",
			"name": "",
			"description": "",
			"type": "",
			"stack_size": 0,
			"max_stack": max_stack_size,
			"stats": {},
			"icon": null
		}
	
	equipped_items = {
		"weapon": null,
		"armor": null,
		"accessory": null
	}
	
	emit_signal("inventory_changed") 