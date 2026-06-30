extends Node

signal protection_activated()
signal protection_expired()

const PROTECTION_HOURS: float = 72.0

var _start_time: float = -1.0
var _is_active: bool = false

func _ready() -> void:
	_check_protection()

func start_protection() -> void:
	_start_time = GameState.game_time
	_is_active = true
	protection_activated.emit()
	_save()

func is_protected() -> bool:
	if not _is_active:
		return false
	var elapsed = GameState.game_time - _start_time
	if elapsed >= PROTECTION_HOURS * 3600.0:
		_is_active = false
		protection_expired.emit()
		_save()
		return false
	return true

func get_remaining_time() -> float:
	if not _is_active:
		return 0.0
	var elapsed = GameState.game_time - _start_time
	var remaining = (PROTECTION_HOURS * 3600.0) - elapsed
	return max(0.0, remaining)

func get_remaining_hours() -> float:
	return get_remaining_time() / 3600.0

func _check_protection() -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://protection.cfg") == OK:
		_start_time = cfg.get_value("protection", "start_time", -1.0)
		_is_active = cfg.get_value("protection", "active", false)
		if _start_time >= 0:
			is_protected()

func _save() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("protection", "start_time", _start_time)
	cfg.set_value("protection", "active", _is_active)
	cfg.save("user://protection.cfg")

func get_save_data() -> Dictionary:
	return {
		"start_time": _start_time,
		"is_active": _is_active
	}

func load_save_data(data: Dictionary) -> void:
	_start_time = data.get("start_time", -1.0)
	_is_active = data.get("is_active", false)
	if _start_time >= 0:
		is_protected()
