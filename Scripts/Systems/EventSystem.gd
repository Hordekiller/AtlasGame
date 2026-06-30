extends Node

signal event_started(event_id: String)
signal event_ended(event_id: String)

const EVENTS := {
	"harvest_festival": {
		"name": "جشن برداشت",
		"description": "تولید منابع +۵۰٪ به مدت ۲۴ ساعت",
		"duration_hours": 24,
		"modifiers": {"production_bonus": 1.5},
		"interval_days": 7
	},
	"military_drill": {
		"name": "رزمایش نظامی",
		"description": "سرعت آموزش واحدها دو برابر",
		"duration_hours": 12,
		"modifiers": {"train_speed": 2.0},
		"interval_days": 5
	},
	"trade_winds": {
		"name": "بادهای تجاری",
		"description": "هزینه تجارت -۵۰٪",
		"duration_hours": 8,
		"modifiers": {"trade_cost": 0.5},
		"interval_days": 3
	},
	"inspiration": {
		"name": "الهام الهی",
		"description": "سرعت پژوهش +۱۰۰٪",
		"duration_hours": 6,
		"modifiers": {"research_speed": 2.0},
		"interval_days": 4
	}
}

var _active_events: Dictionary = {}
var _event_timers: Dictionary = {}
var _last_event_days: Dictionary = {}

func _process(delta: float) -> void:
	if delta <= 0 or delta > 10:
		return
	var to_remove = []
	for eid in _event_timers:
		if not _event_timers.has(eid):
			continue
		_event_timers[eid] -= delta
		if _event_timers[eid] <= 0:
			_end_event(eid)
			to_remove.append(eid)
	for eid in to_remove:
		_event_timers.erase(eid)

func get_all_events() -> Dictionary:
	return EVENTS.duplicate(true)

func get_active_events() -> Dictionary:
	return _active_events.duplicate(true)

func is_event_active(event_id: String) -> bool:
	return _active_events.has(event_id)

func get_event_modifiers() -> Dictionary:
	var all = {}
	for eid in _active_events:
		var mods = EVENTS.get(eid, {}).get("modifiers", {})
		for key in mods:
			all[key] = all.get(key, 1.0) * mods[key]
	return all

func try_start_event(event_id: String) -> bool:
	if event_id in _active_events:
		return false
	var defn = EVENTS.get(event_id, {})
	if defn.is_empty():
		return false
	_active_events[event_id] = defn
	_event_timers[event_id] = defn.get("duration_hours", 1) * 3600.0
	_last_event_days[event_id] = GameState.current_day
	event_started.emit(event_id)
	return true

func check_daily_events() -> void:
	for eid in EVENTS:
		var defn = EVENTS[eid]
		var interval = defn.get("interval_days", 7)
		var last_day = _last_event_days.get(eid, -interval)
		if GameState.current_day - last_day >= interval:
			if not is_event_active(eid):
				try_start_event(eid)

func _end_event(event_id: String) -> void:
	_active_events.erase(event_id)
	_event_timers.erase(event_id)
	event_ended.emit(event_id)

func to_dict() -> Dictionary:
	return {
		"active": _active_events,
		"timers": _event_timers,
		"last_days": _last_event_days
	}

func from_dict(data: Dictionary) -> void:
	_active_events = data.get("active", {})
	_event_timers = data.get("timers", {})
	_last_event_days = data.get("last_days", {})

func get_save_data() -> Dictionary:
	return to_dict()

func load_save_data(data: Dictionary) -> void:
	from_dict(data)
