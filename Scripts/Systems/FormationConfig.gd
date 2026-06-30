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
		"description": "دفاع +۲۰٪، حمله -۲۰٪",
		"attack_modifier": 0.8,
		"defense_modifier": 1.2,
		"speed_modifier": 0.9
	},
	"flanking": {
		"name": "جناحی",
		"description": "حمله +۲۰٪، دفاع -۲۰٪",
		"attack_modifier": 1.2,
		"defense_modifier": 0.8,
		"speed_modifier": 1.1
	},
	"charge": {
		"name": "یورش",
		"description": "حمله +۴۰٪ در راند اول، دفاع -۵۰٪",
		"attack_modifier": 1.4,
		"defense_modifier": 0.5,
		"speed_modifier": 1.3,
		"rounds_active": [1]
	},
	"turtle": {
		"name": "لاک‌پشتی",
		"description": "دفاع +۵۰٪، حمله -۴۰٪، ضد محاصره",
		"attack_modifier": 0.6,
		"defense_modifier": 1.5,
		"speed_modifier": 0.7
	},
	"ambush": {
		"name": "کمین",
		"description": "حمله +۳۰٪ در راند اول، دفاع -۱۰٪",
		"attack_modifier": 1.3,
		"defense_modifier": 0.9,
		"speed_modifier": 1.0,
		"rounds_active": [1]
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

static func get_effective_modifiers(formation_id: String, round: int) -> Dictionary:
	var f = FORMATIONS.get(formation_id, FORMATIONS["standard"])
	var rounds = f.get("rounds_active", [])
	if rounds.is_empty():
		return {"attack": f.get("attack_modifier", 1.0), "defense": f.get("defense_modifier", 1.0)}
	if round in rounds:
		return {"attack": f.get("attack_modifier", 1.0), "defense": f.get("defense_modifier", 1.0)}
	return {"attack": 1.0, "defense": 1.0}