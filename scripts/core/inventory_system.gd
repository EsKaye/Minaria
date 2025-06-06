extends Node

# Inventory properties
@export var max_slots = 20
@export var max_stack_size = 99

# Inventory data
var items = {}
var equipped_items = {
	"tool": null,
	"armor": null,
	"accessory": null
}

# Inventory signals
signal inventory_changed
signal item_added(item_name: String, amount: int)
signal item_removed(item_name: String, amount: int)
signal item_equipped(slot: String, item: Dictionary)
signal item_unequipped(slot: String, item: Dictionary)

func _ready():
	# Initialize inventory
	pass

func add_item(item_name: String, amount: int = 1) -> bool:
	"""
	Add items to the inventory
	Returns true if successful, false if inventory is full
	"""
	if items.size() >= max_slots and !items.has(item_name):
		return false
		
	var current_amount = items.get(item_name, 0)
	var new_amount = current_amount + amount
	
	if new_amount > max_stack_size:
		# Handle stack overflow
		var remaining = new_amount - max_stack_size
		items[item_name] = max_stack_size
		item_added.emit(item_name, max_stack_size - current_amount)
		return add_item(item_name, remaining)
		
	items[item_name] = new_amount
	item_added.emit(item_name, amount)
	inventory_changed.emit()
	return true

func remove_item(item_name: String, amount: int = 1) -> bool:
	"""
	Remove items from the inventory
	Returns true if successful, false if not enough items
	"""
	if !items.has(item_name):
		return false
		
	var current_amount = items[item_name]
	if current_amount < amount:
		return false
		
	items[item_name] = current_amount - amount
	if items[item_name] <= 0:
		items.erase(item_name)
		
	item_removed.emit(item_name, amount)
	inventory_changed.emit()
	return true

func has_item(item_name: String, amount: int = 1) -> bool:
	"""
	Check if the inventory has enough of an item
	"""
	return items.get(item_name, 0) >= amount

func get_item_count(item_name: String) -> int:
	"""
	Get the current amount of an item in the inventory
	"""
	return items.get(item_name, 0)

func get_inventory_contents() -> Dictionary:
	"""
	Get a copy of the current inventory contents
	"""
	return items.duplicate()

func equip_item(slot: String, item_name: String) -> bool:
	"""
	Equip an item to a specific slot
	Returns true if successful, false if item not found or invalid slot
	"""
	if !items.has(item_name):
		return false
		
	if !equipped_items.has(slot):
		return false
		
	# Unequip current item if any
	if equipped_items[slot]:
		unequip_item(slot)
		
	equipped_items[slot] = {
		"name": item_name,
		"amount": 1
	}
	
	remove_item(item_name, 1)
	item_equipped.emit(slot, equipped_items[slot])
	return true

func unequip_item(slot: String) -> bool:
	"""
	Unequip an item from a specific slot
	Returns true if successful, false if slot is empty
	"""
	if !equipped_items.has(slot) or !equipped_items[slot]:
		return false
		
	var item = equipped_items[slot]
	equipped_items[slot] = null
	
	add_item(item.name, item.amount)
	item_unequipped.emit(slot, item)
	return true

func get_equipped_items() -> Dictionary:
	"""
	Get a copy of the currently equipped items
	"""
	return equipped_items.duplicate()

func clear_inventory():
	"""
	Clear all items from the inventory
	"""
	items.clear()
	inventory_changed.emit()

func get_inventory_space() -> int:
	"""
	Get the number of empty slots in the inventory
	"""
	return max_slots - items.size()

func is_inventory_full() -> bool:
	"""
	Check if the inventory is full
	"""
	return items.size() >= max_slots

func can_add_item(item_name: String, amount: int = 1) -> bool:
	"""
	Check if an item can be added to the inventory
	"""
	if items.has(item_name):
		var current_amount = items[item_name]
		return current_amount + amount <= max_stack_size
	return items.size() < max_slots 