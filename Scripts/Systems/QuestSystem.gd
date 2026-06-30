extends Node

signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_progress(quest_id: String, current: int, target: int)

const QUESTS := {
	"first_build": {
		"name": "اولین ساختمان",
		"description": "یک ساختمان در شهر خود بسازید",
		"category": "building",
		"objectives": [{"type": "build", "target": 1}],
		"rewards": {"gold": 100, "wood": 50}
	},
	"first_upgrade": {
		"name": "ارتقاء اول",
		"description": "یک ساختمان را یک سطح ارتقا دهید",
		"category": "building",
		"prerequisite": "first_build",
		"objectives": [{"type": "upgrade", "target": 1}],
		"rewards": {"gold": 200, "crystal": 25}
	},
	"population_50": {
		"name": "رشد جمعیت",
		"description": "جمعیت شهر خود را به ۵۰ برسانید",
		"category": "economy",
		"prerequisite": "first_upgrade",
		"objectives": [{"type": "population", "target": 50}],
		"rewards": {"gold": 300, "wine": 20}
	},
	"research_first": {
		"name": "نخستین پژوهش",
		"description": "یک تحقیق را کامل کنید",
		"category": "research",
		"prerequisite": "first_upgrade",
		"objectives": [{"type": "research", "target": 1}],
		"rewards": {"gold": 250, "research_points": 50}
	},
	"train_army": {
		"name": "ارتش کوچک",
		"description": "۱۰ واحد نظامی آموزش دهید",
		"category": "military",
		"prerequisite": "first_upgrade",
		"objectives": [{"type": "train", "target": 10}],
		"rewards": {"gold": 500, "sulfur": 30}
	},
	"daily_login": {
		"name": "ورود روزانه",
		"description": "هر روز برای دریافت جایزه وارد شوید",
		"category": "daily",
		"repeatable": true,
		"objectives": [{"type": "login", "target": 1}],
		"rewards": {"gold": 100, "ambrosia": 5}
	}
}

var _active_quests: Dictionary = {}
var _completed_quests: Array = []
var _progress: Dictionary = {}
var _last_quest_reset: int = 0

func _ready() -> void:
	EventBus.building_constructed.connect(_on_building_event)
	EventBus.building_upgraded.connect(_on_upgrade_event)
	EventBus.research_completed.connect(_on_research_event)

func get_all_quests() -> Dictionary:
	return QUESTS.duplicate(true)

func get_active_quests() -> Dictionary:
	return _active_quests.duplicate(true)

func get_completed_quests() -> Array:
	return _completed_quests.duplicate()

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in _completed_quests

func is_quest_active(quest_id: String) -> bool:
	return _active_quests.has(quest_id)

func is_available(quest_id: String) -> bool:
	var quest = QUESTS.get(quest_id, {})
	if quest.is_empty():
		return false
	if quest_id in _completed_quests and not quest.get("repeatable", false):
		return false
	if quest_id in _active_quests:
		return false
	var prereq = quest.get("prerequisite", "")
	if not prereq.is_empty() and prereq not in _completed_quests:
		return false
	return true

func start_quest(quest_id: String) -> bool:
	if not is_available(quest_id):
		return false
	_active_quests[quest_id] = QUESTS[quest_id]
	_progress[quest_id] = {}
	for obj in QUESTS[quest_id].get("objectives", []):
		_progress[quest_id][obj.get("type", "")] = 0
	quest_started.emit(quest_id)
	return true

func _increment_progress(quest_id: String, obj_type: String, amount: int = 1) -> void:
	if not _active_quests.has(quest_id):
		return
	if not _progress.has(quest_id):
		return
	var current = _progress[quest_id].get(obj_type, 0) + amount
	_progress[quest_id][obj_type] = current
	var target = _get_target_for_objective(quest_id, obj_type)
	quest_progress.emit(quest_id, current, target)
	if current >= target:
		_complete_quest(quest_id)

func _get_target_for_objective(quest_id: String, obj_type: String) -> int:
	var quest = QUESTS.get(quest_id, {})
	for obj in quest.get("objectives", []):
		if obj.get("type", "") == obj_type:
			return obj.get("target", 1)
	return 1

func _complete_quest(quest_id: String) -> void:
	if quest_id in _completed_quests:
		return
	_completed_quests.append(quest_id)
	_active_quests.erase(quest_id)
	var rewards = QUESTS.get(quest_id, {}).get("rewards", {})
	var city_id = GameState.selected_city_id
	if not city_id.is_empty():
		for rtype in rewards:
			if typeof(rtype) == TYPE_STRING and rtype == "ambrosia":
				continue
			var rti = Globals.RESOURCE_DISPLAY_NAMES.find_key(rtype)
			if rti != null:
				EconomyManager.change_resource(city_id, int(rti), rewards[rtype])
	quest_completed.emit(quest_id)

func _on_building_event(city_id: String, _building_id: String, _grid_pos: Vector2i) -> void:
	for qid in _active_quests:
		_increment_progress(qid, "build")

func _on_upgrade_event(city_id: String, _building_id: String, _grid_pos: Vector2i) -> void:
	for qid in _active_quests:
		_increment_progress(qid, "upgrade")

func _on_research_event(_tech_id: String) -> void:
	for qid in _active_quests:
		_increment_progress(qid, "research")

func check_login() -> void:
	for qid in QUESTS:
		if QUESTS[qid].get("category", "") == "daily":
			if qid in _completed_quests and QUESTS[qid].get("repeatable", false):
				_completed_quests.erase(qid)
			if is_available(qid):
				start_quest(qid)
				_increment_progress(qid, "login")

func to_dict() -> Dictionary:
	return {
		"active": _active_quests,
		"completed": _completed_quests,
		"progress": _progress
	}

func from_dict(data: Dictionary) -> void:
	_active_quests = data.get("active", {})
	_completed_quests = data.get("completed", [])
	_progress = data.get("progress", {})

func get_save_data() -> Dictionary:
	return {
		"quest_progress": _progress,
		"last_quest_reset": _last_quest_reset
	}

func load_save_data(data: Dictionary) -> void:
	_progress = data.get("quest_progress", {})
	_last_quest_reset = data.get("last_quest_reset", 0)
