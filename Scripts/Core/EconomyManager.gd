extends Node

func _ready() -> void:
	EventBus.building_constructed.connect(_on_building_changed)
	EventBus.building_upgraded.connect(_on_building_changed)

func create_city_resources(city_id: String) -> Dictionary:
	var resources = {}
	for rt in Globals.ResourceType.values():
		resources[rt] = 0.0
	resources[Globals.ResourceType.WOOD] = 100.0
	resources[Globals.ResourceType.FOOD] = 50.0
	resources[Globals.ResourceType.GOLD] = 200.0
	resources[Globals.ResourceType.POPULATION] = 10.0
	resources[Globals.ResourceType.WORKERS] = 0.0
	resources[Globals.ResourceType.SATISFACTION] = Globals.HAPPINESS_BASE_SATISFACTION
	return resources

func _on_building_changed(city_id: String, _building_id: String, _extra) -> void:
	recalculate_city_production(city_id)

func recalculate_city_production(city_id: String) -> void:
	if not GameState.current_cities.has(city_id):
		return
	var city = GameState.current_cities[city_id]
	city["production"] = {}
	city["consumption"] = {}

	var total_workers_used: int = 0
	var processed: Array = []

	for pos in city.get("buildings", {}):
		var building_data = city["buildings"][pos]
		if processed.has(building_data):
			continue
		processed.append(building_data)

		if not building_data.get("constructed", false):
			continue

		var building_def = BuildingManager.get_building_def(building_data.id)
		if not building_def:
			continue
		var level = building_data.get("level", 1)
		var assigned = building_data.get("workers_assigned", 0)
		var needed = BuildingManager.get_workers_needed(building_data.id, level)

		total_workers_used += assigned

		var worker_ratio = 1.0
		if needed > 0:
			worker_ratio = float(assigned) / float(needed)

		var prod = building_def.get("production", {})
		var cons = building_def.get("consumption", {})

		for rtype in prod:
			var amount = prod[rtype] * level * worker_ratio
			city["production"][rtype] = city["production"].get(rtype, 0.0) + amount

		for rtype in cons:
			var amount = cons[rtype] * level * worker_ratio
			city["consumption"][rtype] = city["consumption"].get(rtype, 0.0) + amount

	city["total_workers_used"] = total_workers_used

func can_afford(city_id: String, costs: Dictionary) -> bool:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return false
	var resources = city.get("resources", {})
	for rtype in costs:
		var needed = costs[rtype]
		if resources.get(rtype, 0.0) < needed:
			return false
	return true

func deduct_costs(city_id: String, costs: Dictionary) -> void:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return
	var resources = city.get("resources", {})
	for rtype in costs:
		resources[rtype] = resources.get(rtype, 0.0) - costs[rtype]
		EventBus.resource_changed.emit(city_id, str(rtype), resources[rtype], -costs[rtype])

func change_resource(city_id: String, rtype: int, amount: float) -> void:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return
	var resources = city.get("resources", {})
	resources[rtype] = max(0.0, resources.get(rtype, 0.0) + amount)
	EventBus.resource_changed.emit(city_id, str(rtype), resources[rtype], amount)

func add_resources(city_id: String, rtype: int, amount: float) -> void:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return
	var resources = city.get("resources", {})
	resources[rtype] = resources.get(rtype, 0.0) + amount
	EventBus.resource_changed.emit(city_id, str(rtype), resources[rtype], amount)

func get_resource(city_id: String, rtype: int) -> float:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return 0.0
	return city.get("resources", {}).get(rtype, 0.0)

func _get_corruption_percent(city_id: String) -> float:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return 0.0
	var is_capital = false
	var capital_id = GameState.current_cities.keys().front()
	if capital_id == city_id:
		is_capital = true
	var cities_outside = GameState.current_cities.size() - 1
	var corruption = mini(cities_outside * 0.05, 0.5)
	var reduction = 0.0
	for pos in city.get("buildings", {}):
		var b = city["buildings"][pos]
		if b.get("id") == "governor_residence" and b.get("constructed", false):
			reduction += 0.05 * b.get("level", 1)
	corruption = max(0.0, corruption - reduction)
	return corruption

func recalculate_satisfaction(city_id: String) -> float:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return 100.0

	var sat = 100.0
	var pop = city.get("resources", {}).get(Globals.ResourceType.POPULATION, 0.0)
	var town_hall_level = 1
	var max_pop = 50.0

	for pos in city.get("buildings", {}):
		var b = city["buildings"][pos]
		if not b.get("constructed", false):
			continue
		var bid = b.get("id", "")
		var level = b.get("level", 1)
		match bid:
			"tavern": sat += level * 5
			"temple": sat += level * 4
			"museum": sat += level * 3
			"town_hall": town_hall_level = level

	max_pop = town_hall_level * 50.0
	for pos in city.get("buildings", {}):
		var b = city["buildings"][pos]
		if b.get("id") == "farm" and b.get("constructed", false):
			max_pop += b.get("level", 1) * 10

	var housing_ratio = pop / max(max_pop, 1.0)
	if housing_ratio > 0.8:
		sat -= 20.0

	var corruption = _get_corruption_percent(city_id)
	sat -= corruption * 10.0

	var city_count = GameState.current_cities.size() - 1
	sat -= city_count * 2.0

	sat = clampf(sat, 0.0, 200.0)
	city["satisfaction"] = sat
	return sat

func get_corruption(city_id: String) -> float:
	return _get_corruption_percent(city_id) * 100.0

func get_warehouse_capacity(city_id: String) -> float:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return 1000.0
	var capacity = 1000.0
	for pos in city.get("buildings", {}):
		var b = city["buildings"][pos]
		var defn = BuildingManager.get_building_def(b.get("id", ""))
		if not defn:
			continue
		if b.get("constructed", false):
			capacity += defn.get("storage_bonus", 0) * b.get("level", 1)
	return capacity

func _get_town_hall_max_pop(city: Dictionary) -> float:
	var max_pop = 50.0
	for pos in city.get("buildings", {}):
		var b = city["buildings"][pos]
		if b.get("id") == "town_hall" and b.get("constructed", false):
			max_pop = b.get("level", 1) * 50.0
		if b.get("id") == "farm" and b.get("constructed", false):
			max_pop += b.get("level", 1) * 10.0
	return max_pop

func _get_total_unit_upkeep(city: Dictionary) -> float:
	var upkeep = 0.0
	for ut in city.get("units", {}):
		var unit_data = city["units"][ut]
		var count = int(unit_data) if typeof(unit_data) == TYPE_INT else int(unit_data.get("count", 0))
		var defn = MilitaryManager.UNIT_DEFINITIONS.get(ut, {})
		var unit_upkeep = defn.get("upkeep", {})
		upkeep += unit_upkeep.get(Globals.ResourceType.FOOD, 0.0) * count
		upkeep += unit_upkeep.get(Globals.ResourceType.GOLD, 0.0) * count
	return upkeep

func process_tick() -> void:
	for city_id in GameState.current_cities:
		var city = GameState.current_cities[city_id]
		var resources = city.get("resources", {})
		var production = city.get("production", {})
		var consumption = city.get("consumption", {})

		var pop_rt = int(Globals.ResourceType.POPULATION)
		var food_rt = int(Globals.ResourceType.FOOD)
		var gold_rt = int(Globals.ResourceType.GOLD)
		var sat_rt = int(Globals.ResourceType.SATISFACTION)

		var current_pop = resources.get(pop_rt, 0.0)
		var satisfaction = recalculate_satisfaction(city_id)
		resources[sat_rt] = satisfaction

		var corruption = _get_corruption_percent(city_id)

		# corruption penalty on production
		var effective_production = {}
		for rt in production:
			effective_production[rt] = production[rt] * (1.0 - corruption)

		var max_pop = _get_town_hall_max_pop(city)
		var housing_ratio = current_pop / max(max_pop, 1.0)

		# food
		var food_prod = effective_production.get(food_rt, 0.0)
		var unit_upkeep = _get_total_unit_upkeep(city)
		var food_cons = consumption.get(food_rt, 0.0) + current_pop * 0.1 + unit_upkeep
		var food_stock = resources.get(food_rt, 0.0)
		var net_food = food_prod - food_cons
		resources[food_rt] = max(0.0, food_stock + net_food)

		# population growth (GDD formula)
		var pop_growth = 0.0
		if food_stock + net_food > 0:
			pop_growth = food_prod * 0.1 + satisfaction * 0.002 - housing_ratio * 0.05
			pop_growth = clampf(pop_growth, -0.5, 2.0)
		else:
			pop_growth = -abs(net_food) * 0.01

		# workers
		var workers_rt = int(Globals.ResourceType.WORKERS)
		var total_workers = resources.get(workers_rt, 0.0)
		var workers_needed = float(city.get("total_workers_used", 0))
		if current_pop > total_workers and total_workers < workers_needed:
			var new_workers = min(current_pop - total_workers, workers_needed - total_workers, 0.5)
			resources[workers_rt] = total_workers + new_workers

		# apply pop growth
		var new_pop = max(0.0, current_pop + pop_growth)
		resources[pop_rt] = new_pop
		if pop_growth != 0:
			EventBus.resource_changed.emit(city_id, str(pop_rt), new_pop, pop_growth)

		EventBus.resource_changed.emit(city_id, str(food_rt), resources[food_rt], net_food)

		# gold from production + population tax - unit upkeep
		var gold_prod = effective_production.get(gold_rt, 0.0) + current_pop * 0.05
		var gold_cons = 0.0
		for ut in city.get("units", {}):
			var unit_data = city["units"][ut]
			var count = int(unit_data) if typeof(unit_data) == TYPE_INT else int(unit_data.get("count", 0))
			var defn = MilitaryManager.UNIT_DEFINITIONS.get(ut, {})
			gold_cons += defn.get("upkeep", {}).get(Globals.ResourceType.GOLD, 0.0) * count

		var net_gold = gold_prod - gold_cons
		var gold_stock = resources.get(gold_rt, 0.0)
		resources[gold_rt] = max(0.0, gold_stock + net_gold)
		EventBus.resource_changed.emit(city_id, str(gold_rt), resources[gold_rt], net_gold)

		# wine consumption for tavern
		var wine_rt = int(Globals.ResourceType.WINE)
		var wine_needed = 0.0
		for pos in city.get("buildings", {}):
			var b = city["buildings"][pos]
			if b.get("id") == "tavern" and b.get("constructed", false):
				var defn = BuildingManager.get_building_def("tavern")
				wine_needed += defn.get("wine_consumption_per_level", 1.0) * b.get("level", 1)
		if wine_needed > 0:
			var wine_available = resources.get(wine_rt, 0.0)
			var wine_used = min(wine_needed, wine_available)
			resources[wine_rt] = max(0.0, wine_available - wine_used)

		# other resources with warehouse cap
		var warehouse_cap = get_warehouse_capacity(city_id)
		for prod_rt in effective_production:
			if prod_rt == food_rt or prod_rt == gold_rt or prod_rt == pop_rt or prod_rt == sat_rt or prod_rt == wine_rt:
				continue
			var net = effective_production[prod_rt] - consumption.get(prod_rt, 0.0)
			if net != 0:
				var current = resources.get(prod_rt, 0.0)
				resources[prod_rt] = max(0.0, min(warehouse_cap, current + net))
				EventBus.resource_changed.emit(city_id, str(prod_rt), resources[prod_rt], net)

	if GameState.current_day > 0:
		WorldManager.process_trade_routes()
		WorldManager.process_arriving_trades()
	GameStateManager.check_win_conditions()
	GameStateManager.check_lose_conditions()

func get_save_data() -> Dictionary:
	return {}

func load_save_data(_data: Dictionary) -> void:
	pass
