extends Node

# AI States
enum AIState { IDLE, THINKING, ACTING }
var current_state: int = AIState.IDLE

# AI Properties
@export var aggressiveness: float = 0.7  # 0.0 to 1.0, higher means more likely to attack
@export var defensiveness: float = 0.3   # 0.0 to 1.0, higher means more likely to defend
@export var skill_usage: float = 0.5     # 0.0 to 1.0, higher means more likely to use skills
@export var item_usage: float = 0.2      # 0.0 to 1.0, higher means more likely to use items

# References
var combatant: Node
var combat_manager: Node
var target: Node

# Decision making
var last_action: String = ""
var consecutive_defends: int = 0
var consecutive_attacks: int = 0
var last_target: Node = null

# Signals
signal action_decided(action: String, target: Node, skill: Dictionary, item: Dictionary)

func _ready() -> void:
	combatant = get_parent()
	combat_manager = get_node("/root/CombatManager")

func _process(delta: float) -> void:
	if current_state == AIState.IDLE:
		_make_decision()

func _make_decision() -> void:
	current_state = AIState.THINKING
	
	# Find best target
	target = _find_best_target()
	if not target:
		return
	
	# Decide action based on current situation
	var action = _decide_action()
	
	# Emit action signal
	action_decided.emit(action, target, {}, {})
	
	current_state = AIState.ACTING

func _find_best_target() -> Node:
	var player_team = combat_manager.get_player_team()
	if player_team.is_empty():
		return null
	
	# Prioritize targets based on:
	# 1. Lowest health
	# 2. Lowest defense
	# 3. Highest threat (damage output)
	var best_target = null
	var best_score = -INF
	
	for potential_target in player_team:
		if potential_target.current_state == Combatant.CombatState.DEAD:
			continue
		
		var score = _calculate_target_score(potential_target)
		if score > best_score:
			best_score = score
			best_target = potential_target
	
	return best_target

func _calculate_target_score(target: Node) -> float:
	var score = 0.0
	
	# Health factor (lower health = higher priority)
	var health_factor = 1.0 - (target.current_health / target.max_health)
	score += health_factor * 3.0
	
	# Defense factor (lower defense = higher priority)
	var defense_factor = 1.0
	if target.is_defending:
		defense_factor = 0.5
	score += defense_factor * 2.0
	
	# Threat factor (higher damage = higher priority)
	var threat_factor = 0.0
	if target.equipped_weapon.has("damage"):
		threat_factor = target.equipped_weapon.damage / 100.0
	score += threat_factor * 1.5
	
	return score

func _decide_action() -> String:
	# Check if we should defend
	if _should_defend():
		return "defend"
	
	# Check if we should use a skill
	var skill = _should_use_skill()
	if skill:
		return "skill"
	
	# Check if we should use an item
	var item = _should_use_item()
	if item:
		return "item"
	
	# Default to attack
	return "attack"

func _should_defend() -> bool:
	# Don't defend too many times in a row
	if consecutive_defends >= 2:
		return false
	
	# Check if we're low on health
	var health_percent = combatant.current_health / combatant.max_health
	if health_percent < 0.3:
		return randf() < defensiveness
	
	# Check if target is about to use a strong skill
	if target and target.current_state == Combatant.CombatState.CASTING:
		return randf() < defensiveness * 1.5
	
	return false

func _should_use_skill() -> Dictionary:
	# Don't use skills if we're low on mana
	if combatant.current_mana < 20:
		return {}
	
	# Check each available skill
	for skill in combatant.available_skills:
		# Skip if on cooldown
		if combatant.skill_cooldowns.has(skill.name) and combatant.skill_cooldowns[skill.name] > 0:
			continue
		
		# Check if we have enough mana
		if combatant.current_mana < skill.mana_cost:
			continue
		
		# Decide whether to use this skill
		var use_chance = skill_usage
		
		# Increase chance for healing skills when low on health
		if skill.damage_type == "healing" and combatant.current_health < combatant.max_health * 0.5:
			use_chance *= 2.0
		
		# Increase chance for strong skills when target is vulnerable
		if skill.base_damage > 20 and target and target.is_defending:
			use_chance *= 1.5
		
		if randf() < use_chance:
			return skill
	
	return {}

func _should_use_item() -> Dictionary:
	# Don't use items if we have none
	if combatant.inventory.is_empty():
		return {}
	
	# Check each available item
	for item in combatant.inventory.get_combat_items():
		# Skip if we don't have enough
		if item.quantity <= 0:
			continue
		
		# Decide whether to use this item
		var use_chance = item_usage
		
		# Increase chance for healing items when low on health
		if item.type == "healing" and combatant.current_health < combatant.max_health * 0.3:
			use_chance *= 2.0
		
		# Increase chance for mana items when low on mana
		if item.type == "mana" and combatant.current_mana < combatant.max_mana * 0.3:
			use_chance *= 2.0
		
		if randf() < use_chance:
			return item
	
	return {}

func _on_action_completed() -> void:
	current_state = AIState.IDLE
	
	# Update action history
	if last_action == "defend":
		consecutive_defends += 1
		consecutive_attacks = 0
	elif last_action == "attack":
		consecutive_attacks += 1
		consecutive_defends = 0
	else:
		consecutive_defends = 0
		consecutive_attacks = 0
	
	last_target = target 