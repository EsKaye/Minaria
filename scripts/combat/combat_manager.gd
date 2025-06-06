extends Node

# Combat state
enum CombatState {
	IDLE,
	INITIATING,
	ACTIVE,
	VICTORY,
	DEFEAT
}

var current_state: CombatState = CombatState.IDLE
var current_combatants: Array = []
var current_turn: int = 0
var turn_order: Array = []

# Combat settings
@export var max_combatants: int = 6
@export var turn_timeout: float = 30.0
@export var victory_threshold: float = 0.8

# Signals
signal combat_started(combatants: Array)
signal combat_ended(result: String)
signal turn_started(combatant: Node)
signal turn_ended(combatant: Node)
signal action_performed(action: Dictionary)
signal combatant_died(combatant: Node)
signal victory_achieved
signal defeat_occurred

func _ready() -> void:
	"""
	Initialize combat manager
	"""
	# Connect signals
	_connect_signals()

func _connect_signals() -> void:
	"""
	Connect signals from various systems
	"""
	# TODO: Connect signals when systems are created
	pass

func start_combat(combatants: Array) -> bool:
	"""
	Start a new combat encounter
	Returns true if combat started successfully
	"""
	if current_state != CombatState.IDLE:
		return false
	
	if combatants.size() > max_combatants:
		return false
	
	# Initialize combat
	current_combatants = combatants
	current_state = CombatState.INITIATING
	
	# Calculate turn order
	_calculate_turn_order()
	
	# Start first turn
	current_turn = 0
	current_state = CombatState.ACTIVE
	
	emit_signal("combat_started", current_combatants)
	emit_signal("turn_started", turn_order[current_turn])
	
	return true

func end_combat() -> void:
	"""
	End the current combat encounter
	"""
	if current_state == CombatState.IDLE:
		return
	
	# Reset combat state
	current_state = CombatState.IDLE
	current_combatants.clear()
	turn_order.clear()
	current_turn = 0
	
	emit_signal("combat_ended", "ended")

func _calculate_turn_order() -> void:
	"""
	Calculate the turn order based on combatant stats
	"""
	turn_order.clear()
	
	# Sort combatants by initiative
	var sorted_combatants = current_combatants.duplicate()
	sorted_combatants.sort_custom(_sort_by_initiative)
	
	turn_order = sorted_combatants

func _sort_by_initiative(a: Node, b: Node) -> bool:
	"""
	Sort combatants by initiative
	"""
	var a_initiative = a.get_initiative()
	var b_initiative = b.get_initiative()
	
	if a_initiative == b_initiative:
		# If initiative is equal, sort by dexterity
		return a.stats["dexterity"] > b.stats["dexterity"]
	
	return a_initiative > b_initiative

func perform_action(action: Dictionary) -> bool:
	"""
	Perform a combat action
	Returns true if action was performed successfully
	"""
	if current_state != CombatState.ACTIVE:
		return false
	
	var actor = turn_order[current_turn]
	var target = action.get("target", null)
	
	if not target or not target.is_alive():
		return false
	
	# Perform action based on type
	match action["type"]:
		"attack":
			_perform_attack(actor, target, action)
		"skill":
			_perform_skill(actor, target, action)
		"item":
			_perform_item_use(actor, target, action)
		"defend":
			_perform_defend(actor)
		_:
			return false
	
	emit_signal("action_performed", action)
	
	# Check for combat end conditions
	_check_combat_end()
	
	# If combat is still active, move to next turn
	if current_state == CombatState.ACTIVE:
		_next_turn()
	
	return true

func _perform_attack(actor: Node, target: Node, action: Dictionary) -> void:
	"""
	Perform an attack action
	"""
	# Calculate damage
	var damage = _calculate_damage(actor, target, action)
	
	# Apply damage
	target.take_damage(damage)
	
	# Check for critical hit
	if _is_critical_hit(actor):
		# TODO: Implement critical hit effects
		pass

func _perform_skill(actor: Node, target: Node, action: Dictionary) -> void:
	"""
	Perform a skill action
	"""
	# Check if actor has enough mana
	if not actor.use_mana(action["mana_cost"]):
		return
	
	# Apply skill effects
	match action["effect_type"]:
		"damage":
			var damage = _calculate_skill_damage(actor, target, action)
			target.take_damage(damage)
		"heal":
			var heal_amount = _calculate_heal_amount(actor, target, action)
			target.heal(heal_amount)
		"buff":
			_apply_buff(actor, target, action)
		"debuff":
			_apply_debuff(actor, target, action)

func _perform_item_use(actor: Node, target: Node, action: Dictionary) -> void:
	"""
	Perform an item use action
	"""
	var item = action["item"]
	
	# Use item
	if actor.inventory.use_item(item["slot"]):
		# Apply item effects
		match item["type"]:
			"consumable":
				_apply_consumable_effects(actor, target, item)
			"equipment":
				_apply_equipment_effects(actor, item)

func _perform_defend(actor: Node) -> void:
	"""
	Perform a defend action
	"""
	# Apply defense buff
	actor.add_status_effect({
		"type": "defense",
		"value": 1.5,
		"duration": 1
	})

func _calculate_damage(actor: Node, target: Node, action: Dictionary) -> float:
	"""
	Calculate damage for an attack
	"""
	var base_damage = actor.stats["strength"]
	var weapon_damage = 0
	
	# Add weapon damage if equipped
	if actor.equipment.has("weapon") and actor.equipment["weapon"] != null:
		weapon_damage = actor.equipment["weapon"]["damage"]
	
	# Calculate total damage
	var total_damage = (base_damage + weapon_damage) * action.get("damage_multiplier", 1.0)
	
	# Apply target's defense
	var defense = target.get_defense()
	total_damage = max(1, total_damage - defense)
	
	return total_damage

func _calculate_skill_damage(actor: Node, target: Node, action: Dictionary) -> float:
	"""
	Calculate damage for a skill
	"""
	var base_damage = actor.stats["intelligence"]
	var skill_power = action["power"]
	
	# Calculate total damage
	var total_damage = (base_damage + skill_power) * action.get("damage_multiplier", 1.0)
	
	# Apply target's magic defense
	var magic_defense = target.get_magic_defense()
	total_damage = max(1, total_damage - magic_defense)
	
	return total_damage

func _calculate_heal_amount(actor: Node, target: Node, action: Dictionary) -> float:
	"""
	Calculate heal amount
	"""
	var base_heal = actor.stats["intelligence"]
	var skill_power = action["power"]
	
	# Calculate total heal
	var total_heal = (base_heal + skill_power) * action.get("heal_multiplier", 1.0)
	
	return total_heal

func _is_critical_hit(actor: Node) -> bool:
	"""
	Check if an attack is a critical hit
	"""
	var crit_chance = actor.stats["dexterity"] * 0.01
	return randf() < crit_chance

func _apply_buff(actor: Node, target: Node, action: Dictionary) -> void:
	"""
	Apply a buff effect
	"""
	target.add_status_effect({
		"type": action["buff_type"],
		"value": action["value"],
		"duration": action["duration"]
	})

func _apply_debuff(actor: Node, target: Node, action: Dictionary) -> void:
	"""
	Apply a debuff effect
	"""
	target.add_status_effect({
		"type": action["debuff_type"],
		"value": action["value"],
		"duration": action["duration"]
	})

func _apply_consumable_effects(actor: Node, target: Node, item: Dictionary) -> void:
	"""
	Apply consumable item effects
	"""
	match item["effect_type"]:
		"heal":
			target.heal(item["value"])
		"mana":
			target.restore_mana(item["value"])
		"buff":
			target.add_status_effect({
				"type": item["buff_type"],
				"value": item["value"],
				"duration": item["duration"]
			})

func _apply_equipment_effects(actor: Node, item: Dictionary) -> void:
	"""
	Apply equipment effects
	"""
	# TODO: Implement equipment effects
	pass

func _next_turn() -> void:
	"""
	Move to the next turn
	"""
	emit_signal("turn_ended", turn_order[current_turn])
	
	current_turn = (current_turn + 1) % turn_order.size()
	
	# Skip dead combatants
	while not turn_order[current_turn].is_alive():
		current_turn = (current_turn + 1) % turn_order.size()
	
	emit_signal("turn_started", turn_order[current_turn])

func _check_combat_end() -> void:
	"""
	Check if combat should end
	"""
	var player_team_alive = false
	var enemy_team_alive = false
	
	for combatant in current_combatants:
		if combatant.is_alive():
			if combatant.is_player():
				player_team_alive = true
			else:
				enemy_team_alive = true
	
	if not player_team_alive:
		current_state = CombatState.DEFEAT
		emit_signal("defeat_occurred")
		end_combat()
	elif not enemy_team_alive:
		current_state = CombatState.VICTORY
		emit_signal("victory_achieved")
		end_combat()

func get_current_combatant() -> Node:
	"""
	Get the current combatant
	"""
	if current_state != CombatState.ACTIVE:
		return null
	
	return turn_order[current_turn]

func is_combat_active() -> bool:
	"""
	Check if combat is active
	"""
	return current_state == CombatState.ACTIVE

func get_combat_state() -> CombatState:
	"""
	Get current combat state
	"""
	return current_state 