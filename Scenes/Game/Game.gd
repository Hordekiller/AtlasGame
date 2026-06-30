extends Control

@onready var city_view: Node = $CityView
@onready var world_map: Node = $WorldMap
@onready var hud: Control = $HUD
@onready var research_panel: Control = $ResearchPanel
@onready var colonize_dialog: Panel = $ColonizeDialog
@onready var trade_panel: Panel = $TradePanel
@onready var exit_dialog: Panel = $ExitDialog
@onready var ally_panel: Panel = $AllyPanel
@onready var quest_panel: Panel = $QuestPanel
@onready var event_panel: Panel = $EventPanel
@onready var daily_reward: Panel = $DailyReward
@onready var commander_panel: Panel = $CommanderPanel
@onready var battle_scene: Control = $BattleScene
@onready var npc_dialog: Panel = $NPCDialog
@onready var tutorial_manager: CanvasLayer = $TutorialManager

var _current_view: String = "city"

func _get_visible_design() -> Vector2:
	var design = get_viewport().get_visible_rect().size
	if DisplayServer.get_name() != "headless":
		var win = DisplayServer.window_get_size()
		if win.x > 0 and win.y > 0:
			var godot_scale = max(win.x / design.x, win.y / design.y)
			return win / godot_scale
	return design

func _clamp_panel(p: Control) -> void:
	var visible = _get_visible_design()
	var rect = p.get_rect()
	if rect.position.x < 0:
		p.position.x = 0
	if rect.position.y < 0:
		p.position.y = 0
	if rect.end.x > visible.x:
		p.position.x = max(0, visible.x - rect.size.x)
	if rect.end.y > visible.y:
		p.position.y = max(0, visible.y - rect.size.y)

func _on_panel_shown() -> void:
	for p in get_children():
		if p is Control and p.visible and p != hud and p != city_view and p != world_map:
			_clamp_panel(p)

func _ready() -> void:
	EventBus.game_loaded.connect(_on_game_loaded)
	for p in get_children():
		if p is Control and p != hud and p != city_view and p != world_map:
			if p.has_signal("visibility_changed"):
				p.visibility_changed.connect(_on_panel_shown)
	if exit_dialog:
		exit_dialog.hide()
		$ExitDialog/VBox/ConfirmBtn.pressed.connect(_on_exit_confirm)
		$ExitDialog/VBox/CancelBtn.pressed.connect(_on_exit_cancel)
	if ally_panel:
		ally_panel.hide()
	if quest_panel:
		quest_panel.hide()
	if event_panel:
		event_panel.hide()
	if daily_reward:
		daily_reward.hide()
	if commander_panel:
		commander_panel.hide()
	if battle_scene:
		battle_scene.hide()
	if npc_dialog:
		npc_dialog.hide()
	BeginnerProtection.start_protection()
	ObjectPool.prewarm("unit_icon", 20)
	ObjectPool.prewarm("projectile", 30)
	if tutorial_manager and "start_tutorial" in tutorial_manager:
		var tut_data = SaveManager.load_tutorial_state()
		if not tut_data.get("completed", false):
			tutorial_manager.start_tutorial()
	QuestSystem.check_login()
	_check_daily_reward()
	update_all()
	AudioManager.play_main_theme()
	var amb_timer = Timer.new()
	amb_timer.wait_time = 30.0 + randi() % 30
	amb_timer.one_shot = false
	amb_timer.timeout.connect(AudioManager.play_ambient_ocean)
	add_child(amb_timer)
	amb_timer.start()
	GameStateManager.game_won.connect(_on_game_won)
	GameStateManager.game_lost.connect(_on_game_lost)
	ArmyTravel.army_arrived.connect(_on_army_arrived)

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

func _on_exit_confirm() -> void:
	AudioManager.play_button_click()
	SaveManager.save_game(0)
	get_tree().change_scene_to_file("res://Scenes/Menu/MainMenu.tscn")

func show_npc_dialog(npc_city_id: String) -> void:
	if npc_dialog and npc_dialog.has_method("show_for_npc"):
		npc_dialog.show_for_npc(npc_city_id)

func show_battle(battle, attacker_id: String, defender_id: String) -> void:
	if battle_scene and battle_scene.has_method("start_battle"):
		battle_scene.start_battle(battle, attacker_id, defender_id)

func show_military_panel(city_id: String) -> void:
	var mp = $MilitaryPanel
	if mp and mp.has_method("open"):
		mp.open(city_id)

func _on_exit_cancel() -> void:
	AudioManager.play_button_click()
	if exit_dialog:
		exit_dialog.hide()

func _on_game_won(reason: String) -> void:
	UIManager.show_notification("🎉 " + reason, "success")
	SaveManager.save_game(0)

func _on_game_lost(reason: String) -> void:
	UIManager.show_notification("💀 " + reason, "error")
	SaveManager.save_game(0)

func _on_army_arrived(travel_id: String, origin_city_id: String, target_island_id: String, units: Dictionary, commander_id: String) -> void:
	var target = GameState.current_islands.get(target_island_id, {})
	var target_cities = target.get("player_cities", [])
	var target_city_id = ""
	for cid in target_cities:
		if GameState.current_cities.get(cid, {}).get("player", "") == "NPC":
			target_city_id = cid
			break
	if target_city_id.is_empty():
		return
	var attacker: Dictionary = {"city_id": origin_city_id, "units": units, "formation": "standard", "commander_data": {"id": commander_id}}
	var defender: Dictionary = {"city_id": target_city_id, "units": GameState.current_npc_cities.get(target_city_id, {}).get("units", {}), "formation": "standard"}
	var battle = CombatSystem.create_battle(attacker, defender, travel_id)
	EventBus.battle_completed.emit(travel_id, battle.status if battle else "unknown")

func _check_daily_reward() -> void:
	if daily_reward and daily_reward.has_method("check_and_show"):
		daily_reward.check_and_show()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if battle_scene and battle_scene.visible:
			battle_scene.hide()
		elif commander_panel and commander_panel.visible:
			commander_panel.hide()
		elif quest_panel and quest_panel.visible:
			quest_panel.hide()
		elif event_panel and event_panel.visible:
			event_panel.hide()
		elif ally_panel and ally_panel.visible:
			ally_panel.hide()
		elif trade_panel and trade_panel.visible:
			trade_panel.hide()
		elif colonize_dialog and colonize_dialog.visible:
			colonize_dialog.hide()
		elif research_panel and research_panel.visible:
			research_panel.hide()
		elif exit_dialog and exit_dialog.visible:
			exit_dialog.hide()
		elif _current_view == "world":
			switch_to_city_view()
		else:
			if exit_dialog:
				exit_dialog.show()
	elif Input.is_action_just_pressed("ui_cancel") and npc_dialog and npc_dialog.visible:
		npc_dialog.hide()
	elif Input.is_action_just_pressed("map_toggle"):
		if _current_view == "city":
			switch_to_world_map()
		else:
			switch_to_city_view()
