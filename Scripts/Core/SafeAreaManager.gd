extends Node

signal safe_area_changed(rect: Rect2i)

var safe_area: Rect2i = Rect2i()

func _ready() -> void:
	_update_safe_area()
	get_tree().root.size_changed.connect(_update_safe_area)

func _update_safe_area() -> void:
	safe_area = DisplayServer.get_display_safe_area()
	safe_area_changed.emit(safe_area)

func get_margin_left() -> int:
	return safe_area.position.x

func get_margin_right() -> int:
	return DisplayServer.window_get_size().x - (safe_area.position.x + safe_area.size.x)

func get_margin_top() -> int:
	return safe_area.position.y

func get_margin_bottom() -> int:
	return DisplayServer.window_get_size().y - (safe_area.position.y + safe_area.size.y)
