extends Node

# Sound effect resources
@export var button_click: AudioStream
@export var button_hover: AudioStream
@export var menu_open: AudioStream
@export var menu_close: AudioStream
@export var item_pickup: AudioStream
@export var item_drop: AudioStream
@export var crafting_success: AudioStream
@export var crafting_fail: AudioStream
@export var notification: AudioStream

# Audio players
var button_click_player: AudioStreamPlayer
var button_hover_player: AudioStreamPlayer
var menu_open_player: AudioStreamPlayer
var menu_close_player: AudioStreamPlayer
var item_pickup_player: AudioStreamPlayer
var item_drop_player: AudioStreamPlayer
var crafting_success_player: AudioStreamPlayer
var crafting_fail_player: AudioStreamPlayer
var notification_player: AudioStreamPlayer

func _ready():
	# Create audio players
	button_click_player = _create_audio_player(button_click)
	button_hover_player = _create_audio_player(button_hover)
	menu_open_player = _create_audio_player(menu_open)
	menu_close_player = _create_audio_player(menu_close)
	item_pickup_player = _create_audio_player(item_pickup)
	item_drop_player = _create_audio_player(item_drop)
	crafting_success_player = _create_audio_player(crafting_success)
	crafting_fail_player = _create_audio_player(crafting_fail)
	notification_player = _create_audio_player(notification)

func _create_audio_player(stream: AudioStream) -> AudioStreamPlayer:
	"""
	Create an audio player with the given stream
	"""
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "UI"
	add_child(player)
	return player

func play_button_click():
	"""
	Play button click sound
	"""
	button_click_player.play()

func play_button_hover():
	"""
	Play button hover sound
	"""
	button_hover_player.play()

func play_menu_open():
	"""
	Play menu open sound
	"""
	menu_open_player.play()

func play_menu_close():
	"""
	Play menu close sound
	"""
	menu_close_player.play()

func play_item_pickup():
	"""
	Play item pickup sound
	"""
	item_pickup_player.play()

func play_item_drop():
	"""
	Play item drop sound
	"""
	item_drop_player.play()

func play_crafting_success():
	"""
	Play crafting success sound
	"""
	crafting_success_player.play()

func play_crafting_fail():
	"""
	Play crafting fail sound
	"""
	crafting_fail_player.play()

func play_notification():
	"""
	Play notification sound
	"""
	notification_player.play()

func set_volume(volume: float):
	"""
	Set the volume for all UI sounds
	"""
	for player in get_children():
		if player is AudioStreamPlayer:
			player.volume_db = linear_to_db(volume) 