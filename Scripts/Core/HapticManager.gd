extends Node

enum Intensity { LIGHT, MEDIUM, HEAVY }

var _enabled: bool = true

func set_enabled(value: bool) -> void:
	_enabled = value

func light() -> void:
	_emit(20)

func medium() -> void:
	_emit(50)

func heavy() -> void:
	_emit(100)

func button_press() -> void:
	light()

func _emit(duration_ms: int) -> void:
	if not _enabled:
		return
	if not OS.has_feature("android") and not OS.has_feature("ios"):
		return
	Input.vibrate_handheld(duration_ms)
