extends Panel

@onready var close_btn: TextureButton = $VBox/Header/CloseBtn
@onready var commander_list: VBoxContainer = $VBox/Scroll/CommanderList
@onready var portrait: TextureRect = $VBox/Detail/Portrait
@onready var name_label: Label = $VBox/Detail/NameLabel
@onready var level_label: Label = $VBox/Detail/LevelLabel
@onready var stats_label: Label = $VBox/Detail/StatsLabel
@onready var skills_container: VBoxContainer = $VBox/Detail/SkillsContainer
@onready var detail_panel: Panel = $VBox/Detail

var _selected_id: String = ""

func _ready() -> void:
	UITheme.style_panel(self)
	if ResourceLoader.exists("res://Assets/Textures/UI/close.png"):
		close_btn.texture_normal = ResourceLoader.load("res://Assets/Textures/UI/close.png")
	close_btn.pressed.connect(hide)
	detail_panel.hide()
	hide()
	get_viewport().size_changed.connect(_update_responsive)

func _update_responsive() -> void:
	var vp = get_viewport().get_visible_rect()
	var sz = ResponsiveLayout.clamp_modal_size(Vector2(min(600, vp.size.x * 0.9), min(500, vp.size.y * 0.85)))
	custom_minimum_size = sz
	size = sz

func open() -> void:
	show()
	_refresh_list()

func _refresh_list() -> void:
	for child in commander_list.get_children():
		child.queue_free()
	var all = CommanderConfig.get_all_commanders()
	for cid in all:
		var defn = all[cid]
		var has = CommanderSystem.has_commander(cid)
		var btn = Button.new()
		btn.text = "%s [%s] %s" % [defn.get("name", cid), _type_name(defn.get("type", "")), "✅" if has else "🔒"]
		btn.size_flags_horizontal = SIZE_EXPAND_FILL
		btn.flat = true
		UITheme.style_button(btn)
		if has:
			var data = CommanderSystem.get_commander_data(cid)
			btn.text = "%s [%s] سطح %d" % [defn.get("name", cid), _type_name(defn.get("type", "")), data.get("level", 1)]
		btn.pressed.connect(_select_commander.bind(cid))
		commander_list.add_child(btn)

func _select_commander(cid: String) -> void:
	_selected_id = cid
	var defn = CommanderConfig.get_commander(cid)
	if defn.is_empty():
		return
	detail_panel.show()
	name_label.text = defn.get("name", cid)
	var data = CommanderSystem.get_commander_data(cid) if CommanderSystem.has_commander(cid) else {}
	if not data.is_empty():
		var stats = defn.get("base_stats", {})
		level_label.text = "سطح %d | XP: %d/%d" % [data.get("level", 1), data.get("exp", 0), data.get("level", 1) * 100]
		stats_label.text = "حمله: %d | دفاع: %d | سلامت: %d | سرعت: +%d%%" % \
			[stats.get("attack", 0), stats.get("defense", 0), stats.get("health", 0), stats.get("march_speed_bonus", 0) * 100]
	else:
		level_label.text = "قفل شده"
		stats_label.text = ""

	for child in skills_container.get_children():
		child.queue_free()
	for skill in defn.get("skills", []):
		var unlocked = data.get("unlocked_skills", []).has(skill.get("id", "")) if not data.is_empty() else false
		var slbl = Label.new()
		slbl.text = "%s %s: %s" % ["✅" if unlocked else "🔒", skill.get("name", ""), skill.get("description", "")]
		slbl.add_theme_font_size_override("font_size", 10)
		if unlocked:
			slbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		else:
			slbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		skills_container.add_child(slbl)

func _type_name(type: String) -> String:
	match type:
		"naval": return "دریایی"
		"land": return "زمینی"
		"support": return "پشتیبانی"
	return type
