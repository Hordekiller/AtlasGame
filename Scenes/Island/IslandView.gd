extends Control

@onready var name_label: Label = $VBox/Header/NameLabel
@onready var resource_label: Label = $VBox/ResourceLabel
@onready var cities_container: VBoxContainer = $VBox/CitiesScroll/CitiesContainer
@onready var close_btn: TextureButton = $VBox/Header/CloseBtn

var _island_id: String = ""

func _ready() -> void:
	if ResourceLoader.exists("res://Assets/Textures/UI/close.png"):
		close_btn.texture_normal = ResourceLoader.load("res://Assets/Textures/UI/close.png")
	close_btn.pressed.connect(_close)
	get_viewport().size_changed.connect(_update_responsive)
	_update_responsive()

func _update_responsive() -> void:
	var vp = get_viewport().get_visible_rect()
	custom_minimum_size = Vector2(min(320, vp.size.x * 0.7), min(400, vp.size.y * 0.7))
	size = custom_minimum_size

func open(island_id: String) -> void:
	_island_id = island_id
	var island = GameState.current_islands.get(island_id)
	if not island:
		return
	name_label.text = island.get("name", "جزیره ناشناخته")
	var res = island.get("primary_resource", -1)
	resource_label.text = "منبع: " + Globals.ISLAND_RESOURCE_NAMES.get(res, "نامشخص") if res >= 0 else ""

	for child in cities_container.get_children():
		child.queue_free()

	for city_id in island.get("player_cities", []):
		var city = GameState.current_cities.get(city_id)
		if city:
			var hbox = HBoxContainer.new()
			var btn = Button.new()
			btn.text = city.get("name", "") + " (" + city.get("player", "") + ")"
			btn.size_flags_horizontal = SIZE_EXPAND_FILL
			btn.pressed.connect(_on_city_tapped.bind(city_id))
			UITheme.style_button(btn)
			hbox.add_child(btn)
			cities_container.add_child(hbox)

	show()

func _on_city_tapped(city_id: String) -> void:
	EventBus.city_selected.emit(city_id)
	_close()

func _close() -> void:
	hide()
