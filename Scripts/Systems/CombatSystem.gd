extends Node

const MAX_ROUNDS := 12
const RETREAT_ROUNDS := [3, 6, 9]

const UNIT_COUNTERS := {
	"swordsman": {"spearman": 1.2},
	"spearman": {"ram": 1.3, "hoplite": 1.1},
	"hoplite": {"swordsman": 1.1},
	"archer": {"slinger": 1.15},
	"steam_giant": {"militia": 1.25, "spearman": 1.25, "swordsman": 1.25},
	"gyrocopter": {"catapult": 1.3, "mortar": 1.3}
}

class BattleState:
	var battle_id: String
	var attacker: Dictionary
	var defender: Dictionary
	var current_round: int = 0
	var rounds_log: Array[Dictionary] = []
	var status: String = "ongoing"

static func create_battle(attacker: Dictionary, defender: Dictionary, battle_id: String = "") -> BattleState:
	var state = BattleState.new()
	state.battle_id = battle_id if not battle_id.is_empty() else "%s_vs_%s" % [attacker.get("city_id", "???"), defender.get("city_id", "???")]
	state.attacker = attacker
	state.defender = defender
	return state

static func simulate_round(state: BattleState) -> Dictionary:
	var round_data := {}
	state.current_round += 1

	var atk_formation = FormationConfig.get_effective_modifiers(
		state.attacker.get("formation", "standard"), state.current_round)
	var def_formation = FormationConfig.get_effective_modifiers(
		state.defender.get("formation", "standard"), state.current_round)

	var atk_raw = _calculate_attack(state.attacker) * atk_formation["attack"]
	var def_raw = _calculate_attack(state.defender) * def_formation["attack"]
	var atk_def = _calculate_defense(state.attacker) * atk_formation["defense"]
	var def_def = _calculate_defense(state.defender) * def_formation["defense"]

	var def_wall = state.defender.get("wall_defense", 0.0)
	var atk_wall = state.attacker.get("wall_defense", 0.0)

	var def_losses = _apply_damage(state.defender, atk_raw, def_def + def_wall, state.attacker)
	var atk_losses = _apply_damage(state.attacker, def_raw, atk_def + atk_wall, state.defender)

	var atk_skills = _get_triggered_skills(state.attacker, state.current_round)
	var def_skills = _get_triggered_skills(state.defender, state.current_round)

	round_data = {
		"round": state.current_round,
		"attacker_losses": atk_losses,
		"defender_losses": def_losses,
		"skills_triggered": atk_skills + def_skills,
		"attacker_units_remaining": _count_units(state.attacker),
		"defender_units_remaining": _count_units(state.defender)
	}

	state.rounds_log.append(round_data)
	_check_battle_end(state)
	return round_data

static func simulate_full_battle(state: BattleState) -> void:
	while state.status == "ongoing" and state.current_round < MAX_ROUNDS:
		simulate_round(state)

static func can_retreat(state: BattleState) -> bool:
	return state.current_round in RETREAT_ROUNDS and state.status == "ongoing"

static func retreat(state: BattleState) -> void:
	state.status = "retreated"

static func _get_counter_modifier(attacker_type: String, defender_units: Dictionary) -> float:
	var counters = UNIT_COUNTERS.get(attacker_type, {})
	if counters.is_empty():
		return 1.0
	for def_type in counters:
		if defender_units.has(def_type):
			return counters[def_type]
	return 1.0

static func _calculate_attack(army: Dictionary) -> float:
	var total := 0.0
	var units = army.get("units", {})
	var mgr = _get_military_manager()
	for unit_type in units:
		var count = units[unit_type].get("count", 0) if typeof(units[unit_type]) == TYPE_DICTIONARY else int(units[unit_type])
		var defn = mgr.get_unit_def(unit_type) if mgr else null
		var atk = defn.get("attack", 1) if defn else 1
		var counter = _get_counter_modifier(unit_type, units)
		total += count * atk * counter
	var commander = army.get("commander_data", {})
	if not commander.is_empty():
		var mods = _get_commander_mods(commander)
		total *= mods.get("attack", 1.0)
		if _is_naval_army(army):
			total *= mods.get("naval_attack", 1.0)
	return total

static func _calculate_defense(army: Dictionary) -> float:
	var total := 0.0
	var units = army.get("units", {})
	var mgr = _get_military_manager()
	for unit_type in units:
		var count = units[unit_type].get("count", 0) if typeof(units[unit_type]) == TYPE_DICTIONARY else int(units[unit_type])
		var defn = mgr.get_unit_def(unit_type) if mgr else null
		total += count * (defn.get("defense", 1) if defn else 1)
	var commander = army.get("commander_data", {})
	if not commander.is_empty():
		var mods = _get_commander_mods(commander)
		total *= mods.get("defense", 1.0)
		if _is_naval_army(army):
			total *= mods.get("naval_defense", 1.0)
	return total

static func _apply_damage(army: Dictionary, power: float, defense: float, attacker_army: Dictionary = {}) -> Dictionary:
	var losses = {}
	if defense <= 0:
		defense = 1.0
	var rng = RandomNumberGenerator.new()
	var dmg_mult = rng.randf_range(0.85, 1.15)
	var raw_damage = power * dmg_mult
	var effective_defense = max(1.0, defense)
	var losses_per_unit = max(1, ceil(raw_damage / effective_defense))

	var units = army.get("units", {})
	var total_units = _count_units(army)
	if total_units <= 0:
		return losses

	var damage_to_distribute = losses_per_unit
	var unit_types = units.keys()
	unit_types.shuffle()
	for unit_type in unit_types:
		if damage_to_distribute <= 0:
			break
		var count = units[unit_type].get("count", 0) if typeof(units[unit_type]) == TYPE_DICTIONARY else int(units[unit_type])
		if count <= 0:
			continue
		var killed = mini(count, max(1, damage_to_distribute))
		damage_to_distribute -= killed
		if killed > 0:
			losses[unit_type] = killed
			if typeof(units[unit_type]) == TYPE_DICTIONARY:
				units[unit_type]["count"] = count - killed
			else:
				units[unit_type] = count - killed
	return losses

static func _count_units(army: Dictionary) -> int:
	var total := 0
	var units = army.get("units", {})
	for unit_type in units:
		var val = units[unit_type]
		if typeof(val) == TYPE_DICTIONARY:
			total += val.get("count", 0)
		else:
			total += int(val)
	return total

static func _check_battle_end(state: BattleState) -> void:
	if _count_units(state.attacker) <= 0:
		state.status = "defender_win"
	elif _count_units(state.defender) <= 0:
		state.status = "attacker_win"
	elif state.current_round >= MAX_ROUNDS:
		var atk_rem = _count_units(state.attacker)
		var def_rem = _count_units(state.defender)
		if atk_rem > def_rem:
			state.status = "attacker_win"
		elif def_rem > atk_rem:
			state.status = "defender_win"
		else:
			state.status = "draw"

static func _get_triggered_skills(army: Dictionary, round: int) -> Array:
	var triggered = []
	var commander = army.get("commander_data", {})
	if not commander.is_empty():
		var config = CommanderConfig.get_commander(commander.get("id", ""))
		if not config.is_empty():
			for skill in config.get("skills", []):
				if skill.get("type", "") == "active" and round % max(skill.get("unlock_tier", 5), 1) == 0:
					triggered.append(skill.get("name", ""))
	return triggered

static func _get_commander_mods(commander_data: Dictionary) -> Dictionary:
	var id = commander_data.get("id", "")
	var cmdr_system = _get_commander_system()
	if cmdr_system:
		return cmdr_system.get_passive_modifiers(id)
	return {}

static func _is_naval_army(army: Dictionary) -> bool:
	var units = army.get("units", {})
	var mgr = _get_military_manager()
	for utype in units:
		if mgr:
			var defn = mgr.get_unit_def(utype)
			if defn and defn.get("naval", false):
				return true
	return false

static func _get_military_manager():
	if Engine.has_singleton("MilitaryManager"):
		return Engine.get_singleton("MilitaryManager")
	return null

static func _get_commander_system():
	if Engine.has_singleton("CommanderSystem"):
		return Engine.get_singleton("CommanderSystem")
	return null