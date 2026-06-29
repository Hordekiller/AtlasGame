extends Node

var current_cities: Dictionary = {}
var current_islands: Dictionary = {}
var current_research: Dictionary = {}
var current_units: Dictionary = {}
var active_trades: Array = []
var trade_routes: Dictionary = {}
var completed_research: Array = []
var game_time: float = 0.0
var current_day: int = 1
var time_speed: float = 1.0
var selected_city_id: String = ""
var selected_building_pos: Vector2i = Vector2i(-1, -1)
var player_gold: float = 500.0
var player_gems: float = 0.0

func reset() -> void:
	current_cities.clear()
	current_islands.clear()
	current_research.clear()
	current_units.clear()
	active_trades.clear()
	trade_routes.clear()
	completed_research.clear()
	game_time = 0.0
	current_day = 1
	time_speed = 1.0
	selected_city_id = ""
	selected_building_pos = Vector2i(-1, -1)
	player_gold = 500.0
	player_gems = 0.0

func to_dict() -> Dictionary:
	return {
		"cities": current_cities,
		"islands": current_islands,
		"research": current_research,
		"units": current_units,
		"trades": active_trades,
		"trade_routes": trade_routes,
		"completed_research": completed_research,
		"game_time": game_time,
		"current_day": current_day,
		"player_gold": player_gold,
		"player_gems": player_gems
	}

func from_dict(data: Dictionary) -> void:
	current_cities = data.get("cities", {})
	current_islands = data.get("islands", {})
	current_research = data.get("research", {})
	current_units = data.get("units", {})
	active_trades = data.get("trades", [])
	trade_routes = data.get("trade_routes", {})
	completed_research = data.get("completed_research", [])
	game_time = data.get("game_time", 0.0)
	current_day = data.get("current_day", 1)
	player_gold = data.get("player_gold", 500.0)
	player_gems = data.get("player_gems", 0.0)
