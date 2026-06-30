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

func recalculate_satisfaction(city_id: String) -> float:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return Globals.HAPPINESS_BASE_SATISFACTION

	var sat = Globals.HAPPINESS_BASE_SATISFACTION

	var production = city.get("production", {})
	sat += production.get(Globals.ResourceType.SATISFACTION, 0.0)

	var pop = city.get("resources", {}).get(Globals.ResourceType.POPULATION, 0.0)
	sat += pop * Globals.HAPPINESS_CROWDED_PENALTY_PER_POP

	var wine_consumed = 0.0
	for pos in city.get("buildings", {}):
		var b = city["buildings"][pos]
		if b.get("id") == "tavern" and b.get("constructed", false):
			var defn = BuildingManager.get_building_def("tavern")
			var level = b.get("level", 1)
			var wine_needed = defn.get("wine_consumption_per_level", 1.0) * level
			var available = get_resource(city_id, Globals.ResourceType.WINE)
			var actual = min(wine_needed, available)
			b["wine_used_last_tick"] = actual
			sat += actual * Globals.HAPPINESS_WINE_SAT_PER_UNIT
			wine_consumed += actual

	var corruption = get_corruption(city_id)
	sat -= corruption * Globals.HAPPINESS_CORRUPTION_SAT_PENALTY

	sat = clampf(sat, 0.0, 200.0)
	city["satisfaction"] = sat
	return sat

func get_corruption(city_id: String) -> float:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return 0.0

	var total_colonies = GameState.current_cities.size() - 1
	var base_corruption = 0.0
	if total_colonies > 0:
		base_corruption = total_colonies * Globals.HAPPINESS_CORRUPTION_PER_COLONY

	var reduction = 0.0
	for pos in city.get("buildings", {}):
		var b = city["buildings"][pos]
		if b.get("id") == "governor_residence" and b.get("constructed", false):
			var defn = BuildingManager.get_building_def("governor_residence")
			reduction += defn.get("corruption_reduction_per_level", 5.0) * b.get("level", 1)

	base_corruption = max(0.0, base_corruption - reduction)
	return base_corruption

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

		var current_pop = int(resources.get(pop_rt, 0.0))

		var satisfaction = recalculate_satisfaction(city_id)
		resources[sat_rt] = satisfaction

		var target_pop = int(production.get(pop_rt, 0.0) * 20.0)
		var pop_growth = 0.0

		var sat_factor = 0.0
		if satisfaction >= Globals.HAPPINESS_POP_GROWTH_MAX_SAT:
			sat_factor = 1.0
		elif satisfaction <= Globals.HAPPINESS_POP_GROWTH_MIN_SAT:
			sat_factor = 0.0
		else:
			sat_factor = (satisfaction - Globals.HAPPINESS_POP_GROWTH_MIN_SAT) / (Globals.HAPPINESS_POP_GROWTH_MAX_SAT - Globals.HAPPINESS_POP_GROWTH_MIN_SAT)

		if current_pop < target_pop:
			pop_growth = lerpf(Globals.HAPPINESS_POP_GROWTH_MIN_RATE, Globals.HAPPINESS_POP_GROWTH_MAX_RATE, sat_factor)
		elif current_pop > target_pop:
			pop_growth = -0.2

		var workers_rt = int(Globals.ResourceType.WORKERS)
		var total_workers = int(resources.get(workers_rt, 0.0))
		var workers_needed = city.get("total_workers_used", 0)
		var available_pop_for_workers = current_pop - total_workers
		if available_pop_for_workers > 0 and total_workers < workers_needed:
			var new_workers = min(available_pop_for_workers, workers_needed - total_workers, 0.5)
			resources[workers_rt] = total_workers + new_workers

		var food_prod = production.get(food_rt, 0.0)
		var food_cons = consumption.get(food_rt, 0.0) + current_pop * 0.1

		var food_stock = resources.get(food_rt, 0.0)
		var net_food = food_prod - food_cons
		resources[food_rt] = max(0.0, food_stock + net_food)

		if food_stock + net_food <= 0 and net_food < 0:
			pop_growth -= 1.0

		var wine_rt = int(Globals.ResourceType.WINE)
		for pos in city.get("buildings", {}):
			var b = city["buildings"][pos]
			if b.get("id") == "tavern" and b.get("constructed", false):
				var defn = BuildingManager.get_building_def("tavern")
				var level = b.get("level", 1)
				var wine_needed = defn.get("wine_consumption_per_level", 1.0) * level
				var wine_available = resources.get(wine_rt, 0.0)
				var wine_used = min(wine_needed, wine_available)
				resources[wine_rt] = max(0.0, wine_available - wine_used)

		if pop_growth != 0:
			var new_pop = max(0.0, resources.get(pop_rt, 0.0) + pop_growth)
			resources[pop_rt] = new_pop
			EventBus.resource_changed.emit(city_id, str(pop_rt), resources[pop_rt], pop_growth)

		EventBus.resource_changed.emit(city_id, str(food_rt), resources[food_rt], net_food)

		var gold_prod = production.get(gold_rt, 0.0)
		if gold_prod > 0:
			var gold_amount = gold_prod + current_pop * 0.05
			resources[gold_rt] = resources.get(gold_rt, 0.0) + gold_amount
			EventBus.resource_changed.emit(city_id, str(gold_rt), resources[gold_rt], gold_amount)

		var warehouse_cap = get_warehouse_capacity(city_id)
		for prod_rt in production:
			if prod_rt == food_rt or prod_rt == gold_rt or prod_rt == pop_rt or prod_rt == sat_rt:
				continue
			var net = production[prod_rt] - consumption.get(prod_rt, 0.0)
			if net != 0:
				var current = resources.get(prod_rt, 0.0)
				var new_val = max(0.0, min(warehouse_cap, current + net))
				resources[prod_rt] = new_val
				EventBus.resource_changed.emit(city_id, str(prod_rt), resources[prod_rt], net)

	if GameState.current_day > 0:
		WorldManager.process_trade_routes()
		WorldManager.process_arriving_trades()
