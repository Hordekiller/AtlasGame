extends Node

signal npc_attacked(npc_city_id: String, player_city_id: String, result: Dictionary)
signal npc_faction_defeated(faction_id: String)

enum FactionType { PIRATE = 0, BARBARIAN = 1, EMPIRE = 2 }

const FACTION_DEFS := {
	FactionType.PIRATE: {
		"name": "دزدان دریایی",
		"color": Color(0.8, 0.2, 0.2),
		"difficulty": 1, "base_army": 50, "max_army": 200,
		"aggression": 0.7, "economy": 0.3,
		"island_count": 2, "unit_focus": ["slinger", "spearman"]
	},
	FactionType.BARBARIAN: {
		"name": "بربرها",
		"color": Color(0.6, 0.3, 0.1),
		"difficulty": 2, "base_army": 200, "max_army": 500,
		"aggression": 0.4, "economy": 0.5,
		"island_count": 4, "unit_focus": ["hoplite", "swordsman"]
	},
	FactionType.EMPIRE: {
		"name": "امپراتوری",
		"color": Color(0.9, 0.7, 0.1),
		"difficulty": 3, "base_army": 500, "max_army": 1000,
		"aggression": 0.6, "economy": 0.8,
		"island_count": 6, "unit_focus": ["hoplite", "catapult", "archer"]
	}
}

const TICK_INTERVAL: float = 30.0
const HOSTILITY_DECAY: float = 1.0
const HOSTILITY_DECAY_INTERVAL: float = 60.0

var _tick_timer: float = 0.0
var _hostility_timer: float = 0.0
var _faction_hostility: Dictionary = {}
var _faction_state: Dictionary = {}

func _ready() -> void:
	for ftype in FACTION_DEFS:
		var fid = str(ftype)
		if not _faction_hostility.has(fid):
			_faction_hostility[fid] = 0
		if not _faction_state.has(fid):
			_faction_state[fid] = {"defeated": false, "cities_remaining": 0}

func _process(delta: float) -> void:
	_tick_timer += delta
	if _tick_timer >= TICK_INTERVAL:
		_tick_timer = 0.0
		_npc_tick()
	_hostility_timer += delta
	if _hostility_timer >= HOSTILITY_DECAY_INTERVAL:
		_hostility_timer = 0.0
		_decay_hostility()

func get_faction_defs() -> Dictionary:
	return FACTION_DEFS.duplicate(true)

func get_faction_hostility(faction_id: String) -> int:
	return _faction_hostility.get(faction_id, 0)

func get_faction_state(faction_id: String) -> Dictionary:
	return _faction_state.get(faction_id, {"defeated": false, "cities_remaining": 0})

func modify_hostility(faction_id: String, delta: int) -> void:
	_faction_hostility[faction_id] = clampi(_faction_hostility.get(faction_id, 0) + delta, 0, 100)

func _decay_hostility() -> void:
	for fid in _faction_hostility:
		var current = _faction_hostility[fid]
		if current > 0 and current <= 50:
			_faction_hostility[fid] = max(0, current - 1)

func _get_faction_for_npc(npc: Dictionary) -> String:
	var faction_id = npc.get("faction_id", "")
	if faction_id.is_empty():
		faction_id = str(FactionType.PIRATE)
	return faction_id

func _npc_tick() -> void:
	if not is_instance_valid(GameState):
		return
	if GameState.current_npc_cities.is_empty() or GameState.current_cities.is_empty():
		return

	var alive_factions = 0
	for fid in _faction_state:
		_faction_state[fid]["cities_remaining"] = 0

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

		var faction_id = _get_faction_for_npc(npc)
		if _faction_state.has(faction_id):
			_faction_state[faction_id]["cities_remaining"] += 1

		var aggression = npc.get("aggression", 0.1)
		var hostility = _faction_hostility.get(faction_id, 0)
		var hostile_mod = 1.0 + hostility / 100.0

		var army = npc.get("units", {})
		var total_army = 0
		for ut in army:
			total_army += int(army.get(ut, 0))
		var player_units = city.get("units", {})
		var total_player = 0
		for ut in player_units:
			total_player += int(player_units.get(ut, 0)) if typeof(player_units.get(ut)) == TYPE_INT else player_units.get(ut, {}).get("count", 0)

		var attack_chance = aggression * 0.3 * hostile_mod
		if total_army > total_player * 1.5 and randf() < attack_chance:
			_resolve_npc_attack(npc_id, npc, player_cities[0], city)
		else:
			_npc_defensive_build(npc)

	for fid in _faction_state:
		if _faction_state[fid]["cities_remaining"] == 0 and not _faction_state[fid]["defeated"]:
			_faction_state[fid]["defeated"] = true
			alive_factions += 1
			npc_faction_defeated.emit(fid)

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
	EventBus.battle_completed.emit(npc_id + "_vs_" + target_city_id, "true" if loot.keys().size() > 0 else "false")

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
		"faction_id": str(difficulty - 1),
		"resources": {Globals.ResourceType.GOLD: 500 * difficulty, Globals.ResourceType.WOOD: 400 * difficulty}
	}

func get_save_data() -> Dictionary:
	return {
		"faction_hostility": _faction_hostility.duplicate(),
		"faction_state": _faction_state.duplicate(true)
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("faction_hostility"):
		_faction_hostility = data["faction_hostility"].duplicate()
	if data.has("faction_state"):
		_faction_state = data["faction_state"].duplicate(true)
