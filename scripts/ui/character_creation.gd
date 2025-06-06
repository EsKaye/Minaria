extends Control

# UI references
@onready var name_input: LineEdit = $Panel/MarginContainer/VBoxContainer/HBoxContainer/FormContainer/NameInput
@onready var class_option: OptionButton = $Panel/MarginContainer/VBoxContainer/HBoxContainer/FormContainer/ClassOption
@onready var hair_style: OptionButton = $Panel/MarginContainer/VBoxContainer/HBoxContainer/FormContainer/AppearanceOptions/HairStyle/OptionButton
@onready var hair_color: OptionButton = $Panel/MarginContainer/VBoxContainer/HBoxContainer/FormContainer/AppearanceOptions/HairColor/OptionButton
@onready var eye_color: OptionButton = $Panel/MarginContainer/VBoxContainer/HBoxContainer/FormContainer/AppearanceOptions/EyeColor/OptionButton
@onready var character_sprite: Sprite2D = $Panel/MarginContainer/VBoxContainer/HBoxContainer/CharacterPreview/PreviewContainer/CharacterSprite
@onready var randomize_button: Button = $Panel/MarginContainer/VBoxContainer/Buttons/RandomizeButton
@onready var create_button: Button = $Panel/MarginContainer/VBoxContainer/Buttons/CreateButton

# Stats references
@onready var strength_value: Label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/FormContainer/StatsContainer/StrengthValue
@onready var dexterity_value: Label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/FormContainer/StatsContainer/DexterityValue
@onready var intelligence_value: Label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/FormContainer/StatsContainer/IntelligenceValue
@onready var vitality_value: Label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/FormContainer/StatsContainer/VitalityValue

# Character data
var character_data: Dictionary = {
	"name": "",
	"class": "Warrior",
	"appearance": {
		"hair_style": 0,
		"hair_color": 0,
		"eye_color": 0
	},
	"stats": {
		"strength": 10,
		"dexterity": 10,
		"intelligence": 10,
		"vitality": 10
	}
}

# Class base stats
const CLASS_STATS = {
	"Warrior": {
		"strength": 15,
		"dexterity": 8,
		"intelligence": 5,
		"vitality": 12
	},
	"Mage": {
		"strength": 5,
		"dexterity": 8,
		"intelligence": 15,
		"vitality": 7
	},
	"Rogue": {
		"strength": 8,
		"dexterity": 15,
		"intelligence": 10,
		"vitality": 7
	}
}

# Signals
signal character_created(character_data: Dictionary)
signal creation_cancelled

func _ready():
	# Connect signals
	name_input.text_changed.connect(_on_name_changed)
	class_option.item_selected.connect(_on_class_selected)
	hair_style.item_selected.connect(_on_hair_style_selected)
	hair_color.item_selected.connect(_on_hair_color_selected)
	eye_color.item_selected.connect(_on_eye_color_selected)
	randomize_button.pressed.connect(_on_randomize_pressed)
	create_button.pressed.connect(_on_create_pressed)
	
	# Initialize character
	_update_stats()
	_update_preview()

func _on_name_changed(new_name: String):
	character_data["name"] = new_name
	_validate_creation()

func _on_class_selected(index: int):
	var class_name = class_option.get_item_text(index)
	character_data["class"] = class_name
	_update_stats()
	_update_preview()
	_validate_creation()

func _on_hair_style_selected(index: int):
	character_data["appearance"]["hair_style"] = index
	_update_preview()

func _on_hair_color_selected(index: int):
	character_data["appearance"]["hair_color"] = index
	_update_preview()

func _on_eye_color_selected(index: int):
	character_data["appearance"]["eye_color"] = index
	_update_preview()

func _update_stats():
	var class_stats = CLASS_STATS[character_data["class"]]
	character_data["stats"] = class_stats.duplicate()
	
	strength_value.text = str(character_data["stats"]["strength"])
	dexterity_value.text = str(character_data["stats"]["dexterity"])
	intelligence_value.text = str(character_data["stats"]["intelligence"])
	vitality_value.text = str(character_data["stats"]["vitality"])

func _update_preview():
	# TODO: Update character sprite based on appearance settings
	# This will be implemented when we have the character sprites
	pass

func _on_randomize_pressed():
	# Randomize appearance
	character_data["appearance"]["hair_style"] = randi() % hair_style.item_count
	character_data["appearance"]["hair_color"] = randi() % hair_color.item_count
	character_data["appearance"]["eye_color"] = randi() % eye_color.item_count
	
	# Update UI
	hair_style.select(character_data["appearance"]["hair_style"])
	hair_color.select(character_data["appearance"]["hair_color"])
	eye_color.select(character_data["appearance"]["eye_color"])
	
	_update_preview()

func _validate_creation():
	# Enable create button only if name is not empty
	create_button.disabled = character_data["name"].strip_edges().is_empty()

func _on_create_pressed():
	if not character_data["name"].strip_edges().is_empty():
		emit_signal("character_created", character_data.duplicate())
		queue_free()

func show_creation_menu():
	visible = true
	name_input.grab_focus() 