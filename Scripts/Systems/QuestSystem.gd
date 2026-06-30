extends Node

signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_progress(quest_id: String, current: int, target: int)

const STORY_QUESTS := {
	"first_build": {
		"name": "اولین ساختمان",
		"description": "یک ساختمان در شهر خود بسازید",
		"category": "building",
		"objectives": [{"type": "build", "target": 1}],
		"rewards": {Globals.ResourceType.GOLD: 100, Globals.ResourceType.WOOD: 50}
	},
	"first_upgrade": {
		"name": "ارتقاء اول",
		"description": "یک ساختمان را یک سطح ارتقا دهید",
		"category": "building",
		"prerequisite": "first_build",
		"objectives": [{"type": "upgrade", "target": 1}],
		"rewards": {Globals.ResourceType.GOLD: 200, Globals.ResourceType.CRYSTAL: 25}
	},
	"population_50": {
		"name": "رشد جمعیت",
		"description": "جمعیت شهر خود را به ۵۰ برسانید",
		"category": "economy",
		"prerequisite": "first_upgrade",
		"objectives": [{"type": "population", "target": 50}],
		"rewards": {Globals.ResourceType.GOLD: 300, Globals.ResourceType.WINE: 20}
	},
	"research_first": {
		"name": "نخستین پژوهش",
		"description": "یک تحقیق را کامل کنید",
		"category": "research",
		"prerequisite": "first_upgrade",
		"objectives": [{"type": "research", "target": 1}],
		"rewards": {Globals.ResourceType.GOLD: 250, Globals.ResourceType.RESEARCH_PTS: 50}
	},
	"train_army": {
		"name": "ارتش کوچک",
		"description": "۱۰ واحد نظامی آموزش دهید",
		"category": "military",
		"prerequisite": "first_upgrade",
		"objectives": [{"type": "train", "target": 10}],
		"rewards": {Globals.ResourceType.GOLD: 500, Globals.ResourceType.SULFUR: 30}
	}
}

const DAILY_QUESTS := {
	"gatherer": {
		"name": "جمع‌آوری کننده",
		"description": "۵۰۰ چوب جمع‌آوری کنید",
		"objectives": [{"type": "gather_wood", "target": 500}],
		"rewards": {Globals.ResourceType.GOLD: 50}
	},
	"builder_daily": {
		"name": "سازنده",
		"description": "۱ ساختمان بسازید",
		"objectives": [{"type": "build", "target": 1}],
		"rewards": {Globals.ResourceType.STONE: 100}
	},
	"scholar": {
		"name": "دانشمند",
		"description": "۱۰۰ امتیاز پژوهش کسب کنید",
		"objectives": [{"type": "research_pts", "target": 100}],
		"rewards": {Globals.ResourceType.CRYSTAL: 10}
	},
	"recruiter": {
		"name": "استخدام کننده",
		"description": "۱۰ واحد نظامی آموزش دهید",
		"objectives": [{"type": "train", "target": 10}],
		"rewards": {Globals.ResourceType.GOLD: 200}
	},
	"explorer": {
		"name": "کاوشگر",
		"description": "به نقشه جهان سر بزنید",
		"objectives": [{"type": "visit_map", "target": 1}],
		"rewards": {Globals.ResourceType.WINE: 10}
	},
	"loyal": {
		"name": "وفادار",
		"description": "امروز وارد بازی شوید",
		"objectives": [{"type": "login", "target": 1}],
		"rewards": {Globals.ResourceType.RESEARCH_PTS: 25}
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
	EventBus.unit_trained.connect(_on_unit_trained)
	EventBus.day_changed.connect(_on_day_changed)

func get_all_story_quests() -> Dictionary:
	return STORY_QUESTS.duplicate(true)

func get_active_quests() -> Dictionary:
	return _active_quests.duplicate(true)

func get_completed_quests() -> Array:
	return _completed_quests.duplicate()

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in _completed_quests

func is_quest_active(quest_id: String) -> bool:
	return _active_quests.has(quest_id)

func is_available(quest_id: String) -> bool:
	var quest = STORY_QUESTS.get(quest_id, {})
	if quest.is_empty():
		quest = DAILY_QUESTS.get(quest_id, {})
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
	var quest = STORY_QUESTS.get(quest_id, DAILY_QUESTS.get(quest_id, {}))
	if quest.is_empty():
		return false
	_active_quests[quest_id] = quest
	_progress[quest_id] = {}
	for obj in quest.get("objectives", []):
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
	var quest = STORY_QUESTS.get(quest_id, DAILY_QUESTS.get(quest_id, {}))
	var target = 1
	for obj in quest.get("objectives", []):
		if obj.get("type", "") == obj_type:
			target = obj.get("target", 1)
			break
	quest_progress.emit(quest_id, current, target)
	if current >= target:
		_complete_quest(quest_id)

func _complete_quest(quest_id: String) -> void:
	if quest_id in _completed_quests:
		return
	_completed_quests.append(quest_id)
	_active_quests.erase(quest_id)
	var quest = STORY_QUESTS.get(quest_id, DAILY_QUESTS.get(quest_id, {}))
	if quest.is_empty():
		return
	var rewards = quest.get("rewards", {})
	var city_id = GameState.selected_city_id
	if not city_id.is_empty():
		for rtype in rewards:
			if rtype is int:
				EconomyManager.change_resource(city_id, rtype, rewards[rtype])
	quest_completed.emit(quest_id)

func check_login() -> void:
	for qid in DAILY_QUESTS:
		if qid in _completed_quests:
			_completed_quests.erase(qid)
		if qid in _active_quests:
			_active_quests.erase(qid)
		if is_available(qid):
			start_quest(qid)
			if qid == "loyal":
				_increment_progress(qid, "login")

func _on_day_changed(_day: int) -> void:
	if _last_quest_reset < _day:
		_last_quest_reset = _day
		check_login()

func _on_building_event(_city_id: String, _building_id: String, _grid_pos: Vector2i) -> void:
	for qid in _active_quests:
		_increment_progress(qid, "build")

func _on_upgrade_event(_city_id: String, _building_id: String, _extra) -> void:
	for qid in _active_quests:
		_increment_progress(qid, "upgrade")

func _on_research_event(_tech_id: String) -> void:
	for qid in _active_quests:
		_increment_progress(qid, "research")
		_increment_progress(qid, "research_pts", 50)

func _on_unit_trained(_city_id: String, _unit_type: String, count: int) -> void:
	for qid in _active_quests:
		_increment_progress(qid, "train", count)

func to_dict() -> Dictionary:
	return {
		"active": _active_quests.duplicate(true),
		"completed": _completed_quests.duplicate(),
		"progress": _progress.duplicate(true),
		"last_quest_reset": _last_quest_reset
	}

func from_dict(data: Dictionary) -> void:
	_active_quests = data.get("active", {}).duplicate(true)
	_completed_quests = data.get("completed", []).duplicate()
	_progress = data.get("progress", {}).duplicate(true)
	_last_quest_reset = data.get("last_quest_reset", 0)

func get_save_data() -> Dictionary:
	return to_dict()

func load_save_data(data: Dictionary) -> void:
	from_dict(data)