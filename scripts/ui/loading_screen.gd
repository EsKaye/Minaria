extends Control

# UI references
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var loading_text: Label = $VBoxContainer/LoadingText

# Loading state
var loading_progress: float = 0.0
var target_scene: String = ""
var loading_steps: Array[String] = []
var current_step: int = 0

# Animation
var fade_duration: float = 0.5
var is_fading: bool = false

func _ready():
	# Hide loading screen initially
	modulate.a = 0
	visible = false

func start_loading(scene_path: String, steps: Array[String] = []):
	"""
	Start loading a new scene with optional loading steps
	"""
	target_scene = scene_path
	loading_steps = steps
	current_step = 0
	loading_progress = 0.0
	
	# Show loading screen
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	await tween.finished
	
	# Start loading process
	_load_scene()

func _load_scene():
	"""
	Load the target scene
	"""
	# Start loading the scene
	var loader = ResourceLoader.load_interactive(target_scene)
	
	# Update progress while loading
	while true:
		var err = loader.poll()
		
		if err == ERR_FILE_EOF: # Finished loading
			var resource = loader.get_resource()
			_loading_complete(resource)
			break
		elif err == OK:
			# Update progress
			loading_progress = float(loader.get_stage()) / loader.get_stage_count()
			_update_progress()
		
		await get_tree().create_timer(0.1).timeout

func _update_progress():
	"""
	Update the loading progress UI
	"""
	progress_bar.value = loading_progress * 100
	
	# Update loading text if we have steps
	if not loading_steps.is_empty():
		var step_progress = float(current_step) / loading_steps.size()
		var total_progress = (step_progress + loading_progress) / 2
		progress_bar.value = total_progress * 100
		
		if current_step < loading_steps.size():
			loading_text.text = loading_steps[current_step]

func _loading_complete(resource: Resource):
	"""
	Handle scene loading completion
	"""
	# Move to next step if we have steps
	if not loading_steps.is_empty():
		current_step += 1
		if current_step < loading_steps.size():
			_update_progress()
			await get_tree().create_timer(0.5).timeout
			_loading_complete(resource)
			return
	
	# Change to the new scene
	get_tree().change_scene_to_packed(resource)
	
	# Fade out loading screen
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await tween.finished
	visible = false

func set_loading_text(text: String):
	"""
	Set the loading text message
	"""
	loading_text.text = text

func set_progress(progress: float):
	"""
	Set the loading progress (0.0 to 1.0)
	"""
	loading_progress = clamp(progress, 0.0, 1.0)
	progress_bar.value = loading_progress * 100 