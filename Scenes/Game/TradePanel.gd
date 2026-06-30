extends Panel

var _current_city_id: String = ""

@onready var title: Label = $VBox/Title
@onready var source_options: OptionButton = $VBox/SourceOptions
@onready var dest_options: OptionButton = $VBox/DestOptions
@onready var resource_options: OptionButton = $VBox/ResourceOptions
@onready var amount_input: SpinBox = $VBox/AmountInput
@onready var create_btn: Button = $VBox/CreateBtn
@onready var routes_list: VBoxContainer = $VBox/Scroll/RoutesList
@onready var close_btn: Button = $VBox/CloseBtn

func _ready() -> void:
	hide()
	UITheme.style_panel(self)
	UITheme.style_button(create_btn)
	UITheme.style_button(close_btn)
	close_btn.pressed.connect(_on_close)
	create_btn.pressed.connect(_on_create_route)
	get_viewport().size_changed.connect(_update_responsive)

func _update_responsive() -> void:
	var vp = get_viewport().get_visible_rect()
	var sz = ResponsiveLayout.clamp_modal_size(Vector2(min(500, vp.size.x * 0.85), min(400, vp.size.y * 0.75)))
	custom_minimum_size = sz
	size = sz

func open(city_id: String) -> void:
	_current_city_id = city_id
	title.text = "تجارت - " + GameState.current_cities.get(city_id, {}).get("name", "")

	var has_port = _city_has_building(city_id, "port")
	var has_shipyard = _city_has_building(city_id, "shipyard")
	var can_trade = has_port or has_shipyard

	create_btn.disabled = not can_trade
	if not can_trade:
		create_btn.text = "نیاز به بندر یا کارخانه کشتی‌سازی"
	else:
		create_btn.text = "ایجاد مسیر تجاری"

	_populate_city_options()
	_populate_resource_options()
	_refresh_routes()
	show()

func _city_has_building(city_id: String, building_id: String) -> bool:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return false
	for data in city.get("buildings", {}).values():
		if data.get("id") == building_id and data.get("constructed", false):
			return true
	return false

func _populate_city_options() -> void:
	var player_cities = WorldManager.find_player_cities()
	source_options.clear()
	dest_options.clear()

	for cid in player_cities:
		var city = GameState.current_cities.get(cid, {})
		var label = city.get("name", cid)
		source_options.add_item(label)
		source_options.set_item_metadata(source_options.item_count - 1, cid)
		dest_options.add_item(label)
		dest_options.set_item_metadata(dest_options.item_count - 1, cid)

	var idx = 0
	for cid in player_cities:
		if cid == _current_city_id:
			source_options.select(idx)
			break
		idx += 1

func _populate_resource_options() -> void:
	resource_options.clear()
	for rtype in Globals.ResourceType.values():
		var name = Globals.get_resource_name(rtype)
		if rtype != Globals.ResourceType.POPULATION and rtype != Globals.ResourceType.WORKERS:
			resource_options.add_item(name)
			resource_options.set_item_metadata(resource_options.item_count - 1, rtype)

func _refresh_routes() -> void:
	for child in routes_list.get_children():
		child.queue_free()

	var routes = WorldManager.get_trade_routes_for_city(_current_city_id)
	if routes.is_empty():
		var lbl = Label.new()
		lbl.text = "هیچ مسیر تجاری فعالی وجود ندارد"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		routes_list.add_child(lbl)
		return

	for route in routes:
		var hbox = HBoxContainer.new()
		var from_name = GameState.current_cities.get(route.get("from_city", ""), {}).get("name", "?")
		var to_name = GameState.current_cities.get(route.get("to_city", ""), {}).get("name", "?")
		var res_name = Globals.get_resource_name(route.get("resource_type", 0))
		var amount = route.get("amount", 0)
		var interval = route.get("interval_days", 1)

		var info = Label.new()
		info.text = "%s → %s: %s %s (هر %d روز)" % [from_name, to_name, str(amount), res_name, interval]
		info.size_flags_horizontal = SIZE_EXPAND_FILL
		hbox.add_child(info)

		var remove_btn = Button.new()
		remove_btn.text = "✕"
		remove_btn.pressed.connect(_remove_route.bind(route.get("id", "")))
		hbox.add_child(remove_btn)

		routes_list.add_child(hbox)

func _remove_route(route_id: String) -> void:
	WorldManager.remove_trade_route(route_id)
	_refresh_routes()

func _on_create_route() -> void:
	var src = source_options.get_selected_metadata()
	var dst = dest_options.get_selected_metadata()
	if src == dst:
		EventBus.notification_added.emit("مبدأ و مقصد نمی‌توانند یکسان باشند!", "warning")
		return
	var rtype = resource_options.get_selected_metadata()
	var amount = amount_input.value
	if amount <= 0:
		return

	# Apply marketplace ratio — gold cost for trade based on resource type
	if Globals.MARKETPLACE_RATIOS.has(rtype):
		var src_city = GameState.current_cities.get(src, {})
		var gold = src_city.get("resources", {}).get(Globals.ResourceType.GOLD, 0.0)
		var cost = amount * Globals.MARKETPLACE_RATIOS[rtype] * 0.1
		if gold < cost:
			EventBus.notification_added.emit("طلا کافی برای پرداخت هزینه تجارت!", "warning")
			return
		EconomyManager.change_resource(src, Globals.ResourceType.GOLD, -cost)

	AudioManager.play_trade()
	WorldManager.add_trade_route(src, dst, rtype, amount)
	EventBus.notification_added.emit("مسیر تجاری ایجاد شد!", "success")
	_refresh_routes()

func _on_close() -> void:
	hide()
