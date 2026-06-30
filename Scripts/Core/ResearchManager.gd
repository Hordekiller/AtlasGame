extends Node

var _research_tree: Dictionary = {}

func _ready() -> void:
	_load_research_tree()

func _load_research_tree() -> void:
	_research_tree = {
		## TIER 1 - ECONOMY
		"improved_lumber": {
			"name": "چوب‌بری پیشرفته",
			"category": Globals.TechCategory.ECONOMY,
			"tier": 1,
			"cost": 20,
			"duration": 25.0,
			"description": "قابلیت ساخت کارگاه چوب‌بری",
			"prerequisites": [],
			"effects": { "unlock_building": "sawmill" }
		},
		"glass_production": {
			"name": "تولید شیشه",
			"category": Globals.TechCategory.ECONOMY,
			"tier": 1,
			"cost": 25,
			"duration": 35.0,
			"description": "قابلیت ساخت شیشه‌گری",
			"prerequisites": [],
			"effects": { "unlock_building": "glassblower" }
		},
		"marble_usage": {
			"name": "استفاده از مرمر",
			"category": Globals.TechCategory.ECONOMY,
			"tier": 1,
			"cost": 30,
			"duration": 40.0,
			"description": "قابلیت ساخت معدن مرمر و ساختمان‌های پیشرفته",
			"prerequisites": [],
			"effects": { "unlock_building": "marble_quarry" }
		},
		"wine_culture": {
			"name": "فرهنگ شراب",
			"category": Globals.TechCategory.CULTURE,
			"tier": 1,
			"cost": 20,
			"duration": 30.0,
			"description": "قابلیت ساخت تاکستان",
			"prerequisites": [],
			"effects": { "unlock_building": "vineyard" }
		},
		"military_training": {
			"name": "آموزش نظامی",
			"category": Globals.TechCategory.MILITARY,
			"tier": 1,
			"cost": 25,
			"duration": 30.0,
			"description": "قابلیت ساخت پادگان",
			"prerequisites": [],
			"effects": { "unlock_building": "barracks", "unlock_unit": "slinger" }
		},

		## TIER 2 - ECONOMY
		"carpentry": {
			"name": "نجاری",
			"category": Globals.TechCategory.ECONOMY,
			"tier": 2,
			"cost": 30,
			"duration": 35.0,
			"description": "قابلیت ساخت نجار - کاهش مصرف چوب",
			"prerequisites": ["improved_lumber"],
			"effects": { "unlock_building": "carpenter" }
		},
		"architecture": {
			"name": "معماری",
			"category": Globals.TechCategory.ECONOMY,
			"tier": 2,
			"cost": 35,
			"duration": 40.0,
			"description": "قابلیت ساخت معمار - کاهش مصرف مرمر",
			"prerequisites": ["marble_usage"],
			"effects": { "unlock_building": "architect" }
		},
		"optics": {
			"name": "نورشناسی",
			"category": Globals.TechCategory.SCIENCE,
			"tier": 2,
			"cost": 35,
			"duration": 40.0,
			"description": "قابلیت ساخت عینک‌ساز - کاهش مصرف شیشه",
			"prerequisites": ["glass_production"],
			"effects": { "unlock_building": "optician" }
		},
		"market_economy": {
			"name": "اقتصاد بازار",
			"category": Globals.TechCategory.ECONOMY,
			"tier": 2,
			"cost": 40,
			"duration": 45.0,
			"description": "قابلیت ساخت بازار - تجارت با بازیکنان دیگر",
			"prerequisites": ["improved_lumber"],
			"effects": { "unlock_building": "marketplace" }
		},
		"waste_management": {
			"name": "مدیریت پسماند",
			"category": Globals.TechCategory.ECONOMY,
			"tier": 2,
			"cost": 25,
			"duration": 30.0,
			"description": "قابلیت ساخت زباله‌دان - افزایش ظرفیت انبار",
			"prerequisites": [],
			"effects": { "unlock_building": "dump" }
		},

		## TIER 2 - SCIENCE
		"crystal_processing": {
			"name": "فرآوری کریستال",
			"category": Globals.TechCategory.SCIENCE,
			"tier": 2,
			"cost": 45,
			"duration": 55.0,
			"description": "قابلیت ساخت کارگاه کریستال",
			"prerequisites": ["glass_production"],
			"effects": { "unlock_building": "workshop" }
		},
		"alchemy": {
			"name": "کیمیاگری",
			"category": Globals.TechCategory.SCIENCE,
			"tier": 2,
			"cost": 40,
			"duration": 50.0,
			"description": "قابلیت ساخت برج کیمیاگر - تولید گوگرد",
			"prerequisites": ["crystal_processing"],
			"effects": { "unlock_building": "alchemist_tower" }
		},

		## TIER 2 - MILITARY
		"fortification": {
			"name": "استحکامات",
			"category": Globals.TechCategory.MILITARY,
			"tier": 2,
			"cost": 35,
			"duration": 45.0,
			"description": "قابلیت ساخت دیوار دفاعی",
			"prerequisites": ["military_training"],
			"effects": { "unlock_building": "wall" }
		},
		"espionage": {
			"name": "جاسوسی",
			"category": Globals.TechCategory.MILITARY,
			"tier": 2,
			"cost": 50,
			"duration": 55.0,
			"description": "قابلیت ساخت مخفیگاه - عملیات جاسوسی",
			"prerequisites": ["military_training"],
			"effects": { "unlock_building": "hideout" }
		},

		## TIER 2 - CULTURE
		"religion": {
			"name": "دین و آیین",
			"category": Globals.TechCategory.CULTURE,
			"tier": 2,
			"cost": 40,
			"duration": 50.0,
			"description": "قابلیت ساخت معبد",
			"prerequisites": ["wine_culture"],
			"effects": { "unlock_building": "temple" }
		},
		"hospitality": {
			"name": "مهمان‌نوازی",
			"category": Globals.TechCategory.CULTURE,
			"tier": 2,
			"cost": 35,
			"duration": 40.0,
			"description": "قابلیت ساخت میخانه - افزایش رضایت با شراب",
			"prerequisites": ["wine_culture"],
			"effects": { "unlock_building": "tavern" }
		},

		## TIER 2 - NAVIGATION
		"shipbuilding": {
			"name": "کشتی‌سازی",
			"category": Globals.TechCategory.NAVIGATION,
			"tier": 2,
			"cost": 50,
			"duration": 60.0,
			"description": "قابلیت ساخت بندر و کشتی‌های ابتدایی",
			"prerequisites": ["improved_lumber"],
			"effects": { "unlock_building": "port" }
		},

		## TIER 3 - ECONOMY
		"wine_pressing": {
			"name": "شراب‌فشاری",
			"category": Globals.TechCategory.ECONOMY,
			"tier": 3,
			"cost": 45,
			"duration": 50.0,
			"description": "قابلیت ساخت شراب‌فشاری - کاهش مصرف شراب",
			"prerequisites": ["carpentry"],
			"effects": { "unlock_building": "wine_press_building" }
		},
		"pyrotechnics": {
			"name": "آتش‌بازی",
			"category": Globals.TechCategory.SCIENCE,
			"tier": 3,
			"cost": 50,
			"duration": 55.0,
			"description": "قابلیت ساخت آتشبازی - کاهش مصرف کریستال",
			"prerequisites": ["optics"],
			"effects": { "unlock_building": "firework_test" }
		},
		"administration": {
			"name": "مدیریت اداری",
			"category": Globals.TechCategory.ECONOMY,
			"tier": 3,
			"cost": 60,
			"duration": 65.0,
			"description": "قابلیت ساخت اقامتگاه فرماندار - کاهش فساد",
			"prerequisites": ["architecture", "market_economy"],
			"effects": { "unlock_building": "governor_residence" }
		},
		"cultural_heritage": {
			"name": "میراث فرهنگی",
			"category": Globals.TechCategory.CULTURE,
			"tier": 3,
			"cost": 60,
			"duration": 70.0,
			"description": "قابلیت ساخت موزه - افزایش رضایت",
			"prerequisites": ["religion", "hospitality"],
			"effects": { "unlock_building": "museum" }
		},

		## TIER 3 - MILITARY
		"advanced_military": {
			"name": "نظامی پیشرفته",
			"category": Globals.TechCategory.MILITARY,
			"tier": 3,
			"cost": 70,
			"duration": 75.0,
			"description": "واحدهای نظامی قدرتمندتر (هوپلیت)",
			"prerequisites": ["fortification", "military_training"],
			"effects": { "unlock_unit": "hoplite" }
		},
		"siege_warfare": {
			"name": "محاصره",
			"category": Globals.TechCategory.MILITARY,
			"tier": 3,
			"cost": 80,
			"duration": 85.0,
			"description": "واحدهای محاصره‌ای (منجنیق، قوچ)",
			"prerequisites": ["advanced_military"],
			"effects": { "unlock_unit": "catapult" }
		},
		"medical_corps": {
			"name": "سپاه پزشکی",
			"category": Globals.TechCategory.SCIENCE,
			"tier": 3,
			"cost": 55,
			"duration": 60.0,
			"description": "واحد پزشک - بهبود زخمی‌های نبرد",
			"prerequisites": ["alchemy"],
			"effects": { "unlock_unit": "doctor" }
		},

		## TIER 3 - NAVIGATION
		"advanced_shipbuilding": {
			"name": "کشتی‌سازی پیشرفته",
			"category": Globals.TechCategory.NAVIGATION,
			"tier": 3,
			"cost": 70,
			"duration": 80.0,
			"description": "قابلیت ساخت کارخانه کشتی‌سازی و کشتی‌های جنگی",
			"prerequisites": ["shipbuilding"],
			"effects": { "unlock_building": "shipyard", "unlock_unit": "ship_ballista" }
		},
		"cartography": {
			"name": "نقشه‌نگاری",
			"category": Globals.TechCategory.NAVIGATION,
			"tier": 3,
			"cost": 50,
			"duration": 55.0,
			"description": "قابلیت ساخت آرشیو نقشه‌های دریایی",
			"prerequisites": ["shipbuilding"],
			"effects": { "unlock_building": "sea_chart_archive" }
		},

		## TIER 4 - IMPERIAL
		"imperial_cult": {
			"name": "آیین امپراتوری",
			"category": Globals.TechCategory.CULTURE,
			"tier": 4,
			"cost": 120,
			"duration": 120.0,
			"description": "قابلیت ساخت کاخ - استعمار جزایر جدید",
			"prerequisites": ["administration", "cultural_heritage"],
			"effects": { "unlock_building": "palace" }
		},
		"steam_power": {
			"name": "نیروی بخار",
			"category": Globals.TechCategory.SCIENCE,
			"tier": 4,
			"cost": 100,
			"duration": 110.0,
			"description": "قابلیت ساخت کارگاه بخار - واحدهای بخاری",
			"prerequisites": ["medical_corps", "pyrotechnics"],
			"effects": { "unlock_building": "steam_workshop", "unlock_unit": "steam_giant" }
		},
		"piracy": {
			"name": "دزدی دریایی",
			"category": Globals.TechCategory.NAVIGATION,
			"tier": 4,
			"cost": 90,
			"duration": 95.0,
			"description": "قابلیت ساخت قلعه دزدان دریایی",
			"prerequisites": ["advanced_shipbuilding", "cartography"],
			"effects": { "unlock_building": "pirate_fortress" }
		},
		"gunpowder": {
			"name": "باروت",
			"category": Globals.TechCategory.MILITARY,
			"tier": 4,
			"cost": 110,
			"duration": 115.0,
			"description": "واحدهای باروتی (کارابینیر، خمپاره)",
			"prerequisites": ["siege_warfare", "alchemy"],
			"effects": { "unlock_unit": "sulphur_carabineer" }
		},

		## TIER 4 - NAVAL
		"naval_warfare": {
			"name": "جنگ دریایی",
			"category": Globals.TechCategory.NAVIGATION,
			"tier": 4,
			"cost": 100,
			"duration": 105.0,
			"description": "کشتی‌های جنگی پیشرفته",
			"prerequisites": ["advanced_shipbuilding"],
			"effects": { "unlock_unit": "ship_catapult" }
		},
		"naval_ram": {
			"name": "قوچ دریایی",
			"category": Globals.TechCategory.NAVIGATION,
			"tier": 4,
			"cost": 90,
			"duration": 95.0,
			"description": "کشتی قوچ‌دار - نفوذ به خطوط دشمن",
			"prerequisites": ["advanced_shipbuilding"],
			"effects": { "unlock_unit": "ship_ram" }
		},
		"diving_gear": {
			"name": "تجهیزات غواصی",
			"category": Globals.TechCategory.NAVIGATION,
			"tier": 4,
			"cost": 85,
			"duration": 90.0,
			"description": "کشتی غواص - حملات زیرآبی",
			"prerequisites": ["advanced_shipbuilding"],
			"effects": { "unlock_unit": "ship_diving" }
		},

		## TIER 5 - ADVANCED
		"aerial_warfare": {
			"name": "جنگ هوایی",
			"category": Globals.TechCategory.MILITARY,
			"tier": 5,
			"cost": 150,
			"duration": 150.0,
			"description": "قابلیت ساخت کارگاه ماشین پرنده - واحدهای هوایی",
			"prerequisites": ["steam_power", "gunpowder"],
			"effects": { "unlock_building": "flying_machine_workshop", "unlock_unit": "gyrocopter" }
		},
		"rocket_science": {
			"name": "موشک‌شناسی",
			"category": Globals.TechCategory.MILITARY,
			"tier": 5,
			"cost": 180,
			"duration": 180.0,
			"description": "کشتی موشکی - دوربردترین حملات دریایی",
			"prerequisites": ["gunpowder", "aerial_warfare"],
			"effects": { "unlock_unit": "ship_rocket" }
		},
		"steam_armor": {
			"name": "زره بخاری",
			"category": Globals.TechCategory.MILITARY,
			"tier": 5,
			"cost": 160,
			"duration": 160.0,
			"description": "کشتی بخاری زره‌پوش - قدرتمندترین کشتی جنگی",
			"prerequisites": ["naval_warfare", "steam_power"],
			"effects": { "unlock_unit": "ship_steam_ram" }
		},
		"logistics": {
			"name": "تدارکات",
			"category": Globals.TechCategory.ECONOMY,
			"tier": 5,
			"cost": 130,
			"duration": 130.0,
			"description": "کشتی تدارکاتی - حمل نیروی زمینی در دریا",
			"prerequisites": ["administration", "naval_warfare"],
			"effects": { "unlock_unit": "ship_tender" }
		},

		## TIER 3 - NAVIGATION ADDITIONAL
		"trade_network": {
			"name": "شبکه تجاری",
			"category": Globals.TechCategory.NAVIGATION,
			"tier": 3,
			"cost": 60,
			"duration": 65.0,
			"description": "مسیرهای تجاری بیشتر و کارآمدتر",
			"prerequisites": ["shipbuilding"],
			"effects": {}
		},
		"diplomacy": {
			"name": "دیپلماسی",
			"category": Globals.TechCategory.CULTURE,
			"tier": 2,
			"cost": 30,
			"duration": 35.0,
			"description": "ارتباط با بازیکنان دیگر و اتحادها",
			"prerequisites": [],
			"effects": {}
		},
		"fire_ships": {
			"name": "کشتی آتشین",
			"category": Globals.TechCategory.NAVIGATION,
			"tier": 4,
			"cost": 95,
			"duration": 100.0,
			"description": "کشتی آتشین - آسیب منطقه‌ای به ناوگان دشمن",
			"prerequisites": ["naval_warfare", "piracy"],
			"effects": { "unlock_unit": "ship_fire" }
		},
		"paddle_ships": {
			"name": "کشتی پارویی",
			"category": Globals.TechCategory.NAVIGATION,
			"tier": 4,
			"cost": 80,
			"duration": 85.0,
			"description": "کشتی پارویی بخار - سرعت بالا",
			"prerequisites": ["naval_warfare", "steam_power"],
			"effects": { "unlock_unit": "ship_paddle" }
		},
		"field_kitchen": {
			"name": "آشپزخانه صحرایی",
			"category": Globals.TechCategory.MILITARY,
			"tier": 3,
			"cost": 50,
			"duration": 55.0,
			"description": "واحد آشپز - افزایش روحیه سربازان",
			"prerequisites": ["advanced_military"],
			"effects": { "unlock_unit": "cook" }
		},
		"mortar_warfare": {
			"name": "خمپاره",
			"category": Globals.TechCategory.MILITARY,
			"tier": 4,
			"cost": 100,
			"duration": 105.0,
			"description": "خمپاره‌انداز - آسیب سنگین به دیوار",
			"prerequisites": ["siege_warfare", "gunpowder"],
			"effects": { "unlock_unit": "mortar" }
		},
		"balloon_bombing": {
			"name": "بمباران با بالن",
			"category": Globals.TechCategory.MILITARY,
			"tier": 5,
			"cost": 140,
			"duration": 140.0,
			"description": "بمباران هوایی با بالن",
			"prerequisites": ["aerial_warfare", "mortar_warfare"],
			"effects": { "unlock_unit": "balloon_bombardier" }
		},
		"balloon_carrier": {
			"name": "ناو هواپیمابر",
			"category": Globals.TechCategory.NAVIGATION,
			"tier": 5,
			"cost": 200,
			"duration": 200.0,
			"description": "ناو بالن‌بر - حمل واحدهای هوایی در دریا",
			"prerequisites": ["balloon_bombing", "steam_armor"],
			"effects": { "unlock_unit": "ship_balloon_carrier" }
		}
	}

func get_research_def(tech_id: String) -> Dictionary:
	return _research_tree.get(tech_id, {}).duplicate(true)

func get_all_research() -> Dictionary:
	return _research_tree.duplicate(true)

func get_available_research(city_id: String) -> Array:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return []

	var completed = city.get("research_completed", [])
	var in_progress = city.get("research_in_progress", "")
	var result = []

	for tech_id in _research_tree:
		if tech_id in completed:
			continue
		if tech_id == in_progress:
			continue

		var defn = _research_tree[tech_id]
		var can_research = true
		for prereq in defn.get("prerequisites", []):
			if prereq not in completed:
				can_research = false
				break

		if can_research:
			result.append(tech_id)

	return result

func start_research(city_id: String, tech_id: String) -> bool:
	if not _research_tree.has(tech_id):
		return false

	var available = get_available_research(city_id)
	if tech_id not in available:
		return false

	var city = GameState.current_cities.get(city_id)
	if not city:
		return false

	var defn = _research_tree[tech_id]
	var cost = defn.get("cost", 0)

	if city.get("resources", {}).get(Globals.ResourceType.RESEARCH_POINTS, 0.0) < cost:
		return false

	city["resources"][Globals.ResourceType.RESEARCH_POINTS] -= cost
	city["research_in_progress"] = tech_id
	city["research_progress"] = 0.0
	city["research_duration"] = defn.get("duration", 30.0)

	EventBus.research_started.emit(tech_id, defn.get("duration", 30.0))
	return true

func process_tick() -> void:
	for city_id in GameState.current_cities:
		var city = GameState.current_cities[city_id]
		var in_progress = city.get("research_in_progress", "")
		if in_progress == "":
			continue

		var defn = _research_tree.get(in_progress)
		if not defn:
			city["research_in_progress"] = ""
			continue

		var academy_level = _get_academy_level(city)
		var speed_bonus = 1.0 + academy_level * 0.1

		city["research_progress"] = city.get("research_progress", 0.0) + speed_bonus

		if city["research_progress"] >= city.get("research_duration", 30.0):
			_complete_research(city_id, city, in_progress)

func _get_academy_level(city: Dictionary) -> int:
	for pos in city.get("buildings", {}):
		var b = city["buildings"][pos]
		if b.get("id") == "academy":
			return b.get("level", 1)
	return 0

func _complete_research(city_id: String, city: Dictionary, tech_id: String) -> void:
	city["research_in_progress"] = ""
	city["research_progress"] = 0.0

	if not city.has("research_completed"):
		city["research_completed"] = []
	city["research_completed"].append(tech_id)

	var defn = _research_tree.get(tech_id, {})
	var effects = defn.get("effects", {})
	if effects.has("unlock_unit"):
		var unit_id = effects["unlock_unit"]
		if not GameState.current_units.has(unit_id):
			GameState.current_units[unit_id] = {"count": 0, "unlocked": true}
		if not city.has("unlocked_units"):
			city["unlocked_units"] = []
		if unit_id not in city["unlocked_units"]:
			city["unlocked_units"].append(unit_id)

	EventBus.research_completed.emit(tech_id)

func get_save_data() -> Dictionary:
	var data = {}
	for cid in GameState.current_cities:
		var city = GameState.current_cities[cid]
		data[cid] = {
			"research_in_progress": city.get("research_in_progress", ""),
			"research_progress": city.get("research_progress", 0.0),
			"research_completed": city.get("research_completed", [])
		}
	return data

func load_save_data(data: Dictionary) -> void:
	for cid in data:
		var city = GameState.current_cities.get(cid)
		if city:
			city["research_in_progress"] = data[cid].get("research_in_progress", "")
			city["research_progress"] = data[cid].get("research_progress", 0.0)
			city["research_completed"] = data[cid].get("research_completed", [])
