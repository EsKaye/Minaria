extends Node

# Recipe database
var recipes = {
	"wooden_pickaxe": {
		"ingredients": {
			"wood": 3,
			"stone": 2
		},
		"result": "wooden_pickaxe",
		"category": "tools"
	},
	"stone_pickaxe": {
		"ingredients": {
			"wood": 2,
			"stone": 4
		},
		"result": "stone_pickaxe",
		"category": "tools"
	},
	"iron_pickaxe": {
		"ingredients": {
			"wood": 2,
			"iron": 4
		},
		"result": "iron_pickaxe",
		"category": "tools"
	}
}

# Item properties
var item_properties = {
	"wooden_pickaxe": {
		"name": "Wooden Pickaxe",
		"description": "A basic pickaxe made of wood and stone",
		"durability": 50,
		"mining_power": 1,
		"texture": preload("res://assets/sprites/items/wooden_pickaxe.png")
	},
	"stone_pickaxe": {
		"name": "Stone Pickaxe",
		"description": "A sturdy pickaxe made of stone",
		"durability": 100,
		"mining_power": 2,
		"texture": preload("res://assets/sprites/items/stone_pickaxe.png")
	},
	"iron_pickaxe": {
		"name": "Iron Pickaxe",
		"description": "A durable pickaxe made of iron",
		"durability": 200,
		"mining_power": 3,
		"texture": preload("res://assets/sprites/items/iron_pickaxe.png")
	}
}

# Crafting signals
signal recipe_crafted(recipe_name: String, result: Dictionary)
signal crafting_failed(recipe_name: String, reason: String)

func _ready():
	# Initialize crafting system
	pass

func get_available_recipes(inventory: Dictionary) -> Array:
	"""
	Get all recipes that can be crafted with the current inventory
	"""
	var available = []
	
	for recipe_name in recipes:
		var recipe = recipes[recipe_name]
		if can_craft_recipe(recipe, inventory):
			available.append(recipe_name)
			
	return available

func can_craft_recipe(recipe: Dictionary, inventory: Dictionary) -> bool:
	"""
	Check if a recipe can be crafted with the current inventory
	"""
	for ingredient in recipe.ingredients:
		var required = recipe.ingredients[ingredient]
		var available = inventory.get(ingredient, 0)
		
		if available < required:
			return false
			
	return true

func craft_recipe(recipe_name: String, inventory: Dictionary) -> Dictionary:
	"""
	Attempt to craft a recipe using the provided inventory
	Returns the crafted item if successful, empty dictionary if failed
	"""
	var recipe = recipes.get(recipe_name)
	if !recipe:
		crafting_failed.emit(recipe_name, "Recipe not found")
		return {}
		
	if !can_craft_recipe(recipe, inventory):
		crafting_failed.emit(recipe_name, "Insufficient ingredients")
		return {}
		
	# Consume ingredients
	for ingredient in recipe.ingredients:
		var amount = recipe.ingredients[ingredient]
		inventory[ingredient] -= amount
		
	# Create result
	var result = {
		"name": recipe.result,
		"properties": item_properties[recipe.result]
	}
	
	recipe_crafted.emit(recipe_name, result)
	return result

func get_recipe_info(recipe_name: String) -> Dictionary:
	"""
	Get detailed information about a recipe
	"""
	var recipe = recipes.get(recipe_name)
	if !recipe:
		return {}
		
	var info = recipe.duplicate()
	info["result_info"] = item_properties[recipe.result]
	return info

func get_item_info(item_name: String) -> Dictionary:
	"""
	Get detailed information about an item
	"""
	return item_properties.get(item_name, {})

func get_recipes_by_category(category: String) -> Array:
	"""
	Get all recipes in a specific category
	"""
	var category_recipes = []
	
	for recipe_name in recipes:
		var recipe = recipes[recipe_name]
		if recipe.category == category:
			category_recipes.append(recipe_name)
			
	return category_recipes 