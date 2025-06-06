extends Control

# UI references
@onready var name_label: Label = $Panel/MarginContainer/VBoxContainer/NameLabel
@onready var dialog_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/DialogLabel
@onready var continue_label: Label = $Panel/MarginContainer/VBoxContainer/ContinueLabel
@onready var options_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/OptionsContainer

# Dialog state
var dialog_queue: Array[Dictionary] = []
var current_dialog: Dictionary
var is_displaying: bool = false
var is_typing: bool = false
var type_speed: float = 0.05
var type_timer: float = 0.0
var current_text: String = ""
var full_text: String = ""

# Animation
var slide_duration: float = 0.3
var is_sliding: bool = false

# Signals
signal dialog_started
signal dialog_ended
signal option_selected(option_index: int)

func _ready():
	# Hide dialog box initially
	modulate.a = 0
	visible = false
	
	# Connect option button signals
	for i in range(options_container.get_child_count()):
		var button = options_container.get_child(i)
		button.pressed.connect(_on_option_selected.bind(i))

func _process(delta):
	if is_typing:
		type_timer += delta
		if type_timer >= type_speed:
			type_timer = 0
			_advance_text()

func start_dialog(dialog_data: Dictionary):
	"""
	Start displaying a dialog
	"""
	dialog_queue.append(dialog_data)
	
	if not is_displaying:
		_show_next_dialog()

func _show_next_dialog():
	"""
	Show the next dialog in the queue
	"""
	if dialog_queue.is_empty():
		_hide_dialog()
		return
	
	is_displaying = true
	current_dialog = dialog_queue.pop_front()
	
	# Set character name
	name_label.text = current_dialog.get("name", "")
	
	# Set dialog text
	full_text = current_dialog.get("text", "")
	current_text = ""
	dialog_label.text = current_text
	is_typing = true
	
	# Show options if any
	var options = current_dialog.get("options", [])
	if not options.is_empty():
		_show_options(options)
	else:
		options_container.visible = false
		continue_label.visible = true
	
	# Show dialog box
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, slide_duration)
	
	emit_signal("dialog_started")

func _advance_text():
	"""
	Advance the typing animation
	"""
	if current_text.length() < full_text.length():
		current_text += full_text[current_text.length()]
		dialog_label.text = current_text
	else:
		is_typing = false

func _show_options(options: Array):
	"""
	Show dialog options
	"""
	options_container.visible = true
	continue_label.visible = false
	
	# Update option buttons
	for i in range(options_container.get_child_count()):
		var button = options_container.get_child(i)
		if i < options.size():
			button.text = options[i]
			button.visible = true
		else:
			button.visible = false

func _hide_dialog():
	"""
	Hide the dialog box
	"""
	is_displaying = false
	is_typing = false
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, slide_duration)
	await tween.finished
	visible = false
	
	emit_signal("dialog_ended")

func _on_option_selected(option_index: int):
	"""
	Handle option selection
	"""
	emit_signal("option_selected", option_index)
	_show_next_dialog()

func _input(event):
	if not is_displaying:
		return
	
	if event.is_action_pressed("ui_accept") and not is_typing:
		if options_container.visible:
			return
		_show_next_dialog()
	elif event.is_action_pressed("ui_accept") and is_typing:
		# Skip typing animation
		current_text = full_text
		dialog_label.text = current_text
		is_typing = false

func set_type_speed(speed: float):
	"""
	Set the text typing speed
	"""
	type_speed = speed 