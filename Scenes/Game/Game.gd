extends Control

@onready var city_view: Node = $CityView
@onready var world_map: Node = $WorldMap
@onready var hud: Control = $HUD
@onready var research_panel: Control = $ResearchPanel
@onready var colonize_dialog: Panel = $ColonizeDialog
@onready var trade_panel: Panel = $TradePanel

var _current_view: String = "city"

func _ready() -> void:
	EventBus.game_loaded.connect(_on_game_loaded)

func _on_game_loaded() -> void:
	update_all()

func update_all() -> void:
	if hud:
		hud.update_display()
	if city_view:
		city_view.update_view()
	if world_map:
		world_map.update_map()

func switch_to_city_view() -> void:
	_current_view = "city"
	if world_map:
		world_map.hide()
	if city_view:
		city_view.show()
		city_view.update_view()
	update_hud()

func switch_to_world_map() -> void:
	_current_view = "world"
	if city_view:
		city_view.hide()
	if world_map:
		world_map.show()
		world_map.update_map()
	update_hud()

func update_hud() -> void:
	if hud:
		hud.update_display()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if trade_panel and trade_panel.visible:
			trade_panel.hide()
		elif colonize_dialog and colonize_dialog.visible:
			colonize_dialog.hide()
		elif research_panel and research_panel.visible:
			research_panel.hide()
		elif _current_view == "world":
			switch_to_city_view()
		else:
			SaveManager.save_game(0)
			get_tree().change_scene_to_file("res://Scenes/Menu/MainMenu.tscn")
	elif Input.is_action_just_pressed("map_toggle"):
		if _current_view == "city":
			switch_to_world_map()
		else:
			switch_to_city_view()
