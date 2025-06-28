extends CharacterBody2D
class_name PlayerCharacter

## Player Character - Main player entity for Minaria
## Implements modern character controller with state machine, component system, and comprehensive stats
## Provides smooth movement, combat abilities, and interaction systems

# Character stats and attributes
@export_group("Character Stats")
@export var base_speed: float = 300.0
@export var base_acceleration: float = 2000.0
@export var base_friction: float = 1000.0
@export var base_jump_force: float = 400.0
@export var base_health: float = 100.0
@export var base_mana: float = 100.0

# Character attributes
@export_group("Attributes")
@export var strength: int = 10
@export var dexterity: int = 10
@export var intelligence: int = 10
@export var vitality: int = 10
@export var charisma: int = 10

# Character progression
@export_group("Progression")
@export var level: int = 1
@export var experience: int = 0
@export var experience_to_next_level: int = 100

# Movement properties
@export_group("Movement")
@export var speed: float = 300.0
@export var acceleration: float = 2000.0
@export var friction: float = 1000.0
@export var rotation_speed: float = 10.0
@export var jump_force: float = 400.0
@export var air_control: float = 0.5
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

# Combat properties
@export_group("Combat")
@export var attack_damage: float = 20.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 50.0
@export var critical_chance: float = 0.05
@export var critical_multiplier: float = 2.0

# Health and mana
@export_group("Resources")
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var health_regen_rate: float = 1.0
@export var max_mana: float = 100.0
@export var current_mana: float = 100.0
@export var mana_regen_rate: float = 2.0

# Equipment system
@export_group("Equipment")
var equipment: Dictionary = {
	"weapon": null,
	"armor": null,
	"accessory_1": null,
	"accessory_2": null,
	"shield": null
}

# Inventory reference
var inventory: Node

# Component references
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var attack_area: Area2D = $AttackArea

# State machine
enum State {
	IDLE,
	MOVING,
	JUMPING,
	FALLING,
	ATTACKING,
	CASTING,
	INTERACTING,
	STUNNED,
	DEAD
}

var current_state: State = State.IDLE
var previous_state: State = State.IDLE
var state_timer: float = 0.0

# Movement state
var is_grounded: bool = false
var was_grounded: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var last_ground_position: Vector2 = Vector2.ZERO

# Combat state
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var last_attack_time: float = 0.0
var combo_count: int = 0
var max_combo: int = 3

# Interaction state
var nearby_interactables: Array[Node] = []
var current_interaction_target: Node = null

# Status effects
var status_effects: Array[Dictionary] = []
var is_stunned: bool = false
var stun_timer: float = 0.0

# Input state
var input_vector: Vector2 = Vector2.ZERO
var jump_input: bool = false
var attack_input: bool = false
var interact_input: bool = false

# Performance tracking
var frame_count: int = 0
var last_position: Vector2 = Vector2.ZERO

# Signals
signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal experience_gained(amount: int)
signal level_up(new_level: int, new_stats: Dictionary)
signal state_changed(new_state: State, old_state: State)
signal item_equipped(slot: String, item: Dictionary)
signal item_unequipped(slot: String, item: Dictionary)
signal interaction_started(target: Node)
signal interaction_completed(target: Node)
signal attack_performed(damage: float, target: Node)
signal damage_taken(amount: float, source: Node)
signal death

func _ready() -> void:
	"""
	Initialize the player character
	"""
	_initialize_character()
	_connect_signals()
	_setup_components()
	_load_character_data()

func _physics_process(delta: float) -> void:
	"""
	Main physics update loop
	"""
	_handle_input()
	_update_state_machine(delta)
	_update_movement(delta)
	_update_combat(delta)
	_update_interactions(delta)
	_update_status_effects(delta)
	_update_animations(delta)
	_update_ui(delta)

func _handle_input() -> void:
	"""
	Process player input
	"""
	if InputManager:
		input_vector = InputManager.get_input_vector()
		jump_input = InputManager.is_action_just_pressed("jump")
		attack_input = InputManager.is_action_just_pressed("attack")
		interact_input = InputManager.is_action_just_pressed("interact")

func _update_state_machine(delta: float) -> void:
	"""
	Update the character state machine
	"""
	state_timer += delta
	
	match current_state:
		State.IDLE:
			_update_idle_state(delta)
		State.MOVING:
			_update_moving_state(delta)
		State.JUMPING:
			_update_jumping_state(delta)
		State.FALLING:
			_update_falling_state(delta)
		State.ATTACKING:
			_update_attacking_state(delta)
		State.CASTING:
			_update_casting_state(delta)
		State.INTERACTING:
			_update_interacting_state(delta)
		State.STUNNED:
			_update_stunned_state(delta)
		State.DEAD:
			_update_dead_state(delta)

func _update_idle_state(delta: float) -> void:
	"""
	Update idle state behavior
	"""
	# Apply friction
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Check for movement input
	if input_vector != Vector2.ZERO:
		change_state(State.MOVING)
	
	# Check for jump input
	if jump_input and is_grounded:
		change_state(State.JUMPING)
	
	# Check for attack input
	if attack_input and can_attack():
		change_state(State.ATTACKING)
	
	# Check for interaction input
	if interact_input and can_interact():
		change_state(State.INTERACTING)
	
	# Check if falling
	if not is_grounded and velocity.y > 0:
		change_state(State.FALLING)

func _update_moving_state(delta: float) -> void:
	"""
	Update moving state behavior
	"""
	if input_vector != Vector2.ZERO:
		# Accelerate
		velocity = velocity.move_toward(input_vector * speed, acceleration * delta)
		
		# Update sprite direction
		sprite.flip_h = input_vector.x < 0
		
		# Check for jump input
		if jump_input and is_grounded:
			change_state(State.JUMPING)
		
		# Check for attack input
		if attack_input and can_attack():
			change_state(State.ATTACKING)
		
		# Check for interaction input
		if interact_input and can_interact():
			change_state(State.INTERACTING)
	else:
		# No input, return to idle
		change_state(State.IDLE)
	
	# Check if falling
	if not is_grounded and velocity.y > 0:
		change_state(State.FALLING)
	
	# Move character
	move_and_slide()

func _update_jumping_state(delta: float) -> void:
	"""
	Update jumping state behavior
	"""
	# Apply gravity
	velocity.y += get_gravity() * delta
	
	# Handle air control
	if input_vector != Vector2.ZERO:
		velocity.x = velocity.x.move_toward(input_vector.x * speed * air_control, acceleration * delta)
	
	# Update sprite direction
	sprite.flip_h = input_vector.x < 0
	
	# Check for landing
	if is_grounded and velocity.y >= 0:
		change_state(State.IDLE)
	
	# Check for attack input
	if attack_input and can_attack():
		change_state(State.ATTACKING)
	
	# Move character
	move_and_slide()

func _update_falling_state(delta: float) -> void:
	"""
	Update falling state behavior
	"""
	# Apply gravity
	velocity.y += get_gravity() * delta
	
	# Handle air control
	if input_vector != Vector2.ZERO:
		velocity.x = velocity.x.move_toward(input_vector.x * speed * air_control, acceleration * delta)
	
	# Update sprite direction
	sprite.flip_h = input_vector.x < 0
	
	# Check for landing
	if is_grounded and velocity.y >= 0:
		change_state(State.IDLE)
	
	# Check for attack input
	if attack_input and can_attack():
		change_state(State.ATTACKING)
	
	# Move character
	move_and_slide()

func _update_attacking_state(delta: float) -> void:
	"""
	Update attacking state behavior
	"""
	# Stop movement during attack
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Update attack cooldown
	attack_cooldown -= delta
	
	# Check if attack is complete
	if attack_cooldown <= 0:
		change_state(State.IDLE)
	
	# Move character
	move_and_slide()

func _update_casting_state(delta: float) -> void:
	"""
	Update casting state behavior
	"""
	# Stop movement during casting
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# TODO: Implement casting logic
	change_state(State.IDLE)
	
	# Move character
	move_and_slide()

func _update_interacting_state(delta: float) -> void:
	"""
	Update interacting state behavior
	"""
	# Stop movement during interaction
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# TODO: Implement interaction logic
	change_state(State.IDLE)
	
	# Move character
	move_and_slide()

func _update_stunned_state(delta: float) -> void:
	"""
	Update stunned state behavior
	"""
	# Apply friction
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Update stun timer
	stun_timer -= delta
	
	# Check if stun is over
	if stun_timer <= 0:
		is_stunned = false
		change_state(State.IDLE)
	
	# Move character
	move_and_slide()

func _update_dead_state(delta: float) -> void:
	"""
	Update dead state behavior
	"""
	# Stop all movement
	velocity = Vector2.ZERO
	
	# TODO: Implement death logic
	pass

func _update_movement(delta: float) -> void:
	"""
	Update movement-related systems
	"""
	# Update grounded state
	was_grounded = is_grounded
	is_grounded = is_on_floor()
	
	# Update coyote timer
	if is_grounded:
		coyote_timer = coyote_time
		last_ground_position = position
	else:
		coyote_timer -= delta
	
	# Update jump buffer
	if jump_input:
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

func _update_combat(delta: float) -> void:
	"""
	Update combat-related systems
	"""
	# Update attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# Regenerate health and mana
	_regenerate_resources(delta)

func _update_interactions(delta: float) -> void:
	"""
	Update interaction systems
	"""
	# Update nearby interactables
	_update_nearby_interactables()

func _update_status_effects(delta: float) -> void:
	"""
	Update status effects
	"""
	var effects_to_remove: Array[int] = []
	
	for i in range(status_effects.size()):
		var effect = status_effects[i]
		effect.duration -= delta
		
		if effect.duration <= 0:
			effects_to_remove.push_back(i)
		else:
			_apply_status_effect(effect, delta)
	
	# Remove expired effects
	for i in range(effects_to_remove.size() - 1, -1, -1):
		status_effects.remove_at(effects_to_remove[i])

func _update_animations(delta: float) -> void:
	"""
	Update character animations
	"""
	if animation_player:
		match current_state:
			State.IDLE:
				animation_player.play("idle")
			State.MOVING:
				animation_player.play("run")
			State.JUMPING:
				animation_player.play("jump")
			State.FALLING:
				animation_player.play("fall")
			State.ATTACKING:
				animation_player.play("attack")
			State.CASTING:
				animation_player.play("cast")
			State.INTERACTING:
				animation_player.play("interact")
			State.STUNNED:
				animation_player.play("stunned")
			State.DEAD:
				animation_player.play("death")

func _update_ui(delta: float) -> void:
	"""
	Update UI elements
	"""
	# Update health and mana displays
	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)

func _initialize_character() -> void:
	"""
	Initialize character properties
	"""
	# Set initial stats
	speed = base_speed
	acceleration = base_acceleration
	friction = base_friction
	jump_force = base_jump_force
	max_health = base_health
	current_health = base_health
	max_mana = base_mana
	current_mana = max_mana
	
	# Calculate derived stats
	_calculate_derived_stats()

func _connect_signals() -> void:
	"""
	Connect character signals
	"""
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)
	
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_entered)

func _setup_components() -> void:
	"""
	Setup character components
	"""
	# Setup interaction area
	if interaction_area:
		interaction_area.monitoring = true
		interaction_area.monitorable = false
	
	# Setup attack area
	if attack_area:
		attack_area.monitoring = false
		attack_area.monitorable = false

func _load_character_data() -> void:
	"""
	Load character data from save file
	"""
	# TODO: Load character data from save system
	pass

func change_state(new_state: State) -> void:
	"""
	Change the current state with proper cleanup and setup
	"""
	if new_state == current_state:
		return
	
	previous_state = current_state
	current_state = new_state
	state_timer = 0.0
	
	# Handle state transition
	_handle_state_transition(previous_state, new_state)
	
	# Emit signal
	state_changed.emit(new_state, previous_state)

func _handle_state_transition(old_state: State, new_state: State) -> void:
	"""
	Handle specific state transitions
	"""
	match old_state:
		State.ATTACKING:
			_end_attack()
		State.INTERACTING:
			_end_interaction()
	
	match new_state:
		State.JUMPING:
			_start_jump()
		State.ATTACKING:
			_start_attack()
		State.INTERACTING:
			_start_interaction()

func _start_jump() -> void:
	"""
	Start a jump
	"""
	velocity.y = -jump_force
	
	# Play jump sound
	if AudioManager:
		AudioManager.play_sfx("jump")

func _start_attack() -> void:
	"""
	Start an attack
	"""
	is_attacking = true
	attack_cooldown = 1.0 / attack_speed
	last_attack_time = Time.get_time_dict_from_system()
	
	# Enable attack area
	if attack_area:
		attack_area.monitoring = true
	
	# Play attack sound
	if AudioManager:
		AudioManager.play_sfx("attack")

func _end_attack() -> void:
	"""
	End the current attack
	"""
	is_attacking = false
	
	# Disable attack area
	if attack_area:
		attack_area.monitoring = false

func _start_interaction() -> void:
	"""
	Start an interaction
	"""
	if current_interaction_target:
		interaction_started.emit(current_interaction_target)
		
		# Play interaction sound
		if AudioManager:
			AudioManager.play_sfx("interact")

func _end_interaction() -> void:
	"""
	End the current interaction
	"""
	if current_interaction_target:
		interaction_completed.emit(current_interaction_target)

func can_attack() -> bool:
	"""
	Check if the character can attack
	"""
	return not is_attacking and attack_cooldown <= 0 and not is_stunned and current_state != State.DEAD

func can_interact() -> bool:
	"""
	Check if the character can interact
	"""
	return current_interaction_target != null and not is_stunned and current_state != State.DEAD

func take_damage(amount: float, source: Node = null) -> void:
	"""
	Take damage and update health
	"""
	if current_state == State.DEAD:
		return
	
	current_health = max(0, current_health - amount)
	damage_taken.emit(amount, source)
	
	# Play damage sound
	if AudioManager:
		AudioManager.play_sfx("damage")
	
	if current_health <= 0:
		die()
	else:
		# Apply damage effects
		_apply_damage_effects(amount)

func heal(amount: float) -> void:
	"""
	Heal the character
	"""
	current_health = min(max_health, current_health + amount)
	
	# Play heal sound
	if AudioManager:
		AudioManager.play_sfx("heal")

func use_mana(amount: float) -> bool:
	"""
	Use mana if available
	
	Returns:
		True if mana was used successfully
	"""
	if current_mana >= amount:
		current_mana -= amount
		return true
	return false

func gain_experience(amount: int) -> void:
	"""
	Gain experience and check for level up
	"""
	experience += amount
	experience_gained.emit(amount)
	
	# Check for level up
	while experience >= experience_to_next_level:
		level_up()

func level_up() -> void:
	"""
	Level up the character
	"""
	level += 1
	experience -= experience_to_next_level
	experience_to_next_level = _calculate_next_level_exp()
	
	# Increase stats
	strength += 1
	dexterity += 1
	intelligence += 1
	vitality += 1
	charisma += 1
	
	# Recalculate derived stats
	_calculate_derived_stats()
	
	# Heal to full on level up
	current_health = max_health
	current_mana = max_mana
	
	# Emit signal
	var new_stats = {
		"strength": strength,
		"dexterity": dexterity,
		"intelligence": intelligence,
		"vitality": vitality,
		"charisma": charisma
	}
	level_up.emit(level, new_stats)
	
	# Play level up sound
	if AudioManager:
		AudioManager.play_sfx("level_up")

func die() -> void:
	"""
	Handle character death
	"""
	change_state(State.DEAD)
	death.emit()
	
	# Play death sound
	if AudioManager:
		AudioManager.play_sfx("death")

func get_gravity() -> float:
	"""
	Get the current gravity value
	"""
	return ProjectSettings.get_setting("physics/2d/default_gravity")

func _calculate_derived_stats() -> void:
	"""
	Calculate stats derived from base attributes
	"""
	# Health based on vitality
	max_health = base_health + (vitality * 10)
	
	# Mana based on intelligence
	max_mana = base_mana + (intelligence * 5)
	
	# Speed based on dexterity
	speed = base_speed + (dexterity * 5)
	
	# Attack damage based on strength
	attack_damage = 20.0 + (strength * 2)
	
	# Attack speed based on dexterity
	attack_speed = 1.0 + (dexterity * 0.1)

func _calculate_next_level_exp() -> int:
	"""
	Calculate experience required for next level
	"""
	return 100 + (level * 50)

func _regenerate_resources(delta: float) -> void:
	"""
	Regenerate health and mana over time
	"""
	# Health regeneration
	if current_health < max_health:
		current_health = min(max_health, current_health + health_regen_rate * delta)
	
	# Mana regeneration
	if current_mana < max_mana:
		current_mana = min(max_mana, current_mana + mana_regen_rate * delta)

func _update_nearby_interactables() -> void:
	"""
	Update the list of nearby interactable objects
	"""
	nearby_interactables.clear()
	
	# Get overlapping bodies in interaction area
	if interaction_area:
		var bodies = interaction_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("interactable"):
				nearby_interactables.append(body)
		
		# Update current interaction target
		if nearby_interactables.size() > 0:
			current_interaction_target = nearby_interactables[0]
		else:
			current_interaction_target = null

func _apply_status_effect(effect: Dictionary, delta: float) -> void:
	"""
	Apply a status effect
	"""
	match effect.type:
		"poison":
			take_damage(effect.damage * delta)
		"heal":
			heal(effect.healing * delta)
		"speed_boost":
			speed = base_speed * effect.multiplier
		"speed_reduction":
			speed = base_speed * effect.multiplier

func _apply_damage_effects(amount: float) -> void:
	"""
	Apply effects when taking damage
	"""
	# Visual feedback
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _on_interaction_area_entered(body: Node2D) -> void:
	"""
	Handle interaction area entry
	"""
	if body.is_in_group("interactable"):
		nearby_interactables.append(body)
		if not current_interaction_target:
			current_interaction_target = body

func _on_interaction_area_exited(body: Node2D) -> void:
	"""
	Handle interaction area exit
	"""
	if body in nearby_interactables:
		nearby_interactables.erase(body)
		if current_interaction_target == body:
			if nearby_interactables.size() > 0:
				current_interaction_target = nearby_interactables[0]
			else:
				current_interaction_target = null

func _on_attack_area_entered(body: Node2D) -> void:
	"""
	Handle attack area entry
	"""
	if body.is_in_group("enemy") and is_attacking:
		# Calculate damage
		var damage = attack_damage
		
		# Check for critical hit
		if randf() < critical_chance:
			damage *= critical_multiplier
		
		# Apply damage to target
		if body.has_method("take_damage"):
			body.take_damage(damage, self)
		
		attack_performed.emit(damage, body)

func get_character_data() -> Dictionary:
	"""
	Get character data for saving
	"""
	return {
		"position": position,
		"health": current_health,
		"mana": current_mana,
		"level": level,
		"experience": experience,
		"strength": strength,
		"dexterity": dexterity,
		"intelligence": intelligence,
		"vitality": vitality,
		"charisma": charisma,
		"equipment": equipment
	}

func load_character_data(data: Dictionary) -> void:
	"""
	Load character data from save
	"""
	if data.has("position"):
		position = data.position
	
	if data.has("health"):
		current_health = data.health
	
	if data.has("mana"):
		current_mana = data.mana
	
	if data.has("level"):
		level = data.level
	
	if data.has("experience"):
		experience = data.experience
	
	if data.has("strength"):
		strength = data.strength
	
	if data.has("dexterity"):
		dexterity = data.dexterity
	
	if data.has("intelligence"):
		intelligence = data.intelligence
	
	if data.has("vitality"):
		vitality = data.vitality
	
	if data.has("charisma"):
		charisma = data.charisma
	
	if data.has("equipment"):
		equipment = data.equipment
	
	# Recalculate derived stats
	_calculate_derived_stats() 