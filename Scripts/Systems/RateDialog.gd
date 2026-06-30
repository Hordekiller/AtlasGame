extends Node

var _rate_shown: bool = false

func _ready() -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://rate.cfg") == OK:
		_rate_shown = cfg.get_value("rate", "shown", false)

func check_and_show() -> void:
	if _rate_shown:
		return
	if GameState.current_day >= 3 or GameState.current_cities.size() >= 2:
		_rate_shown = true
		var cfg = ConfigFile.new()
		cfg.set_value("rate", "shown", true)
		cfg.save("user://rate.cfg")
		DisplayServer.dialog_show("AtlasGame", "از بازی لذت می‌برید؟ لطفاً امتیاز دهید!", "امتیاز", "بعداً")
		EventBus.notification_added.emit("لطفاً در فروشگاه به ما امتیاز دهید!", "info")