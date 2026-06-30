extends Node

var _active_notifications: Array = []
var _notification_container: Control = null

func _ready() -> void:
	EventBus.notification_added.connect(_on_notification)
	EventBus.unit_trained.connect(_on_unit_trained)
	EventBus.battle_initiated.connect(_on_battle_initiated)
	EventBus.battle_completed.connect(_on_battle_completed)
	EventBus.battle_result.connect(_on_battle_result)
	EventBus.battle_surrender.connect(_on_battle_surrender)
	EventBus.trade_sent.connect(_on_trade_sent)
	EventBus.trade_received.connect(_on_trade_received)
	EventBus.trade_route_created.connect(_on_trade_route_created)
	EventBus.trade_route_removed.connect(_on_trade_route_removed)
	EventBus.trade_ship_arrived.connect(_on_trade_ship_arrived)
	EventBus.city_colonized.connect(_on_city_colonized)
	EventBus.day_changed.connect(_on_day_changed)
	EventBus.game_saved.connect(_on_game_saved)
	EventBus.spy_mission_started.connect(_on_spy_mission_started)
	EventBus.spy_mission_completed.connect(_on_spy_mission_completed)
	EventBus.spy_discovered.connect(_on_spy_discovered)
	EventBus.spy_killed.connect(_on_spy_killed)
	EventBus.marketplace_trade_created.connect(_on_marketplace_trade_created)
	EventBus.marketplace_trade_completed.connect(_on_marketplace_trade_completed)
	EventBus.marketplace_merchant_arrived.connect(_on_marketplace_merchant_arrived)

func set_notification_container(container: Control) -> void:
	_notification_container = container

func show_notification(message: String, type: String = "info") -> void:
	EventBus.notification_added.emit(message, type)

func _on_notification(message: String, type: String) -> void:
	_active_notifications.append({"message": message, "type": type, "time": 0.0})
	if _active_notifications.size() > 5:
		_active_notifications.pop_front()

func get_notifications() -> Array:
	return _active_notifications.duplicate()

func clear_notifications() -> void:
	_active_notifications.clear()

func _on_unit_trained(city_id: String, unit_type: String, count: int) -> void:
	EventBus.notification_added.emit("واحد " + unit_type + " در " + str(count) + " عدد آموزش داده شد", "info")

func _on_battle_initiated(attacker_id: String, defender_id: String) -> void:
	EventBus.notification_added.emit("نبرد آغاز شد: " + attacker_id + " علیه " + defender_id, "warning")

func _on_battle_completed(battle_id: String, winner: String) -> void:
	EventBus.notification_added.emit("نبرد به پایان رسید. برنده: " + winner, "info")

func _on_battle_result(battle_id: String, winner: String, loot: Dictionary, casualties: Dictionary) -> void:
	EventBus.notification_added.emit("غارت نبرد: " + str(loot.size()) + " منبع", "info")

func _on_battle_surrender(battle_id: String, surrendering_city: String, remaining_units: int) -> void:
	EventBus.notification_added.emit(surrendering_city + " تسلیم شد", "warning")

func _on_trade_sent(from_city: String, to_city: String, resources: Dictionary) -> void:
	EventBus.notification_added.emit("تجارت از " + from_city + " به " + to_city + " ارسال شد", "info")

func _on_trade_received(city_id: String, resources: Dictionary) -> void:
	EventBus.notification_added.emit("کالاهای تجاری به " + city_id + " رسید", "info")

func _on_trade_route_created(route_id: String, from_city: String, to_city: String, resource_type: int, amount: float) -> void:
	EventBus.notification_added.emit("مسیر تجاری جدید: " + from_city + " ← " + to_city, "success")

func _on_trade_route_removed(route_id: String) -> void:
	EventBus.notification_added.emit("مسیر تجاری حذف شد", "warning")

func _on_trade_ship_arrived(route_id: String, from_city: String, to_city: String, resource_type: int, amount: float) -> void:
	EventBus.notification_added.emit("کشتی تجاری از " + from_city + " به " + to_city + " رسید", "info")

func _on_city_colonized(city_id: String, city_name: String, island_id: String) -> void:
	EventBus.notification_added.emit("شهر جدید تأسیس شد: " + city_name, "success")

func _on_day_changed(day: int) -> void:
	pass

func _on_game_saved() -> void:
	EventBus.notification_added.emit("بازی ذخیره شد", "info")

func _on_spy_mission_started(city_id: String, target_city_id: String, mission_type: String) -> void:
	EventBus.notification_added.emit("ماموریت جاسوسی به " + target_city_id + " آغاز شد", "info")

func _on_spy_mission_completed(city_id: String, target_city_id: String, mission_type: String, success: bool, result: Dictionary) -> void:
	if success:
		EventBus.notification_added.emit("ماموریت جاسوسی در " + target_city_id + " موفق بود", "success")
	else:
		EventBus.notification_added.emit("ماموریت جاسوسی در " + target_city_id + " شکست خورد", "error")

func _on_spy_discovered(city_id: String, spy_city_id: String) -> void:
	EventBus.notification_added.emit("جاسوس دشمن در " + city_id + " کشف شد", "warning")

func _on_spy_killed(city_id: String, spy_city_id: String) -> void:
	EventBus.notification_added.emit("جاسوس در " + city_id + " کشته شد", "warning")

func _on_marketplace_trade_created(trade_id: String, city_id: String, resource_type: int, amount: int, price: float) -> void:
	EventBus.notification_added.emit("پیشنهاد تجاری جدید در " + city_id, "info")

func _on_marketplace_trade_completed(trade_id: String, city_id: String) -> void:
	EventBus.notification_added.emit("معامله در " + city_id + " تکمیل شد", "success")

func _on_marketplace_merchant_arrived(city_id: String, resource_type: int, amount: int) -> void:
	EventBus.notification_added.emit("بازرگان به " + city_id + " رسید", "info")
