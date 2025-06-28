extends Node
class_name CombatManager

## Combat Manager - Advanced combat system for Minaria
## Provides comprehensive turn-based combat with modern mechanics, status effects, and AI integration
## Implements sophisticated combat patterns with performance optimization and extensible design

# Combat states
enum CombatState {
	IDLE,
	INITIATING,
	ACTIVE,
	VICTORY,
	DEFEAT,
	PAUSED
}

# Combat phases
enum CombatPhase {
	INITIATIVE,
	PLANNING,
	EXECUTION,
	RESOLUTION
}

# Action types
enum ActionType {
	ATTACK,
	SKILL,
	ITEM,
	DEFEND,
	FLEE,
	SPECIAL
}

# Combat configuration
@export_group("Combat Configuration")
@export var max_combatants: int = 8
@export var turn_timeout: float = 30.0
@export var victory_threshold: float = 0.8
@export var auto_combat_enabled: bool = false
@export var combat_speed: float = 1.0

# Combat state
var current_state: CombatState = CombatState.IDLE
var current_phase: CombatPhase = CombatPhase.INITIATIVE
var current_combatants: Array[Node] = []
var current_turn: int = 0
var turn_order: Array[Node] = []
var round_number: int = 0

# Combat timing
var turn_timer: float = 0.0
var action_timer: float = 0.0
var animation_timer: float = 0.0
var phase_timer: float = 0.0

# Combat data
var combat_history: Array[Dictionary] = []
var action_queue: Array[Dictionary] = []
var pending_actions: Array[Dictionary] = []
var status_effects: Dictionary = {}

# Performance tracking
var combat_start_time: float = 0.0
var turn_count: int = 0
var action_count: int = 0
var performance_data: Dictionary = {}

# AI and automation
var ai_combatants: Array[Node] = []
var auto_combat_timer: float = 0.0
var auto_combat_delay: float = 1.0

# Combat environment
var combat_environment: Dictionary = {}
var terrain_effects: Array[Dictionary] = []
var weather_effects: Array[Dictionary] = []

# Signals
signal combat_started(combatants: Array, environment: Dictionary)
signal combat_ended(result: String, duration: float)
signal turn_started(combatant: Node, turn_number: int)
signal turn_ended(combatant: Node, turn_number: int)
signal action_performed(action: Dictionary, result: Dictionary)
signal action_queued(action: Dictionary)
signal combatant_died(combatant: Node, killer: Node)
signal combatant_revived(combatant: Node)
signal status_effect_applied(combatant: Node, effect: Dictionary)
signal status_effect_removed(combatant: Node, effect: Dictionary)
signal victory_achieved(winner_team: String)
signal defeat_occurred(loser_team: String)
signal combat_paused
signal combat_resumed
signal phase_changed(new_phase: CombatPhase)
signal round_started(round_number: int)

func _ready() -> void:
	"""
	Initialize the combat manager system
	"""
	_initialize_combat_systems()
	_connect_signals()
	_setup_performance_tracking()

func _process(delta: float) -> void:
	"""
	Main combat update loop
	"""
	delta *= combat_speed
	
	_update_combat_timing(delta)
	_update_combat_phases(delta)
	_update_ai_combatants(delta)
	_update_status_effects(delta)
	_update_performance_tracking(delta)

func _initialize_combat_systems() -> void:
	"""
	Initialize all combat systems
	"""
	# Initialize combat data structures
	combat_history.clear()
	action_queue.clear()
	pending_actions.clear()
	status_effects.clear()
	
	# Reset combat state
	current_state = CombatState.IDLE
	current_phase = CombatPhase.INITIATIVE
	current_turn = 0
	round_number = 0

func _connect_signals() -> void:
	"""
	Connect combat-related signals
	"""
	# Connect to game manager signals
	if GameManager:
		GameManager.game_state_changed.connect(_on_game_state_changed)
		GameManager.game_paused.connect(_on_game_paused)

func start_combat(combatants: Array, environment: Dictionary = {}) -> bool:
	"""
	Start a new combat encounter
	
	Args:
		combatants: Array of combatant nodes
		environment: Combat environment data
		
	Returns:
		True if combat started successfully
	"""
	if current_state != CombatState.IDLE:
		return false
	
	if combatants.size() > max_combatants:
		return false
	
	# Initialize combat
	current_combatants = combatants
	combat_environment = environment
	current_state = CombatState.INITIATING
	combat_start_time = Time.get_time_dict_from_system()
	
	# Setup combat environment
	_setup_combat_environment(environment)
	
	# Calculate turn order
	_calculate_turn_order()
	
	# Initialize combatants
	_initialize_combatants()
	
	# Start first turn
	current_turn = 0
	round_number = 1
	current_state = CombatState.ACTIVE
	current_phase = CombatPhase.INITIATIVE
	
	# Emit signals
	combat_started.emit(current_combatants, combat_environment)
	round_started.emit(round_number)
	turn_started.emit(turn_order[current_turn], current_turn)
	
	return true

func end_combat(result: String = "ended") -> void:
	"""
	End the current combat encounter
	
	Args:
		result: Result of the combat (victory, defeat, fled, etc.)
	"""
	if current_state == CombatState.IDLE:
		return
	
	# Calculate combat duration
	var combat_duration = Time.get_time_dict_from_system() - combat_start_time
	
	# Reset combat state
	current_state = CombatState.IDLE
	current_phase = CombatPhase.INITIATIVE
	current_combatants.clear()
	turn_order.clear()
	current_turn = 0
	round_number = 0
	
	# Clear combat data
	combat_history.clear()
	action_queue.clear()
	pending_actions.clear()
	status_effects.clear()
	
	# Emit signals
	combat_ended.emit(result, combat_duration)

func pause_combat() -> void:
	"""
	Pause the current combat
	"""
	if current_state == CombatState.ACTIVE:
		current_state = CombatState.PAUSED
		combat_paused.emit()

func resume_combat() -> void:
	"""
	Resume the paused combat
	"""
	if current_state == CombatState.PAUSED:
		current_state = CombatState.ACTIVE
		combat_resumed.emit()

func queue_action(action: Dictionary) -> bool:
	"""
	Queue an action for execution
	
	Args:
		action: Action data dictionary
		
	Returns:
		True if action was queued successfully
	"""
	if current_state != CombatState.ACTIVE:
		return false
	
	# Validate action
	if not _validate_action(action):
		return false
	
	# Add action to queue
	action_queue.append(action)
	action_queued.emit(action)
	
	return true

func execute_action(action: Dictionary) -> Dictionary:
	"""
	Execute a combat action immediately
	
	Args:
		action: Action data dictionary
		
	Returns:
		Result dictionary containing action outcome
	"""
	if current_state != CombatState.ACTIVE:
		return {"success": false, "error": "Combat not active"}
	
	# Validate action
	if not _validate_action(action):
		return {"success": false, "error": "Invalid action"}
	
	# Execute action based on type
	var result = {}
	match action.get("type", ""):
		ActionType.ATTACK:
			result = _execute_attack_action(action)
		ActionType.SKILL:
			result = _execute_skill_action(action)
		ActionType.ITEM:
			result = _execute_item_action(action)
		ActionType.DEFEND:
			result = _execute_defend_action(action)
		ActionType.FLEE:
			result = _execute_flee_action(action)
		ActionType.SPECIAL:
			result = _execute_special_action(action)
		_:
			result = {"success": false, "error": "Unknown action type"}
	
	# Record action in history
	combat_history.append({
		"turn": current_turn,
		"round": round_number,
		"action": action,
		"result": result,
		"timestamp": Time.get_time_dict_from_system()
	})
	
	# Emit action performed signal
	action_performed.emit(action, result)
	
	# Check for combat end conditions
	_check_combat_end_conditions()
	
	return result

func _execute_attack_action(action: Dictionary) -> Dictionary:
	"""
	Execute an attack action
	
	Args:
		action: Attack action data
		
	Returns:
		Attack result dictionary
	"""
	var actor = action.get("actor")
	var target = action.get("target")
	
	if not actor or not target:
		return {"success": false, "error": "Invalid actor or target"}
	
	# Calculate attack data
	var attack_data = _calculate_attack_data(actor, target, action)
	
	# Apply damage
	var damage_result = target.take_damage(attack_data.damage, attack_data.damage_type)
	
	# Check for critical hit
	if attack_data.is_critical:
		_apply_critical_hit_effects(actor, target, attack_data)
	
	# Check for status effects
	if attack_data.status_effects.size() > 0:
		for effect in attack_data.status_effects:
			_apply_status_effect(target, effect)
	
	# Check for death
	if not target.is_alive():
		_handle_combatant_death(target, actor)
	
	return {
		"success": true,
		"damage": attack_data.damage,
		"is_critical": attack_data.is_critical,
		"status_effects": attack_data.status_effects,
		"target_died": not target.is_alive()
	}

func _execute_skill_action(action: Dictionary) -> Dictionary:
	"""
	Execute a skill action
	
	Args:
		action: Skill action data
		
	Returns:
		Skill result dictionary
	"""
	var actor = action.get("actor")
	var target = action.get("target")
	var skill = action.get("skill")
	
	if not actor or not target or not skill:
		return {"success": false, "error": "Invalid skill action data"}
	
	# Check mana cost
	if not actor.use_mana(skill.mana_cost):
		return {"success": false, "error": "Insufficient mana"}
	
	# Calculate skill effects
	var skill_data = _calculate_skill_data(actor, target, skill)
	
	# Apply skill effects
	var results = []
	for effect in skill_data.effects:
		var effect_result = _apply_skill_effect(actor, target, effect)
		results.append(effect_result)
	
	return {
		"success": true,
		"effects": results,
		"mana_cost": skill.mana_cost
	}

func _execute_item_action(action: Dictionary) -> Dictionary:
	"""
	Execute an item use action
	
	Args:
		action: Item action data
		
	Returns:
		Item result dictionary
	"""
	var actor = action.get("actor")
	var target = action.get("target")
	var item = action.get("item")
	
	if not actor or not target or not item:
		return {"success": false, "error": "Invalid item action data"}
	
	# Use item from inventory
	if not actor.inventory.use_item(item.slot):
		return {"success": false, "error": "Item not available"}
	
	# Apply item effects
	var item_data = _calculate_item_data(actor, target, item)
	var results = []
	
	for effect in item_data.effects:
		var effect_result = _apply_item_effect(actor, target, effect)
		results.append(effect_result)
	
	return {
		"success": true,
		"effects": results,
		"item_consumed": true
	}

func _execute_defend_action(action: Dictionary) -> Dictionary:
	"""
	Execute a defend action
	
	Args:
		action: Defend action data
		
	Returns:
		Defend result dictionary
	"""
	var actor = action.get("actor")
	
	if not actor:
		return {"success": false, "error": "Invalid actor"}
	
	# Apply defense buff
	var defense_effect = {
		"type": "defense",
		"value": 1.5,
		"duration": 1,
		"source": "defend_action"
	}
	
	_apply_status_effect(actor, defense_effect)
	
	return {
		"success": true,
		"defense_bonus": 1.5,
		"duration": 1
	}

func _execute_flee_action(action: Dictionary) -> Dictionary:
	"""
	Execute a flee action
	
	Args:
		action: Flee action data
		
	Returns:
		Flee result dictionary
	"""
	var actor = action.get("actor")
	
	if not actor:
		return {"success": false, "error": "Invalid actor"}
	
	# Calculate flee chance
	var flee_chance = _calculate_flee_chance(actor)
	var flee_successful = randf() < flee_chance
	
	if flee_successful:
		# Remove actor from combat
		current_combatants.erase(actor)
		turn_order.erase(actor)
		
		# Check if all players fled
		if _all_players_fled():
			end_combat("fled")
	
	return {
		"success": true,
		"flee_successful": flee_successful,
		"flee_chance": flee_chance
	}

func _execute_special_action(action: Dictionary) -> Dictionary:
	"""
	Execute a special action
	
	Args:
		action: Special action data
		
	Returns:
		Special action result dictionary
	"""
	# Special actions are custom implementations
	var special_type = action.get("special_type", "")
	
	match special_type:
		"summon":
			return _execute_summon_action(action)
		"transform":
			return _execute_transform_action(action)
		"ultimate":
			return _execute_ultimate_action(action)
		_:
			return {"success": false, "error": "Unknown special action type"}

func _calculate_attack_data(actor: Node, target: Node, action: Dictionary) -> Dictionary:
	"""
	Calculate attack data including damage, critical hits, and effects
	
	Args:
		actor: Attacking combatant
		target: Target combatant
		action: Attack action data
		
	Returns:
		Attack data dictionary
	"""
	var base_damage = actor.stats.get("strength", 10)
	var weapon_damage = 0
	var weapon = actor.equipment.get("weapon", null)
	
	if weapon:
		weapon_damage = weapon.get("damage", 0)
	
	# Calculate total damage
	var total_damage = (base_damage + weapon_damage) * action.get("damage_multiplier", 1.0)
	
	# Apply random variation
	var variation = randf_range(0.9, 1.1)
	total_damage *= variation
	
	# Check for critical hit
	var crit_chance = actor.stats.get("critical_chance", 0.05)
	var is_critical = randf() < crit_chance
	
	if is_critical:
		total_damage *= actor.stats.get("critical_multiplier", 2.0)
	
	# Apply target's defense
	var defense = target.get_defense()
	total_damage = max(1, total_damage - defense)
	
	# Determine damage type
	var damage_type = weapon.get("damage_type", "physical") if weapon else "physical"
	
	# Calculate status effects
	var status_effects = _calculate_attack_status_effects(actor, target, action)
	
	return {
		"damage": total_damage,
		"damage_type": damage_type,
		"is_critical": is_critical,
		"status_effects": status_effects
	}

func _calculate_skill_data(actor: Node, target: Node, skill: Dictionary) -> Dictionary:
	"""
	Calculate skill data including effects and costs
	
	Args:
		actor: Skill user
		target: Skill target
		skill: Skill data
		
	Returns:
		Skill data dictionary
	"""
	var effects = []
	var skill_power = skill.get("power", 0)
	var skill_type = skill.get("type", "damage")
	
	match skill_type:
		"damage":
			var damage = _calculate_skill_damage(actor, target, skill)
			effects.append({
				"type": "damage",
				"value": damage,
				"damage_type": skill.get("damage_type", "magical")
			})
		"heal":
			var heal_amount = _calculate_heal_amount(actor, target, skill)
			effects.append({
				"type": "heal",
				"value": heal_amount
			})
		"buff":
			var buff_effect = _calculate_buff_effect(actor, target, skill)
			effects.append(buff_effect)
		"debuff":
			var debuff_effect = _calculate_debuff_effect(actor, target, skill)
			effects.append(debuff_effect)
		"multi_target":
			var multi_effects = _calculate_multi_target_effects(actor, target, skill)
			effects.append_array(multi_effects)
	
	return {
		"effects": effects,
		"mana_cost": skill.get("mana_cost", 0),
		"cooldown": skill.get("cooldown", 0)
	}

func _calculate_item_data(actor: Node, target: Node, item: Dictionary) -> Dictionary:
	"""
	Calculate item use data
	
	Args:
		actor: Item user
		target: Item target
		item: Item data
		
	Returns:
		Item data dictionary
	"""
	var effects = []
	var item_type = item.get("type", "consumable")
	
	match item_type:
		"consumable":
			var consumable_effects = _calculate_consumable_effects(actor, target, item)
			effects.append_array(consumable_effects)
		"equipment":
			var equipment_effects = _calculate_equipment_effects(actor, item)
			effects.append_array(equipment_effects)
	
	return {
		"effects": effects,
		"item_type": item_type
	}

func _apply_status_effect(combatant: Node, effect: Dictionary) -> void:
	"""
	Apply a status effect to a combatant
	
	Args:
		combatant: Target combatant
		effect: Status effect data
	"""
	if not combatant:
		return
	
	# Add effect to combatant
	combatant.add_status_effect(effect)
	
	# Track effect in combat manager
	var effect_id = str(combatant.get_instance_id()) + "_" + effect.get("type", "unknown")
	status_effects[effect_id] = {
		"combatant": combatant,
		"effect": effect,
		"applied_turn": current_turn,
		"applied_round": round_number
	}
	
	status_effect_applied.emit(combatant, effect)

func _handle_combatant_death(combatant: Node, killer: Node) -> void:
	"""
	Handle the death of a combatant
	
	Args:
		combatant: Dead combatant
		killer: Combatant who caused the death
	"""
	# Emit death signal
	combatant_died.emit(combatant, killer)
	
	# Remove from turn order
	turn_order.erase(combatant)
	
	# Check if all combatants of one team are dead
	_check_combat_end_conditions()

func _check_combat_end_conditions() -> void:
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
		defeat_occurred.emit("player")
		end_combat("defeat")
	elif not enemy_team_alive:
		current_state = CombatState.VICTORY
		victory_achieved.emit("player")
		end_combat("victory")

func _all_players_fled() -> bool:
	"""
	Check if all player combatants have fled
	
	Returns:
		True if all players fled
	"""
	for combatant in current_combatants:
		if combatant.is_player() and combatant.is_alive():
			return false
	return true

func _calculate_flee_chance(actor: Node) -> float:
	"""
	Calculate the chance of successfully fleeing
	
	Args:
		actor: Combatant attempting to flee
		
	Returns:
		Flee chance between 0 and 1
	"""
	var base_chance = 0.3
	var speed_bonus = actor.stats.get("speed", 10) * 0.01
	var health_penalty = (1.0 - actor.get_health_percentage()) * 0.2
	
	return clamp(base_chance + speed_bonus - health_penalty, 0.0, 0.9)

func _validate_action(action: Dictionary) -> bool:
	"""
	Validate an action before execution
	
	Args:
		action: Action to validate
		
	Returns:
		True if action is valid
	"""
	if not action.has("type"):
		return false
	
	if not action.has("actor"):
		return false
	
	var actor = action.get("actor")
	if not actor or not actor.is_alive():
		return false
	
	# Check if it's the actor's turn
	if current_state == CombatState.ACTIVE and turn_order[current_turn] != actor:
		return false
	
	return true

func _setup_combat_environment(environment: Dictionary) -> void:
	"""
	Setup the combat environment
	
	Args:
		environment: Environment data
	"""
	# Apply terrain effects
	if environment.has("terrain"):
		_apply_terrain_effects(environment.terrain)
	
	# Apply weather effects
	if environment.has("weather"):
		_apply_weather_effects(environment.weather)
	
	# Apply time of day effects
	if environment.has("time_of_day"):
		_apply_time_effects(environment.time_of_day)

func _initialize_combatants() -> void:
	"""
	Initialize all combatants for combat
	"""
	for combatant in current_combatants:
		# Reset combat-specific stats
		combatant.reset_combat_stats()
		
		# Apply pre-combat effects
		_apply_pre_combat_effects(combatant)
		
		# Setup AI if needed
		if not combatant.is_player():
			ai_combatants.append(combatant)

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
	
	Args:
		a: First combatant
		b: Second combatant
		
	Returns:
		True if a should go before b
	"""
	var a_initiative = a.get_initiative()
	var b_initiative = b.get_initiative()
	
	if a_initiative == b_initiative:
		# If initiative is equal, sort by dexterity
		return a.stats.get("dexterity", 0) > b.stats.get("dexterity", 0)
	
	return a_initiative > b_initiative

func _next_turn() -> void:
	"""
	Move to the next turn
	"""
	if turn_order.size() == 0:
		return
	
	# End current turn
	turn_ended.emit(turn_order[current_turn], current_turn)
	
	# Move to next turn
	current_turn = (current_turn + 1) % turn_order.size()
	
	# Skip dead combatants
	while not turn_order[current_turn].is_alive():
		current_turn = (current_turn + 1) % turn_order.size()
		
		# If we've gone through all combatants, start new round
		if current_turn == 0:
			round_number += 1
			round_started.emit(round_number)
	
	# Start new turn
	turn_started.emit(turn_order[current_turn], current_turn)

func _update_combat_timing(delta: float) -> void:
	"""
	Update combat timing systems
	"""
	if current_state != CombatState.ACTIVE:
		return
	
	turn_timer += delta
	action_timer += delta
	animation_timer += delta
	phase_timer += delta
	
	# Check for turn timeout
	if turn_timer >= turn_timeout:
		_timeout_turn()

func _update_combat_phases(delta: float) -> void:
	"""
	Update combat phase management
	"""
	if current_state != CombatState.ACTIVE:
		return
	
	match current_phase:
		CombatPhase.INITIATIVE:
			_update_initiative_phase(delta)
		CombatPhase.PLANNING:
			_update_planning_phase(delta)
		CombatPhase.EXECUTION:
			_update_execution_phase(delta)
		CombatPhase.RESOLUTION:
			_update_resolution_phase(delta)

func _update_ai_combatants(delta: float) -> void:
	"""
	Update AI combatant behavior
	"""
	if not auto_combat_enabled:
		return
	
	auto_combat_timer += delta
	
	if auto_combat_timer >= auto_combat_delay:
		auto_combat_timer = 0.0
		
		for ai_combatant in ai_combatants:
			if ai_combatant.is_alive() and turn_order[current_turn] == ai_combatant:
				_execute_ai_action(ai_combatant)

func _update_status_effects(delta: float) -> void:
	"""
	Update status effects
	"""
	var effects_to_remove: Array[String] = []
	
	for effect_id in status_effects:
		var effect_data = status_effects[effect_id]
		var effect = effect_data.effect
		var combatant = effect_data.combatant
		
		# Update effect duration
		if effect.has("duration"):
			effect.duration -= delta
			
			if effect.duration <= 0:
				effects_to_remove.append(effect_id)
				status_effect_removed.emit(combatant, effect)
	
	# Remove expired effects
	for effect_id in effects_to_remove:
		status_effects.erase(effect_id)

func _update_performance_tracking(delta: float) -> void:
	"""
	Update performance tracking metrics
	"""
	performance_data = {
		"combat_duration": Time.get_time_dict_from_system() - combat_start_time,
		"turn_count": turn_count,
		"action_count": action_count,
		"active_combatants": current_combatants.size(),
		"status_effects": status_effects.size()
	}

func _execute_ai_action(ai_combatant: Node) -> void:
	"""
	Execute AI action for a combatant
	
	Args:
		ai_combatant: AI-controlled combatant
	"""
	# Simple AI: attack random enemy
	var enemies = []
	for combatant in current_combatants:
		if combatant.is_alive() and combatant != ai_combatant:
			enemies.append(combatant)
	
	if enemies.size() > 0:
		var target = enemies[randi() % enemies.size()]
		var action = {
			"type": ActionType.ATTACK,
			"actor": ai_combatant,
			"target": target
		}
		execute_action(action)

func _timeout_turn() -> void:
	"""
	Handle turn timeout
	"""
	# Auto-defend or skip turn
	var current_combatant = turn_order[current_turn]
	var action = {
		"type": ActionType.DEFEND,
		"actor": current_combatant
	}
	execute_action(action)

func _on_game_state_changed(new_state: GameManager.GameState, old_state: GameManager.GameState) -> void:
	"""
	Handle game state changes
	"""
	match new_state:
		GameManager.GameState.COMBAT:
			# Combat state handled by combat start
			pass
		GameManager.GameState.PAUSED:
			pause_combat()
		GameManager.GameState.PLAYING:
			resume_combat()

func _on_game_paused(is_paused: bool) -> void:
	"""
	Handle game pause state
	"""
	if is_paused:
		pause_combat()
	else:
		resume_combat()

func get_current_combatant() -> Node:
	"""
	Get the current combatant
	
	Returns:
		Current combatant or null
	"""
	if current_state != CombatState.ACTIVE or turn_order.size() == 0:
		return null
	
	return turn_order[current_turn]

func is_combat_active() -> bool:
	"""
	Check if combat is active
	
	Returns:
		True if combat is active
	"""
	return current_state == CombatState.ACTIVE

func get_combat_state() -> CombatState:
	"""
	Get current combat state
	
	Returns:
		Current combat state
	"""
	return current_state

func get_combat_data() -> Dictionary:
	"""
	Get comprehensive combat data
	
	Returns:
		Dictionary containing combat information
	"""
	return {
		"state": current_state,
		"phase": current_phase,
		"turn": current_turn,
		"round": round_number,
		"combatants": current_combatants.size(),
		"turn_order": turn_order.size(),
		"action_queue": action_queue.size(),
		"status_effects": status_effects.size()
	}

func get_performance_data() -> Dictionary:
	"""
	Get performance data for the combat system
	
	Returns:
		Dictionary containing performance metrics
	"""
	return performance_data.duplicate() 