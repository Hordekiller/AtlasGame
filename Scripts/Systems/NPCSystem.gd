extends Node

signal npc_attacked(npc_city_id: String, player_city_id: String, result: Dictionary)

const TICK_INTERVAL: float = 30.0
var _tick_timer: float = 0.0

func _process(delta: float) -> void:
	_tick_timer += delta
	if _tick_timer >= TICK_INTERVAL:
		_tick_timer = 0.0
		_npc_tick()

func _npc_tick() -> void:
	for npc_id in GameState.current_npc_cities:
		var npc = GameState.current_npc_cities[npc_id]
		if not npc:
			continue
		var island_id = npc.get("island_id", "")
		var island = GameState.current_islands.get(island_id, {})
		var player_cities = island.get("player_cities", [])
		if player_cities.is_empty():
			continue

		var city = GameState.current_cities.get(player_cities[0], {})
		if city.is_empty():
			continue

		var aggression = npc.get("aggression", 0.1)
		var army = npc.get("units", {})
		var total_army = 0
		for ut in army:
			total_army += int(army.get(ut, 0))
		var player_units = city.get("units", {})
		var total_player = 0
		for ut in player_units:
			total_player += int(player_units.get(ut, 0)) if typeof(player_units.get(ut)) == TYPE_INT else player_units.get(ut, {}).get("count", 0)

		if total_army > total_player * 1.5 and randf() < aggression * 0.3:
			_resolve_npc_attack(npc_id, npc, player_cities[0], city)
		else:
			_npc_defensive_build(npc)

func _resolve_npc_attack(npc_id: String, npc: Dictionary, target_city_id: String, target_city: Dictionary) -> void:
	var attacker_units = npc.get("units", {}).duplicate()
	var defender_units = target_city.get("units", {})
	var defender_buildings = target_city.get("buildings", {})
	var wall_def = 0.0
	for bpos in defender_buildings:
		var b = defender_buildings[bpos]
		var defn = BuildingManager.get_building_def(b.get("id", ""))
		if defn and defn.get("wall_defense", false):
			wall_def += defn.get("wall_defense_base", 0.0) + defn.get("wall_defense_per_level", 0.0) * b.get("level", 1)
		if defn and defn.get("garrison_attack_per_level", 0) > 0:
			var lvl = b.get("level", 1)
			var gar_atk = defn.get("garrison_attack_per_level", 0) * lvl
			for ut in attacker_units:
				var cnt = int(attacker_units.get(ut, 0))
				var dmg = min(cnt, max(1, gar_atk / max(1, len(attacker_units.keys()))))
				attacker_units[ut] = max(0, cnt - dmg)

	var atk_power = 0
	for ut in attacker_units:
		atk_power += int(attacker_units.get(ut, 0))
	var def_power = 0
	for ut in defender_units:
		var cnt = int(defender_units.get(ut, 0)) if typeof(defender_units.get(ut)) == TYPE_INT else defender_units.get(ut, {}).get("count", 0)
		def_power += cnt
	var effective_defense = max(1, def_power + wall_def)

	var loot: Dictionary = {}
	if atk_power > effective_defense:
		var city_res = target_city.get("resources", {})
		var steal_pct = clampf(float(atk_power - effective_defense) / atk_power, 0.0, 0.5)
		for rt in city_res:
			var amt = int(city_res[rt] * steal_pct)
			if amt > 0:
				loot[rt] = amt
		EventBus.notification_added.emit("شهر %s مورد حمله %s قرار گرفت!" % [target_city.get("name", "???"), npc.get("name", "???")], "warning")
	else:
		for ut in attacker_units:
			var cnt = int(attacker_units.get(ut, 0))
			var losses = min(cnt, ceil(cnt * 0.3))
			attacker_units[ut] = cnt - losses
		EventBus.notification_added.emit("حمله %s به %s دفع شد!" % [npc.get("name", "???"), target_city.get("name", "???")], "success")
	npc["units"] = attacker_units
	var result = {"loot": loot, "attacker": npc_id, "defender": target_city_id}
	npc_attacked.emit(npc_id, target_city_id, result)
	EventBus.battle_completed.emit(npc_id + "_vs_" + target_city_id, loot.keys().size() > 0 as String)

func _npc_defensive_build(npc: Dictionary) -> void:
	var defense = npc.get("defense_level", 1)
	if defense < 5 and randf() < 0.4:
		npc["defense_level"] = defense + 1
		for ut in npc.get("units", {}):
			npc["units"][ut] = int(npc["units"][ut]) + 5

static func spawn_npc_city(island_id: String, difficulty: int = 1) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	var npc_names = ["اردشیر", "داریوش", "کوروش", "خشایار", "مهرداد"]
	var idx = rng.randi_range(0, npc_names.size() - 1)
	var city_name = npc_names[idx] + "‌شهر"
	var npc_id = "npc_spawn_%s" % island_id
	var unit_types = ["slinger", "hoplite", "archer"]
	var units = {}
	for ut in unit_types:
		units[ut] = rng.randi_range(20, 50) * difficulty
	return {
		"id": npc_id, "name": city_name, "island_id": island_id,
		"player": "NPC", "grid_size": 12,
		"buildings": {}, "units": units,
		"defense_level": difficulty, "army_size": difficulty * 200,
		"aggression": clampf(difficulty * 0.2, 0.1, 0.9),
		"resources": {Globals.ResourceType.GOLD: 500 * difficulty, Globals.ResourceType.WOOD: 400 * difficulty}
	}
