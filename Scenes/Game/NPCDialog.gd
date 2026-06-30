extends Panel

@onready var close_btn: TextureButton = $VBox/Header/CloseBtn
@onready var name_label: Label = $VBox/NameLabel
@onready var info_label: Label = $VBox/InfoLabel
@onready var attack_btn: Button = $VBox/AttackBtn
@onready var spy_btn: Button = $VBox/SpyBtn
@onready var trade_btn: Button = $VBox/TradeBtn

var _current_npc_id: String = ""
var _current_island_id: String = ""

func _ready() -> void:
	UITheme.style_panel(self)
	if ResourceLoader.exists("res://Assets/Textures/UI/close.png"):
		close_btn.texture_normal = ResourceLoader.load("res://Assets/Textures/UI/close.png")
	close_btn.pressed.connect(_hide_panel)
	attack_btn.pressed.connect(_on_attack)
	spy_btn.pressed.connect(_on_spy)
	trade_btn.pressed.connect(_on_trade)
	hide()

func show_for_npc(npc_city_id: String) -> void:
	_current_npc_id = npc_city_id
	var npc = GameState.current_npc_cities.get(npc_city_id)
	if not npc:
		hide()
		return
	_current_island_id = npc.get("island_id", "")
	name_label.text = npc.get("name", "شهر ناشناخته")
	var def_lvl = npc.get("defense_level", 1)
	var army = npc.get("units", {})
	var total = 0
	for ut in army:
		total += int(army.get(ut, 0))
	info_label.text = "دفاع: %d\nنیروی نظامی: ~%d\nتهاجم: %.0f%%" % [def_lvl, total, npc.get("aggression", 0.1) * 100]
	attack_btn.disabled = not _has_military_city()
	spy_btn.disabled = not _has_hideout()
	var has_port = _has_port_city()
	trade_btn.disabled = not has_port
	show()

func _has_military_city() -> bool:
	for cid in GameState.current_cities:
		var city = GameState.current_cities[cid]
		var buildings = city.get("buildings", {})
		for bpos in buildings:
			if buildings[bpos].get("id") == "barracks":
				return true
	return false

func _has_hideout() -> bool:
	for cid in GameState.current_cities:
		var city = GameState.current_cities[cid]
		var buildings = city.get("buildings", {})
		for bpos in buildings:
			if buildings[bpos].get("id") == "hideout":
				return true
	return false

func _has_port_city() -> bool:
	for cid in GameState.current_cities:
		var city = GameState.current_cities[cid]
		var buildings = city.get("buildings", {})
		for bpos in buildings:
			if buildings[bpos].get("id") == "port":
				return true
	return false

func _on_attack() -> void:
	var npc = GameState.current_npc_cities.get(_current_npc_id)
	if not npc:
		return
	var src_city = _find_best_military_city()
	if src_city.is_empty():
		EventBus.notification_added.emit("شهری با پادگان ندارید!", "warning")
		return
	var player_units = src_city.get("units", {})
	var total = 0
	for ut in player_units:
		var cnt = int(player_units.get(ut, 0)) if typeof(player_units.get(ut)) == TYPE_INT else player_units.get(ut, {}).get("count", 0)
		total += cnt
	if total < 10:
		EventBus.notification_added.emit("نیروی کافی برای حمله ندارید!", "warning")
		return

	var battle = CombatSystem.create_battle(
		{"city_id": src_city.get("id", ""), "units": player_units, "formation": "standard"},
		{"city_id": _current_npc_id, "units": npc.get("units", {}), "formation": "standard"},
		"player_vs_%s" % _current_npc_id
	)
	var game = get_parent()
	if game and game.has_method("show_battle"):
		game.show_battle(battle, src_city.get("id", ""), _current_npc_id)
	_hide_panel()

func _on_spy() -> void:
	EventBus.spy_mission_started.emit("", _current_npc_id, "sabotage")
	EventBus.notification_added.emit("ماموریت جاسوسی به %s اعزام شد!" % name_label.text, "info")

func _on_trade() -> void:
	EventBus.trade_sent.emit("", _current_npc_id, {})
	EventBus.notification_added.emit("پیشنهاد تجارت به %s ارسال شد!" % name_label.text, "info")

func _find_best_military_city() -> Dictionary:
	var best: Dictionary = {}
	var best_count = 0
	for cid in GameState.current_cities:
		var city = GameState.current_cities[cid]
		var units = city.get("units", {})
		var total = 0
		for ut in units:
			var cnt = int(units.get(ut, 0)) if typeof(units.get(ut)) == TYPE_INT else units.get(ut, {}).get("count", 0)
			total += cnt
		if total > best_count:
			best = city
			best_count = total
	return best

func _hide_panel() -> void:
	hide()
