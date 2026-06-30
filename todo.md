[6/30/26 7:14 AM] aDmin: # AGENT PROMPT — PHASE 2: Android Landscape + Modern Mobile Strategy Upgrade

## CONTEXT & MISSION

پروژه Godot 4 یک بازی MMORTS شبیه Ikariam داری که فاز اول پیاده‌سازیش انجام شده.
حالا باید این موارد رو انجام بدی:

1. تمام کدهای موجود را بخوان و درک کن — بدون خواندن کامل هیچ فایلی رو دست نزن
2. بازی را از حالت وب/دسکتاپ به Android Landscape-only تبدیل کن
3. مکانیزم‌های جنگ و gameplay را از بازی‌های موبایل موفق الهام بگیر و ارتقا بده
4. منابع و سیستم جزیره‌ای Ikariam حفظ بشه — فقط combat، progression و UX ارتقا پیدا کنه

شروع هر session:
ls -R res://
cat [هر فایل .gd و .tscn موجود]
---

## بخش اول: تنظیمات Android Landscape

### Project Settings (project.godot)

[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/size/mode=0
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
window/handheld/orientation=SCREEN_LANDSCAPE

[rendering]
renderer/rendering_method="mobile"
renderer/rendering_method.mobile="gl_compatibility"
textures/vram_compression/import_etc2_astc=true

[input_devices]
pointing/emulate_touch_from_mouse=true
### Android Export Preset (اضافه به export_presets.cfg)

[preset.0]
name="Android"
platform="Android"
runnable=true
dedicated_server=false

[preset.0.options]
custom_template/debug=""
custom_template/release=""
gradle_build/use_gradle_build=true
gradle_build/gradle_build_directory="android"
package/unique_name="com.yourstudio.islandconquest"
package/name="Island Conquest"
package/signed=true
version/code=1
version/name="1.0.0"
package/min_sdk=24
package/target_sdk=34
screen/immersive_mode=true
screen/orientation=0
user_data_backup/allow=false
graphics/opengl_debug=false
xr_features/xr_mode=0
permissions/internet=true
permissions/vibrate=true
permissions/receive_boot_completed=true
### CanvasLayer و Safe Area (برای notch/punch-hole)

# autoloads/SafeAreaManager.gd
extends Node

signal safe_area_changed(rect: Rect2i)

var safe_area: Rect2i = Rect2i()

func _ready() -> void:
    _update_safe_area()
    get_tree().root.size_changed.connect(_update_safe_area)

func _update_safe_area() -> void:
    safe_area = DisplayServer.get_display_safe_area()
    safe_area_changed.emit(safe_area)

func get_margin_left() -> int:
    return safe_area.position.x

func get_margin_right() -> int:
    return DisplayServer.window_get_size().x - (safe_area.position.x + safe_area.size.x)

func get_margin_top() -> int:
    return safe_area.position.y
---

## بخش دوم: UI Layout — Landscape Design

### قانون کلی Landscape Mobile UI

╔══════════════════════════════════════════════════════════════════╗
║  [LOGO/MAP]    RESOURCE BAR (top center)          [SETTINGS]   ║
║                                                                  ║
║                                                                  ║
║              MAIN GAME VIEW (center)                            ║
║                                                                  ║
║                                                                  ║
║  [LEFT THUMB ZONE]                     [RIGHT THUMB ZONE]       ║
║  Navigation / Camera pan               Action Buttons / Menu    ║
╚══════════════════════════════════════════════════════════════════╝
قوانین ثابت:
- Resource bar: بالای صفحه، تمام عرض
- دکمه‌های اصلی: گوشه پایین راست (شست راست)
- Camera pan / map navigation: لمس و drag روی ناحیه مرکزی
- Panels و bottom sheets: از پایین slide-in می‌کنن (نه popup)
- حداقل touch target: 88×88 px در 1920×1080
- هیچ متنی زیر 18sp نباشه

### ResourceBar.tscn — Landscape version

HBoxContainer (ResourceBar)
├── MarginContainer (left_safe_margin) — dynamic margin
├── ResourceItem (wood)     ← icon + label + per_hour
├── ResourceItem (marble)
├── ResourceItem (crystal)
├── ResourceItem (sulfur)
├── ResourceItem (wine)
├── Separator
├── ResourceItem (gold)     ← gold جدا نشون داده میشه
├── HSeparator
├── HappinessIndicator      ← face icon + percentage
└── MarginContainer (right_safe_margin)
```gdscript
# scenes/ui/ResourceBar.gd
extends HBoxContainer
[6/30/26 7:14 AM] aDmin: @onready var resource_items: Dictionary = {}

func _ready() -> void:
    SafeAreaManager.safe_area_changed.connect(_adjust_margins)
    _build_items()
    _adjust_margins(SafeAreaManager.safe_area)

func update_resources(res: Dictionary, rates: Dictionary) -> void:
    for key in res:
        if resource_items.has(key):
            resource_items[key].set_value(res[key], rates.get(key, 0.0))

func _adjust_margins(area: Rect2i) -> void:
    $LeftMargin.add_theme_constant_override("margin_left", SafeAreaManager.get_margin_left() + 8)
    $RightMargin.add_theme_constant_override("margin_right", SafeAreaManager.get_margin_right() + 8)

### AdvisorBar — Landscape: پایین راست

VBoxContainer (AdvisorBar) — anchor: bottom_right
├── AdvisorButton (town)       🏛️
├── AdvisorButton (military)   ⚔️
├── AdvisorButton (research)   🔬
├── AdvisorButton (diplomacy)  🤝
└── AdvisorButton (alliance)   🛡️

هر دکمه: ۸۸×۸۸ px، با badge اگر notification داشته باشه.

---

## بخش سوم: COMBAT SYSTEM — الهام از بازی‌های موفق

### مشکلات Ikariam که باید حل بشه:
- جنگ Ikariam 30 دقیقه per round → خیلی کند برای موبایل
- هیچ visual combat نداشت — فقط log متنی
- هیچ hero/commander نداشت
- defensive mechanics ضعیف بود

### راه‌حل: سیستم Combat ترکیبی

**الهام از:**
- **Clash of Clans**: base defense layout، troop placement، spell timing
- **Rise of Kingdoms**: commander system، march + rally
- **Lords Mobile**: hero skills، formation system
- **Northgard**: resource pressure در جنگ

---

### ۳.۱ Hero/Commander System (از Rise of Kingdoms + Lords Mobile)

هر بازیکن تا ۵ Commander داره:

gdscript
# scripts/data/CommanderConfig.gd
extends Node

const COMMANDERS := {
    "navigator": {
        "name": "Navigator",
        "type": "naval",         # naval / land / support
        "rarity": "rare",        # common / rare / epic / legendary
        "base_stats": {
            "attack": 120, "defense": 80, "health": 1000,
            "march_speed_bonus": 0.15
        },
        "skills": [
            {
                "id": "sea_master",
                "name": "Sea Master",
                "description": "Naval units deal +20% damage",
                "type": "passive",
                "unlock_level": 1
            },
            {
                "id": "tidal_wave",
                "name": "Tidal Wave",
                "description": "Active: All allied naval units attack simultaneously next round",
                "type": "active",
                "cooldown_rounds": 3,
                "unlock_level": 5
            },
            {
                "id": "admirals_blessing",
                "name": "Admiral's Blessing",
                "description": "Fleet capacity +30%",
                "type": "passive",
                "unlock_level": 10
            }
        ],
        "max_level": 50,
        "exp_per_level": [100, 150, 200, 300, 450, 700, 1000, 1500, 2000, 3000]
    },
    "warlord": {
        "name": "Warlord",
        "type": "land",
        "rarity": "epic",
        "base_stats": {
            "attack": 180, "defense": 120, "health": 1500,
            "troop_attack_bonus": 0.25
        },
        "skills": [
            {
                "id": "battle_cry",
                "name": "Battle Cry",
                "description": "Land troops attack +15% for 3 rounds",
                "type": "active",
                "cooldown_rounds": 4,
                "unlock_level": 1
            },
            {
                "id": "iron_will",
                "name": "Iron Will",
                "description": "Troops fight until 0 HP (no retreat debuff)",
                "type": "passive",
                "unlock_level": 15
            }
        ],
        "max_level": 50
    }
    # ... add more commanders
}

**Commander Leveling:**
gdscript
# scripts/systems/CommanderSystem.gd
extends RefCounted
[6/30/26 7:14 AM] aDmin: static func add_exp(commander_id: String, exp: int) -> Dictionary:
    var data = GameState.commanders.get(commander_id, {})
    data["exp"] = data.get("exp", 0) + exp
    var config = CommanderConfig.COMMANDERS[commander_id]
    var level = data.get("level", 1)
    var leveled_up := false
    while level < config["max_level"]:
        var required = config["exp_per_level"][min(level - 1, config["exp_per_level"].size() - 1)]
        if data["exp"] >= required:
            data["exp"] -= required
            level += 1
            leveled_up = true
        else:
            break
    data["level"] = level
    GameState.commanders[commander_id] = data
    return {"leveled_up": leveled_up, "new_level": level}

static func get_active_skills(commander_id: String) -> Array:
    var config = CommanderConfig.COMMANDERS.get(commander_id, {})
    var level = GameState.commanders.get(commander_id, {}).get("level", 1)
    return config.get("skills", []).filter(func(s): return level >= s.get("unlock_level", 1))

---

### ۳.۲ Formation System (از Lords Mobile)

هر حمله یک Formation داره:

gdscript
# scripts/data/FormationConfig.gd
const FORMATIONS := {
    "standard": {
        "name": "Standard",
        "description": "Balanced — no bonuses",
        "attack_modifier": 1.0,
        "defense_modifier": 1.0,
        "speed_modifier": 1.0
    },
    "aggressive": {
        "name": "Aggressive",
        "description": "+30% attack, -20% defense",
        "attack_modifier": 1.3,
        "defense_modifier": 0.8,
        "speed_modifier": 1.1
    },
    "defensive": {
        "name": "Defensive",
        "description": "-15% attack, +40% defense",
        "attack_modifier": 0.85,
        "defense_modifier": 1.4,
        "speed_modifier": 0.9
    },
    "naval_assault": {
        "name": "Naval Assault",
        "description": "Naval units: +25% attack, land units disabled",
        "attack_modifier": 1.25,
        "defense_modifier": 0.6,
        "speed_modifier": 1.2,
        "restricts": ["land"]
    }
}

---

### ۳.۳ Combat Rounds — سریع‌تر از Ikariam

| | Ikariam (قدیم) | بازی ما (جدید) |
|---|---|---|
| فاصله بین rounds | 30 دقیقه | **5 دقیقه** |
| حداکثر rounds | نامحدود | **12 round** |
| مدت کل جنگ | روزها | **حداکثر 1 ساعت** |
| نمایش | متن لاگ | **Animated battle scene** |
| hero skills | ندارد | **Active + Passive** |
| retreat | در هر round | **در round 3، 6، 9** |

gdscript
# scripts/systems/CombatSystem.gd
extends RefCounted

const ROUND_DURATION_SECONDS := 300  # 5 minutes
const MAX_ROUNDS := 12
const RETREAT_ROUNDS := [3, 6, 9]

class BattleState:
    var battle_id: String
    var attacker: Dictionary   # {units, commander_id, formation, hero_skills}
    var defender: Dictionary
    var current_round: int = 0
    var rounds_log: Array[Dictionary] = []
    var status: String = "ongoing"  # ongoing / attacker_win / defender_win / retreated

static func simulate_round(state: BattleState) -> Dictionary:
    var round_data := {}
    state.current_round += 1
    
    # Commander skill triggers
    var atk_skills = _get_triggered_skills(state.attacker, state.current_round)
    var def_skills = _get_triggered_skills(state.defender, state.current_round)
    
    # Formation modifiers
    var atk_formation = FormationConfig.FORMATIONS.get(
        state.attacker.get("formation", "standard"), {})
    var def_formation = FormationConfig.FORMATIONS.get(
        state.defender.get("formation", "standard"), {})
    
    # Calculate damage
    var atk_power = _calculate_total_attack(state.attacker) \
        * atk_formation.get("attack_modifier", 1.0)
    var def_power = _calculate_total_attack(state.defender) \
        * def_formation.get("attack_modifier", 1.0)
    
    var atk_defense = _calculate_total_defense(state.attacker) \
[6/30/26 7:14 AM] aDmin: * atk_formation.get("defense_modifier", 1.0)
    var def_defense = _calculate_total_defense(state.defender) \
        * def_formation.get("defense_modifier", 1.0)
    
    var def_losses = _apply_damage(state.defender, atk_power, def_defense)
    var atk_losses = _apply_damage(state.attacker, def_power, atk_defense)
    
    round_data = {
        "round": state.current_round,
        "attacker_losses": atk_losses,
        "defender_losses": def_losses,
        "skills_triggered": atk_skills + def_skills,
        "attacker_units_remaining": _count_units(state.attacker),
        "defender_units_remaining": _count_units(state.defender)
    }
    
    state.rounds_log.append(round_data)
    _check_battle_end(state)
    return round_data

static func _calculate_total_attack(army: Dictionary) -> float:
    var total := 0.0
    var units = army.get("units", {})
    for unit_type in units:
        var count = units[unit_type]
        var config = UnitConfig.get_config(unit_type)
        total += count * config.get("attack", 0)
    # Add commander bonus
    var cmd_id = army.get("commander_id", "")
    if not cmd_id.is_empty():
        var cmd = CommanderConfig.COMMANDERS.get(cmd_id, {})
        total *= (1.0 + cmd.get("base_stats", {}).get("troop_attack_bonus", 0.0))
    return total

static func _apply_damage(army: Dictionary, enemy_attack: float, own_defense: float) -> Dictionary:
    var net_damage = max(0.0, enemy_attack - own_defense * 0.5)
    var losses := {}
    var units = army.get("units", {})
    var total_hp = _calculate_total_health(army)
    if total_hp <= 0:
        return losses
    var loss_ratio = min(1.0, net_damage / total_hp)
    for unit_type in units:
        var lost = int(units[unit_type] * loss_ratio)
        losses[unit_type] = lost
        units[unit_type] = max(0, units[unit_type] - lost)
    return losses

static func _check_battle_end(state: BattleState) -> void:
    var atk_alive = _count_units(state.attacker) > 0
    var def_alive = _count_units(state.defender) > 0
    if not atk_alive:
        state.status = "defender_win"
    elif not def_alive:
        state.status = "attacker_win"
    elif state.current_round >= MAX_ROUNDS:
        state.status = "defender_win"  # Defender wins on timeout

static func calculate_pillage(attacker_result: String, defender_resources: Dictionary, 
                               pillage_efficiency: float) -> Dictionary:
    if attacker_result != "attacker_win":
        return {}
    var pillaged := {}
    for res in defender_resources:
        if res == "gold":
            pillaged[res] = int(defender_resources[res] * 0.15 * pillage_efficiency)
        else:
            pillaged[res] = int(defender_resources[res] * 0.25 * pillage_efficiency)
    return pillaged

---

### ۳.۴ Battle Visual Scene (Animated)

BattleScene.tscn
├── Background (island/sea sprite based on location)
├── AttackerSide (left)
│   ├── UnitFormationDisplay — نمایش unit icons در formation
│   ├── CommanderPortrait
│   └── HPBar
├── DefenderSide (right)
│   ├── UnitFormationDisplay
│   ├── CommanderPortrait
│   └── HPBar
├── BattleAnimationLayer
│   ├── ProjectilePool — arrows, cannonballs
│   └── ImpactEffects — explosions, sparks
├── UI
│   ├── RoundLabel ("Round 3 / 12")
│   ├── TimerLabel ("Next round in: 4:32")
│   ├── SkillActivationBanner — "WARLORD: BATTLE CRY!"
│   └── RetreatButton — فقط در round 3، 6، 9 نشون داده بشه
└── BattleLog (scrollable، سمت پایین)


gdscript
# scenes/battle/BattleScene.gd
extends Node2D

@onready var attacker_side: Control = $AttackerSide
@onready var defender_side: Control = $DefenderSide
@onready var round_label: Label = $UI/RoundLabel
@onready var timer_label: Label = $UI/TimerLabel
@onready var retreat_btn: Button = $UI/RetreatButton
@onready var skill_banner: Label = $UI/SkillActivationBanner
@onready var battle_log: RichTextLabel = $UI/BattleLog

var battle_data: Dictionary = {}
var current_round: int = 0
[6/30/26 7:14 AM] aDmin: func setup(data: Dictionary) -> void:
    battle_data = data
    current_round = data.get("current_round", 0)
    _refresh_display()
    _update_timer()

func _update_timer() -> void:
    var next_round_at: int = battle_data.get("next_round_at", 0)
    var remaining = TimeManager.seconds_until(next_round_at)
    timer_label.text = "Next round: %s" % TimeManager.format_duration(remaining)
    
    # Retreat button only at retreat points
    retreat_btn.visible = CombatSystem.RETREAT_ROUNDS.has(current_round)

func play_round_animation(round_data: Dictionary) -> void:
    # Skill banner
    for skill in round_data.get("skills_triggered", []):
        skill_banner.text = "⚡ %s: %s!" % [skill["commander"], skill["skill_name"]]
        skill_banner.show()
        await get_tree().create_timer(2.0).timeout
        skill_banner.hide()
    
    # Unit loss animation — shrink formation icons
    await _animate_losses(round_data)
    
    # Log entry
    var log_line = "[b]Round %d[/b]: Attacker lost %d units, Defender lost %d units\n" % [
        round_data["round"],
        _sum_losses(round_data["attacker_losses"]),
        _sum_losses(round_data["defender_losses"])
    ]
    battle_log.append_text(log_line)

func _animate_losses(round_data: Dictionary) -> void:
    # اضافه کردن تعداد مشخصی projectile به سمت طرف مقابل
    for i in range(min(5, _sum_losses(round_data["defender_losses"]))):
        _spawn_projectile(attacker_side.global_position, defender_side.global_position)
    await get_tree().create_timer(0.8).timeout
    # آپدیت HP bars
    _update_hp_bars(round_data)

---

## بخش چهارم: PROGRESSION SYSTEM — الهام از Clash of Clans

### ۴.۱ Builder System (از Clash of Clans)

به جای یک صف ساخت — چندین Builder:

gdscript
# scripts/systems/BuildingSystem.gd

# در GameState اضافه کن:
var builders: Array[Dictionary] = [
    {"id": 0, "busy": false, "finish_at": 0, "building_slot": -1},
    {"id": 1, "busy": false, "finish_at": 0, "building_slot": -1}
    # بازیکن می‌تونه builder سوم رو با premium آنلاک کنه
]

static func get_free_builder() -> int:
    for i in GameState.builders.size():
        if not GameState.builders[i]["busy"]:
            return i
    return -1  # همه مشغولن

static func can_start_construction() -> bool:
    return get_free_builder() >= 0

static func start_upgrade(slot_id: int, building_type: String, level: int) -> bool:
    var builder_id = get_free_builder()
    if builder_id < 0:
        return false
    var duration = ResourceSystem.get_upgrade_time_seconds(building_type, level)
    var finish_at = TimeManager.get_server_time() + duration
    GameState.builders[builder_id]["busy"] = true
    GameState.builders[builder_id]["finish_at"] = finish_at
    GameState.builders[builder_id]["building_slot"] = slot_id
    NetworkManager.send_action("upgrade_building", {
        "slot_id": slot_id,
        "building_type": building_type,
        "builder_id": builder_id
    })
    return true

**Builder UI — نمایش در HUD:**
BuilderStatusBar (زیر resource bar):
├── BuilderSlot[0]: 🔨 Academy Lv3 → 2h 15m
├── BuilderSlot[1]: 🔨 Free (tap to manage)
└── [+ Unlock 3rd Builder — 300 Ambrosia]

### ۴.۲ Daily Quests & Events (از Rise of Kingdoms + Clash of Clans)

gdscript
# scripts/systems/QuestSystem.gd
extends Node

const DAILY_QUESTS := [
    {"id": "collect_wood", "title": "Collect 500 Wood", "target": 500, "reward": {"gold": 200, "exp": 50}},
    {"id": "train_units", "title": "Train 20 Units", "target": 20, "reward": {"gold": 300, "exp": 80}},
    {"id": "upgrade_building", "title": "Complete 1 Building Upgrade", "target": 1, "reward": {"gold": 500, "exp": 150}},
    {"id": "research_point", "title": "Generate 100 Research Points", "target": 100, "reward": {"crystal": 50, "exp": 100}},
    {"id": "login_reward", "title": "Daily Login", "target": 1, "reward": {"ambrosia": 5, "gold": 100}}
]

var quest_progress: Dictionary = {}
[6/30/26 7:14 AM] aDmin: func get_active_quests() -> Array:
    var today = Time.get_date_string_from_system()
    if GameState.last_quest_reset != today:
        _reset_daily_quests()
    return DAILY_QUESTS.map(func(q):
        var p = quest_progress.get(q["id"], 0)
        return q.merge({"progress": p, "completed": p >= q["target"]}, true)
    )

func track_progress(quest_id: String, amount: int = 1) -> void:
    quest_progress[quest_id] = quest_progress.get(quest_id, 0) + amount
    _check_completion(quest_id)

### ۴.۳ Season Pass / Events (ساده)

gdscript
# scripts/systems/EventSystem.gd
const CURRENT_EVENT := {
    "name": "Island Festival",
    "duration_days": 7,
    "special_resource": "festival_coin",
    "tasks": [
        {"desc": "Win 3 battles", "coins": 50},
        {"desc": "Upgrade 5 buildings", "coins": 100},
        {"desc": "Trade with 3 players", "coins": 75}
    ],
    "rewards": [
        {"coins_required": 100, "reward": {"gold": 10000}},
        {"coins_required": 300, "reward": {"marble": 5000}},
        {"coins_required": 500, "reward": {"commander_shard": "legendary_admiral", "count": 10}}
    ]
}

---

## بخش پنجم: ISLAND & WORLD MAP — بهبود

### ۵.۱ Island View بهبود یافته

الهام از Rise of Kingdoms — نقشه جهان با جزایر:

IslandView (Landscape):
├── IslandMap (center-left 70% of screen)
│   ├── IslandTerrain (sprite, زمین + آب اطراف)
│   ├── PlayerTownSpots (16 نقطه روی جزیره)
│   │   └── TownMarker per player (color-coded by alliance)
│   ├── SharedBuilding (center island, eg: Quarry level 7)
│   └── CameraController (pinch zoom + drag)
│
└── IslandSidebar (right 30%)
    ├── IslandInfo (name, luxury resource, player count)
    ├── CooperationPanel (donate to shared building)
    ├── AgoraMessages (last 5 messages)
    └── PlayerList (scrollable, با rank + alliance)

### ۵.۲ World Map Cluster View

جزایر به cluster تقسیم میشن (از Rise of Kingdoms الهام):

gdscript
# Island clusters: هر 5x5 grid از جزایر یک "Region" میشه
# Region داره اسم و رنگ خودش

const REGIONS := {
    "aegean": {"name": "Aegean Sea", "color": Color(0.2, 0.5, 0.9), "bonus": "trade"},
    "mediterranean": {"name": "Mediterranean", "color": Color(0.1, 0.7, 0.4), "bonus": "production"},
    "ionian": {"name": "Ionian Sea", "color": Color(0.8, 0.3, 0.1), "bonus": "military"}
}

---

## بخش ششم: DEFENSE SYSTEM — الهام از Clash of Clans

Ikariam دفاع خوبی نداشت. ما اضافه می‌کنیم:

### Defensive Buildings

gdscript
# اضافه به BuildingConfig.gd
"watchtower": {
    "name": "Watchtower",
    "max_level": 15,
    "base_cost": {"wood": 300, "marble": 200},
    "base_time_seconds": 180,
    "function": "early_warning",  # نشون میده چه کسی داره میاد و چه زمانی
    "unlock_at": {"town_hall": 4}
},
"cannon_battery": {
    "name": "Cannon Battery",
    "max_level": 20,
    "base_cost": {"sulfur": 200, "marble": 300, "gold": 1500},
    "function": "auto_defense",   # در اولین round بدون commander حمله می‌کنه
    "base_stats": {"auto_attack": 500},
    "unlock_at": {"town_hall": 7, "barracks": 5}
},
"harbor_chain": {
    "name": "Harbor Chain",
    "max_level": 10,
    "base_cost": {"marble": 500, "crystal": 200},
    "function": "naval_defense",  # blockade کشتی‌های دشمن رو کند می‌کنه
    "speed_reduction": 0.4,
    "unlock_at": {"shipyard": 5}
},
"treasury_vault": {
    "name": "Treasury Vault",
    "max_level": 20,
    "function": "resource_protection",  # بخشی از منابع رو در غارت محافظت می‌کنه
    "protection_ratio": 0.2,  # 20% منابع غیرقابل غارته
    "unlock_at": {"town_hall": 6}
}

### Beginner Protection

gdscript
# در GameState:
var protection_end_at: int = 0  # timestamp

func is_under_protection() -> bool:
    return TimeManager.get_server_time() < protection_end_at

# جدید بازیکن ۷۲ ساعت محافظت داره
# اگر حمله کنه، محافظت فوری برداشته میشه
`

---

## بخش هفتم: MONETIZATION — بدون pay-to-win

فقط speed-ups و cosmetics:
[6/30/26 7:14 AM] aDmin: # scripts/systems/ShopSystem.gd
const AMBROSIA_PACKAGES := [
    {"id": "starter", "ambrosia": 100, "price_usd": 0.99, "bonus_pct": 0},
    {"id": "small", "ambrosia": 550, "price_usd": 4.99, "bonus_pct": 10},
    {"id": "medium", "ambrosia": 1200, "price_usd": 9.99, "bonus_pct": 20},
    {"id": "large", "ambrosia": 2600, "price_usd": 19.99, "bonus_pct": 30},
]

const AMBROSIA_SHOP := {
    # Speed-ups (فقط زمان)
    "speedup_1h": {"cost": 50, "type": "speedup", "minutes": 60},
    "speedup_8h": {"cost": 250, "type": "speedup", "minutes": 480},
    "speedup_24h": {"cost": 500, "type": "speedup", "minutes": 1440},
    
    # Builder slot سوم — one-time purchase
    "builder_slot_3": {"cost": 300, "type": "permanent", "effect": "extra_builder"},
    
    # Cosmetics — هیچ تاثیر gameplay ای ندارن
    "skin_golden_town": {"cost": 200, "type": "cosmetic", "target": "town_hall"},
    "skin_flame_fleet": {"cost": 150, "type": "cosmetic", "target": "shipyard"},
    
    # Commander shards — می‌شه از gameplay هم گرفت
    "shard_pack_rare": {"cost": 100, "type": "commander_shard", "rarity": "rare", "count": 5},
}

# ❌ هرگز:
# - تجهیزات قوی‌تر
# - یونیت‌های قوی‌تر
# - مزیت در تحقیق
# - منابع خارج از حد طبیعی
---

## بخش هشتم: ANDROID-SPECIFIC CODE

### Back Button Handler

# scenes/main/Main.gd
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):  # Android back button
        _handle_back_press()

func _handle_back_press() -> void:
    # بستن آخرین panel باز
    var panels := [
        $AlliancePanel, $ResearchPanel, $MilitaryPanel, $TradePanel
    ]
    for panel in panels:
        if panel.visible:
            panel.hide()
            return
    # اگر هیچ panel ای باز نبود، exit dialog
    $ExitConfirmDialog.popup_centered()
### Haptic Feedback

# autoloads/HapticManager.gd
extends Node

func tap() -> void:
    if OS.get_name() == "Android":
        Input.vibrate_handheld(20)  # 20ms

func success() -> void:
    if OS.get_name() == "Android":
        Input.vibrate_handheld(40)

func error() -> void:
    if OS.get_name() == "Android":
        for i in 3:
            Input.vibrate_handheld(30)
            await get_tree().create_timer(0.1).timeout
### Screen Keep Awake

# در Main.gd _ready():
func _ready() -> void:
    if OS.get_name() == "Android":
        OS.keep_screen_on = true
    # وقتی بازی background میره:
    get_tree().root.focus_entered.connect(func(): OS.keep_screen_on = true)
    get_tree().root.focus_exited.connect(func(): OS.keep_screen_on = false)
### Gesture Handler برای World Map

# scenes/world_map/WorldMapGestures.gd
extends Node

signal pan_delta(delta: Vector2)
signal zoom_changed(factor: float)

var _touch_points: Dictionary = {}
var _last_pinch_distance: float = -1.0

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _touch_points[event.index] = event.position
        else:
            _touch_points.erase(event.index)
            _last_pinch_distance = -1.0
    
    elif event is InputEventScreenDrag:
        _touch_points[event.index] = event.position
        if _touch_points.size() == 1:
            pan_delta.emit(-event.relative)
        elif _touch_points.size() == 2:
            _handle_pinch()

func _handle_pinch() -> void:
    var points = _touch_points.values()
    var dist = points[0].distance_to(points[1])
    if _last_pinch_distance > 0:
        var factor = dist / _last_pinch_distance
        zoom_changed.emit(factor)
    _last_pinch_distance = dist
---

## بخش نهم: PERFORMANCE — اندروید

### Texture Settings (در Import)
Format: ETC2 (VRAM Compressed)
Mipmaps: On
Filter: Linear
Repeat: Disabled (برای UI sprites)
Max Size: 2048x2048 (هیچ texture‌ای بزرگ‌تر نباشه)
### Object Pooling برای world map tiles

`gdscript
# scripts/utils/ObjectPool.gd
extends Node

var _pools: Dictionary = {}
[6/30/26 7:14 AM] aDmin: func get_object(scene_path: String) -> Node:
    if not _pools.has(scene_path):
        _pools[scene_path] = []
    var pool: Array = _pools[scene_path]
    for obj in pool:
        if not obj.visible:
            obj.visible = true
            return obj
    # Pool خالیه، instance جدید بساز
    var new_obj = load(scene_path).instantiate()
    pool.append(new_obj)
    add_child(new_obj)
    return new_obj

func return_object(obj: Node) -> void:
    obj.visible = false

### Frame Budget
Target: 60 FPS on Snapdragon 665+
_process() فقط برای: timer countdown، camera
_physics_process() استفاده نشه (بازی turn-based نیست real-time)
سنگین‌ترین کارها (JSON parse، calculation) در call_deferred() یا thread

---

## بخش دهم: تسک‌های باقی‌مانده (فاز ۲)

### PHASE 2A — Android Conversion (اول انجام بده)
- [ ] **2A-1** Project settings → landscape lock، renderer=mobile، safe area setup
- [ ] **2A-2** تمام صحنه‌های موجود را از portrait/desktop به landscape بازطراحی کن
- [ ] **2A-3** ResourceBar را horizontal و کامل پیاده‌سازی کن
- [ ] **2A-4** AdvisorBar را vertical سمت راست پایین بذار
- [ ] **2A-5** Back button handler و exit dialog
- [ ] **2A-6** SafeAreaManager اضافه و به همه UI panels وصل کن
- [ ] **2A-7** HapticManager اضافه کن، به تمام دکمه‌های اصلی وصل کن

### PHASE 2B — Commander System
- [ ] **2B-1** CommanderConfig.gd با حداقل ۶ commander
- [ ] **2B-2** CommanderSystem.gd (leveling، skill unlock)
- [ ] **2B-3** CommanderPanel.tscn — نمایش portrait، level، skills، equip به march
- [ ] **2B-4** وصل کردن commander به attack flow در NetworkManager

### PHASE 2C — Combat Upgrade
- [ ] **2C-1** CombatSystem.gd با formation و commander modifiers
- [ ] **2C-2** BattleScene.tscn — animated، landscape layout
- [ ] **2C-3** Round timer (5 min)، retreat button در rounds 3/6/9
- [ ] **2C-4** Projectile pool برای battle animation
- [ ] **2C-5** CombatReport بهبود یافته — per-round breakdown با chart

### PHASE 2D — Defense & Builder
- [ ] **2D-1** Defensive buildings اضافه به BuildingConfig (watchtower، cannon، harbor chain، vault)
- [ ] **2D-2** Builder system — dual builder، builder status bar در HUD
- [ ] **2D-3** Beginner protection (72h) — نمایش shield icon روی town

### PHASE 2E — Daily Loop
- [ ] **2E-1** QuestSystem.gd + QuestPanel.tscn
- [ ] **2E-2** EventSystem.gd + EventPanel.tscn
- [ ] **2E-3** Daily login reward popup
- [ ] **2E-4** NotificationManager — schedule local notifications برای builder finish، research، incoming attack

### PHASE 2F — Polish
- [ ] **2F-1** Gesture handler برای WorldMap (pinch zoom + pan)
- [ ] **2F-2** ObjectPool برای island tiles
- [ ] **2F-3** تمام texture ها → ETC2 verify
- [ ] **2F-4** Android export → APK sign → test روی دستگاه واقعی
- [ ] **2F-5** Performance profiler — target 60fps روی mid-range

---

## قوانین AGENT

1. **اول بخوان، بعد بنویس** — `cat` همه فایل‌های موجود قبل از هر تغییر
2. **landscape اجباریه** — هیچ UI element ای نباید برای portrait طراحی بشه
3. **touch targets حداقل 88px** — در 1920×1080 base resolution
4. **هیچ pay-to-win** — Ambrosia فقط speed-up و cosmetic
5. **منابع Ikariam حفظ بشه** — Wood, Marble, Crystal, Sulfur, Wine, Gold
6. **جزایر حفظ بشه** — سیستم جزیره‌ای و shared buildings حفظ بشه
7. **combat سریع‌تر از Ikariam** — حداکثر ۱ ساعت per battle، ۵ دقیقه per round
8. **Signal-based communication** — هیچ get_node با path مستقیم بین scenes
9. **Android renderer** — همیشه `gl_compatibility` نه `forward+`
10. **بعد از هر task** output بده:

✅ TASK [2A-1] COMPLETE
Modified: project.godot, autoloads/SafeAreaManager.gd
Next: [2A-2] — Landscape layout conversion for existing scenes
`