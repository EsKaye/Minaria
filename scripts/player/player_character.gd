extends CharacterBody2D

# Movement properties
@export var speed: float = 300.0
@export var acceleration: float = 2000.0
@export var friction: float = 1000.0
@export var rotation_speed: float = 10.0

# Stats
var stats: Dictionary = {
	"strength": 10,
	"dexterity": 10,
	"intelligence": 10,
	"vitality": 10,
	"level": 1,
	"experience": 0
}

# Health and mana
var max_health: float = 100.0
var current_health: float = 100.0
var max_mana: float = 100.0
var current_mana: float = 100.0

# Equipment
var equipment: Dictionary = {
	"weapon": null,
	"armor": null,
	"accessory": null
}

# Inventory reference
var inventory: Node

# Animation player reference
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

# State machine
enum State {
	IDLE,
	MOVING,
	ATTACKING,
	CASTING,
	INTERACTING,
	DEAD
}

var current_state: State = State.IDLE
var previous_state: State = State.IDLE

# Signals
signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal experience_gained(amount: int)
signal level_up(new_level: int)
signal state_changed(new_state: State, old_state: State)
signal item_equipped(slot: String, item: Dictionary)
signal item_unequipped(slot: String, item: Dictionary)

func _ready():
	# Initialize stats based on class
	_initialize_stats()
	
	# Connect signals
	_connect_signals()

func _initialize_stats() -> void:
	"""
	Initialize character stats based on class
	"""
	# TODO: Set stats based on character class
	pass

func _connect_signals() -> void:
	"""
	Connect signals from various systems
	"""
	# TODO: Connect signals when systems are created
	pass

func _physics_process(delta: float) -> void:
	"""
	Handle physics updates
	"""
	match current_state:
		State.IDLE:
			_handle_idle_state(delta)
		State.MOVING:
			_handle_moving_state(delta)
		State.ATTACKING:
			_handle_attacking_state(delta)
		State.CASTING:
			_handle_casting_state(delta)
		State.INTERACTING:
			_handle_interacting_state(delta)
		State.DEAD:
			_handle_dead_state(delta)

func _handle_idle_state(delta: float) -> void:
	"""
	Handle idle state behavior
	"""
	# Apply friction
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Check for movement input
	var input_vector = _get_movement_input()
	if input_vector != Vector2.ZERO:
		change_state(State.MOVING)
	
	# Update animation
	animation_player.play("idle")

func _handle_moving_state(delta: float) -> void:
	"""
	Handle moving state behavior
	"""
	# Get movement input
	var input_vector = _get_movement_input()
	
	if input_vector != Vector2.ZERO:
		# Accelerate
		velocity = velocity.move_toward(input_vector * speed, acceleration * delta)
		
		# Update sprite direction
		sprite.flip_h = input_vector.x < 0
		
		# Update animation
		animation_player.play("run")
	else:
		# No input, return to idle
		change_state(State.IDLE)
	
	# Move character
	move_and_slide()

func _handle_attacking_state(delta: float) -> void:
	"""
	Handle attacking state behavior
	"""
	# TODO: Implement attack logic
	pass

func _handle_casting_state(delta: float) -> void:
	"""
	Handle casting state behavior
	"""
	# TODO: Implement spell casting logic
	pass

func _handle_interacting_state(delta: float) -> void:
	"""
	Handle interacting state behavior
	"""
	# TODO: Implement interaction logic
	pass

func _handle_dead_state(delta: float) -> void:
	"""
	Handle dead state behavior
	"""
	# TODO: Implement death logic
	pass

func _get_movement_input() -> Vector2:
	"""
	Get normalized movement input vector
	"""
	var input_vector = Vector2.ZERO
	
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	
	return input_vector.normalized()

func change_state(new_state: State) -> void:
	"""
	Change the current state
	"""
	if new_state == current_state:
		return
	
	previous_state = current_state
	current_state = new_state
	
	emit_signal("state_changed", current_state, previous_state)

func take_damage(amount: float) -> void:
	"""
	Take damage and update health
	"""
	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)
	
	if current_health <= 0:
		change_state(State.DEAD)

func heal(amount: float) -> void:
	"""
	Heal and update health
	"""
	current_health = min(max_health, current_health + amount)
	emit_signal("health_changed", current_health, max_health)

func use_mana(amount: float) -> bool:
	"""
	Use mana if available
	"""
	if current_mana >= amount:
		current_mana -= amount
		emit_signal("mana_changed", current_mana, max_mana)
		return true
	return false

func restore_mana(amount: float) -> void:
	"""
	Restore mana
	"""
	current_mana = min(max_mana, current_mana + amount)
	emit_signal("mana_changed", current_mana, max_mana)

func gain_experience(amount: int) -> void:
	"""
	Gain experience and check for level up
	"""
	stats["experience"] += amount
	emit_signal("experience_gained", amount)
	
	# Check for level up
	var exp_needed = _get_exp_for_level(stats["level"] + 1)
	if stats["experience"] >= exp_needed:
		_level_up()

func _level_up() -> void:
	"""
	Handle level up
	"""
	stats["level"] += 1
	stats["experience"] = 0
	
	# Increase stats
	stats["strength"] += 2
	stats["dexterity"] += 2
	stats["intelligence"] += 2
	stats["vitality"] += 2
	
	# Update derived stats
	max_health = 100 + (stats["vitality"] * 10)
	max_mana = 100 + (stats["intelligence"] * 5)
	
	# Restore health and mana
	current_health = max_health
	current_mana = max_mana
	
	emit_signal("level_up", stats["level"])
	emit_signal("health_changed", current_health, max_health)
	emit_signal("mana_changed", current_mana, max_mana)

func _get_exp_for_level(level: int) -> int:
	"""
	Calculate experience needed for a level
	"""
	return level * 100

func equip_item(slot: String, item: Dictionary) -> void:
	"""
	Equip an item
	"""
	if equipment.has(slot):
		unequip_item(slot)
	
	equipment[slot] = item
	emit_signal("item_equipped", slot, item)
	
	# Apply item stats
	_apply_item_stats(item)

func unequip_item(slot: String) -> void:
	"""
	Unequip an item
	"""
	if equipment.has(slot) and equipment[slot] != null:
		var item = equipment[slot]
		equipment[slot] = null
		emit_signal("item_unequipped", slot, item)
		
		# Remove item stats
		_remove_item_stats(item)

func _apply_item_stats(item: Dictionary) -> void:
	"""
	Apply item stats to character
	"""
	# TODO: Implement stat modification
	pass

func _remove_item_stats(item: Dictionary) -> void:
	"""
	Remove item stats from character
	"""
	# TODO: Implement stat removal
	pass 