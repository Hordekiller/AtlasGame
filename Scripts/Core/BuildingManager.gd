extends Node

signal builder_status_changed(available: int, total: int)
signal build_started(city_id: String, building_id: String, grid_pos: Vector2i)
signal build_completed(city_id: String, building_id: String, grid_pos: Vector2i)

const BASE_BUILDERS: int = 1
const MAX_BUILDERS: int = 2

var _building_definitions: Dictionary = {}
var _construction_queue: Array = []
var _extra_builders: int = 0

const TIER_BUILD_TIME: Dictionary = {
	1: 5.0,
	2: 12.0,
	3: 25.0,
	4: 45.0,
	5: 75.0
}

const TIER_WORKERS: Dictionary = {
	1: 2,
	2: 4,
	3: 6,
	4: 10,
	5: 15
}

func get_workers_needed(building_id: String, level: int) -> int:
	var defn = _building_definitions.get(building_id)
	if not defn:
		return 0
	var base = TIER_WORKERS.get(defn.get("tier", 1), 2)
	return base + (level - 1) * 2

func get_assigned_workers(city_id: String, grid_pos: Vector2i) -> int:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return 0
	var data = city.get("buildings", {}).get(grid_pos)
	if not data:
		return 0
	return data.get("workers_assigned", data.get("level", 1) * 2)

func set_workers(city_id: String, grid_pos: Vector2i, count: int) -> bool:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return false
	var data = city.get("buildings", {}).get(grid_pos)
	if not data:
		return false
	var defn = _building_definitions.get(data.get("id", ""))
	if not defn:
		return false
	var needed = get_workers_needed(data.get("id", ""), data.get("level", 1))
	count = clampi(count, 0, needed)
	data["workers_assigned"] = count
	EconomyManager.recalculate_city_production(city_id)
	return true

func _ready() -> void:
	_load_building_definitions()

func _load_building_definitions() -> void:
	_building_definitions = {
		"lumberjack": {
			"name": "چوب‌بر",
			"category": Globals.BuildingCategory.RESOURCE,
			"tier": 1,
			"size": Vector2i(2, 2),
			"max_level": 10,
			"production": { Globals.ResourceType.WOOD: 2.0 },
			"costs": { Globals.ResourceType.WOOD: 10 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 15, Globals.ResourceType.GOLD: 5 },
			"description": "تولید چوب",
			"requires_research": []
		},
		"quarry": {
			"name": "معدن سنگ",
			"category": Globals.BuildingCategory.RESOURCE,
			"tier": 1,
			"size": Vector2i(2, 2),
			"max_level": 10,
			"production": { Globals.ResourceType.STONE: 1.5 },
			"costs": { Globals.ResourceType.WOOD: 15, Globals.ResourceType.GOLD: 5 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 20, Globals.ResourceType.STONE: 10, Globals.ResourceType.GOLD: 10 },
			"description": "تولید سنگ",
			"requires_research": []
		},
		"farm": {
			"name": "مزرعه",
			"category": Globals.BuildingCategory.RESOURCE,
			"tier": 1,
			"size": Vector2i(2, 2),
			"max_level": 10,
			"production": { Globals.ResourceType.FOOD: 4.0 },
			"costs": { Globals.ResourceType.WOOD: 8 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 12, Globals.ResourceType.GOLD: 3 },
			"description": "تولید غذا برای جمعیت",
			"requires_research": []
		},
		"vineyard": {
			"name": "تاکستان",
			"category": Globals.BuildingCategory.PRODUCTION,
			"tier": 2,
			"size": Vector2i(2, 2),
			"max_level": 8,
			"production": { Globals.ResourceType.WINE: 1.0 },
			"costs": { Globals.ResourceType.WOOD: 20, Globals.ResourceType.GOLD: 15 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 25, Globals.ResourceType.GOLD: 20, Globals.ResourceType.WINE: 5 },
			"description": "تولید شراب برای فرهنگ",
			"requires_research": ["wine_culture"],
			"requires_island_resource": Globals.IslandResource.WINE
		},
		"glassblower": {
			"name": "شیشه‌گر",
			"category": Globals.BuildingCategory.PRODUCTION,
			"tier": 2,
			"size": Vector2i(2, 2),
			"max_level": 8,
			"production": { Globals.ResourceType.GLASS: 0.8 },
			"consumption": { Globals.ResourceType.WOOD: 0.5 },
			"costs": { Globals.ResourceType.WOOD: 25, Globals.ResourceType.GOLD: 20 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 30, Globals.ResourceType.GOLD: 25, Globals.ResourceType.STONE: 10 },
			"description": "تولید شیشه از چوب",
			"requires_research": ["glass_production"],
			"requires_island_resource": Globals.IslandResource.GLASS
		},
		"marble_quarry": {
			"name": "معدن مرمر",
			"category": Globals.BuildingCategory.RESOURCE,
			"tier": 2,
			"size": Vector2i(2, 2),
			"max_level": 8,
			"production": { Globals.ResourceType.MARBLE: 1.0 },
			"costs": { Globals.ResourceType.WOOD: 30, Globals.ResourceType.GOLD: 20, Globals.ResourceType.STONE: 15 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 35, Globals.ResourceType.GOLD: 30, Globals.ResourceType.STONE: 20 },
			"description": "تولید مرمر برای ساختمان‌های پیشرفته",
			"requires_research": ["marble_usage"],
			"requires_island_resource": Globals.IslandResource.MARBLE
		},
		"academy": {
			"name": "آکادمی",
			"category": Globals.BuildingCategory.RESEARCH,
			"tier": 1,
			"size": Vector2i(3, 3),
			"max_level": 10,
			"production": { Globals.ResourceType.RESEARCH_POINTS: 1.0 },
			"costs": { Globals.ResourceType.WOOD: 40, Globals.ResourceType.GOLD: 30, Globals.ResourceType.STONE: 20 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 50, Globals.ResourceType.GOLD: 40, Globals.ResourceType.MARBLE: 10 },
			"description": "تولید امتیاز پژوهش برای تحقیق فناوری‌ها",
			"requires_research": []
		},
		"warehouse": {
			"name": "انبار",
			"category": Globals.BuildingCategory.STORAGE,
			"tier": 1,
			"size": Vector2i(2, 2),
			"max_level": 10,
			"storage_bonus": 5000,
			"costs": { Globals.ResourceType.WOOD: 15, Globals.ResourceType.GOLD: 10 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 20, Globals.ResourceType.GOLD: 15, Globals.ResourceType.STONE: 5 },
			"description": "افزایش ظرفیت انبار شهر",
			"requires_research": []
		},
		"town_hall": {
			"name": "تالار شهر",
			"category": Globals.BuildingCategory.INFRASTRUCTURE,
			"tier": 1,
			"size": Vector2i(3, 3),
			"max_level": 10,
			"production": { Globals.ResourceType.POPULATION: 5.0 },
			"costs": { Globals.ResourceType.WOOD: 20, Globals.ResourceType.GOLD: 15, Globals.ResourceType.STONE: 10 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 30, Globals.ResourceType.GOLD: 25, Globals.ResourceType.MARBLE: 10 },
			"description": "ساختمان مرکزی شهر، افزایش جمعیت",
			"requires_research": []
		},
		"barracks": {
			"name": "پادگان",
			"category": Globals.BuildingCategory.MILITARY,
			"tier": 2,
			"size": Vector2i(3, 3),
			"max_level": 5,
			"costs": { Globals.ResourceType.WOOD: 35, Globals.ResourceType.GOLD: 25, Globals.ResourceType.STONE: 20 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 40, Globals.ResourceType.GOLD: 35, Globals.ResourceType.MARBLE: 15 },
			"description": "ساخت و آموزش واحدهای نظامی",
			"requires_research": ["military_training"],
			"units_trainable": ["slinger", "hoplite", "steam_giant", "gyrocopter", "cook", "doctor"]
		},
		"port": {
			"name": "بندر",
			"category": Globals.BuildingCategory.INFRASTRUCTURE,
			"tier": 2,
			"size": Vector2i(4, 2),
			"max_level": 5,
			"costs": { Globals.ResourceType.WOOD: 50, Globals.ResourceType.GOLD: 40, Globals.ResourceType.STONE: 30 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 60, Globals.ResourceType.GOLD: 50, Globals.ResourceType.MARBLE: 20 },
			"description": "قابلیت تجارت دریایی و کشتی‌سازی",
			"requires_research": ["shipbuilding"],
		},
		"temple": {
			"name": "معبد",
			"category": Globals.BuildingCategory.CULTURE,
			"tier": 2,
			"size": Vector2i(3, 3),
			"max_level": 5,
			"costs": { Globals.ResourceType.WOOD: 30, Globals.ResourceType.GOLD: 50, Globals.ResourceType.STONE: 25, Globals.ResourceType.MARBLE: 10 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 40, Globals.ResourceType.GOLD: 60, Globals.ResourceType.MARBLE: 20, Globals.ResourceType.WINE: 10 },
			"description": "افزایش رضایت و فرهنگ شهر",
			"requires_research": ["religion"],
			"production": { Globals.ResourceType.SATISFACTION: 4.0 }
		},
		"workshop": {
			"name": "کارگاه",
			"category": Globals.BuildingCategory.PRODUCTION,
			"tier": 3,
			"size": Vector2i(2, 2),
			"max_level": 8,
			"production": { Globals.ResourceType.CRYSTAL: 0.5 },
			"consumption": { Globals.ResourceType.WOOD: 0.3, Globals.ResourceType.GOLD: 0.2 },
			"costs": { Globals.ResourceType.WOOD: 40, Globals.ResourceType.GOLD: 35, Globals.ResourceType.STONE: 25, Globals.ResourceType.MARBLE: 15 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 45, Globals.ResourceType.GOLD: 40, Globals.ResourceType.MARBLE: 20, Globals.ResourceType.CRYSTAL: 5 },
			"description": "تولید کریستال برای پژوهش",
			"requires_research": ["crystal_processing"]
		},
		"sawmill": {
			"name": "کارگاه چوب‌بری",
			"category": Globals.BuildingCategory.PRODUCTION,
			"tier": 2,
			"size": Vector2i(2, 2),
			"max_level": 8,
			"production": { Globals.ResourceType.WOOD: 3.0 },
			"costs": { Globals.ResourceType.WOOD: 20, Globals.ResourceType.GOLD: 15 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 25, Globals.ResourceType.GOLD: 20, Globals.ResourceType.STONE: 10 },
			"description": "تولید پیشرفته چوب",
			"requires_research": ["improved_lumber"]
		},
		"wall": {
			"name": "دیوار دفاعی",
			"category": Globals.BuildingCategory.MILITARY,
			"tier": 2,
			"size": Vector2i(1, 1),
			"max_level": 10,
			"costs": { Globals.ResourceType.WOOD: 10, Globals.ResourceType.STONE: 15 },
			"upgrade_costs": { Globals.ResourceType.STONE: 20, Globals.ResourceType.GOLD: 10, Globals.ResourceType.MARBLE: 5 },
			"description": "تقویت دفاع شهر در برابر حملات",
			"requires_research": ["fortification"],
			"wall_defense": true,
			"wall_defense_base": 10.0,
			"wall_defense_per_level": 5.0
		},
		"tavern": {
			"name": "میخانه",
			"category": Globals.BuildingCategory.CULTURE,
			"tier": 2,
			"size": Vector2i(2, 2),
			"max_level": 10,
			"costs": { Globals.ResourceType.WOOD: 25, Globals.ResourceType.GOLD: 30, Globals.ResourceType.STONE: 15 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 30, Globals.ResourceType.GOLD: 40, Globals.ResourceType.MARBLE: 10, Globals.ResourceType.WINE: 5 },
			"description": "افزایش رضایت با مصرف شراب، هر سطح +۵ رضایت",
			"requires_research": ["hospitality"],
			"wine_consumption_per_level": 1.0,
			"production": { Globals.ResourceType.SATISFACTION: 5.0 }
		},
		"museum": {
			"name": "موزه",
			"category": Globals.BuildingCategory.CULTURE,
			"tier": 3,
			"size": Vector2i(3, 2),
			"max_level": 5,
			"costs": { Globals.ResourceType.WOOD: 50, Globals.ResourceType.GOLD: 80, Globals.ResourceType.MARBLE: 30, Globals.ResourceType.GLASS: 20 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 60, Globals.ResourceType.GOLD: 100, Globals.ResourceType.MARBLE: 40, Globals.ResourceType.GLASS: 30 },
			"description": "افزایش رضایت از طریق مصنوعات، هر سطح +۳ رضایت",
			"requires_research": ["cultural_heritage"],
			"production": { Globals.ResourceType.SATISFACTION: 3.0 }
		},
		"palace": {
			"name": "کاخ",
			"category": Globals.BuildingCategory.SPECIAL,
			"tier": 4,
			"size": Vector2i(4, 4),
			"max_level": 5,
			"unique": true,
			"costs": { Globals.ResourceType.WOOD: 200, Globals.ResourceType.GOLD: 300, Globals.ResourceType.MARBLE: 100, Globals.ResourceType.GLASS: 50 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 250, Globals.ResourceType.GOLD: 400, Globals.ResourceType.MARBLE: 150, Globals.ResourceType.GLASS: 80 },
			"description": "کاخ مرکزی امپراتوری - هر سطح یک مستعمره اضافی مجاز می‌کند",
			"requires_research": ["imperial_cult"],
			"colonies_per_level": 1
		},
		"governor_residence": {
			"name": "اقامتگاه فرماندار",
			"category": Globals.BuildingCategory.SPECIAL,
			"tier": 3,
			"size": Vector2i(3, 3),
			"max_level": 5,
			"costs": { Globals.ResourceType.WOOD: 80, Globals.ResourceType.GOLD: 120, Globals.ResourceType.MARBLE: 40, Globals.ResourceType.GLASS: 20 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 100, Globals.ResourceType.GOLD: 150, Globals.ResourceType.MARBLE: 60, Globals.ResourceType.GLASS: 30 },
			"description": "کاهش فساد در مستعمرات - هر سطح ۵٪ فساد را کاهش می‌دهد",
			"requires_research": ["administration"],
			"corruption_reduction_per_level": 5.0
		},
		"hideout": {
			"name": "مخفیگاه",
			"category": Globals.BuildingCategory.SPECIAL,
			"tier": 3,
			"size": Vector2i(2, 2),
			"max_level": 5,
			"costs": { Globals.ResourceType.WOOD: 60, Globals.ResourceType.GOLD: 100, Globals.ResourceType.STONE: 30, Globals.ResourceType.GLASS: 15 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 70, Globals.ResourceType.GOLD: 130, Globals.ResourceType.MARBLE: 20, Globals.ResourceType.GLASS: 20 },
			"description": "عملیات جاسوسی علیه بازیکنان دیگر - هر سطح مأموریت‌های بیشتری فعال می‌کند",
			"requires_research": ["espionage"],
			"max_spy_missions": 2
		},
		"marketplace": {
			"name": "بازار",
			"category": Globals.BuildingCategory.INFRASTRUCTURE,
			"tier": 2,
			"size": Vector2i(3, 2),
			"max_level": 10,
			"costs": { Globals.ResourceType.WOOD: 35, Globals.ResourceType.GOLD: 50, Globals.ResourceType.STONE: 20 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 40, Globals.ResourceType.GOLD: 60, Globals.ResourceType.MARBLE: 15 },
			"description": "تجارت منابع با سایر بازیکنان و NPC - هر سطح تعداد قراردادهای تجاری را افزایش می‌دهد",
			"requires_research": ["market_economy"],
			"trade_contracts_per_level": 1
		},
		"shipyard": {
			"name": "کارخانه کشتی‌سازی",
			"category": Globals.BuildingCategory.MILITARY,
			"tier": 3,
			"size": Vector2i(4, 3),
			"max_level": 5,
			"costs": { Globals.ResourceType.WOOD: 80, Globals.ResourceType.GOLD: 100, Globals.ResourceType.STONE: 50, Globals.ResourceType.MARBLE: 30 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 100, Globals.ResourceType.GOLD: 130, Globals.ResourceType.MARBLE: 50, Globals.ResourceType.GLASS: 20 },
			"description": "ساخت کشتی‌های جنگی پیشرفته",
			"requires_research": ["advanced_shipbuilding"],
			"units_trainable": ["ship_ballista", "ship_catapult", "ship_mortar", "ship_ram", "ship_diving", "ship_fire", "ship_paddle", "ship_balloon_carrier", "ship_rocket", "ship_steam_ram", "ship_tender"]
		},
		"carpenter": {
			"name": "نجار",
			"category": Globals.BuildingCategory.REDUCTION,
			"tier": 2,
			"size": Vector2i(2, 2),
			"max_level": 5,
			"costs": { Globals.ResourceType.WOOD: 20, Globals.ResourceType.GOLD: 15 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 25, Globals.ResourceType.GOLD: 20, Globals.ResourceType.STONE: 10 },
			"description": "کاهش مصرف چوب در ساختمان‌سازی - هر سطح ۴٪ کاهش",
			"requires_research": ["carpentry"],
			"cost_reduction": { Globals.ResourceType.WOOD: 4.0 }
		},
		"architect": {
			"name": "معمار",
			"category": Globals.BuildingCategory.REDUCTION,
			"tier": 2,
			"size": Vector2i(2, 2),
			"max_level": 5,
			"costs": { Globals.ResourceType.WOOD: 20, Globals.ResourceType.GOLD: 25, Globals.ResourceType.STONE: 15 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 25, Globals.ResourceType.GOLD: 30, Globals.ResourceType.MARBLE: 10 },
			"description": "کاهش مصرف مرمر در ساختمان‌سازی - هر سطح ۴٪ کاهش",
			"requires_research": ["architecture"],
			"cost_reduction": { Globals.ResourceType.MARBLE: 4.0 }
		},
		"optician": {
			"name": "عینک‌ساز",
			"category": Globals.BuildingCategory.REDUCTION,
			"tier": 2,
			"size": Vector2i(2, 2),
			"max_level": 5,
			"costs": { Globals.ResourceType.WOOD: 20, Globals.ResourceType.GOLD: 20, Globals.ResourceType.GLASS: 10 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 25, Globals.ResourceType.GOLD: 25, Globals.ResourceType.GLASS: 15 },
			"description": "کاهش مصرف شیشه در ساختمان‌سازی - هر سطح ۴٪ کاهش",
			"requires_research": ["optics"],
			"cost_reduction": { Globals.ResourceType.GLASS: 4.0 }
		},
		"firework_test": {
			"name": "آتشبازی",
			"category": Globals.BuildingCategory.REDUCTION,
			"tier": 2,
			"size": Vector2i(2, 2),
			"max_level": 5,
			"costs": { Globals.ResourceType.WOOD: 15, Globals.ResourceType.GOLD: 25, Globals.ResourceType.CRYSTAL: 5 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 20, Globals.ResourceType.GOLD: 30, Globals.ResourceType.CRYSTAL: 10 },
			"description": "کاهش مصرف کریستال در ساختمان‌سازی - هر سطح ۴٪ کاهش",
			"requires_research": ["pyrotechnics"],
			"cost_reduction": { Globals.ResourceType.CRYSTAL: 4.0 }
		},
		"wine_press_building": {
			"name": "شراب‌فشاری",
			"category": Globals.BuildingCategory.REDUCTION,
			"tier": 2,
			"size": Vector2i(2, 2),
			"max_level": 5,
			"costs": { Globals.ResourceType.WOOD: 20, Globals.ResourceType.GOLD: 20, Globals.ResourceType.WINE: 10 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 25, Globals.ResourceType.GOLD: 25, Globals.ResourceType.MARBLE: 10, Globals.ResourceType.WINE: 15 },
			"description": "کاهش مصرف شراب در ساختمان‌سازی - هر سطح ۴٪ کاهش",
			"requires_research": ["wine_pressing"],
			"cost_reduction": { Globals.ResourceType.WINE: 4.0 }
		},
		"alchemist_tower": {
			"name": "برج کیمیاگر",
			"category": Globals.BuildingCategory.PRODUCTION,
			"tier": 3,
			"size": Vector2i(2, 2),
			"max_level": 5,
			"production": { Globals.ResourceType.SULFUR: 0.5 },
			"consumption": { Globals.ResourceType.WOOD: 0.2, Globals.ResourceType.GOLD: 0.3 },
			"costs": { Globals.ResourceType.WOOD: 50, Globals.ResourceType.GOLD: 80, Globals.ResourceType.STONE: 30, Globals.ResourceType.CRYSTAL: 20 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 60, Globals.ResourceType.GOLD: 100, Globals.ResourceType.MARBLE: 30, Globals.ResourceType.CRYSTAL: 25 },
			"description": "تولید گوگرد برای واحدهای نظامی پیشرفته",
			"requires_research": ["alchemy"],
			"requires_island_resource": Globals.IslandResource.SULFUR
		},
		"dump": {
			"name": "زباله‌دان",
			"category": Globals.BuildingCategory.INFRASTRUCTURE,
			"tier": 1,
			"size": Vector2i(2, 2),
			"max_level": 5,
			"costs": { Globals.ResourceType.WOOD: 10, Globals.ResourceType.GOLD: 5 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 15, Globals.ResourceType.GOLD: 8, Globals.ResourceType.STONE: 5 },
			"description": "نگهداری منابع مازاد - افزایش ظرفیت انبار",
			"requires_research": ["waste_management"],
			"storage_bonus": 2000
		},
		"sea_chart_archive": {
			"name": "آرشیو نقشه‌های دریایی",
			"category": Globals.BuildingCategory.SPECIAL,
			"tier": 3,
			"size": Vector2i(2, 2),
			"max_level": 3,
			"costs": { Globals.ResourceType.WOOD: 60, Globals.ResourceType.GOLD: 80, Globals.ResourceType.GLASS: 20, Globals.ResourceType.MARBLE: 20 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 80, Globals.ResourceType.GOLD: 100, Globals.ResourceType.MARBLE: 30 },
			"description": "افزایش سرعت کشتی‌های تجاری و جنگی",
			"requires_research": ["cartography"],
			"ship_speed_bonus_per_level": 10.0
		},
		"pirate_fortress": {
			"name": "قلعه دزدان دریایی",
			"category": Globals.BuildingCategory.MILITARY,
			"tier": 4,
			"size": Vector2i(3, 3),
			"max_level": 3,
			"costs": { Globals.ResourceType.WOOD: 150, Globals.ResourceType.GOLD: 200, Globals.ResourceType.STONE: 100, Globals.ResourceType.SULFUR: 50 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 180, Globals.ResourceType.GOLD: 250, Globals.ResourceType.MARBLE: 80, Globals.ResourceType.SULFUR: 60 },
			"description": "قابلیت دزدی دریایی از مسیرهای تجاری دشمن",
			"requires_research": ["piracy"],
			"pirate_attack_bonus_per_level": 15.0
		},
		"steam_workshop": {
			"name": "کارگاه بخار",
			"category": Globals.BuildingCategory.PRODUCTION,
			"tier": 4,
			"size": Vector2i(3, 3),
			"max_level": 5,
			"production": { Globals.ResourceType.SULFUR: 1.0, Globals.ResourceType.CRYSTAL: 0.5 },
			"consumption": { Globals.ResourceType.WOOD: 0.5, Globals.ResourceType.GOLD: 0.5, Globals.ResourceType.STONE: 0.3 },
			"costs": { Globals.ResourceType.WOOD: 80, Globals.ResourceType.GOLD: 150, Globals.ResourceType.MARBLE: 50, Globals.ResourceType.SULFUR: 30, Globals.ResourceType.CRYSTAL: 20 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 100, Globals.ResourceType.GOLD: 200, Globals.ResourceType.MARBLE: 70, Globals.ResourceType.SULFUR: 40 },
			"description": "تولید گوگرد و کریستال برای واحدهای بخاری",
			"requires_research": ["steam_power"]
		},
		"flying_machine_workshop": {
			"name": "کارگاه ماشین پرنده",
			"category": Globals.BuildingCategory.MILITARY,
			"tier": 5,
			"size": Vector2i(3, 3),
			"max_level": 3,
			"costs": { Globals.ResourceType.WOOD: 120, Globals.ResourceType.GOLD: 250, Globals.ResourceType.MARBLE: 80, Globals.ResourceType.GLASS: 50, Globals.ResourceType.SULFUR: 60 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 150, Globals.ResourceType.GOLD: 300, Globals.ResourceType.MARBLE: 100, Globals.ResourceType.SULFUR: 80 },
			"description": "ساخت واحدهای پرنده (ژیروکوپتر و بالن)",
			"requires_research": ["aerial_warfare"],
			"units_trainable": ["gyrocopter", "balloon_bombardier"]
		},
		"watchtower": {
			"name": "برج دیده‌بانی",
			"category": Globals.BuildingCategory.MILITARY,
			"tier": 1,
			"size": Vector2i(2, 2),
			"max_level": 5,
			"costs": { Globals.ResourceType.WOOD: 30, Globals.ResourceType.GOLD: 20 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 35, Globals.ResourceType.GOLD: 25, Globals.ResourceType.STONE: 10 },
			"description": "افزایش دید و شناسایی حملات زودهنگام",
			"requires_research": [],
			"sight_range_per_level": 20
		},
		"cannon": {
			"name": "توپ دفاعی",
			"category": Globals.BuildingCategory.MILITARY,
			"tier": 3,
			"size": Vector2i(2, 2),
			"max_level": 10,
			"costs": { Globals.ResourceType.WOOD: 80, Globals.ResourceType.GOLD: 100, Globals.ResourceType.SULFUR: 30 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 100, Globals.ResourceType.GOLD: 120, Globals.ResourceType.SULFUR: 40 },
			"description": "آسیب به واحدهای مهاجم در هر راند نبرد",
			"requires_research": ["gunpowder"],
			"garrison_attack_per_level": 15,
			"garrison_defense_per_level": 5
		},
		"harbor_chain": {
			"name": "زنجیر بندر",
			"category": Globals.BuildingCategory.MILITARY,
			"tier": 3,
			"size": Vector2i(2, 2),
			"max_level": 3,
			"costs": { Globals.ResourceType.WOOD: 120, Globals.ResourceType.GOLD: 150, Globals.ResourceType.MARBLE: 50 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 150, Globals.ResourceType.GOLD: 180, Globals.ResourceType.MARBLE: 60 },
			"description": "جلوگیری از ورود کشتی‌های دشمن به بندر",
			"requires_research": ["naval_engineering"],
			"block_chance_per_level": 20,
			"naval_damage_per_level": 10
		},
		"vault": {
			"name": "خزانه",
			"category": Globals.BuildingCategory.INFRASTRUCTURE,
			"tier": 1,
			"size": Vector2i(2, 2),
			"max_level": 10,
			"costs": { Globals.ResourceType.WOOD: 20, Globals.ResourceType.GOLD: 15, Globals.ResourceType.STONE: 10 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 25, Globals.ResourceType.GOLD: 20, Globals.ResourceType.STONE: 15 },
			"description": "محافظت از منابع در برابر غارت - هر سطح ۵٪ محافظت",
			"requires_research": [],
			"protection_per_level": 5
		},
		"city_wall": {
			"name": "دیوار شهر",
			"category": Globals.BuildingCategory.INFRASTRUCTURE,
			"tier": 2,
			"size": Vector2i(3, 1),
			"max_level": 20,
			"costs": { Globals.ResourceType.WOOD: 50, Globals.ResourceType.GOLD: 30, Globals.ResourceType.STONE: 40 },
			"upgrade_costs": { Globals.ResourceType.WOOD: 60, Globals.ResourceType.GOLD: 40, Globals.ResourceType.STONE: 50 },
			"description": "افزایش دفاع کلی شهر - هر سطح ۵٪ دفاع بیشتر",
			"requires_research": ["masonry"],
			"wall_defense_bonus_per_level": 5
		}
	}

func get_building_def(id: String) -> Dictionary:
	return _building_definitions.get(id, {}).duplicate(true)

func get_all_building_defs() -> Dictionary:
	return _building_definitions.duplicate(true)

func get_buildings_for_category(category: int) -> Array:
	var result = []
	for id in _building_definitions:
		if _building_definitions[id].category == category:
			result.append(id)
	return result

func get_buildings_available(city_id: String) -> Array:
	var result = []
	var city = GameState.current_cities.get(city_id)
	var research = city.get("research_completed", []) if city else []
	var palace_level = _get_palace_level(city)

	for id in _building_definitions:
		var defn = _building_definitions[id]
		var can_build = true
		for req in defn.get("requires_research", []):
			if req not in research:
				can_build = false
				break
		if defn.get("unique", false) and id == "palace" and palace_level > 0:
			can_build = false
		if can_build:
			result.append(id)
	return result

func _get_palace_level(city: Dictionary) -> int:
	if not city:
		return 0
	for pos in city.get("buildings", {}):
		var b = city["buildings"][pos]
		if b.get("id") == "palace":
			return b.get("level", 0)
	return 0

func get_max_colonies(city_id: String) -> int:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return 0
	var palace_level = _get_palace_level(city)
	if palace_level == 0:
		return 0
	return palace_level * Globals.HAPPINESS_MAX_COLONIES_PER_PALACE_LEVEL

func get_cost_reduction(city_id: String, resource_type: int) -> float:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return 0.0
	var total = 0.0
	for pos in city.get("buildings", {}):
		var b = city["buildings"][pos]
		var defn = _building_definitions.get(b.get("id", ""))
		if not defn:
			continue
		var reduction = defn.get("cost_reduction", {})
		if reduction.has(resource_type):
			total += reduction[resource_type] * b.get("level", 1)
	return clampf(total, 0.0, 80.0)

func get_wall_defense(city_id: String) -> float:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return 0.0
	for pos in city.get("buildings", {}):
		var b = city["buildings"][pos]
		var defn = _building_definitions.get(b.get("id", ""))
		if defn and defn.get("wall_defense", false):
			var base = defn.get("wall_defense_base", 0.0)
			var per_level = defn.get("wall_defense_per_level", 0.0)
			return base + per_level * b.get("level", 0)
	return 0.0

func get_available_builders() -> int:
	return BASE_BUILDERS + _extra_builders

func get_max_builders() -> int:
	return MAX_BUILDERS

func add_extra_builder() -> bool:
	if _extra_builders + BASE_BUILDERS >= MAX_BUILDERS:
		return false
	_extra_builders += 1
	builder_status_changed.emit(get_available_builders(), MAX_BUILDERS)
	return true

func get_active_constructions(city_id: String) -> int:
	var count = 0
	var city = GameState.current_cities.get(city_id)
	if not city:
		return 0
	for pos in city.get("buildings", {}):
		var b = city["buildings"][pos]
		if b.get("constructing", false) or b.get("upgrading", false):
			count += 1
	return count

func can_start_new_construction(city_id: String) -> bool:
	return get_active_constructions(city_id) < get_available_builders()

func get_trade_contracts(city_id: String) -> int:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return 0
	var count = 0
	for pos in city.get("buildings", {}):
		var b = city["buildings"][pos]
		var defn = _building_definitions.get(b.get("id", ""))
		if defn and defn.get("id", "") == "marketplace":
			count += defn.get("trade_contracts_per_level", 1) * b.get("level", 1)
	return count

func can_place_building(city_id: String, building_id: String, grid_pos: Vector2i) -> Dictionary:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return {"success": false, "reason": "شهر یافت نشد"}

	var defn = _building_definitions.get(building_id)
	if not defn:
		return {"success": false, "reason": "ساختمان نامعتبر"}

	var size = defn.get("size", Vector2i(1, 1))
	var grid_size = city.get("grid_size", 16)

	for x in range(grid_pos.x, grid_pos.x + size.x):
		for y in range(grid_pos.y, grid_pos.y + size.y):
			if x < 0 or x >= grid_size or y < 0 or y >= grid_size:
				return {"success": false, "reason": "خارج از محدوده شهر"}
			if city.get("buildings", {}).has(Vector2i(x, y)):
				return {"success": false, "reason": "این مکان قبلاً اشغال شده"}

	if defn.get("unique", false):
		if _has_unique_building(city_id, building_id):
			return {"success": false, "reason": "این ساختمان منحصربه‌فرد قبلاً ساخته شده"}

	var island_requirement = defn.get("requires_island_resource", -1)
	if island_requirement >= 0:
		var city = GameState.current_cities.get(city_id)
		if city:
			var island_id = city.get("island_id", "")
			var island = GameState.current_islands.get(island_id, {})
			var primary = island.get("primary_resource", -1)
			if primary != island_requirement:
				return {"success": false, "reason": "این ساختمان به جزیره با منبع خاص نیاز دارد"}

	var costs = defn.get("costs", {})
	if not EconomyManager.can_afford(city_id, costs):
		return {"success": false, "reason": "منابع کافی نیست"}

	var available = get_buildings_available(city_id)
	if building_id not in available:
		return {"success": false, "reason": "پیش‌نیازهای تحقیق تأمین نشده"}

	return {"success": true}

func _has_unique_building(city_id: String, building_id: String) -> bool:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return false
	for pos in city.get("buildings", {}):
		if city["buildings"][pos].get("id") == building_id:
			return true
	return false

func place_building(city_id: String, building_id: String, grid_pos: Vector2i) -> bool:
	var check = can_place_building(city_id, building_id, grid_pos)
	if not check.success:
		push_warning("Cannot place building: ", check.reason)
		return false

	if not can_start_new_construction(city_id):
		push_warning("No available builders for city: ", city_id)
		return false

	var defn = _building_definitions[building_id]
	var size = defn.get("size", Vector2i(1, 1))
	var city = GameState.current_cities[city_id]

	var costs = defn.get("costs", {}).duplicate()
	for r in costs:
		var red = get_cost_reduction(city_id, r)
		if red > 0:
			costs[r] = int(costs[r] * (100.0 - red) / 100.0)

	EconomyManager.deduct_costs(city_id, costs)

	var build_time = get_build_time(building_id)
	var building_data = {
		"id": building_id,
		"level": 1,
		"grid_pos": grid_pos,
		"size": size,
		"constructed_time": GameState.game_time,
		"constructed": false,
		"constructing": true,
		"construct_time_left": build_time,
		"construct_time_total": build_time,
		"upgrading": false,
		"upgrade_time_left": 0.0,
		"upgrade_time_total": 10.0,
		"workers_assigned": 0
	}

	if not city.has("buildings"):
		city["buildings"] = {}

	for x in range(grid_pos.x, grid_pos.x + size.x):
		for y in range(grid_pos.y, grid_pos.y + size.y):
			city["buildings"][Vector2i(x, y)] = building_data

	EventBus.building_constructed.emit(city_id, building_id, grid_pos)
	return true

func upgrade_building(city_id: String, grid_pos: Vector2i) -> bool:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return false

	var building_data = city.get("buildings", {}).get(grid_pos)
	if not building_data:
		return false

	if not building_data.get("constructed", false):
		return false

	if building_data.get("upgrading", false):
		return false

	if not can_start_new_construction(city_id):
		push_warning("No available builders for upgrade in city: ", city_id)
		return false

	var defn = _building_definitions.get(building_data.get("id", ""))
	if not defn:
		return false

	var current_level = building_data.get("level", 1)
	if current_level >= defn.get("max_level", 10):
		return false

	var costs = defn.get("upgrade_costs", {}).duplicate()
	var scaled_costs = {}
	for r in costs:
		var amount = costs[r] * current_level
		var reduction = get_cost_reduction(city_id, r)
		if reduction > 0:
			amount = int(amount * (100.0 - reduction) / 100.0)
		scaled_costs[r] = amount

	if not EconomyManager.can_afford(city_id, scaled_costs):
		return false

	EconomyManager.deduct_costs(city_id, scaled_costs)

	var upgrade_time = get_upgrade_time(building_data.id, current_level)
	building_data["upgrading"] = true
	building_data["upgrade_time_left"] = upgrade_time
	building_data["upgrade_time_total"] = upgrade_time
	building_data["target_level"] = current_level + 1

	return true

func demolish_building(city_id: String, grid_pos: Vector2i) -> bool:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return false

	var building_data = city.get("buildings", {}).get(grid_pos)
	if not building_data:
		return false

	var size = building_data.get("size", Vector2i(1, 1))
	var origin = building_data.get("grid_pos", grid_pos)

	var defn = _building_definitions.get(building_data.get("id", ""), {})
	if defn and GameState.selected_city_id == city_id:
		var costs = defn.get("costs", {})
		for r in costs:
			var refund = int(costs[r] * 0.25)
			if refund > 0:
				EconomyManager.add_resources(city_id, r, refund)

	var to_remove = []
	for pos in city.get("buildings", {}):
		if city["buildings"][pos] == building_data:
			to_remove.append(pos)
	for pos in to_remove:
		city["buildings"].erase(pos)

	EconomyManager.recalculate_city_production(city_id)
	EventBus.building_demolished.emit(city_id, origin)
	return true

func get_build_time(building_id: String) -> float:
	var defn = _building_definitions.get(building_id)
	if not defn:
		return 5.0
	var tier = defn.get("tier", 1)
	return TIER_BUILD_TIME.get(tier, 5.0)

func get_upgrade_time(building_id: String, current_level: int) -> float:
	var defn = _building_definitions.get(building_id)
	if not defn:
		return 5.0
	var tier = defn.get("tier", 1)
	var base = TIER_BUILD_TIME.get(tier, 5.0)
	return base * current_level * 0.8

func process_tick() -> void:
	for city_id in GameState.current_cities:
		var city = GameState.current_cities[city_id]
		var buildings = city.get("buildings", {})
		var processed: Array = []

		for pos in buildings:
			var data = buildings[pos]
			if processed.has(data):
				continue
			processed.append(data)

			var constructing = data.get("constructing", false)
			var upgrading = data.get("upgrading", false)

			if constructing:
				var time_left = data.get("construct_time_left", 0.0)
				time_left -= 1.0
				data["construct_time_left"] = time_left

				var total = data.get("construct_time_total", 1.0)
				var progress = 1.0 - (time_left / total)
				EventBus.building_construct_progress.emit(city_id, data.get("grid_pos", pos), progress, total)

				if time_left <= 0.0:
					data["constructing"] = false
					data["constructed"] = true
					data["construct_time_left"] = 0.0
					EconomyManager.recalculate_city_production(city_id)
					AudioManager.play_build()
					EventBus.building_construct_complete.emit(city_id, data.get("grid_pos", pos), data.get("id", ""))

			elif upgrading:
				var time_left = data.get("upgrade_time_left", 0.0)
				time_left -= 1.0
				data["upgrade_time_left"] = time_left

				var total = data.get("upgrade_time_total", 1.0)
				var progress = 1.0 - (time_left / total)
				EventBus.building_upgrade_progress.emit(city_id, data.get("grid_pos", pos), progress, total)

				if time_left <= 0.0:
					data["upgrading"] = false
					data["upgrade_time_left"] = 0.0
					data["level"] = data.get("target_level", data["level"] + 1)
					EconomyManager.recalculate_city_production(city_id)
					var new_level = data.get("level", 1)
					AudioManager.play_upgrade()
					EventBus.building_upgrade_complete.emit(city_id, data.get("grid_pos", pos), data.get("id", ""), new_level)
					EventBus.building_upgraded.emit(city_id, data.get("id", ""), new_level)
