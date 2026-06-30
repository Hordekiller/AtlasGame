extends Node

const COMMANDERS := {
	"navigator": {
		"name": "ناخدا",
		"type": "naval",
		"rarity": "rare",
		"base_stats": {
			"attack": 120, "defense": 80, "health": 1000,
			"march_speed_bonus": 0.15
		},
		"skills": [
			{
				"id": "sea_master", "name": "استاد دریا",
				"description": "واحدهای دریایی +20% آسیب",
				"type": "passive",
				"unlock_tier": 1,
				"modifiers": {"naval_attack": 1.2}
			},
			{
				"id": "storm_caller", "name": "فراخوان طوفان",
				"description": "کاهش ۳۰٪ دفاع دشمن در راند ۱",
				"type": "active",
				"unlock_tier": 2,
				"modifiers": {"enemy_defense_reduction": 0.7}
			},
			{
				"id": "fleet_commander", "name": "فرمانده ناوگان",
				"description": "+۱۵٪ سرعت حرکت ناوگان",
				"type": "passive",
				"unlock_tier": 3,
				"modifiers": {"march_speed": 1.15}
			}
		]
	},
	"warlord": {
		"name": "جنگ سالار",
		"type": "land",
		"rarity": "epic",
		"base_stats": {
			"attack": 150, "defense": 100, "health": 1200,
			"march_speed_bonus": 0.05
		},
		"skills": [
			{
				"id": "berserker", "name": "خشم",
				"description": "واحدهای زمینی +۳۰٪ آسیب در راند ۱",
				"type": "active",
				"unlock_tier": 1,
				"modifiers": {"land_attack_round1": 1.3}
			},
			{
				"id": "iron_wall", "name": "دیوار آهنین",
				"description": "+۲۵٪ دفاع برای تمام واحدها",
				"type": "passive",
				"unlock_tier": 2,
				"modifiers": {"defense": 1.25}
			},
			{
				"id": "war_cry", "name": "فریاد جنگ",
				"description": "-۲۰٪ روحیه دشمن در راند ۳",
				"type": "active",
				"unlock_tier": 4,
				"modifiers": {"enemy_morale": 0.8}
			}
		]
	},
	"tactician": {
		"name": "تاکتیسین",
		"type": "support",
		"rarity": "legendary",
		"base_stats": {
			"attack": 90, "defense": 140, "health": 900,
			"march_speed_bonus": 0.1
		},
		"skills": [
			{
				"id": "strategic_retreat", "name": "عقب‌نشینی تاکتیکی",
				"description": "می‌توان در راند ۲، ۵، ۸ عقب‌نشینی کرد",
				"type": "passive",
				"unlock_tier": 1,
				"modifiers": {"retreat_rounds": [2, 5, 8]}
			},
			{
				"id": "battle_medic", "name": "پزشک جنگی",
				"description": "۲۰٪ از تلفات هر راند بازمی‌گردد",
				"type": "passive",
				"unlock_tier": 3,
				"modifiers": {"casualty_recovery": 0.2}
			},
			{
				"id": "ambush", "name": "کمین",
				"description": "حمله غافلگیرانه: +۴۰٪ آسیب در راند ۱",
				"type": "active",
				"unlock_tier": 5,
				"modifiers": {"ambush_bonus": 1.4}
			}
		]
	},
	"builder": {
		"name": "معمار",
		"type": "support",
		"rarity": "common",
		"base_stats": {
			"attack": 60, "defense": 60, "health": 800,
			"march_speed_bonus": 0.0
		},
		"skills": [
			{
				"id": "rapid_construction", "name": "ساخت سریع",
				"description": "سرعت ساخت ساختمان‌ها +۲۵٪",
				"type": "passive",
				"unlock_tier": 1,
				"modifiers": {"build_speed": 1.25}
			},
			{
				"id": "resource_saver", "name": "صرفه‌جویی",
				"description": "-۱۵٪ هزینه منابع برای ساخت و ارتقا",
				"type": "passive",
				"unlock_tier": 2,
				"modifiers": {"cost_reduction": 0.85}
			}
		]
	},
	"spy_master": {
		"name": "جاسوس",
		"type": "support",
		"rarity": "epic",
		"base_stats": {
			"attack": 80, "defense": 70, "health": 700,
			"march_speed_bonus": 0.2
		},
		"skills": [
			{
				"id": "intel_gathering", "name": "گردآوری اطلاعات",
				"description": "اطلاعات دشمن قبل از نبرد نمایش داده می‌شود",
				"type": "passive",
				"unlock_tier": 1,
				"modifiers": {"intel": true}
			},
			{
				"id": "sabotage", "name": "خرابکاری",
				"description": "-۲۵٪ تولید منابع شهر هدف به مدت ۲۴ ساعت",
				"type": "active",
				"unlock_tier": 3,
				"modifiers": {"production_reduction": 0.75}
			}
		]
	},
	"admiral": {
		"name": "دریادار",
		"type": "naval",
		"rarity": "legendary",
		"base_stats": {
			"attack": 180, "defense": 120, "health": 1400,
			"march_speed_bonus": 0.2
		},
		"skills": [
			{
				"id": "fleet_admiral", "name": "دریادار ناوگان",
				"description": "تمام واحدهای دریایی +۳۵٪ حمله و +۲۰٪ دفاع",
				"type": "passive",
				"unlock_tier": 1,
				"modifiers": {"naval_attack": 1.35, "naval_defense": 1.2}
			},
			{
				"id": "blockade", "name": "محاصره دریایی",
				"description": "قطعه مسیر تجاری دشمن به مدت ۱۲ ساعت",
				"type": "active",
				"unlock_tier": 2,
				"modifiers": {"blockade_hours": 12}
			},
			{
				"id": "tidal_wave", "name": "سونامی",
				"description": "خسارت گسترده به ناوگان دشمن در راند ۴",
				"type": "active",
				"unlock_tier": 5,
				"modifiers": {"tidal_damage": 0.5}
			}
		]
	}
}

static func get_commander(id: String) -> Dictionary:
	return COMMANDERS.get(id, {})

static func get_commanders_by_type(cmd_type: String) -> Array:
	var result = []
	for cid in COMMANDERS:
		if COMMANDERS[cid].get("type", "") == cmd_type:
			result.append(cid)
	return result

static func get_all_commanders() -> Dictionary:
	return COMMANDERS.duplicate(true)

static func get_total_skills(commander_id: String) -> int:
	var c = COMMANDERS.get(commander_id, {})
	return c.get("skills", []).size()
