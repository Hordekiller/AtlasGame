extends Node

const WORLD_SEED: int = 42
const ISLAND_COUNT: int = 25
const CITIES_PER_ISLAND: int = 4

func generate_world() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = WORLD_SEED
	GameState.current_islands.clear()

	for i in range(ISLAND_COUNT):
		var island_id = "island_%d" % i
		var island_data = _generate_island(island_id, i, rng)
		GameState.current_islands[island_id] = island_data

	_generate_npc_cities(rng)
	GameState.current_npc_cities = _npc_cities_data.duplicate(true)

func _generate_island(island_id: String, index: int, rng: RandomNumberGenerator) -> Dictionary:
	var resource_types = [
		Globals.IslandResource.WOOD,
		Globals.IslandResource.MARBLE,
		Globals.IslandResource.GLASS,
		Globals.IslandResource.WINE,
		Globals.IslandResource.CRYSTAL,
		Globals.IslandResource.SULFUR
	]
	var primary_resource = resource_types[index % resource_types.size()]
	var secondary_resource = resource_types[(index + 2) % resource_types.size()]

	var names = [
		"سرسیاه", "سفیدکوه", "سبزدره", "زرین", "آبی",
		"آتشین", "نقره‌ای", "کهربا", "یاقوت", "زبرجد",
		"سرخ", "بنفش", "فیروزه", "الماس", "مرجانی",
		"عقیق", "لاجورد", "یشم", "سنگین", "بلور"
	]

	return {
		"id": island_id,
		"name": "جزیره " + names[index % names.size()],
		"index": index,
		"primary_resource": primary_resource,
		"secondary_resource": secondary_resource,
		"city_positions": _generate_city_positions(rng),
		"player_cities": [],
		"npc_cities": [],
		"explored": false
	}

func _generate_city_positions(rng: RandomNumberGenerator) -> Array:
	var positions = []
	for i in range(CITIES_PER_ISLAND):
		var angle = rng.randf_range(0, PI * 2)
		var dist = rng.randf_range(0.3, 0.8)
		positions.append(Vector2(cos(angle) * dist, sin(angle) * dist))
	return positions

var _npc_cities_data: Dictionary = {}

func _generate_npc_cities(rng: RandomNumberGenerator) -> void:
	_npc_cities_data.clear()
	var npc_names = [
		"اردشیر", "داریوش", "کوروش", "خشایار", "مهرداد",
		"بهمن", "فرهاد", "شاپور", "بهرام", "تیرداد",
		"اردوان", "گودرز", "نرسی", "هرمز", "پیروز",
		"قباد", "انوشیروان", "یزدگرد", "خسرو", "بابک"
	]
	var npc_island_count = min(12, ISLAND_COUNT)
	var island_indices = []
	for i in range(ISLAND_COUNT):
		island_indices.append(i)
	rng.shuffle(island_indices)

	var used_names = []
	for i in range(npc_island_count):
		var island_idx = island_indices[i]
		var island_id = "island_%d" % island_idx
		var island = GameState.current_islands[island_id]

		var name_idx = rng.randi_range(0, npc_names.size() - 1)
		var city_name = npc_names[name_idx] + "‌شهر"
		if city_name in used_names:
			city_name = "شهر " + npc_names[name_idx]
		used_names.append(city_name)

		var npc_city_id = "npc_%s" % island_id
		var defense_level = rng.randi_range(1, 5)
		var army_size = rng.randi_range(50, 500)
		var unit_types = ["slinger", "hoplite", "archer"]
		var units = {}
		for ut in unit_types:
			units[ut] = rng.randi_range(10, army_size / len(unit_types))

		var buildings = {}
		var starter_ids = ["town_hall", "lumberjack", "quarry", "farm", "barracks", "warehouse", "wall"]
		var bpos = Vector2i(4, 4)
		for bid in starter_ids:
			var defn = BuildingManager.get_building_def(bid)
			var sz = defn.get("size", Vector2i(2, 2))
			var lvl = rng.randi_range(1, defense_level)
			var bdata = {
				"id": bid, "level": lvl,
				"grid_pos": bpos, "size": sz,
				"constructed": true, "constructing": false,
				"upgrading": false, "workers_assigned": 2
			}
			for x in range(bpos.x, bpos.x + sz.x):
				for y in range(bpos.y, bpos.y + sz.y):
					buildings[Vector2i(x, y)] = bdata
			bpos += Vector2i(3, 0)

		var npc_data = {
			"id": npc_city_id,
			"name": city_name,
			"island_id": island_id,
			"player": "NPC",
			"grid_size": Globals.CitySize.SMALL,
			"buildings": buildings,
			"units": units,
			"defense_level": defense_level,
			"army_size": army_size,
			"aggression": rng.randf_range(0.1, 0.9),
			"resources": { Globals.ResourceType.GOLD: 1000, Globals.ResourceType.WOOD: 800 }
		}
		_npc_cities_data[npc_city_id] = npc_data
		island["npc_cities"].append(npc_city_id)

func create_player_city(city_name: String, island_id: String, position_index: int, player_name: String = "بازیکن") -> String:
	var island = GameState.current_islands.get(island_id)
	if not island:
		push_error("Island not found: ", island_id)
		return ""

	var city_id = "city_%s" % randi()
	island["explored"] = true

	var city_data = {
		"id": city_id,
		"name": city_name,
		"island_id": island_id,
		"player": player_name,
		"grid_size": Globals.CitySize.SMALL,
		"resources": {},
		"buildings": {},
		"production": {},
		"consumption": {},
		"research_completed": [],
		"research_in_progress": "",
		"research_progress": 0.0,
		"units": {},
		"population": 0,
		"satisfaction": 100.0,
		"warehouse_capacity": 5000,
		"defense": 0,
		"position_index": position_index,
		"created_at": GameState.game_time
	}

	city_data["resources"] = EconomyManager.create_city_resources(city_id)

	GameState.current_cities[city_id] = city_data
	island["player_cities"].append(city_id)

	_create_starting_buildings(city_id, city_data)

	EconomyManager.recalculate_city_production(city_id)
	EventBus.city_created.emit(city_id, city_name, island_id)

	return city_id

func _create_starting_buildings(city_id: String, city: Dictionary) -> void:
	var center = Vector2i(7, 7)
	city["buildings"] = {}

	var starters = ["town_hall", "lumberjack", "lumberjack", "farm", "farm", "academy", "warehouse"]

	var offset = Vector2i(0, 0)
	for i in range(starters.size()):
		var building_id = starters[i]
		var defn = BuildingManager.get_building_def(building_id)
		var size = defn.get("size", Vector2i(2, 2))

		var pos = center + Vector2i(
			(i % 4) * (size.x + 1) - 6,
			(i / 4) * (size.y + 1) - 3
		)
		pos.x = clamp(pos.x, 0, city["grid_size"] - size.x)
		pos.y = clamp(pos.y, 0, city["grid_size"] - size.y)

		var building_data = {
			"id": building_id,
			"level": 1,
			"grid_pos": pos,
			"size": size,
			"constructed_time": 0.0,
			"constructed": true,
			"constructing": false,
			"upgrading": false,
			"upgrade_time_left": 0.0,
			"upgrade_time_total": 10.0,
			"workers_assigned": BuildingManager.get_workers_needed(building_id, 1)
		}

		for x in range(pos.x, pos.x + size.x):
			for y in range(pos.y, pos.y + size.y):
				city["buildings"][Vector2i(x, y)] = building_data

func get_island_for_city(city_id: String) -> Dictionary:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return {}
	return GameState.current_islands.get(city.get("island_id", ""), {})

func find_player_cities() -> Array:
	var result = []
	for city_id in GameState.current_cities:
		var city = GameState.current_cities[city_id]
		if city.get("player", "") != "":
			result.append(city_id)
	return result

func can_colonize(city_id: String) -> bool:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return false
	var has_port = false
	for data in city.get("buildings", {}).values():
		if data.get("id") == "port":
			has_port = true
			break
	if not has_port:
		return false
	var max_colonies = BuildingManager.get_max_colonies(city_id)
	var current_colonies = 0
	for cid in GameState.current_cities:
		if cid != city_id and GameState.current_cities[cid].get("player", "") != "":
			current_colonies += 1
	if max_colonies <= 0:
		return false
	return current_colonies < max_colonies

func colony_cost() -> Dictionary:
	return {
		Globals.ResourceType.WOOD: 300,
		Globals.ResourceType.GOLD: 200
	}

func colonize_island(city_id: String, island_id: String, city_name: String) -> String:
	var island = GameState.current_islands.get(island_id)
	if not island:
		return ""

	if not can_colonize(city_id):
		return ""

	var city = GameState.current_cities.get(city_id)
	if not city:
		return ""

	var positions = island.get("city_positions", [])
	if positions.is_empty():
		return ""

	if island.get("player_cities", []).size() >= positions.size():
		EventBus.notification_added.emit("این جزیره ظرفیت شهر جدید ندارد!", "warning")
		return ""

	var cost = colony_cost()
	for rtype in cost:
		var amt = cost[rtype]
		if EconomyManager.get_resource(city_id, rtype) < amt:
			return ""

	for rtype in cost:
		EconomyManager.change_resource(city_id, rtype, -cost[rtype])

	var next_pos = island.get("player_cities", []).size()
	var colonized = create_player_city(city_name, island_id, next_pos)
	if colonized != "":
		GameState.current_islands[island_id]["explored"] = true
		EventBus.city_colonized.emit(colonized, city_name, island_id)
	return colonized

func add_trade_route(from_city: String, to_city: String, resource_type: int, amount: float, interval_days: int = 1) -> String:
	var route_id = "trade_%d" % randi()
	var route = {
		"id": route_id,
		"from_city": from_city,
		"to_city": to_city,
		"resource_type": resource_type,
		"amount": amount,
		"interval_days": interval_days,
		"next_shipment_day": GameState.current_day + interval_days,
		"active": true
	}
	GameState.trade_routes[route_id] = route
	EventBus.trade_route_created.emit(route_id, from_city, to_city, resource_type, amount)
	return route_id

func remove_trade_route(route_id: String) -> void:
	if GameState.trade_routes.has(route_id):
		GameState.trade_routes.erase(route_id)
		EventBus.trade_route_removed.emit(route_id)

func get_trade_routes_for_city(city_id: String) -> Array:
	var result = []
	for route in GameState.trade_routes.values():
		if route.get("from_city") == city_id or route.get("to_city") == city_id:
			result.append(route)
	return result

func get_island_distance(island_a: String, island_b: String) -> float:
	var a = GameState.current_islands.get(island_a, {})
	var b = GameState.current_islands.get(island_b, {})
	var idx_a = a.get("index", 0)
	var idx_b = b.get("index", 0)
	var diff = abs(idx_a - idx_b)
	return float(min(diff, 20 - diff))

func process_trade_routes() -> void:
	for route_id in GameState.trade_routes:
		var route = GameState.trade_routes[route_id]
		if not route.get("active", true):
			continue
		if GameState.current_day >= route.get("next_shipment_day", 0):
			var from_city = GameState.current_cities.get(route.get("from_city", ""))
			var to_city = GameState.current_cities.get(route.get("to_city", ""))
			if not from_city or not to_city:
				continue

			var rtype = route.get("resource_type", 0)
			var amount = route.get("amount", 0)
			var available = EconomyManager.get_resource(route["from_city"], rtype)
			if available >= amount:
				var island_a = get_island_for_city(route["from_city"]).get("id", "")
				var island_b = get_island_for_city(route["to_city"]).get("id", "")
				var distance = get_island_distance(island_a, island_b)
				var travel_time = distance * 1.0

				GameState.active_trades.append({
					"route_id": route_id,
					"from_city": route["from_city"],
					"to_city": route["to_city"],
					"resource_type": rtype,
					"amount": amount,
					"departure_day": GameState.current_day,
					"arrival_day": GameState.current_day + travel_time
				})
				EconomyManager.change_resource(route["from_city"], rtype, -amount)
				EventBus.trade_sent.emit(route["from_city"], route["to_city"], {rtype: amount})

			route["next_shipment_day"] = GameState.current_day + route.get("interval_days", 1)

func process_arriving_trades() -> void:
	var arrived = []
	for i in range(GameState.active_trades.size()):
		var trade = GameState.active_trades[i]
		if GameState.current_day >= trade.get("arrival_day", 0):
			var rtype = trade.get("resource_type", 0)
			var amount = trade.get("amount", 0)
			var to_city = trade.get("to_city", "")
			EconomyManager.change_resource(to_city, rtype, amount)
			EventBus.trade_received.emit(to_city, {rtype: amount})
			EventBus.trade_ship_arrived.emit(trade.get("route_id", ""), trade.get("from_city", ""), to_city, rtype, amount)
			arrived.append(i)

	for i in range(arrived.size() - 1, -1, -1):
		GameState.active_trades.remove_at(arrived[i])
