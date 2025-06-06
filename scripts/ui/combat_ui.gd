extends Control

# UI References
@onready var player_team = $Combatants/PlayerTeam
@onready var enemy_team = $Combatants/EnemyTeam
@onready var current_turn_label = $ActionPanel/MarginContainer/VBoxContainer/CurrentTurn
@onready var action_buttons = $ActionPanel/MarginContainer/VBoxContainer/ActionButtons
@onready var skill_panel = $SkillPanel
@onready var skill_list = $SkillPanel/MarginContainer/VBoxContainer/SkillList
@onready var item_panel = $ItemPanel
@onready var item_list = $ItemPanel/MarginContainer/VBoxContainer/ItemList
@onready var target_panel = $TargetPanel
@onready var target_list = $TargetPanel/MarginContainer/VBoxContainer/TargetList

# Combat Manager Reference
var combat_manager: Node

# Current State
var current_action: String = ""
var current_target: Node = null
var selected_skill: Dictionary = {}
var selected_item: Dictionary = {}

# Signals
signal action_selected(action: String)
signal target_selected(target: Node)
signal skill_selected(skill: Dictionary)
signal item_selected(item: Dictionary)

func _ready() -> void:
	# Connect button signals
	$ActionPanel/MarginContainer/VBoxContainer/ActionButtons/AttackButton.pressed.connect(_on_attack_pressed)
	$ActionPanel/MarginContainer/VBoxContainer/ActionButtons/SkillButton.pressed.connect(_on_skill_pressed)
	$ActionPanel/MarginContainer/VBoxContainer/ActionButtons/ItemButton.pressed.connect(_on_item_pressed)
	$ActionPanel/MarginContainer/VBoxContainer/ActionButtons/DefendButton.pressed.connect(_on_defend_pressed)
	
	# Connect back buttons
	$SkillPanel/MarginContainer/VBoxContainer/BackButton.pressed.connect(_on_skill_back_pressed)
	$ItemPanel/MarginContainer/VBoxContainer/BackButton.pressed.connect(_on_item_back_pressed)
	$TargetPanel/MarginContainer/VBoxContainer/BackButton.pressed.connect(_on_target_back_pressed)
	
	# Hide panels initially
	skill_panel.hide()
	item_panel.hide()
	target_panel.hide()

func initialize(manager: Node) -> void:
	combat_manager = manager
	
	# Connect combat manager signals
	combat_manager.turn_started.connect(_on_turn_started)
	combat_manager.turn_ended.connect(_on_turn_ended)
	combat_manager.combat_ended.connect(_on_combat_ended)
	combat_manager.combatant_died.connect(_on_combatant_died)

func update_combatants(player_combatants: Array, enemy_combatants: Array) -> void:
	# Clear existing combatants
	for child in player_team.get_children():
		child.queue_free()
	for child in enemy_team.get_children():
		child.queue_free()
	
	# Add player combatants
	for combatant in player_combatants:
		var combatant_ui = _create_combatant_ui(combatant)
		player_team.add_child(combatant_ui)
	
	# Add enemy combatants
	for combatant in enemy_combatants:
		var combatant_ui = _create_combatant_ui(combatant)
		enemy_team.add_child(combatant_ui)

func _create_combatant_ui(combatant: Node) -> Control:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(200, 300)
	
	# Add combatant sprite
	var sprite = TextureRect.new()
	sprite.expand_mode = TextureRect.EXPAND_FILL
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture = combatant.sprite.texture
	container.add_child(sprite)
	
	# Add health bar
	var health_bar = ProgressBar.new()
	health_bar.max_value = combatant.max_health
	health_bar.value = combatant.current_health
	health_bar.custom_minimum_size = Vector2(180, 20)
	container.add_child(health_bar)
	
	# Add mana bar
	var mana_bar = ProgressBar.new()
	mana_bar.max_value = combatant.max_mana
	mana_bar.value = combatant.current_mana
	mana_bar.custom_minimum_size = Vector2(180, 20)
	container.add_child(mana_bar)
	
	# Add name label
	var name_label = Label.new()
	name_label.text = combatant.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(name_label)
	
	return container

func update_turn_display(combatant: Node) -> void:
	current_turn_label.text = "Current Turn: %s" % combatant.name

func _on_turn_started(combatant: Node) -> void:
	update_turn_display(combatant)
	
	# Show/hide action buttons based on if it's player's turn
	if combatant.is_in_group("player"):
		action_buttons.show()
	else:
		action_buttons.hide()

func _on_turn_ended(combatant: Node) -> void:
	# Hide all panels
	skill_panel.hide()
	item_panel.hide()
	target_panel.hide()
	
	# Reset current action and target
	current_action = ""
	current_target = null
	selected_skill = {}
	selected_item = {}

func _on_combat_ended(victory: bool) -> void:
	# Hide UI
	hide()
	
	# Show victory/defeat message
	var message = "Victory!" if victory else "Defeat!"
	# TODO: Show message to player

func _on_combatant_died(combatant: Node) -> void:
	# Update combatant UI
	for child in player_team.get_children():
		if child.get_node_or_null("NameLabel") and child.get_node("NameLabel").text == combatant.name:
			child.modulate = Color(0.5, 0.5, 0.5)
			break
	
	for child in enemy_team.get_children():
		if child.get_node_or_null("NameLabel") and child.get_node("NameLabel").text == combatant.name:
			child.modulate = Color(0.5, 0.5, 0.5)
			break

func _on_attack_pressed() -> void:
	current_action = "attack"
	_show_target_selection()

func _on_skill_pressed() -> void:
	_show_skill_panel()

func _on_item_pressed() -> void:
	_show_item_panel()

func _on_defend_pressed() -> void:
	current_action = "defend"
	action_selected.emit("defend")

func _show_skill_panel() -> void:
	skill_panel.show()
	item_panel.hide()
	target_panel.hide()
	
	# Clear existing skills
	for child in skill_list.get_children():
		child.queue_free()
	
	# Add available skills
	var current_combatant = combat_manager.get_current_combatant()
	for skill in current_combatant.available_skills:
		var button = Button.new()
		button.text = skill.name
		button.pressed.connect(_on_skill_selected.bind(skill))
		skill_list.add_child(button)

func _show_item_panel() -> void:
	item_panel.show()
	skill_panel.hide()
	target_panel.hide()
	
	# Clear existing items
	for child in item_list.get_children():
		child.queue_free()
	
	# Add available items
	var current_combatant = combat_manager.get_current_combatant()
	for item in current_combatant.inventory.get_combat_items():
		var button = Button.new()
		button.text = "%s (x%d)" % [item.name, item.quantity]
		button.pressed.connect(_on_item_selected.bind(item))
		item_list.add_child(button)

func _show_target_selection() -> void:
	target_panel.show()
	skill_panel.hide()
	item_panel.hide()
	
	# Clear existing targets
	for child in target_list.get_children():
		child.queue_free()
	
	# Add valid targets based on current action
	var current_combatant = combat_manager.get_current_combatant()
	var target_team = enemy_team if current_combatant.is_in_group("player") else player_team
	
	for child in target_team.get_children():
		if child.modulate != Color(0.5, 0.5, 0.5):  # Not dead
			var button = Button.new()
			button.text = child.get_node("NameLabel").text
			button.pressed.connect(_on_target_selected.bind(child))
			target_list.add_child(button)

func _on_skill_selected(skill: Dictionary) -> void:
	selected_skill = skill
	skill_panel.hide()
	_show_target_selection()

func _on_item_selected(item: Dictionary) -> void:
	selected_item = item
	item_panel.hide()
	_show_target_selection()

func _on_target_selected(target: Control) -> void:
	current_target = target
	target_panel.hide()
	
	if current_action == "attack":
		action_selected.emit("attack")
	elif current_action == "skill":
		skill_selected.emit(selected_skill)
	elif current_action == "item":
		item_selected.emit(selected_item)
	
	target_selected.emit(current_target)

func _on_skill_back_pressed() -> void:
	skill_panel.hide()

func _on_item_back_pressed() -> void:
	item_panel.hide()

func _on_target_back_pressed() -> void:
	target_panel.hide()
	
	# Reset current action and target
	current_action = ""
	current_target = null
	selected_skill = {}
	selected_item = {} 