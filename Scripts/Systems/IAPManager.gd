extends Node

const PRODUCTS := {
	"gem_pack_small": {"name": "بسته جواهر کوچک", "price": "$1.99", "gems": 500},
	"gem_pack_large": {"name": "بسته جواهر بزرگ", "price": "$4.99", "gems": 2000},
	"builder_bundle": {"name": "بسته سازنده", "price": "$2.99", "builders": 1},
	"monthly_pass": {"name": "اشتراک ماهانه", "price": "$9.99", "duration_days": 30},
	"remove_ads": {"name": "حذف تبلیغات", "price": "$3.99"}
}

var is_iap_enabled: bool = false

func _ready() -> void:
	if OS.has_feature("production"):
		is_iap_enabled = true

func get_product(product_id: String) -> Dictionary:
	return PRODUCTS.get(product_id, {})

func purchase(product_id: String) -> bool:
	if not is_iap_enabled:
		push_warning("IAP disabled in current build")
		return false
	if not PRODUCTS.has(product_id):
		return false
	var product = PRODUCTS[product_id]
	if product.has("gems"):
		GameState.player_gems += product["gems"]
	if product.has("builders"):
		BuildingManager._extra_builders += product["builders"]
	EventBus.notification_added.emit("خرید انجام شد: " + product.get("name", ""), "success")
	return true