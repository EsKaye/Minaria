extends CharacterBody2D

# Player movement parameters
@export var speed = 300.0
@export var jump_velocity = -400.0
@export var gravity = 980.0

# Player state
var is_interacting = false
var current_layer = 0  # For 2.5D layer system

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity_scale = 1.0

func _ready():
	# Initialize player state
	pass

func _physics_process(delta):
	# Add the gravity
	if not is_on_floor():
		velocity.y += gravity * gravity_scale * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	# Handle interaction
	if Input.is_action_just_pressed("interact"):
		interact()

	move_and_slide()

func interact():
	"""
	Handle player interaction with objects in the world
	"""
	is_interacting = true
	# TODO: Implement interaction logic
	# - Check for interactable objects in range
	# - Trigger appropriate interaction
	# - Handle crafting interface
	is_interacting = false

func change_layer(new_layer: int):
	"""
	Change the player's current layer in the 2.5D world
	"""
	if new_layer >= 0 and new_layer < 3:  # Assuming 3 layers for now
		current_layer = new_layer
		# TODO: Implement layer transition effects
		# - Update z-index
		# - Handle collision layers
		# - Trigger transition animations 