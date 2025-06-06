extends Control

# UI references
@onready var recipe_list: ItemList = $Panel/MarginContainer/VBoxContainer/HBoxContainer/RecipeList
@onready var recipe_title: Label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/RecipeDetails/RecipeTitle
@onready var recipe_description: RichTextLabel = $Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/RecipeDetails/RecipeDescription
@onready var ingredients_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/RecipeDetails/Ingredients/IngredientsList
@onready var item_icon: TextureRect = $Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/RecipeDetails/Result/ResultItem/ItemIcon
@onready var item_name: Label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/RecipeDetails/Result/ResultItem/ItemName
@onready var craft_button: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/CraftButton
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

# Recipe data
var recipes: Dictionary = {}
var active_recipe_id: String = ""
var inventory: Node

# Signals
signal item_crafted(item_id: String, quantity: int)
signal menu_closed

func _ready():
	# Connect signals
	recipe_list.item_selected.connect(_on_recipe_selected)
	craft_button.pressed.connect(_on_craft_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Hide initially
	visible = false

func set_inventory(inventory_node: Node):
	"""
	Set the inventory reference
	"""
	inventory = inventory_node

func add_recipe(recipe_data: Dictionary):
	"""
	Add a new recipe to the list
	"""
	var recipe_id = recipe_data.get("id", "")
	if recipe_id.is_empty():
		return
	
	recipes[recipe_id] = recipe_data
	_update_recipe_list()
	
	# Select the new recipe
	var index = recipe_list.get_item_index(recipe_id)
	if index >= 0:
		recipe_list.select(index)
		_on_recipe_selected(index)

func remove_recipe(recipe_id: String):
	"""
	Remove a recipe from the list
	"""
	if not recipes.has(recipe_id):
		return
	
	recipes.erase(recipe_id)
	_update_recipe_list()
	
	# Clear details if this recipe was selected
	if active_recipe_id == recipe_id:
		_clear_recipe_details()

func _update_recipe_list():
	"""
	Update the recipe list UI
	"""
	recipe_list.clear()
	
	for recipe_id in recipes:
		var recipe = recipes[recipe_id]
		var title = recipe.get("title", "Untitled Recipe")
		var category = recipe.get("category", "Misc")
		
		recipe_list.add_item("%s - %s" % [category, title], null, false)
		recipe_list.set_item_metadata(recipe_list.get_item_count() - 1, recipe_id)

func _show_recipe_details(recipe_id: String):
	"""
	Show details for the selected recipe
	"""
	if not recipes.has(recipe_id):
		return
	
	active_recipe_id = recipe_id
	var recipe = recipes[recipe_id]
	
	# Update title and description
	recipe_title.text = recipe.get("title", "Untitled Recipe")
	recipe_description.text = recipe.get("description", "")
	
	# Update ingredients
	_clear_ingredients()
	var ingredients = recipe.get("ingredients", [])
	for ingredient in ingredients:
		var item_id = ingredient.get("item_id", "")
		var quantity = ingredient.get("quantity", 1)
		var available = _check_ingredient_availability(item_id, quantity)
		
		var label = Label.new()
		label.text = "• %s x%d %s" % [
			item_id,
			quantity,
			"✓" if available else "✗"
		]
		label.modulate = Color(0, 1, 0, 1) if available else Color(1, 0, 0, 1)
		ingredients_list.add_child(label)
	
	# Update result
	var result = recipe.get("result", {})
	item_name.text = result.get("item_id", "Unknown Item")
	
	# Update craft button state
	craft_button.disabled = not _can_craft_recipe(recipe)

func _clear_recipe_details():
	"""
	Clear the recipe details section
	"""
	active_recipe_id = ""
	recipe_title.text = ""
	recipe_description.text = ""
	_clear_ingredients()
	item_name.text = ""
	item_icon.texture = null
	craft_button.disabled = true

func _clear_ingredients():
	"""
	Clear the ingredients list
	"""
	for child in ingredients_list.get_children():
		child.queue_free()

func _check_ingredient_availability(item_id: String, quantity: int) -> bool:
	"""
	Check if the required quantity of an ingredient is available
	"""
	if not inventory:
		return false
	
	return inventory.has_item(item_id, quantity)

func _can_craft_recipe(recipe: Dictionary) -> bool:
	"""
	Check if the recipe can be crafted
	"""
	if not inventory:
		return false
	
	var ingredients = recipe.get("ingredients", [])
	for ingredient in ingredients:
		var item_id = ingredient.get("item_id", "")
		var quantity = ingredient.get("quantity", 1)
		
		if not _check_ingredient_availability(item_id, quantity):
			return false
	
	return true

func _on_recipe_selected(index: int):
	"""
	Handle recipe selection
	"""
	var recipe_id = recipe_list.get_item_metadata(index)
	_show_recipe_details(recipe_id)

func _on_craft_pressed():
	"""
	Handle craft button press
	"""
	if not active_recipe_id.is_empty() and recipes.has(active_recipe_id):
		var recipe = recipes[active_recipe_id]
		var result = recipe.get("result", {})
		var item_id = result.get("item_id", "")
		var quantity = result.get("quantity", 1)
		
		# Remove ingredients
		var ingredients = recipe.get("ingredients", [])
		for ingredient in ingredients:
			var ing_item_id = ingredient.get("item_id", "")
			var ing_quantity = ingredient.get("quantity", 1)
			inventory.remove_item(ing_item_id, ing_quantity)
		
		# Add result
		inventory.add_item(item_id, quantity)
		
		# Emit signal
		emit_signal("item_crafted", item_id, quantity)
		
		# Update recipe details
		_show_recipe_details(active_recipe_id)

func _on_close_pressed():
	"""
	Handle close button press
	"""
	visible = false
	emit_signal("menu_closed")

func show_crafting_menu():
	"""
	Show the crafting menu
	"""
	visible = true
	_update_recipe_list()
	
	# Select first recipe if none selected
	if active_recipe_id.is_empty() and recipe_list.get_item_count() > 0:
		recipe_list.select(0)
		_on_recipe_selected(0) 