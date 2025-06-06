extends Node

# Animation properties
const FADE_DURATION = 0.3
const SLIDE_DURATION = 0.3
const SCALE_DURATION = 0.2

# Animation states
var current_animations = {}

func fade_in(node: Control, duration: float = FADE_DURATION):
	"""
	Fade in a UI element
	"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	node.modulate.a = 0
	node.show()
	
	tween.tween_property(node, "modulate:a", 1.0, duration)
	
	current_animations[node] = tween
	tween.finished.connect(_on_animation_finished.bind(node))

func fade_out(node: Control, duration: float = FADE_DURATION):
	"""
	Fade out a UI element
	"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(node, "modulate:a", 0.0, duration)
	tween.tween_callback(node.hide)
	
	current_animations[node] = tween
	tween.finished.connect(_on_animation_finished.bind(node))

func slide_in(node: Control, direction: Vector2, duration: float = SLIDE_DURATION):
	"""
	Slide in a UI element from a direction
	"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	var start_pos = node.position
	var target_pos = start_pos
	
	# Calculate start position based on direction
	if direction.x != 0:
		start_pos.x += direction.x * node.size.x
	if direction.y != 0:
		start_pos.y += direction.y * node.size.y
	
	node.position = start_pos
	node.show()
	
	tween.tween_property(node, "position", target_pos, duration)
	
	current_animations[node] = tween
	tween.finished.connect(_on_animation_finished.bind(node))

func slide_out(node: Control, direction: Vector2, duration: float = SLIDE_DURATION):
	"""
	Slide out a UI element in a direction
	"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	var start_pos = node.position
	var target_pos = start_pos
	
	# Calculate target position based on direction
	if direction.x != 0:
		target_pos.x += direction.x * node.size.x
	if direction.y != 0:
		target_pos.y += direction.y * node.size.y
	
	tween.tween_property(node, "position", target_pos, duration)
	tween.tween_callback(node.hide)
	
	current_animations[node] = tween
	tween.finished.connect(_on_animation_finished.bind(node))

func scale_in(node: Control, duration: float = SCALE_DURATION):
	"""
	Scale in a UI element
	"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	node.scale = Vector2.ZERO
	node.show()
	
	tween.tween_property(node, "scale", Vector2.ONE, duration)
	
	current_animations[node] = tween
	tween.finished.connect(_on_animation_finished.bind(node))

func scale_out(node: Control, duration: float = SCALE_DURATION):
	"""
	Scale out a UI element
	"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(node, "scale", Vector2.ZERO, duration)
	tween.tween_callback(node.hide)
	
	current_animations[node] = tween
	tween.finished.connect(_on_animation_finished.bind(node))

func shake(node: Control, strength: float = 10.0, duration: float = 0.5):
	"""
	Shake a UI element
	"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	var start_pos = node.position
	
	# Create shake effect
	for i in range(5):
		var offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		tween.tween_property(node, "position", start_pos + offset, duration / 10)
		tween.tween_property(node, "position", start_pos, duration / 10)
	
	current_animations[node] = tween
	tween.finished.connect(_on_animation_finished.bind(node))

func _on_animation_finished(node: Control):
	"""
	Handle animation completion
	"""
	if current_animations.has(node):
		current_animations.erase(node)

func stop_animations(node: Control):
	"""
	Stop all animations for a node
	"""
	if current_animations.has(node):
		current_animations[node].kill()
		current_animations.erase(node) 