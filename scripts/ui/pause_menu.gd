extends Control

# UI references
@onready var resume_button = $Panel/VBoxContainer/Buttons/ResumeButton
@onready var save_button = $Panel/VBoxContainer/Buttons/SaveButton
@onready var load_button = $Panel/VBoxContainer/Buttons/LoadButton
@onready var options_button = $Panel/VBoxContainer/Buttons/OptionsButton
@onready var quit_button = $Panel/VBoxContainer/Buttons/QuitButton

# Menu state
var is_paused = false

# UI signals
signal menu_closed
signal game_saved
signal game_loaded
signal options_opened
signal quit_to_menu

func _ready():
	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Hide menu initially
	hide()

func show_menu():
	"""
	Show the pause menu
	"""
	show()
	is_paused = true
	get_tree().paused = true

func hide_menu():
	"""
	Hide the pause menu
	"""
	hide()
	is_paused = false
	get_tree().paused = false

func _on_resume_pressed():
	"""
	Handle resume button press
	"""
	hide_menu()
	menu_closed.emit()

func _on_save_pressed():
	"""
	Handle save button press
	"""
	# TODO: Show save game dialog
	game_saved.emit()

func _on_load_pressed():
	"""
	Handle load button press
	"""
	# TODO: Show load game dialog
	game_loaded.emit()

func _on_options_pressed():
	"""
	Handle options button press
	"""
	# TODO: Show options menu
	options_opened.emit()

func _on_quit_pressed():
	"""
	Handle quit button press
	"""
	# TODO: Show confirmation dialog
	quit_to_menu.emit()

func _input(event):
	"""
	Handle input events
	"""
	if event.is_action_pressed("pause"):
		if is_paused:
			_on_resume_pressed()
		else:
			show_menu() 