extends Node

const MISSION_TYPES = {
	SABOTAGE = "sabotage",
	STEAL_RESOURCES = "steal_resources",
	STEAL_RESEARCH = "steal_research",
	REVEAL_TROOPS = "reveal_troops",
	INCITE_REVOLT = "incite_revolt",
	POISON_WATER = "poison_water"
}

const MISSION_COSTS = {
	"sabotage": { Globals.ResourceType.GOLD: 100 },
	"steal_resources": { Globals.ResourceType.GOLD: 50 },
	"steal_research": { Globals.ResourceType.GOLD: 80, Globals.ResourceType.CRYSTAL: 20 },
	"reveal_troops": { Globals.ResourceType.GOLD: 40 },
	"incite_revolt": { Globals.ResourceType.GOLD: 150, Globals.ResourceType.WINE: 50 },
	"poison_water": { Globals.ResourceType.GOLD: 120, Globals.ResourceType.CRYSTAL: 30 }
}

const MISSION_BASE_SUCCESS = {
	"sabotage": 0.4,
	"steal_resources": 0.7,
	"steal_research": 0.5,
	"reveal_troops": 0.8,
	"incite_revolt": 0.2,
	"poison_water": 0.3
}

const MISSION_DURATION = {
	"sabotage": 60.0,
	"steal_resources": 30.0,
	"steal_research": 45.0,
	"reveal_troops": 20.0,
	"incite_revolt": 90.0,
	"poison_water": 75.0
}

const DISCOVERY_BASE_CHANCE = 0.1
const DISCOVERY_KILL_CHANCE = 0.3

var _active_missions: Dictionary = {}

func get_max_missions(city_id: String) -> int:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return 0
	var max_missions = 0
	for pos in city.get("buildings", {}):
		var b = city["buildings"][pos]
		if b.get("id") == "hideout" and b.get("constructed", false):
			var defn = BuildingManager.get_building_def("hideout")
			max_missions = defn.get("max_spy_missions", 2) * b.get("level", 1)
	return max_missions

func get_active_mission_count(city_id: String) -> int:
	var count = 0
	for mission_id in _active_missions:
		if _active_missions[mission_id].city_id == city_id:
			count += 1
	return count

const MISSION_RESEARCH_REQ: Dictionary = {
	"sabotage": "sabotage",
	"incite_revolt": "espionage",
	"poison_water": "espionage"
}

func can_launch_mission(city_id: String, target_city_id: String, mission_type: String) -> Dictionary:
	if not MISSION_COSTS.has(mission_type):
		return {"success": false, "reason": "نوع مأموریت نامعتبر"}

	if not GameState.current_cities.has(city_id) or not GameState.current_cities.has(target_city_id):
		return {"success": false, "reason": "شهر مبدأ یا مقصد نامعتبر"}

	if city_id == target_city_id:
		return {"success": false, "reason": "نمی‌توان به شهر خود جاسوسی کرد"}

	if get_active_mission_count(city_id) >= get_max_missions(city_id):
		return {"success": false, "reason": "تعداد مأموریت‌های همزمان به حداکثر رسیده"}

	var req_tech = MISSION_RESEARCH_REQ.get(mission_type, "")
	if not req_tech.is_empty():
		var city = GameState.current_cities.get(city_id, {})
		var completed = city.get("research_completed", [])
		if req_tech not in completed:
			return {"success": false, "reason": "نیازمند پژوهش: " + ResearchManager.get_research_def(req_tech).get("name", req_tech)}

	var costs = MISSION_COSTS.get(mission_type, {})
	if not EconomyManager.can_afford(city_id, costs):
		return {"success": false, "reason": "منابع کافی برای مأموریت نیست"}

	return {"success": true}

func launch_mission(city_id: String, target_city_id: String, mission_type: String) -> bool:
	var check = can_launch_mission(city_id, target_city_id, mission_type)
	if not check.success:
		push_warning("Cannot launch spy mission: ", check.reason)
		return false

	var costs = MISSION_COSTS.get(mission_type, {})
	EconomyManager.deduct_costs(city_id, costs)

	var mission_id = "spy_%s_%s_%s_%d" % [city_id, target_city_id, mission_type, GameState.game_time]
	var duration = MISSION_DURATION.get(mission_type, 30.0)

	_active_missions[mission_id] = {
		"id": mission_id,
		"city_id": city_id,
		"target_city_id": target_city_id,
		"mission_type": mission_type,
		"progress": 0.0,
		"duration": duration,
		"success": false,
		"discovered": false,
		"completed": false
	}

	EventBus.spy_mission_started.emit(city_id, target_city_id, mission_type)
	return true

func process_tick() -> void:
	var completed = []

	for mission_id in _active_missions:
		var mission = _active_missions[mission_id]
		if mission.completed:
			completed.append(mission_id)
			continue

		mission.progress += 1.0

		if mission.progress >= mission.duration:
			_execute_mission(mission)
			mission.completed = true
			completed.append(mission_id)

	for mission_id in completed:
		var mission = _active_missions[mission_id]
		if mission.result:
			EventBus.spy_mission_completed.emit(mission.city_id, mission.target_city_id, mission.mission_type, mission.success, mission.result)
		_active_missions.erase(mission_id)

func _get_spy_commander_level(city_id: String) -> int:
	var cmd = CommanderSystem.get_commander_for_city(city_id)
	if cmd.is_empty():
		return 0
	return cmd.get("level", 0)

func _execute_mission(mission: Dictionary) -> void:
	var city_id = mission.city_id
	var target_city_id = mission.target_city_id
	var mission_type = mission.mission_type

	var hideout_level = _get_hideout_level(city_id)
	var target_hideout_level = _get_hideout_level(target_city_id)
	var spy_level = _get_spy_commander_level(city_id)

	var base_success = MISSION_BASE_SUCCESS.get(mission_type, 0.5)
	var success_chance = base_success + spy_level * 0.1 - target_hideout_level * 0.03
	success_chance = base_success + hideout_level * 0.05 - target_hideout_level * 0.03
	success_chance = clampf(success_chance, 0.05, 0.95)

	var roll = randf()
	mission.success = roll <= success_chance

	var discovery_chance = DISCOVERY_BASE_CHANCE + (1.0 - success_chance) * 0.3 - hideout_level * 0.02
	discovery_chance = clampf(discovery_chance, 0.02, 0.8)

	var result = {}
	if mission.success:
		match mission_type:
			"sabotage":
				result = _do_sabotage(target_city_id, hideout_level)
			"steal_resources":
				result = _do_steal_resources(city_id, target_city_id, hideout_level)
			"steal_research":
				result = _do_steal_research(city_id, target_city_id)
			"reveal_troops":
				result = _do_reveal_troops(target_city_id)
			"incite_revolt":
				result = _do_incite_revolt(target_city_id, hideout_level)
			"poison_water":
				result = _do_poison_water(target_city_id, hideout_level)
	else:
		result = {"message": "مأموریت ناموفق بود"}

	mission.result = result

	var discovery_roll = randf()
	if discovery_roll <= discovery_chance:
		mission.discovered = true
		EventBus.spy_discovered.emit(target_city_id, city_id)

		var kill_roll = randf()
		if kill_roll <= DISCOVERY_KILL_CHANCE:
			EventBus.spy_killed.emit(target_city_id, city_id)

func _do_sabotage(target_city_id: String, level: int) -> Dictionary:
	var target_city = GameState.current_cities.get(target_city_id)
	if not target_city:
		return {"message": "شهر هدف یافت نشد"}

	var buildings = target_city.get("buildings", {})
	var target_building = null
	for pos in buildings:
		var b = buildings[pos]
		if b.get("id") != "town_hall" and b.get("constructed", false) and b.get("level", 1) > 1:
			target_building = b
			break

	if not target_building:
		return {"message": "ساختمانی برای خرابکاری یافت نشد"}

	var level_loss = 1 + int(level >= 3 and randi() % 2 == 0)
	target_building["level"] = max(1, target_building.get("level", 1) - level_loss)

	var building_id = target_building.get("id", "")
	EconomyManager.recalculate_city_production(target_city_id)

	return {
		"message": "خرابکاری موفق: سطح %s کاهش یافت" % BuildingManager.get_building_def(building_id).get("name", building_id),
		"building_id": building_id,
		"level_loss": level_loss
	}

func _do_steal_resources(from_city_id: String, to_city_id: String, level: int) -> Dictionary:
	var target = GameState.current_cities.get(from_city_id)
	var source = GameState.current_cities.get(to_city_id)
	if not target or not source:
		return {"message": "شهر یافت نشد"}

	var target_resources = target.get("resources", {})
	var stolen_gold = int(target_resources.get(Globals.ResourceType.GOLD, 0.0) * 0.15 * (1.0 + level * 0.1))
	stolen_gold = mini(stolen_gold, 500 + level * 100)

	if stolen_gold > 0 and not to_city_id.is_empty():
		target_resources[Globals.ResourceType.GOLD] = max(0.0, target_resources.get(Globals.ResourceType.GOLD, 0.0) - stolen_gold)
		EconomyManager.change_resource(to_city_id, Globals.ResourceType.GOLD, stolen_gold)
		EventBus.resource_changed.emit(from_city_id, str(Globals.ResourceType.GOLD), target_resources[Globals.ResourceType.GOLD], -stolen_gold)

	return {"message": "سرقت منابع موفق: %d طلا" % stolen_gold, "gold_stolen": stolen_gold}

func _do_steal_research(from_city_id: String, to_city_id: String) -> Dictionary:
	var target = GameState.current_cities.get(from_city_id)
	var source = GameState.current_cities.get(to_city_id)
	if not target or not source:
		return {"message": "شهر یافت نشد"}

	var target_research = target.get("research_in_progress", "")
	if target_research == "":
		return {"message": "هیچ تحقیقی برای سرقت وجود ندارد"}

	if not source.has("research_completed"):
		source["research_completed"] = []

	if target_research not in source["research_completed"]:
		source["research_completed"].append(target_research)
		ResearchManager._apply_stolen_research(source, target_research)
		return {"message": "تحقیق %s به سرقت رفت" % target_research, "stolen_tech": target_research}

	return {"message": "تحقیق تکراری بود", "stolen_tech": target_research}

func _do_reveal_troops(target_city_id: String) -> Dictionary:
	var target = GameState.current_cities.get(target_city_id)
	if not target:
		return {"message": "شهر یافت نشد"}

	var units = target.get("units", {})
	var unit_list = {}
	for unit_type in units:
		if units[unit_type].get("count", 0) > 0:
			unit_list[unit_type] = units[unit_type].get("count", 0)

	return {"message": "اطلاعات نظامی به دست آمد", "units": unit_list}

func _do_incite_revolt(target_city_id: String, level: int) -> Dictionary:
	var target = GameState.current_cities.get(target_city_id)
	if not target:
		return {"message": "شهر یافت نشد"}

	var sat = target.get("satisfaction", 50.0)
	var revolt_drop = 15.0 + level * 5.0
	target["satisfaction"] = max(0.0, sat - revolt_drop)
	EventBus.resource_changed.emit(target_city_id, str(Globals.ResourceType.SATISFACTION), target["satisfaction"], -revolt_drop)

	return {"message": "شورش: رضایت %d واحد کاهش یافت" % revolt_drop, "satisfaction_drop": revolt_drop}

func _do_poison_water(target_city_id: String, level: int) -> Dictionary:
	var target = GameState.current_cities.get(target_city_id)
	if not target:
		return {"message": "شهر یافت نشد"}

	var pop = target.get("resources", {}).get(Globals.ResourceType.POPULATION, 0.0)
	var pop_loss = int(pop * 0.05 * (1.0 + level * 0.1))
	pop_loss = mini(pop_loss, 100 + level * 20)

	target["resources"][Globals.ResourceType.POPULATION] = max(0.0, pop - pop_loss)
	EventBus.resource_changed.emit(target_city_id, str(Globals.ResourceType.POPULATION), target["resources"][Globals.ResourceType.POPULATION], -pop_loss)

	return {"message": "آب مسموم: %d نفر تلفات" % pop_loss, "population_loss": pop_loss}

func _get_hideout_level(city_id: String) -> int:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return 0
	for pos in city.get("buildings", {}):
		var b = city["buildings"][pos]
		if b.get("id") == "hideout" and b.get("constructed", false):
			return b.get("level", 1)
	return 0

func get_discovered_missions(city_id: String) -> Array:
	var result = []
	for mission_id in _active_missions:
		var mission = _active_missions[mission_id]
		if mission.target_city_id == city_id and mission.discovered:
			result.append(mission)
	return result

func get_active_missions_for_city(city_id: String) -> Array:
	var result = []
	for mission_id in _active_missions:
		var mission = _active_missions[mission_id]
		if mission.city_id == city_id:
			result.append(mission)
	return result

func get_missions_against_city(city_id: String) -> Array:
	var result = []
	for mission_id in _active_missions:
		var mission = _active_missions[mission_id]
		if mission.target_city_id == city_id:
			result.append(mission)
	return result

func get_save_data() -> Dictionary:
	return {
		"active_missions": _active_missions
	}

func load_save_data(data: Dictionary) -> void:
	_active_missions = data.get("active_missions", {})
