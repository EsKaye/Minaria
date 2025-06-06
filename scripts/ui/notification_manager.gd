extends Node

# Notification types
enum NotificationType {
	INFO,
	SUCCESS,
	WARNING,
	ERROR
}

# Notification queue
var notification_queue: Array[Dictionary] = []
var is_displaying: bool = false

# UI references
@onready var notification_container: VBoxContainer = $NotificationContainer
@onready var notification_scene: PackedScene = preload("res://scenes/ui/notification.tscn")
@onready var ui_sound_manager: Node = get_node("/root/UISoundManager")

# Constants
const MAX_NOTIFICATIONS: int = 3
const NOTIFICATION_DURATION: float = 3.0
const FADE_DURATION: float = 0.3

func _ready():
	# Initialize notification container
	notification_container = VBoxContainer.new()
	notification_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	notification_container.position = Vector2(20, 20)
	notification_container.custom_minimum_size = Vector2(300, 0)
	add_child(notification_container)

func show_notification(message: String, type: NotificationType = NotificationType.INFO, duration: float = NOTIFICATION_DURATION):
	"""
	Show a notification with the given message and type
	"""
	# Add notification to queue
	notification_queue.append({
		"message": message,
		"type": type,
		"duration": duration
	})
	
	# Play notification sound
	ui_sound_manager.play_notification()
	
	# Process queue if not already displaying
	if not is_displaying:
		_process_queue()

func _process_queue():
	"""
	Process the notification queue
	"""
	if notification_queue.is_empty():
		is_displaying = false
		return
	
	is_displaying = true
	
	# Remove old notifications if at max
	if notification_container.get_child_count() >= MAX_NOTIFICATIONS:
		var oldest_notification = notification_container.get_child(0)
		oldest_notification.queue_free()
	
	# Create new notification
	var notification_data = notification_queue.pop_front()
	var notification = notification_scene.instantiate()
	notification_container.add_child(notification)
	
	# Set notification properties
	notification.set_message(notification_data.message)
	notification.set_type(notification_data.type)
	
	# Animate notification
	notification.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 1.0, FADE_DURATION)
	
	# Wait for duration
	await get_tree().create_timer(notification_data.duration).timeout
	
	# Fade out
	tween = create_tween()
	tween.tween_property(notification, "modulate:a", 0.0, FADE_DURATION)
	await tween.finished
	
	# Remove notification
	notification.queue_free()
	
	# Process next notification
	_process_queue()

func clear_notifications():
	"""
	Clear all notifications
	"""
	notification_queue.clear()
	for child in notification_container.get_children():
		child.queue_free()
	is_displaying = false 