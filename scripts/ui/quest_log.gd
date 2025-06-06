extends Control

# UI references
@onready var quest_list: ItemList = $Panel/MarginContainer/VBoxContainer/QuestList
@onready var quest_title: Label = $Panel/MarginContainer/VBoxContainer/QuestDetails/QuestTitle
@onready var quest_description: RichTextLabel = $Panel/MarginContainer/VBoxContainer/QuestDetails/QuestDescription
@onready var objectives_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/QuestDetails/Objectives/ObjectivesList
@onready var rewards_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/QuestDetails/Rewards/RewardsList
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

# Quest data
var quests: Dictionary = {}
var active_quest_id: String = ""

# Quest status icons
const STATUS_ICONS = {
	"active": "⚪",
	"completed": "✅",
	"failed": "❌"
}

func _ready():
	# Connect signals
	quest_list.item_selected.connect(_on_quest_selected)
	close_button.pressed.connect(_on_close_pressed)
	
	# Hide initially
	visible = false

func add_quest(quest_data: Dictionary):
	"""
	Add a new quest to the log
	"""
	var quest_id = quest_data.get("id", "")
	if quest_id.is_empty():
		return
	
	quests[quest_id] = quest_data
	_update_quest_list()
	
	# Select the new quest
	var index = quest_list.get_item_index(quest_id)
	if index >= 0:
		quest_list.select(index)
		_on_quest_selected(index)

func update_quest(quest_id: String, updates: Dictionary):
	"""
	Update an existing quest
	"""
	if not quests.has(quest_id):
		return
	
	# Update quest data
	for key in updates:
		quests[quest_id][key] = updates[key]
	
	# Update UI
	_update_quest_list()
	
	# Update details if this quest is selected
	if active_quest_id == quest_id:
		_show_quest_details(quest_id)

func remove_quest(quest_id: String):
	"""
	Remove a quest from the log
	"""
	if not quests.has(quest_id):
		return
	
	quests.erase(quest_id)
	_update_quest_list()
	
	# Clear details if this quest was selected
	if active_quest_id == quest_id:
		_clear_quest_details()

func _update_quest_list():
	"""
	Update the quest list UI
	"""
	quest_list.clear()
	
	for quest_id in quests:
		var quest = quests[quest_id]
		var status = quest.get("status", "active")
		var title = quest.get("title", "Untitled Quest")
		var icon = STATUS_ICONS.get(status, "⚪")
		
		quest_list.add_item("%s %s" % [icon, title], null, false)
		quest_list.set_item_metadata(quest_list.get_item_count() - 1, quest_id)

func _show_quest_details(quest_id: String):
	"""
	Show details for the selected quest
	"""
	if not quests.has(quest_id):
		return
	
	active_quest_id = quest_id
	var quest = quests[quest_id]
	
	# Update title and description
	quest_title.text = quest.get("title", "Untitled Quest")
	quest_description.text = quest.get("description", "")
	
	# Update objectives
	_clear_objectives()
	var objectives = quest.get("objectives", [])
	for objective in objectives:
		var status = objective.get("status", "active")
		var text = objective.get("text", "")
		var icon = STATUS_ICONS.get(status, "⚪")
		
		var label = Label.new()
		label.text = "%s %s" % [icon, text]
		objectives_list.add_child(label)
	
	# Update rewards
	_clear_rewards()
	var rewards = quest.get("rewards", [])
	for reward in rewards:
		var label = Label.new()
		label.text = "• %s" % reward
		rewards_list.add_child(label)

func _clear_quest_details():
	"""
	Clear the quest details section
	"""
	active_quest_id = ""
	quest_title.text = ""
	quest_description.text = ""
	_clear_objectives()
	_clear_rewards()

func _clear_objectives():
	"""
	Clear the objectives list
	"""
	for child in objectives_list.get_children():
		child.queue_free()

func _clear_rewards():
	"""
	Clear the rewards list
	"""
	for child in rewards_list.get_children():
		child.queue_free()

func _on_quest_selected(index: int):
	"""
	Handle quest selection
	"""
	var quest_id = quest_list.get_item_metadata(index)
	_show_quest_details(quest_id)

func _on_close_pressed():
	"""
	Handle close button press
	"""
	visible = false

func show_quest_log():
	"""
	Show the quest log
	"""
	visible = true
	_update_quest_list()
	
	# Select first quest if none selected
	if active_quest_id.is_empty() and quest_list.get_item_count() > 0:
		quest_list.select(0)
		_on_quest_selected(0) 