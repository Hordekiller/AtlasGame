extends CanvasLayer

enum TutorialStep {
	NONE,
	WELCOME,
	FIRST_CITY,
	BUILD_LUMBERJACK,
	BUILD_FARM,
	EXPLORE_ISLAND,
	BUILD_BARRACKS,
	RESEARCH_TECH,
	TRAIN_UNITS,
	ATTACK_NPC,
	COLONIZE,
	COMPLETE
}

var current_step: int = TutorialStep.NONE
var tutorial_active: bool = false
var completed_tutorials: Array = []

@onready var overlay: ColorRect = $Overlay
@onready var tooltip: Panel = $Tooltip
@onready var tooltip_label: Label = $Tooltip/Label
@onready var next_btn: Button = $Tooltip/NextBtn
@onready var skip_btn: Button = $Tooltip/SkipBtn

func _ready() -> void:
	overlay.color = Color(0, 0, 0, 0.4)
	tooltip.hide()
	overlay.hide()
	next_btn.pressed.connect(_on_next)
	skip_btn.pressed.connect(_on_skip)
	EventBus.building_construct_complete.connect(_on_building_built)
	EventBus.research_completed.connect(_on_research_done)
	EventBus.battle_completed.connect(_on_battle_done)
	get_viewport().size_changed.connect(_update_responsive)
	_update_responsive()

func _update_responsive() -> void:
	var vp = get_viewport().get_visible_rect()
	var s = ResponsiveLayout.scale_factor if Engine.has_singleton("ResponsiveLayout") else 1.0
	tooltip.custom_minimum_size = Vector2(min(400, vp.size.x * 0.8), 0)
	tooltip.position = Vector2(vp.size.x * 0.5 - tooltip.custom_minimum_size.x * 0.5, vp.size.y * 0.15)
	tooltip_label.add_theme_font_size_override("font_size", maxi(12, int(14 * s)))
	next_btn.custom_minimum_size = Vector2(maxi(80, 120 * s), maxi(36, 44 * s))
	skip_btn.custom_minimum_size = Vector2(maxi(60, 80 * s), maxi(36, 44 * s))

func start_tutorial() -> void:
	tutorial_active = true
	current_step = TutorialStep.WELCOME
	_show_step()

func _show_step() -> void:
	if not tutorial_active:
		return
	overlay.show()
	tooltip.show()
	match current_step:
		TutorialStep.WELCOME:
			tooltip_label.text = "به GameMB خوش آمدید!\n\nشما فرمانروای یک امپراتوری تازه‌تأسیس هستید.\nبرای شروع، اولین شهر خود را اداره کنید."
			next_btn.text = "شروع کن!"
		TutorialStep.FIRST_CITY:
			tooltip_label.text = "این شهر شماست.\nدر پایین صفحه، دکمه‌های مشاور را می‌بینید.\nبرای دیدن ساختمان‌های قابل ساخت، روی دکمه 'ساختمان' کلیک کنید."
			next_btn.text = "بعدی"
		TutorialStep.BUILD_LUMBERJACK:
			tooltip_label.text = "ابتدا یک 'چوب‌بر' بسازید.\nچوب منبع اصلی برای ساخت‌وساز است.\n۵۰+ چوب موجود دارید - کافی است!"
			next_btn.text = "بعدی"
		TutorialStep.BUILD_FARM:
			tooltip_label.text = "عالی! حالا یک 'مزرعه' بسازید.\nمزرعه غذا تولید می‌کند و جمعیت شهر را افزایش می‌دهد."
			next_btn.text = "بعدی"
		TutorialStep.EXPLORE_ISLAND:
			tooltip_label.text = "حالا به نقشه جهان بروید.\nجزایر اطراف را کاوش کنید.\nروی جزایر ناشناخته (???) کلیک کنید."
			next_btn.text = "بعدی"
		TutorialStep.BUILD_BARRACKS:
			tooltip_label.text = "برای دفاع از شهر، یک 'پادگان' بسازید.\nپادگان به شما امکان آموزش سرباز می‌دهد."
			next_btn.text = "بعدی"
		TutorialStep.RESEARCH_TECH:
			tooltip_label.text = "زمان تحقیق فرا رسیده!\nآکادمی را ساخته و فناوری 'آموزش نظامی' را تحقیق کنید."
			next_btn.text = "بعدی"
		TutorialStep.TRAIN_UNITS:
			tooltip_label.text = "حالا به پنل نظامی بروید و چند سرباز آموزش دهید.\nبرای حمله به شهرهای دشمن به نیرو نیاز دارید."
			next_btn.text = "بعدی"
		TutorialStep.ATTACK_NPC:
			tooltip_label.text = "روی نقشه جهان، شهرهای دشمن (قرمز) را پیدا کنید.\nروی آنها کلیک کرده و گزینه 'حمله' را انتخاب کنید."
			next_btn.text = "بعدی"
		TutorialStep.COLONIZE:
			tooltip_label.text = "عالی! حالا که قدرت دارید، جزایر جدید را مستعمره کنید.\nروی جزایر خالی کلیک کنید و شهر جدیدی تأسیس نمایید."
			next_btn.text = "اتمام"
		TutorialStep.COMPLETE:
			tooltip_label.text = "تبریک! آموزش اولیه به پایان رسید.\n\nاکنون می‌توانید:\n- امپراتوری خود را گسترش دهید\n- با دشمنان بجنگید\n- فناوری‌های جدید تحقیق کنید\n- و بر整个世界 مسلط شوید!"
			next_btn.text = "باشه!"
		_:
			tutorial_active = false
			overlay.hide()
			tooltip.hide()

func _on_next() -> void:
	current_step += 1
	if current_step >= TutorialStep.COMPLETE:
		tutorial_active = false
		overlay.hide()
		tooltip.hide()
		completed_tutorials.append("main_tutorial")
		EventBus.notification_added.emit("آموزش به پایان رسید!", "success")
		return
	_show_step()

func _on_skip() -> void:
	tutorial_active = false
	overlay.hide()
	tooltip.hide()
	completed_tutorials.append("main_tutorial")

func _on_building_built(city_id: String, grid_pos: Vector2i, building_id: String) -> void:
	if building_id == "lumberjack" and current_step == TutorialStep.BUILD_LUMBERJACK:
		_on_next()
	elif building_id == "farm" and current_step == TutorialStep.BUILD_FARM:
		_on_next()

func _on_research_done(tech_id: String) -> void:
	if tech_id == "military_training" and current_step == TutorialStep.RESEARCH_TECH:
		_on_next()

func _on_battle_done(battle_id: String, winner: String) -> void:
	if current_step == TutorialStep.ATTACK_NPC:
		_on_next()

func save_state() -> Dictionary:
	return {"completed_tutorials": completed_tutorials}

func load_state(data: Dictionary) -> void:
	completed_tutorials = data.get("completed_tutorials", [])
