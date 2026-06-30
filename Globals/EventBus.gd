extends Node

signal resource_changed(city_id: String, resource_type: String, new_amount: float, delta: float)
signal building_constructed(city_id: String, building_id: String, grid_pos: Vector2i)
signal building_upgraded(city_id: String, building_id: String, new_level: int)
signal building_demolished(city_id: String, grid_pos: Vector2i)
signal building_upgrade_progress(city_id: String, grid_pos: Vector2i, progress: float, total: float)
signal building_construct_progress(city_id: String, grid_pos: Vector2i, progress: float, total: float)
signal building_upgrade_complete(city_id: String, grid_pos: Vector2i, building_id: String, new_level: int)
signal building_construct_complete(city_id: String, grid_pos: Vector2i, building_id: String)
signal city_created(city_id: String, city_name: String, island_id: String)
signal research_completed(tech_id: String)
signal research_started(tech_id: String, duration: float)
signal unit_trained(city_id: String, unit_type: String, count: int)
signal battle_initiated(attacker_id: String, defender_id: String)
signal battle_completed(battle_id: String, winner: String)
signal trade_sent(from_city: String, to_city: String, resources: Dictionary)
signal trade_received(city_id: String, resources: Dictionary)
signal trade_route_created(route_id: String, from_city: String, to_city: String, resource_type: int, amount: float)
signal trade_route_removed(route_id: String)
signal trade_ship_arrived(route_id: String, from_city: String, to_city: String, resource_type: int, amount: float)
signal city_colonized(city_id: String, city_name: String, island_id: String)
signal day_changed(day: int)
signal game_loaded()
signal game_saved()
signal notification_added(message: String, type: String)
signal city_selected(city_id: String)
signal building_selected(city_id: String, grid_pos: Vector2i)
signal time_speed_changed(speed: float)

signal spy_mission_started(city_id: String, target_city_id: String, mission_type: String)
signal spy_mission_completed(city_id: String, target_city_id: String, mission_type: String, success: bool, result: Dictionary)
signal spy_discovered(city_id: String, spy_city_id: String)
signal spy_killed(city_id: String, spy_city_id: String)

signal marketplace_trade_created(trade_id: String, city_id: String, resource_type: int, amount: int, price: float)
signal marketplace_trade_completed(trade_id: String, city_id: String)
signal marketplace_merchant_arrived(city_id: String, resource_type: int, amount: int)

signal battle_phase(battle_id: String, attacker_city_id: String, defender_city_id: String, phase: int)
signal battle_round(battle_id: String, round: int, attacker_units: Dictionary, defender_units: Dictionary)
signal battle_unit_destroyed(battle_id: String, unit_type: String, is_attacker: bool)
signal battle_result(battle_id: String, winner: String, loot: Dictionary, casualties: Dictionary)
signal battle_surrender(battle_id: String, surrendering_city: String, remaining_units: int)

func safe_emit(signal_name: String, args: Array = []) -> void:
	if not is_instance_valid(self):
		return
	var target = Callable(self, signal_name)
	if not target.is_valid():
		return
	match args.size():
		0: target.call()
		1: target.call(args[0])
		2: target.call(args[0], args[1])
		3: target.call(args[0], args[1], args[2])
		4: target.call(args[0], args[1], args[2], args[3])
		5: target.call(args[0], args[1], args[2], args[3], args[4])
		_: target.callv(args)
