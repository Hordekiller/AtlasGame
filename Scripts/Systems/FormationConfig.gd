extends Node

const FORMATIONS := {
	"standard": {
		"name": "استاندارد",
		"description": "حمله و دفاع متعادل",
		"attack_modifier": 1.0,
		"defense_modifier": 1.0,
		"speed_modifier": 1.0
	},
	"phalanx": {
		"name": "فالانژ",
		"description": "+۳۰٪ دفاع، -۱۵٪ حمله",
		"attack_modifier": 0.85,
		"defense_modifier": 1.3,
		"speed_modifier": 0.9
	},
	"flanking": {
		"name": "جناحی",
		"description": "حملات جناحی +۲۰٪ آسیب",
		"attack_modifier": 1.2,
		"defense_modifier": 0.8,
		"speed_modifier": 1.1
	},
	"charge": {
		"name": "یورش",
		"description": "حمله قوی در راند اول، دفاع ضعیف",
		"attack_modifier": 1.4,
		"defense_modifier": 0.6,
		"speed_modifier": 1.3,
		"round_limited": 3
	},
	"fortress": {
		"name": "سنگر",
		"description": "دفاع قوی اما سرعت کم",
		"attack_modifier": 0.7,
		"defense_modifier": 1.6,
		"speed_modifier": 0.7
	},
	"ambush": {
		"name": "کمین",
		"description": "+۴۰٪ حمله در راند اول، سپس کاهش",
		"attack_modifier": 1.4,
		"defense_modifier": 0.9,
		"speed_modifier": 1.0,
		"round_limited": 1
	}
}

static func get_formation(id: String) -> Dictionary:
	return FORMATIONS.get(id, FORMATIONS["standard"])

static func get_all_formations() -> Dictionary:
	return FORMATIONS.duplicate(true)

static func get_formation_names() -> Dictionary:
	var result = {}
	for f in FORMATIONS:
		result[f] = FORMATIONS[f].get("name", f)
	return result
