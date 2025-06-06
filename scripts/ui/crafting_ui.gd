extends Control

# UI references
@onready var recipe_list = $Panel/VBoxContainer/Content/RecipeList/VBoxContainer
@onready var recipe_grid = $Panel/VBoxContainer/Content/CraftingArea/RecipeGrid
@onready var craft_button = $Panel/VBoxContainer/Content/CraftingArea/CraftButton
@onready var recipe_info = $Panel/VBoxContainer/Content/CraftingArea/RecipeInfo

# Recipe slot scene
var recipe_slot_scene = preload("res://scenes/ui/recipe_slot.tscn")

# Crafting state
var selected_recipe = null
var crafting_system = null

# UI signals
signal crafting_closed
signal recipe_selected(recipe: Dictionary)
signal item_crafted(recipe: Dictionary)

func _ready():
	# Connect signals
	$Panel/VBoxContainer/Header/CloseButton.pressed.connect(_on_close_pressed)
	craft_button.pressed.connect(_on_craft_pressed)
	
	# Initialize recipe grid
	initialize_recipe_grid()

func initialize_recipe_grid():
	"""
	Initialize the recipe grid with empty slots
	"""
	for i in range(9):  # 3x3 grid
		var slot = recipe_slot_scene.instantiate()
		slot.slot_index = i
		recipe_grid.add_child(slot)

func set_crafting_system(system):
	"""
	Set the crafting system reference and connect signals
	"""
	crafting_system = system
	crafting_system.recipes_changed.connect(_on_recipes_changed)
	update_recipe_list()

func update_recipe_list():
	"""
	Update the recipe list with available recipes
	"""
	if !crafting_system:
		return
		
	# Clear existing recipes
	for child in recipe_list.get_children():
		child.queue_free()
		
	# Add available recipes
	var recipes = crafting_system.get_available_recipes()
	for recipe in recipes:
		var recipe_button = Button.new()
		recipe_button.text = recipe.name
		recipe_button.pressed.connect(_on_recipe_button_pressed.bind(recipe))
		recipe_list.add_child(recipe_button)

func show_recipe_info(recipe: Dictionary):
	"""
	Show recipe information
	"""
	if !recipe:
		recipe_info.hide()
		return
		
	recipe_info.show()
	$Panel/VBoxContainer/Content/CraftingArea/RecipeTitle.text = recipe.name
	$Panel/VBoxContainer/Content/CraftingArea/RecipeInfo/RecipeName.text = recipe.name
	$Panel/VBoxContainer/Content/CraftingArea/RecipeInfo/RecipeDescription.text = recipe.description
	
	# Update requirements
	var requirements = $Panel/VBoxContainer/Content/CraftingArea/RecipeInfo/Requirements
	for child in requirements.get_children():
		if child.name != "RequirementsTitle":
			child.queue_free()
			
	for ingredient in recipe.ingredients:
		var label = Label.new()
		label.text = ingredient.name + ": " + str(ingredient.amount)
		requirements.add_child(label)
		
	# Update recipe grid
	update_recipe_grid(recipe)

func update_recipe_grid(recipe: Dictionary):
	"""
	Update the recipe grid with ingredients
	"""
	# Clear grid
	for slot in recipe_grid.get_children():
		slot.clear_slot()
		
	# Add ingredients
	var row = 0
	var col = 0
	for ingredient in recipe.ingredients:
		var slot = recipe_grid.get_child(row * 3 + col)
		slot.set_item(ingredient.name, ingredient.amount)
		
		col += 1
		if col >= 3:
			col = 0
			row += 1

func _on_close_pressed():
	"""
	Handle close button press
	"""
	crafting_closed.emit()
	queue_free()

func _on_recipe_button_pressed(recipe: Dictionary):
	"""
	Handle recipe button press
	"""
	selected_recipe = recipe
	show_recipe_info(recipe)
	recipe_selected.emit(recipe)

func _on_craft_pressed():
	"""
	Handle craft button press
	"""
	if !selected_recipe or !crafting_system:
		return
		
	if crafting_system.craft_item(selected_recipe.name):
		item_crafted.emit(selected_recipe)
		update_recipe_list()

func _on_recipes_changed():
	"""
	Handle recipes changed
	"""
	update_recipe_list()

func _input(event):
	"""
	Handle input events
	"""
	if event.is_action_pressed("crafting"):
		_on_close_pressed() 