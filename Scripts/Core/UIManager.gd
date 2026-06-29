extends Node

var _active_notifications: Array = []
var _notification_container: Control = null

func _ready() -> void:
	EventBus.notification_added.connect(_on_notification)

func set_notification_container(container: Control) -> void:
	_notification_container = container

func show_notification(message: String, type: String = "info") -> void:
	EventBus.notification_added.emit(message, type)

func _on_notification(message: String, type: String) -> void:
	_active_notifications.append({"message": message, "type": type, "time": 0.0})
	if _active_notifications.size() > 5:
		_active_notifications.pop_front()

func get_notifications() -> Array:
	return _active_notifications.duplicate()

func clear_notifications() -> void:
	_active_notifications.clear()
