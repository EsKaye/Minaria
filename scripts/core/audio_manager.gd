extends Node
class_name AudioManager

## Audio Manager - Centralized audio system for Minaria
## Handles all game audio including music, sound effects, and ambient sounds
## Provides volume controls, audio pooling, and dynamic audio management

# Audio buses
enum AudioBus {
	MASTER,
	MUSIC,
	SFX,
	AMBIENT,
	UI
}

# Audio categories for organization
enum AudioCategory {
	MUSIC,
	SFX,
	AMBIENT,
	UI,
	COMBAT,
	ENVIRONMENT
}

# Volume settings
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var ambient_volume: float = 0.6
var ui_volume: float = 0.9

# Audio players
var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var ui_players: Array[AudioStreamPlayer] = []

# Audio pools for performance
var audio_pool: Array[AudioStreamPlayer] = []
var max_pool_size: int = 20

# Current audio state
var current_music: String = ""
var current_ambient: String = ""
var is_music_fading: bool = false
var is_ambient_fading: bool = false

# Audio resources cache
var audio_cache: Dictionary = {}

# Signals
signal music_changed(track_name: String)
signal ambient_changed(track_name: String)
signal volume_changed(bus: AudioBus, volume: float)
signal audio_finished(category: AudioCategory, track_name: String)

func _ready() -> void:
	"""
	Initialize the audio manager system
	"""
	_setup_audio_buses()
	_create_audio_players()
	_load_audio_resources()
	_connect_signals()

func _setup_audio_buses() -> void:
	"""
	Setup audio buses for different audio categories
	"""
	# Create buses if they don't exist
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "Music")
	
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "SFX")
	
	if AudioServer.get_bus_index("Ambient") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_index(AudioServer.get_bus_count() - 1, "Ambient")
	
	if AudioServer.get_bus_index("UI") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "UI")

func _create_audio_players() -> void:
	"""
	Create audio players for different categories
	"""
	# Music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	add_child(music_player)
	
	# Ambient player
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.bus = "Ambient"
	add_child(ambient_player)
	
	# Create SFX players pool
	for i in range(5):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer" + str(i)
		player.bus = "SFX"
		player.finished.connect(_on_sfx_finished.bind(player))
		sfx_players.append(player)
		add_child(player)
	
	# Create UI players pool
	for i in range(3):
		var player = AudioStreamPlayer.new()
		player.name = "UIPlayer" + str(i)
		player.bus = "UI"
		player.finished.connect(_on_ui_finished.bind(player))
		ui_players.append(player)
		add_child(player)

func _load_audio_resources() -> void:
	"""
	Preload and cache audio resources for better performance
	"""
	var audio_dir = "res://assets/audio/"
	var dir = DirAccess.open(audio_dir)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".ogg") or file_name.ends_with(".wav"):
				var audio_path = audio_dir + file_name
				var audio_stream = load(audio_path)
				if audio_stream:
					audio_cache[file_name.get_basename()] = audio_stream
			
			file_name = dir.get_next()

func _connect_signals() -> void:
	"""
	Connect audio player signals
	"""
	music_player.finished.connect(_on_music_finished)
	ambient_player.finished.connect(_on_ambient_finished)

func play_music(track_name: String, fade_in: float = 1.0) -> void:
	"""
	Play background music with optional fade-in effect
	
	Args:
		track_name: Name of the music track to play
		fade_in: Fade-in duration in seconds
	"""
	if track_name == current_music:
		return
	
	if audio_cache.has(track_name):
		current_music = track_name
		music_player.stream = audio_cache[track_name]
		music_player.play()
		
		if fade_in > 0:
			_fade_in_audio(music_player, fade_in)
		
		music_changed.emit(track_name)

func play_ambient(track_name: String, fade_in: float = 2.0) -> void:
	"""
	Play ambient background sounds
	
	Args:
		track_name: Name of the ambient track to play
		fade_in: Fade-in duration in seconds
	"""
	if track_name == current_ambient:
		return
	
	if audio_cache.has(track_name):
		current_ambient = track_name
		ambient_player.stream = audio_cache[track_name]
		ambient_player.play()
		
		if fade_in > 0:
			_fade_in_audio(ambient_player, fade_in)
		
		ambient_changed.emit(track_name)

func play_sfx(sound_name: String, volume: float = 1.0, pitch: float = 1.0) -> void:
	"""
	Play a sound effect using the audio pool
	
	Args:
		sound_name: Name of the sound effect to play
		volume: Volume level (0.0 to 1.0)
		pitch: Pitch variation
	"""
	var available_player = _get_available_sfx_player()
	if available_player and audio_cache.has(sound_name):
		available_player.stream = audio_cache[sound_name]
		available_player.volume_db = linear_to_db(volume)
		available_player.pitch_scale = pitch
		available_player.play()

func play_ui_sound(sound_name: String, volume: float = 1.0) -> void:
	"""
	Play UI-specific sounds
	
	Args:
		sound_name: Name of the UI sound to play
		volume: Volume level (0.0 to 1.0)
	"""
	var available_player = _get_available_ui_player()
	if available_player and audio_cache.has(sound_name):
		available_player.stream = audio_cache[sound_name]
		available_player.volume_db = linear_to_db(volume)
		available_player.play()

func stop_music(fade_out: float = 1.0) -> void:
	"""
	Stop background music with optional fade-out effect
	
	Args:
		fade_out: Fade-out duration in seconds
	"""
	if fade_out > 0:
		_fade_out_audio(music_player, fade_out)
	else:
		music_player.stop()
		current_music = ""

func stop_ambient(fade_out: float = 2.0) -> void:
	"""
	Stop ambient sounds with optional fade-out effect
	
	Args:
		fade_out: Fade-out duration in seconds
	"""
	if fade_out > 0:
		_fade_out_audio(ambient_player, fade_out)
	else:
		ambient_player.stop()
		current_ambient = ""

func set_volume(bus: AudioBus, volume: float) -> void:
	"""
	Set volume for a specific audio bus
	
	Args:
		bus: Audio bus to adjust
		volume: Volume level (0.0 to 1.0)
	"""
	var bus_name = AudioBus.keys()[bus].to_lower()
	var bus_index = AudioServer.get_bus_index(bus_name.capitalize())
	
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume))
		volume_changed.emit(bus, volume)

func _get_available_sfx_player() -> AudioStreamPlayer:
	"""
	Get an available SFX player from the pool
	"""
	for player in sfx_players:
		if not player.playing:
			return player
	
	# If all players are busy, create a new one
	var new_player = AudioStreamPlayer.new()
	new_player.name = "SFXPlayer" + str(sfx_players.size())
	new_player.bus = "SFX"
	new_player.finished.connect(_on_sfx_finished.bind(new_player))
	sfx_players.append(new_player)
	add_child(new_player)
	
	return new_player

func _get_available_ui_player() -> AudioStreamPlayer:
	"""
	Get an available UI player from the pool
	"""
	for player in ui_players:
		if not player.playing:
			return player
	
	# If all players are busy, create a new one
	var new_player = AudioStreamPlayer.new()
	new_player.name = "UIPlayer" + str(ui_players.size())
	new_player.bus = "UI"
	new_player.finished.connect(_on_ui_finished.bind(new_player))
	ui_players.append(new_player)
	add_child(new_player)
	
	return new_player

func _fade_in_audio(player: AudioStreamPlayer, duration: float) -> void:
	"""
	Fade in audio over specified duration
	"""
	player.volume_db = -80.0
	var tween = create_tween()
	tween.tween_property(player, "volume_db", 0.0, duration)

func _fade_out_audio(player: AudioStreamPlayer, duration: float) -> void:
	"""
	Fade out audio over specified duration
	"""
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80.0, duration)
	tween.tween_callback(player.stop)

func _on_music_finished() -> void:
	"""
	Handle music track completion
	"""
	audio_finished.emit(AudioCategory.MUSIC, current_music)

func _on_ambient_finished() -> void:
	"""
	Handle ambient track completion
	"""
	audio_finished.emit(AudioCategory.AMBIENT, current_ambient)

func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	"""
	Handle SFX completion
	"""
	# Player is automatically returned to pool
	pass

func _on_ui_finished(player: AudioStreamPlayer) -> void:
	"""
	Handle UI sound completion
	"""
	# Player is automatically returned to pool
	pass

func save_audio_settings() -> Dictionary:
	"""
	Save current audio settings
	"""
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"ambient_volume": ambient_volume,
		"ui_volume": ui_volume
	}

func load_audio_settings(settings: Dictionary) -> void:
	"""
	Load audio settings from saved data
	"""
	if settings.has("master_volume"):
		master_volume = settings.master_volume
		set_volume(AudioBus.MASTER, master_volume)
	
	if settings.has("music_volume"):
		music_volume = settings.music_volume
		set_volume(AudioBus.MUSIC, music_volume)
	
	if settings.has("sfx_volume"):
		sfx_volume = settings.sfx_volume
		set_volume(AudioBus.SFX, sfx_volume)
	
	if settings.has("ambient_volume"):
		ambient_volume = settings.ambient_volume
		set_volume(AudioBus.AMBIENT, ambient_volume)
	
	if settings.has("ui_volume"):
		ui_volume = settings.ui_volume
		set_volume(AudioBus.UI, ui_volume) 