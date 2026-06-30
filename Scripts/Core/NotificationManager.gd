extends Node

var _notification_queue: Array = []

func schedule_building_complete(city_name: String, building_name: String, delay_seconds: float) -> void:
	if not _has_permission():
		return
	var msg = "ساخت %s در %s کامل شد!" % [building_name, city_name]
	_schedule(msg, delay_seconds)

func schedule_upgrade_complete(city_name: String, building_name: String, delay_seconds: float) -> void:
	if not _has_permission():
		return
	var msg = "ارتقاء %s در %s کامل شد!" % [building_name, city_name]
	_schedule(msg, delay_seconds)

func schedule_research_complete(tech_name: String, delay_seconds: float) -> void:
	if not _has_permission():
		return
	var msg = "پژوهش %s کامل شد!" % [tech_name]
	_schedule(msg, delay_seconds)

func schedule_attack_incoming(city_name: String, delay_seconds: float) -> void:
	if not _has_permission():
		return
	var msg = "⚠ شهر %s مورد حمله قرار گرفت!" % [city_name]
	_schedule(msg, delay_seconds)

func cancel_all() -> void:
	if OS.has_feature("android") or OS.has_feature("ios"):
		pass

func _schedule(message: String, delay_seconds: float) -> void:
	_notification_queue.append({"message": message, "delay": delay_seconds})
	if OS.has_feature("android"):
		var time_from_now = int(Time.get_unix_time_from_system() + delay_seconds)
		var args = ["android/app/com.gamemb.ikariam/.GodotApp",
			"--es", "title", "جزیره",
			"--es", "message", message,
			"--ei", "time", time_from_now]
		OS.execute("am", args, [], false)

func _has_permission() -> bool:
	return true

func can_schedule() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios")

func get_save_data() -> Dictionary:
	return {
		"notification_queue": _notification_queue
	}

func load_save_data(data: Dictionary) -> void:
	_notification_queue = data.get("notification_queue", [])
