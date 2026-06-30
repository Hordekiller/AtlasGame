extends Panel

var _advisors: Array = []
var _active_advisor: int = -1
var _message_timer: float = 0.0

@onready var advisor_container: VBoxContainer = $AdvisorContainer
@onready var message_panel: Panel = $MessagePanel
@onready var message_label: Label = $MessagePanel/VBox/MessageLabel
@onready var advisor_name: Label = $MessagePanel/VBox/AdvisorName

const ADVISOR_DATA = [
	{
		"id": "mayor",
		"name": "شهردار",
		"icon": "res://Assets/Textures/Advisor/mayor.png",
		"icon_active": "res://Assets/Textures/Advisor/mayor_active.png"
	},
	{
		"id": "scientist",
		"name": "دانشمند",
		"icon": "res://Assets/Textures/Advisor/scientist.png",
		"icon_active": "res://Assets/Textures/Advisor/scientist_active.png"
	},
	{
		"id": "general",
		"name": "ژنرال",
		"icon": "res://Assets/Textures/Advisor/general.png",
		"icon_active": "res://Assets/Textures/Advisor/general_active.png"
	},
	{
		"id": "diplomat",
		"name": "دیپلمات",
		"icon": "res://Assets/Textures/Advisor/diplomat.png",
		"icon_active": "res://Assets/Textures/Advisor/diplomat_active.png"
	}
]

const ADVICE_MESSAGES = {
	"mayor": [
		"شهروندان به غذا و مسکن نیاز دارند.",
		"برای افزایش جمعیت، مزرعه و انبار بسازید.",
		"رضایت شهروندان را با ساخت میخانه افزایش دهید.",
		"استعمار جزایر جدید نیاز به کاخ سطح ۲+ دارد."
	],
	"scientist": [
		"پژوهش قفل فناوری‌های جدید را باز می‌کند.",
		"فناوری اقتصاد باعث افزایش تولید منابع می‌شود.",
		"فناوری نظامی واحدهای قدرتمندتری ارائه می‌دهد.",
		"کشتی‌های سریع‌تر با فناوری دریانوردی."
	],
	"general": [
		"پادگان برای آموزش نیروهای زمینی ضروری است.",
		"دیوار دفاعی شهر را در برابر حملات محافظت می‌کند.",
		"کشتی‌های جنگی برای حفاظت از مسیرهای تجاری.",
		"نیروی دریایی قوی برای استعمار جزایر دور ضروری است."
	],
	"diplomat": [
		"مسیرهای تجاری بین شهرهای خود ایجاد کنید.",
		"بندر برای تجارت دریایی و استعمار الزامی است.",
		"بازار به شما امکان خرید و فروش منابع را می‌دهد.",
		"روابط خوب با شهرهای دیگر باعث رونق اقتصاد می‌شود."
	]
}

func _ready() -> void:
	UITheme.style_panel(self)
	UITheme.style_panel(message_panel)
	_setup_advisors()
	message_panel.hide()
	EventBus.notification_added.connect(_on_game_notification)
	get_viewport().size_changed.connect(_update_responsive)

func _update_responsive() -> void:
	var s = ResponsiveLayout.scale_factor
	position = Vector2(get_viewport().get_visible_rect().size.x - 60 * s, 70 * s)

func _setup_advisors() -> void:
	for ad in ADVISOR_DATA:
		var btn = TextureButton.new()
		var icon_path = ad.icon if ResourceLoader.exists(ad.icon) else ""
		if not icon_path.is_empty():
			btn.texture_normal = ResourceLoader.load(icon_path)
		var active_path = ad.icon_active if ResourceLoader.exists(ad.icon_active) else ""
		if not active_path.is_empty():
			btn.texture_pressed = ResourceLoader.load(active_path)
			btn.texture_hover = ResourceLoader.load(active_path)
		var s = ResponsiveLayout.scale_factor
		btn.custom_minimum_size = Vector2(48 * s, 48 * s)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.pressed.connect(_on_advisor_clicked.bind(_advisors.size()))
		advisor_container.add_child(btn)
		_advisors.append(ad)

func _on_advisor_clicked(idx: int) -> void:
	AudioManager.play_button_click()
	var ad = ADVISOR_DATA[idx]
	advisor_name.text = ad.name

	var messages = ADVICE_MESSAGES.get(ad.id, [])
	if not messages.is_empty():
		message_label.text = messages[randi() % messages.size()]
	else:
		message_label.text = "در حال حاضر توصیه‌ای ندارم."

	message_panel.show()
	message_panel.position = Vector2(-message_panel.size.x - 10, advisor_container.get_child(idx).position.y)
	_message_timer = 6.0

func _on_game_notification(_message: String, _type: String) -> void:
	_active_advisor = randi() % _advisors.size()
	var ad = ADVISOR_DATA[_active_advisor]
	var messages = ADVICE_MESSAGES.get(ad.id, [])
	if not messages.is_empty():
		var msg = messages[randi() % messages.size()]
		advisor_name.text = ad.name
		message_label.text = msg
		message_panel.show()
		message_panel.position = Vector2(-message_panel.size.x - 10, 0)
		_message_timer = 5.0

func _process(delta: float) -> void:
	if _message_timer > 0:
		_message_timer -= delta
		if _message_timer <= 0:
			message_panel.hide()
