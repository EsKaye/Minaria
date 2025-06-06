extends Control

# Menu signals
signal new_game_pressed
signal load_game_pressed
signal options_pressed
signal quit_pressed

func _ready():
	# Connect button signals
	$VBoxContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$VBoxContainer/LoadGameButton.pressed.connect(_on_load_game_pressed)
	$VBoxContainer/OptionsButton.pressed.connect(_on_options_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	
	# Initialize menu state
	update_load_game_button()

func _on_new_game_pressed():
	"""
	Handle new game button press
	"""
	new_game_pressed.emit()
	
	# TODO: Add transition animation
	# TODO: Add sound effect

func _on_load_game_pressed():
	"""
	Handle load game button press
	"""
	load_game_pressed.emit()
	
	# TODO: Add transition animation
	# TODO: Add sound effect

func _on_options_pressed():
	"""
	Handle options button press
	"""
	options_pressed.emit()
	
	# TODO: Add transition animation
	# TODO: Add sound effect

func _on_quit_pressed():
	"""
	Handle quit button press
	"""
	quit_pressed.emit()
	
	# TODO: Add confirmation dialog
	# TODO: Add transition animation
	# TODO: Add sound effect

func update_load_game_button():
	"""
	Update the load game button state based on save file availability
	"""
	var has_save = false  # TODO: Check for save files
	$VBoxContainer/LoadGameButton.disabled = !has_save

func _input(event):
	"""
	Handle input events
	"""
	if event.is_action_pressed("ui_cancel"):
		# Handle escape key
		if get_tree().current_scene == self:
			_on_quit_pressed() 