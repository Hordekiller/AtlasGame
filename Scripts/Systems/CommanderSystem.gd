extends Node

signal commander_leveled_up(commander_id: String, new_level: int)
signal commander_skill_unlocked(commander_id: String, skill_id: String)
signal commander_gained_exp(commander_id: String, exp: int, total: int)
signal commander_shard_collected(commander_id: String, shards: int, total_needed: int)

const EXP_PER_LEVEL: int = 100
const MAX_COMMANDER_LEVEL: int = 50

const SHARD_REQUIREMENTS := {
	"common": 10, "rare": 25, "epic": 50, "legendary": 100
}

const SKILL_TIER_LEVELS := {
	1: 1, 2: 5, 3: 10, 4: 20, 5: 35
}

var _commanders: Dictionary = {}
var _commander_shards: Dictionary = {}

func has_commander(commander_id: String) -> bool:
	return _commanders.has(commander_id)

func get_shards(commander_id: String) -> int:
	return _commander_shards.get(commander_id, 0)

func get_shards_needed(commander_id: String) -> int:
	var config = CommanderConfig.get_commander(commander_id)
	if config.is_empty():
		return 999
	var rarity = config.get("rarity", "common")
	return SHARD_REQUIREMENTS.get(rarity, 10)

func collect_shards(commander_id: String, amount: int) -> bool:
	var current = _commander_shards.get(commander_id, 0)
	var needed = get_shards_needed(commander_id)
	if _commanders.has(commander_id):
		return false
	current += amount
	_commander_shards[commander_id] = current
	commander_shard_collected.emit(commander_id, current, needed)
	if current >= needed:
		_commander_shards[commander_id] = 0
		return add_commander(commander_id)
	return false

func get_commander_data(commander_id: String) -> Dictionary:
	if not _commanders.has(commander_id):
		var config = CommanderConfig.get_commander(commander_id)
		if config.is_empty():
			return {}
		_commanders[commander_id] = {
			"id": commander_id,
			"level": 1,
			"exp": 0,
			"unlocked_skills": [],
			"assigned_to": "",
			"march_slot": -1
		}
	return _commanders[commander_id]

func add_commander(commander_id: String) -> bool:
	if _commanders.has(commander_id):
		return false
	var config = CommanderConfig.get_commander(commander_id)
	if config.is_empty():
		return false
	_commander_shards.erase(commander_id)
	_commanders[commander_id] = {
		"id": commander_id,
		"level": 1,
		"exp": 0,
		"unlocked_skills": [],
		"assigned_to": "",
		"march_slot": -1
	}
	return true

func get_all_player_commanders() -> Dictionary:
	return _commanders.duplicate(true)

func assign_to_city(commander_id: String, city_id: String) -> bool:
	if not _commanders.has(commander_id):
		return false
	_commanders[commander_id]["assigned_to"] = city_id
	return true

func assign_to_march(commander_id: String, slot: int) -> bool:
	if not _commanders.has(commander_id):
		return false
	_commanders[commander_id]["march_slot"] = slot
	return true

func gain_exp(commander_id: String, amount: int) -> void:
	if not _commanders.has(commander_id):
		return
	var data = _commanders[commander_id]
	data["exp"] += amount
	commander_gained_exp.emit(commander_id, amount, data["exp"])
	while data["exp"] >= _exp_for_next_level(data["level"]):
		data["exp"] -= _exp_for_next_level(data["level"])
		if data["level"] < MAX_COMMANDER_LEVEL:
			data["level"] += 1
			commander_leveled_up.emit(commander_id, data["level"])
			_check_skill_unlock(commander_id)

func _exp_for_next_level(level: int) -> int:
	return EXP_PER_LEVEL * level

func _check_skill_unlock(commander_id: String) -> void:
	var data = _commanders.get(commander_id)
	if not data:
		return
	var config = CommanderConfig.get_commander(commander_id)
	if config.is_empty():
		return
	for skill in config.get("skills", []):
		var sid = skill.get("id", "")
		var tier = skill.get("unlock_tier", 1)
		var required_level = SKILL_TIER_LEVELS.get(tier, tier * 10)
		if sid not in data["unlocked_skills"] and data["level"] >= required_level:
			data["unlocked_skills"].append(sid)
			commander_skill_unlocked.emit(commander_id, sid)

func get_active_skills(commander_id: String) -> Array:
	var data = _commanders.get(commander_id, {})
	var config = CommanderConfig.get_commander(commander_id)
	if config.is_empty():
		return []
	var result = []
	for skill in config.get("skills", []):
		if skill.get("id", "") in data.get("unlocked_skills", []) and skill.get("type", "") == "active":
			result.append(skill)
	return result

func get_passive_modifiers(commander_id: String) -> Dictionary:
	var data = _commanders.get(commander_id, {})
	var config = CommanderConfig.get_commander(commander_id)
	if config.is_empty():
		return {}
	var modifiers = {}
	for skill in config.get("skills", []):
		if skill.get("id", "") in data.get("unlocked_skills", []) and skill.get("type", "") == "passive":
			for key in skill.get("modifiers", {}):
				modifiers[key] = modifiers.get(key, 1.0) * skill["modifiers"][key]
	return modifiers

func get_commander_for_city(city_id: String) -> Dictionary:
	for cid in _commanders:
		if _commanders[cid].get("assigned_to", "") == city_id:
			var result = _commanders[cid].duplicate()
			result["config"] = CommanderConfig.get_commander(cid)
			return result
	return {}

func to_dict() -> Dictionary:
	return {"commanders": _commanders.duplicate(true), "shards": _commander_shards.duplicate()}

func from_dict(data: Dictionary) -> void:
	_commanders = data.get("commanders", {}).duplicate(true)
	_commander_shards = data.get("shards", {}).duplicate()
