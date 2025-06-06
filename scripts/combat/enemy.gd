extends Combatant

# Enemy Properties
@export var enemy_type: String = "normal"  # normal, elite, boss
@export var experience_value: int = 100
@export var gold_value: int = 50
@export var drop_table: Array[Dictionary] = []

# AI Reference
@onready var ai = $EnemyAI

# Enemy-specific skills
var enemy_skills: Array[Dictionary] = []

func _ready() -> void:
	super._ready()
	
	# Add to enemy group
	add_to_group("enemy")
	
	# Connect AI signals
	ai.action_decided.connect(_on_ai_action_decided)
	
	# Load enemy-specific skills
	_load_enemy_skills()

func _load_enemy_skills() -> void:
	match enemy_type:
		"normal":
			enemy_skills = [
				{
					"name": "Quick Strike",
					"description": "A fast attack that deals moderate damage",
					"damage_type": "physical",
					"base_damage": 15,
					"mana_cost": 10,
					"cooldown": 2.0,
					"target_type": "single",
					"animation": "quick_strike"
				}
			]
		"elite":
			enemy_skills = [
				{
					"name": "Power Strike",
					"description": "A powerful attack that deals high damage",
					"damage_type": "physical",
					"base_damage": 25,
					"mana_cost": 20,
					"cooldown": 3.0,
					"target_type": "single",
					"animation": "power_strike"
				},
				{
					"name": "Battle Cry",
					"description": "Increases attack power for a short time",
					"damage_type": "buff",
					"base_damage": 0,
					"mana_cost": 15,
					"cooldown": 5.0,
					"target_type": "self",
					"animation": "battle_cry"
				}
			]
		"boss":
			enemy_skills = [
				{
					"name": "Devastating Blow",
					"description": "A devastating attack that deals massive damage",
					"damage_type": "physical",
					"base_damage": 40,
					"mana_cost": 30,
					"cooldown": 4.0,
					"target_type": "single",
					"animation": "devastating_blow"
				},
				{
					"name": "War Cry",
					"description": "Increases attack power and defense for a short time",
					"damage_type": "buff",
					"base_damage": 0,
					"mana_cost": 25,
					"cooldown": 6.0,
					"target_type": "self",
					"animation": "war_cry"
				},
				{
					"name": "Ground Slam",
					"description": "Slams the ground, damaging all enemies",
					"damage_type": "physical",
					"base_damage": 20,
					"mana_cost": 35,
					"cooldown": 5.0,
					"target_type": "all",
					"animation": "ground_slam"
				}
			]
	
	# Add skills to available skills
	available_skills.append_array(enemy_skills)

func _on_ai_action_decided(action: String, target: Node, skill: Dictionary, item: Dictionary) -> void:
	match action:
		"attack":
			perform_attack(target)
		"skill":
			use_skill(skill, target)
		"item":
			use_item(item, target)
		"defend":
			defend()
	
	# Notify AI that action is complete
	ai._on_action_completed()

func use_item(item: Dictionary, target: Node) -> void:
	if current_state == CombatState.DEAD:
		return
	
	# Use item from inventory
	if inventory.has_item(item.id):
		inventory.use_item(item.id)
		
		# Apply item effects
		match item.type:
			"healing":
				heal(item.value)
			"mana":
				restore_mana(item.value)
			"buff":
				_apply_buff(item)

func _apply_buff(buff_data: Dictionary) -> void:
	# Apply buff effects
	match buff_data.effect:
		"attack_up":
			strength *= buff_data.value
		"defense_up":
			vitality *= buff_data.value
		"speed_up":
			# TODO: Implement speed buff
			pass

func _on_death() -> void:
	# Drop items
	_drop_items()
	
	# Give experience and gold to player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.gain_experience(experience_value)
		player.add_gold(gold_value)

func _drop_items() -> void:
	for drop in drop_table:
		if randf() < drop.chance:
			# Create item drop
			var item_drop = preload("res://scenes/items/item_drop.tscn").instantiate()
			item_drop.item_data = drop.item
			item_drop.global_position = global_position
			get_tree().current_scene.add_child(item_drop) 