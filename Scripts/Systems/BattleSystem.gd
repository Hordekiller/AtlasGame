extends Node

enum BATTLE_PHASES {
	NAVAL,
	BOMBARDMENT,
	GROUND,
	SIEGE,
	AFTERMATH
}

const ROW_ORDER = ["front", "back", "artillery"]
const FRONT_ROW = 0
const BACK_ROW = 1
const ARTILLERY_ROW = 2

var _active_battles: Dictionary = {}

func initiate_battle(attacker_city_id: String, defender_city_id: String) -> String:
	var battle_id = "%s_vs_%s_%d" % [attacker_city_id, defender_city_id, GameState.game_time]
	var battle = {
		"id": battle_id,
		"attacker_id": attacker_city_id,
		"defender_id": defender_city_id,
		"phase": BATTLE_PHASES.NAVAL,
		"round": 0,
		"attacker_units": _prepare_army(attacker_city_id),
		"defender_units": _prepare_army(defender_city_id),
		"attacker_navy": _prepare_navy(attacker_city_id),
		"defender_navy": _prepare_navy(defender_city_id),
		"attacker_wall": BuildingManager.get_wall_defense(defender_city_id),
		"attacker_morale": 100.0,
		"defender_morale": 100.0,
		"loot": {},
		"total_attacker_losses": {},
		"total_defender_losses": {},
		"done": false,
		"surrendered": false
	}
	_active_battles[battle_id] = battle
	var city = GameState.current_cities.get(defender_city_id)
	if city:
		city["under_attack"] = true
	EventBus.battle_initiated.emit(attacker_city_id, defender_city_id)
	return battle_id

func _prepare_army(city_id: String) -> Dictionary:
	var result = { "front": [], "back": [], "artillery": [] }
	if not GameState.current_cities.has(city_id):
		return result
	var city = GameState.current_cities[city_id]
	var units = city.get("units", {})

	for unit_type in units:
		var defn = MilitaryManager.get_unit_def(unit_type)
		if not defn or defn.get("naval", false):
			continue
		var count = units[unit_type].get("count", 0)
		if count <= 0:
			continue

		var row = defn.get("row", "back")
		var row_key = row if row in result else "back"
		result[row_key].append({
			"type": unit_type,
			"defn": defn,
			"count": count,
			"hp": defn.get("health", 20),
			"max_hp": defn.get("health", 20)
		})
	return result

func _prepare_navy(city_id: String) -> Array:
	var result = []
	if not GameState.current_cities.has(city_id):
		return result
	var city = GameState.current_cities[city_id]
	var units = city.get("units", {})

	for unit_type in units:
		var defn = MilitaryManager.get_unit_def(unit_type)
		if not defn or not defn.get("naval", false):
			continue
		var count = units[unit_type].get("count", 0)
		if count <= 0:
			continue

		result.append({
			"type": unit_type,
			"defn": defn,
			"count": count,
			"hp": defn.get("health", 50),
			"max_hp": defn.get("health", 50)
		})
	return result

func process_tick() -> void:
	var to_remove = []
	for battle_id in _active_battles:
		var battle = _active_battles[battle_id]
		if battle.done:
			to_remove.append(battle_id)
			continue

		match battle.phase:
			BATTLE_PHASES.NAVAL:
				_process_naval_phase(battle)
			BATTLE_PHASES.BOMBARDMENT:
				_process_bombardment_phase(battle)
			BATTLE_PHASES.GROUND:
				_process_ground_phase(battle)
			BATTLE_PHASES.SIEGE:
				_process_siege_phase(battle)
			BATTLE_PHASES.AFTERMATH:
				_process_aftermath(battle)
				battle.done = true
				to_remove.append(battle_id)

	for battle_id in to_remove:
		var battle = _active_battles[battle_id]
		_finalize_battle(battle)
		_active_battles.erase(battle_id)

func _process_naval_phase(battle: Dictionary) -> void:
	var atk_navy = battle.get("attacker_navy", [])
	var def_navy = battle.get("defender_navy", [])

	if atk_navy.is_empty() and def_navy.is_empty():
		battle.phase = BATTLE_PHASES.BOMBARDMENT
		return

	if def_navy.is_empty():
		battle.phase = BATTLE_PHASES.BOMBARDMENT
		return

	if atk_navy.is_empty():
		battle.phase = BATTLE_PHASES.AFTERMATH
		return

	battle.round += 1
	var round_attacker_destroyed = []
	var round_defender_destroyed = []

	for atk_ship in atk_navy:
		if atk_ship.count <= 0:
			continue
		var target = _select_target(def_navy)
		if target == null:
			continue
		var dmg = atk_ship.defn.get("attack", 0) * atk_ship.count
		var kills = dmg / max(target.defn.get("defense", 1) + target.defn.get("health", 1), 1)
		kills = mini(kills, target.count)
		target.count -= kills

		if atk_ship.defn.get("ram_damage_bonus", 0.0) > 0:
			var extra_dmg = dmg * atk_ship.defn.get("ram_damage_bonus", 1.0) * 0.1
			var extra_kills = int(extra_dmg / max(target.defn.get("health", 50), 1))
			extra_kills = mini(extra_kills, target.count)
			target.count -= extra_kills
			kills += extra_kills

		if kills > 0:
			round_defender_destroyed.append({"type": target.type, "count": kills})

	for def_ship in def_navy:
		if def_ship.count <= 0:
			continue
		var target = _select_target(atk_navy)
		if target == null:
			continue
		var dmg = def_ship.defn.get("attack", 0) * def_ship.count
		var kills = dmg / max(target.defn.get("defense", 1) + target.defn.get("health", 1), 1)
		kills = mini(kills, target.count)
		target.count -= kills
		if kills > 0:
			round_attacker_destroyed.append({"type": target.type, "count": kills})

	for entry in round_attacker_destroyed:
		EventBus.battle_unit_destroyed.emit(battle.id, entry.type, true)
		_track_losses(battle.total_attacker_losses, entry.type, entry.count)
	for entry in round_defender_destroyed:
		EventBus.battle_unit_destroyed.emit(battle.id, entry.type, false)
		_track_losses(battle.total_defender_losses, entry.type, entry.count)

	atk_navy = _remove_dead(atk_navy)
	def_navy = _remove_dead(def_navy)
	battle.attacker_navy = atk_navy
	battle.defender_navy = def_navy

	EventBus.battle_round.emit(battle.id, battle.round, round_attacker_destroyed, round_defender_destroyed)

func _process_bombardment_phase(battle: Dictionary) -> void:
	var artiller = []
	for row in ["artillery"]:
		for unit_group in battle.attacker_units.get(row, []):
			if unit_group.count > 0:
				artiller.append(unit_group)

	var wall_hp = battle.attacker_wall
	var destroyed_artillery = []

	if wall_hp <= 0:
		battle.phase = BATTLE_PHASES.GROUND
		return

	if artiller.is_empty():
		battle.phase = BATTLE_PHASES.GROUND
		return

	for unit_group in artiller:
		var wall_dmg = unit_group.defn.get("wall_damage", 0.0)
		var total_wall_dmg = wall_dmg * unit_group.count
		wall_hp -= total_wall_dmg

		battle.round += 1
		EventBus.battle_round.emit(battle.id, battle.round, {}, {"wall_damage": total_wall_dmg})

	wall_hp = max(0.0, wall_hp)
	battle.attacker_wall = wall_hp

	if wall_hp <= 0:
		battle.phase = BATTLE_PHASES.GROUND

func _process_ground_phase(battle: Dictionary) -> void:
	var atk_units = battle.attacker_units
	var def_units = battle.defender_units

	var atk_total = _count_all(atk_units)
	var def_total = _count_all(def_units)

	if atk_total == 0:
		battle.phase = BATTLE_PHASES.AFTERMATH
		battle.surrendered = false
		return

	if def_total == 0:
		battle.phase = BATTLE_PHASES.SIEGE
		return

	battle.round += 1
	var round_attacker_destroyed = []
	var round_defender_destroyed = []

	var cook_morale_bonus = _calc_morale_bonus(atk_units, "cook")
	var def_cook_morale = _calc_morale_bonus(def_units, "cook")

	battle.attacker_morale = clampf(battle.attacker_morale + cook_morale_bonus, 0.0, 150.0)
	battle.defender_morale = clampf(battle.defender_morale + def_cook_morale, 0.0, 150.0)

	var atk_front = battle.attacker_morale / 100.0
	var def_front = battle.defender_morale / 100.0

	var atk_alive = true
	var def_alive = true

	for atk_row in ROW_ORDER:
		if not atk_alive:
			break
		for atk_group in atk_units.get(atk_row, []):
			if atk_group.count <= 0:
				continue
			var def_target_row = _get_defender_target_row(battle, atk_row)
			var def_target = _select_target_group(def_units.get(def_target_row, []))
			if def_target == null:
				continue

			var dmg = atk_group.defn.get("attack", 0) * atk_group.count * atk_front
			var def_val = def_target.defn.get("defense", 1) + def_target.defn.get("health", 1)
			var kills = int(dmg / max(def_val, 1) * 0.8)
			kills = mini(max(kills, 1), def_target.count)
			def_target.count -= kills
			round_defender_destroyed.append({"type": def_target.type, "count": kills})

	for def_row in ROW_ORDER:
		if not def_alive:
			break
		for def_group in def_units.get(def_row, []):
			if def_group.count <= 0:
				continue
			var atk_target_row = _get_attacker_target_row(atk_units, def_row)
			var atk_target = _select_target_group(atk_units.get(atk_target_row, []))
			if atk_target == null:
				continue

			var dmg = def_group.defn.get("attack", 0) * def_group.count * def_front
			var def_val = atk_target.defn.get("defense", 1) + atk_target.defn.get("health", 1)
			var kills = int(dmg / max(def_val, 1) * 0.8)
			kills = mini(max(kills, 1), atk_target.count)
			atk_target.count -= kills
			round_attacker_destroyed.append({"type": atk_target.type, "count": kills})

	for entry in round_attacker_destroyed:
		EventBus.battle_unit_destroyed.emit(battle.id, entry.type, true)
		_track_losses(battle.total_attacker_losses, entry.type, entry.count)
	for entry in round_defender_destroyed:
		EventBus.battle_unit_destroyed.emit(battle.id, entry.type, false)
		_track_losses(battle.total_defender_losses, entry.type, entry.count)

	var doctor_heal = _calc_heal(atk_units, battle.total_attacker_losses)
	if doctor_heal > 0:
		_heal_wounded(atk_units, doctor_heal)

	var def_doctor_heal = _calc_heal(def_units, battle.total_defender_losses)
	if def_doctor_heal > 0:
		_heal_wounded(def_units, def_doctor_heal)

	battle.attacker_morale -= 5.0 * (1.0 - atk_front)
	battle.defender_morale -= 2.0 * (1.0 - def_front)

	_remove_empty_units(atk_units)
	_remove_empty_units(def_units)

	EventBus.battle_round.emit(battle.id, battle.round, round_attacker_destroyed, round_defender_destroyed)

func _process_siege_phase(battle: Dictionary) -> void:
	var atk_total = _count_all(battle.attacker_units)
	if atk_total <= 0:
		battle.phase = BATTLE_PHASES.AFTERMATH
		return

	var wall_hp = battle.attacker_wall
	if wall_hp > 0:
		battle.phase = BATTLE_PHASES.BOMBARDMENT
		return

	var def_total = _count_all(battle.defender_units)
	if def_total <= 0:
		battle.phase = BATTLE_PHASES.AFTERMATH
		return

	var attack_power = 0
	for row in ROW_ORDER:
		for unit_group in battle.attacker_units.get(row, []):
			attack_power += unit_group.defn.get("attack", 1) * unit_group.count

	var def_power = 0
	for row in ROW_ORDER:
		for unit_group in battle.defender_units.get(row, []):
			def_power += (unit_group.defn.get("defense", 1) + unit_group.defn.get("health", 1)) * unit_group.count

	var surrender_threshold = def_power * 0.3
	if attack_power > def_power * 1.5 or battle.defender_morale <= 20.0:
		battle.surrendered = true
		var remaining = def_total
		battle.phase = BATTLE_PHASES.AFTERMATH
		EventBus.battle_surrender.emit(battle.id, battle.defender_id, remaining)
		return

	battle.phase = BATTLE_PHASES.GROUND

func _process_aftermath(battle: Dictionary) -> void:
	var winner = battle.attacker_id
	if battle.surrendered:
		winner = battle.attacker_id

	var atk_alive = _count_all(battle.attacker_units)
	var def_alive = _count_all(battle.defender_units)
	if def_alive > atk_alive and atk_alive <= 0:
		winner = battle.defender_id

	var loot = {}
	if winner == battle.attacker_id:
		var def_city = GameState.current_cities.get(battle.defender_id)
		if def_city:
			var res = def_city.get("resources", {})
			for rt in [Globals.ResourceType.GOLD, Globals.ResourceType.WOOD, Globals.ResourceType.FOOD, Globals.ResourceType.STONE]:
				var stolen = int(res.get(rt, 0.0) * 0.3)
				loot[rt] = stolen
				res[rt] = max(0.0, res.get(rt, 0.0) - stolen)
				EventBus.resource_changed.emit(battle.defender_id, str(rt), res[rt], -stolen)

			_remove_units_from_city(battle.attacker_id, battle.total_attacker_losses)
			_remove_units_from_city(battle.defender_id, battle.total_defender_losses)

			if battle.attacker_wall > 0:
				for pos in def_city.get("buildings", {}):
					var b = def_city["buildings"][pos]
					if b.get("id") == "wall":
						b["level"] = max(1, b.get("level", 1) - 1)
						break

			def_city["under_attack"] = false
	else:
		_remove_units_from_city(battle.attacker_id, battle.total_attacker_losses)
		_remove_units_from_city(battle.defender_id, battle.total_defender_losses)
		var def_city = GameState.current_cities.get(battle.defender_id)
		if def_city:
			def_city["under_attack"] = false

	battle.loot = loot
	EventBus.battle_result.emit(battle.id, winner, loot, {
		"attacker_losses": battle.total_attacker_losses,
		"defender_losses": battle.total_defender_losses
	})

func _finalize_battle(battle: Dictionary) -> void:
	var winner = battle.attacker_id
	var atk_alive = _count_all(battle.attacker_units)
	var def_alive = _count_all(battle.defender_units)
	if def_alive > atk_alive or (def_alive > 0 and atk_alive <= 0):
		winner = battle.defender_id

	EventBus.battle_completed.emit(battle.id, winner)

func _select_target(units: Array):
	for unit in units:
		if unit.count > 0:
			return unit
	return null

func _select_target_group(groups: Array):
	for g in groups:
		if g.count > 0:
			return g
	return null

func _get_defender_target_row(battle: Dictionary, attacker_row: String) -> String:
	if attacker_row == "front":
		return "front"
	elif attacker_row == "back":
		if _count_row(battle.defender_units, "front") > 0:
			return "front"
		return "back"
	elif attacker_row == "artillery":
		if _count_row(battle.defender_units, "front") > 0:
			return "front"
		elif _count_row(battle.defender_units, "back") > 0:
			return "back"
		return "artillery"
	return "front"

func _get_attacker_target_row(atk_units: Dictionary, defender_row: String) -> String:
	if defender_row == "front":
		if _count_row(atk_units, "front") > 0:
			return "front"
		return "back"
	return defender_row

func _count_row(units: Dictionary, row: String) -> int:
	var total = 0
	for g in units.get(row, []):
		total += g.count
	return total

func _count_all(units: Dictionary) -> int:
	var total = 0
	for row in ROW_ORDER:
		total += _count_row(units, row)
	return total

func _remove_dead(units: Array) -> Array:
	return units.filter(func(u): return u.count > 0)

func _remove_empty_units(units: Dictionary) -> void:
	for row in ROW_ORDER:
		units[row] = units[row].filter(func(g): return g.count > 0)

func _track_losses(losses: Dictionary, unit_type: String, count: int) -> void:
	losses[unit_type] = losses.get(unit_type, 0) + count

func _calc_morale_bonus(units: Dictionary, unit_type: String) -> float:
	var total = 0.0
	for row in ROW_ORDER:
		for g in units.get(row, []):
			if g.type == unit_type:
				total += g.defn.get("morale_bonus", 0.0) * g.count
	return total * 0.1

func _calc_heal(units: Dictionary, losses: Dictionary) -> float:
	var total_heal = 0.0
	for row in ROW_ORDER:
		for g in units.get(row, []):
			if g.type == "doctor":
				total_heal += g.defn.get("heal_ratio", 0.15) * g.count * g.defn.get("health", 20)
	return total_heal

func _heal_wounded(units: Dictionary, heal_amount: float) -> void:
	for row in ROW_ORDER:
		for g in units.get(row, []):
			var missing_hp = g.max_hp - g.hp
			if missing_hp > 0:
				var healed = min(heal_amount, missing_hp)
				g.hp += healed
				heal_amount -= healed
				if heal_amount <= 0:
					return

func _remove_units_from_city(city_id: String, losses: Dictionary) -> void:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return
	var units = city.get("units", {})
	for unit_type in losses:
		var lost = losses[unit_type]
		if units.has(unit_type):
			var current = units[unit_type].get("count", 0)
			units[unit_type]["count"] = max(0, current - lost)

func has_active_battle(city_id: String) -> bool:
	for battle_id in _active_battles:
		var battle = _active_battles[battle_id]
		if battle.attacker_id == city_id or battle.defender_id == city_id:
			return true
	return false

func get_battle_for_city(city_id: String) -> Dictionary:
	for battle_id in _active_battles:
		var battle = _active_battles[battle_id]
		if battle.attacker_id == city_id or battle.defender_id == city_id:
			return battle
	return {}
