extends Node

signal army_arrived(travel_id: String, origin_city_id: String, target_island_id: String, units: Dictionary, commander_id: String)

var _travels: Dictionary = {}

func deploy_army(origin_city_id: String, target_island_id: String, units: Dictionary, commander_id: String = "") -> String:
	var travel_id = "travel_%s_%s_%d" % [origin_city_id, target_island_id, Time.get_unix_time_from_system()]
	var origin_island_id = ""
	var city = GameState.current_cities.get(origin_city_id, {})
	if city:
		origin_island_id = city.get("island_id", "")

	var origin_idx = _get_island_index(origin_island_id)
	var target_idx = _get_island_index(target_island_id)
	var distance = absi(origin_idx - target_idx) + 1
	var travel_time = distance * 10.0

	var origin_units = city.get("units", {})
	for ut in units:
		var count = units[ut]
		if origin_units.has(ut):
			origin_units[ut]["count"] = max(0, origin_units[ut].get("count", 0) - count)

	_travels[travel_id] = {
		"travel_id": travel_id,
		"origin_city_id": origin_city_id,
		"target_island_id": target_island_id,
		"units": units.duplicate(true),
		"commander_id": commander_id,
		"departure_time": GameState.game_time,
		"arrival_time": GameState.game_time + travel_time,
		"travel_duration": travel_time,
		"returning": false
	}
	return travel_id

func process_tick() -> void:
	var to_arrive: Array = []
	for tid in _travels:
		var t = _travels[tid]
		if GameState.game_time >= t["arrival_time"] and not t.get("arrived", false):
			to_arrive.append(tid)
	for tid in to_arrive:
		var t = _travels[tid]
		t["arrived"] = true
		army_arrived.emit(tid, t["origin_city_id"], t["target_island_id"], t["units"], t["commander_id"])
		_travels.erase(tid)

func return_army(origin_city_id: String, surviving_units: Dictionary) -> void:
	var city = GameState.current_cities.get(origin_city_id, {})
	if city.is_empty():
		return
	if not city.has("units"):
		city["units"] = {}
	for ut in surviving_units:
		var count = surviving_units[ut]
		if city["units"].has(ut):
			city["units"][ut]["count"] = city["units"][ut].get("count", 0) + count
		else:
			city["units"][ut] = {"count": count, "training": 0, "training_progress": 0.0}

func get_active_travels() -> Array:
	var result = []
	for tid in _travels:
		result.append(_travels[tid].duplicate(true))
	return result

func _get_island_index(island_id: String) -> int:
	var idx = 0
	for iid in GameState.current_islands:
		var island = GameState.current_islands[iid]
		if island_id == iid:
			return island.get("index", idx)
		idx += 1
	return 0

func get_save_data() -> Dictionary:
	return {"travels": _travels}

func load_save_data(data: Dictionary) -> void:
	_travels = data.get("travels", {})
