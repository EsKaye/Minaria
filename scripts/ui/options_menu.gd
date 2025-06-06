extends Control

# UI references
@onready var tab_container = $Panel/VBoxContainer/TabContainer
@onready var resolution_button = $Panel/VBoxContainer/TabContainer/Graphics/Resolution/OptionButton
@onready var fullscreen_check = $Panel/VBoxContainer/TabContainer/Graphics/Fullscreen
@onready var vsync_check = $Panel/VBoxContainer/TabContainer/Graphics/VSync
@onready var master_volume = $Panel/VBoxContainer/TabContainer/Audio/MasterVolume/HSlider
@onready var music_volume = $Panel/VBoxContainer/TabContainer/Audio/MusicVolume/HSlider
@onready var sfx_volume = $Panel/VBoxContainer/TabContainer/Audio/SFXVolume/HSlider
@onready var apply_button = $Panel/VBoxContainer/Buttons/ApplyButton
@onready var cancel_button = $Panel/VBoxContainer/Buttons/CancelButton

# Settings state
var current_settings = {}
var pending_settings = {}

# UI signals
signal settings_applied(settings: Dictionary)
signal settings_cancelled
signal menu_closed

func _ready():
	# Connect signals
	$Panel/VBoxContainer/Header/CloseButton.pressed.connect(_on_close_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Connect control signals
	resolution_button.item_selected.connect(_on_resolution_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	master_volume.value_changed.connect(_on_master_volume_changed)
	music_volume.value_changed.connect(_on_music_volume_changed)
	sfx_volume.value_changed.connect(_on_sfx_volume_changed)
	
	# Load current settings
	load_settings()

func load_settings():
	"""
	Load current settings from config
	"""
	# TODO: Load from config file
	current_settings = {
		"resolution": 0,  # 1920x1080
		"fullscreen": false,
		"vsync": true,
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.8
	}
	
	pending_settings = current_settings.duplicate()
	apply_settings_to_ui()

func apply_settings_to_ui():
	"""
	Apply current settings to UI elements
	"""
	resolution_button.selected = current_settings.resolution
	fullscreen_check.button_pressed = current_settings.fullscreen
	vsync_check.button_pressed = current_settings.vsync
	master_volume.value = current_settings.master_volume
	music_volume.value = current_settings.music_volume
	sfx_volume.value = current_settings.sfx_volume

func _on_resolution_selected(index: int):
	"""
	Handle resolution selection
	"""
	pending_settings.resolution = index

func _on_fullscreen_toggled(button_pressed: bool):
	"""
	Handle fullscreen toggle
	"""
	pending_settings.fullscreen = button_pressed

func _on_vsync_toggled(button_pressed: bool):
	"""
	Handle vsync toggle
	"""
	pending_settings.vsync = button_pressed

func _on_master_volume_changed(value: float):
	"""
	Handle master volume change
	"""
	pending_settings.master_volume = value
	# TODO: Update audio bus volume

func _on_music_volume_changed(value: float):
	"""
	Handle music volume change
	"""
	pending_settings.music_volume = value
	# TODO: Update music bus volume

func _on_sfx_volume_changed(value: float):
	"""
	Handle SFX volume change
	"""
	pending_settings.sfx_volume = value
	# TODO: Update SFX bus volume

func _on_apply_pressed():
	"""
	Handle apply button press
	"""
	current_settings = pending_settings.duplicate()
	settings_applied.emit(current_settings)
	# TODO: Save to config file
	hide()

func _on_cancel_pressed():
	"""
	Handle cancel button press
	"""
	pending_settings = current_settings.duplicate()
	apply_settings_to_ui()
	settings_cancelled.emit()
	hide()

func _on_close_pressed():
	"""
	Handle close button press
	"""
	menu_closed.emit()
	hide()

func _input(event):
	"""
	Handle input events
	"""
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed() 