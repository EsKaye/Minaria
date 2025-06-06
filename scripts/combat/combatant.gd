extends CharacterBody2D

# Combatant Properties
@export var combatant_name: String = "Combatant"
@export var max_health: float = 100.0
@export var max_mana: float = 50.0
@export var strength: int = 10
@export var dexterity: int = 10
@export var intelligence: int = 10
@export var vitality: int = 10

# Current Stats
var current_health: float
var current_mana: float
var current_experience: int = 0
var level: int = 1

# Combat State
enum CombatState { IDLE, ATTACKING, CASTING, DEFENDING, DEAD }
var current_state: int = CombatState.IDLE
var is_defending: bool = false
var defense_multiplier: float = 1.0

# Equipment
var equipped_weapon: Dictionary = {}
var equipped_armor: Dictionary = {}
var equipped_accessory: Dictionary = {}

# Skills
var available_skills: Array[Dictionary] = []
var skill_cooldowns: Dictionary = {}

# References
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var weapon_pivot = $WeaponPivot
@onready var weapon_sprite = $WeaponPivot/WeaponSprite

# Signals
signal health_changed(new_health: float)
signal mana_changed(new_mana: float)
signal state_changed(new_state: int)
signal died

func _ready() -> void:
	# Initialize stats
	current_health = max_health
	current_mana = max_mana
	
	# Load default skills
	_load_default_skills()
	
	# Connect signals
	$InteractionArea.area_entered.connect(_on_interaction_area_entered)
	$InteractionArea.area_exited.connect(_on_interaction_area_exited)

func _load_default_skills() -> void:
	# Add basic attack skill
	available_skills.append({
		"name": "Basic Attack",
		"description": "A basic physical attack",
		"damage_type": "physical",
		"base_damage": 10,
		"mana_cost": 0,
		"cooldown": 0,
		"target_type": "single",
		"animation": "attack"
	})

func take_damage(amount: float, damage_type: String = "physical") -> void:
	if current_state == CombatState.DEAD:
		return
	
	# Apply defense if defending
	if is_defending:
		amount *= defense_multiplier
	
	# Apply armor reduction if applicable
	if equipped_armor.has("damage_reduction"):
		amount *= (1.0 - equipped_armor.damage_reduction)
	
	# Apply damage
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	
	# Check for death
	if current_health <= 0:
		_die()
	
	# Play hit animation
	animation_player.play("hit")

func heal(amount: float) -> void:
	if current_state == CombatState.DEAD:
		return
	
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)

func use_mana(amount: float) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		mana_changed.emit(current_mana)
		return true
	return false

func restore_mana(amount: float) -> void:
	current_mana = min(max_mana, current_mana + amount)
	mana_changed.emit(current_mana)

func gain_experience(amount: int) -> void:
	current_experience += amount
	
	# Check for level up
	var exp_needed = level * 100  # Simple level up formula
	if current_experience >= exp_needed:
		level_up()

func level_up() -> void:
	level += 1
	current_experience = 0
	
	# Increase stats
	max_health += vitality * 5
	max_mana += intelligence * 2
	strength += 1
	dexterity += 1
	intelligence += 1
	vitality += 1
	
	# Restore health and mana
	current_health = max_health
	current_mana = max_mana
	
	# Emit signals
	health_changed.emit(current_health)
	mana_changed.emit(current_mana)

func perform_attack(target: Node) -> void:
	if current_state == CombatState.DEAD:
		return
	
	current_state = CombatState.ATTACKING
	state_changed.emit(current_state)
	
	# Calculate damage
	var base_damage = strength * 2
	if equipped_weapon.has("damage"):
		base_damage += equipped_weapon.damage
	
	# Apply critical hit chance based on dexterity
	var crit_chance = dexterity * 0.01
	if randf() < crit_chance:
		base_damage *= 1.5
	
	# Play attack animation
	animation_player.play("attack")
	
	# Apply damage to target
	target.take_damage(base_damage)
	
	# Return to idle state
	await animation_player.animation_finished
	current_state = CombatState.IDLE
	state_changed.emit(current_state)

func use_skill(skill: Dictionary, target: Node) -> void:
	if current_state == CombatState.DEAD:
		return
	
	# Check cooldown
	if skill_cooldowns.has(skill.name) and skill_cooldowns[skill.name] > 0:
		return
	
	# Check mana cost
	if not use_mana(skill.mana_cost):
		return
	
	current_state = CombatState.CASTING
	state_changed.emit(current_state)
	
	# Play skill animation
	animation_player.play(skill.animation)
	
	# Calculate damage
	var base_damage = skill.base_damage
	match skill.damage_type:
		"physical":
			base_damage += strength
		"magical":
			base_damage += intelligence
	
	# Apply damage to target
	target.take_damage(base_damage, skill.damage_type)
	
	# Set cooldown
	skill_cooldowns[skill.name] = skill.cooldown
	
	# Return to idle state
	await animation_player.animation_finished
	current_state = CombatState.IDLE
	state_changed.emit(current_state)

func defend() -> void:
	if current_state == CombatState.DEAD:
		return
	
	current_state = CombatState.DEFENDING
	state_changed.emit(current_state)
	
	is_defending = true
	defense_multiplier = 0.5  # Reduce incoming damage by 50%
	
	# Play defend animation
	animation_player.play("defend")

func end_defense() -> void:
	is_defending = false
	defense_multiplier = 1.0
	
	if current_state == CombatState.DEFENDING:
		current_state = CombatState.IDLE
		state_changed.emit(current_state)

func _die() -> void:
	current_state = CombatState.DEAD
	state_changed.emit(current_state)
	
	# Play death animation
	animation_player.play("death")
	
	# Emit death signal
	died.emit()

func _on_interaction_area_entered(area: Area2D) -> void:
	# Handle interaction with other combatants
	pass

func _on_interaction_area_exited(area: Area2D) -> void:
	# Handle end of interaction
	pass

func _process(delta: float) -> void:
	# Update cooldowns
	for skill_name in skill_cooldowns.keys():
		if skill_cooldowns[skill_name] > 0:
			skill_cooldowns[skill_name] -= delta 