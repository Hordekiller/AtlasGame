# 🏛️ AtlasGame — Game Design Document

> نسخه ۰.۴ | آخرین به‌روزرسانی: ۳۰ ژوئن ۲۰۲۶
> الهام: Ikariam | Rise of Kingdoms | Clash of Clans
> پلتفرم: Android (Landscape) | iOS (آینده)

---

## ۱. Core Concept

AtlasGame یک استراتژی اقتصادی-نظامی در دنیای جزیره‌ای یونان باستان است. بازیکن به‌عنوان فرمانروای یک شهر-کشور (Polis) شروع کرده و با مدیریت اقتصاد، تحقیق، دیپلماسی و جنگ، امپراتوری خود را گسترش می‌دهد.

**Unique Selling Points:**
- سیستم Commander الهام از Rise of Kingdoms با ۶ فرمانده قابل ارتقا
- نبرد نوبتی ۱۲ راند با ۶ فورمیشن
- ۱۳ منبع اقتصادی با زنجیره تولید و مصرف
- جهان deterministic با ۲۰+ جزیره و شهرهای NPC پویا
- ۳۸ نوع ساختمان در ۸ دسته

---

## ۲. Player Progression Curve

```
Level   Time to Reach   Unlocks                      Goal
─────────────────────────────────────────────────────────────
 1-3    0-10 min        Town Hall, Lumberjack, Farm  اولین شهر
 4-6    10-30 min       Academy, Research            اولین تحقیق
 7-9    30-60 min       Barracks, Slinger            اولین سرباز
10-12   1-2 hrs         Port, Colonize               ۲ جزیره
13-15   2-4 hrs         Shipyard, Navy               ۳ جزیره
16-20   4-8 hrs         Palace level 3               ۵ جزیره
21-30   8-24 hrs        Steam Giant                  ۱۰ جزیره
31-40   24-48 hrs       Flying Machine               ۱۵ جزیره
41-50   48+ hrs         Legendary Commander          ۲۰ جزیره (برد)
```

> **MVP Target:** بازیکن تا قدم ۱۵ (۴-۸ ساعت گیم‌پلی) پیش برود

---

## ۳. Economy System

### ۳.۱. Resources Table

| ID | Name | تولید پایه | مصرف پایه | منبع تولید | اولویت مصرف |
|----|------|-----------|-----------|-----------|------------|
| WOOD | چوب | ۲/ثانیه | ۰.۵/ثانیه | چوب‌بر | ساخت |
| STONE | سنگ | ۱.۵/ثانیه | ۰.۳/ثانیه | معدن | ساخت |
| FOOD | غذا | ۴/ثانیه | جمعیت×۰.۱ | مزرعه | جمعیت > ساخت |
| GOLD | طلا | ۱/ثانیه | واحد×۰.۵ | معدن طلا | نظامی > تجارت |
| WINE | شراب | ۱/ثانیه | میخانه×۱ | تاکستان | رضایت |
| MARBLE | مرمر | ۱/ثانیه | ۰.۱/ثانیه | معدن مرمر | ساخت سطح بالا |
| GLASS | شیشه | ۰.۸/ثانیه | ۰.۲/ثانیه | شیشه‌گر | ساخت سطح بالا |
| CRYSTAL | کریستال | ۰.۵/ثانیه | ۰.۱/ثانیه | کارگاه | تحقیق |
| SULFUR | گوگرد | ۰.۵/ثانیه | ۰.۱/ثانیه | برج کیمیاگر | نظامی |
| RESEARCH_PTS | پژوهش | ۱/ثانیه | — | آکادمی | تحقیق |
| POPULATION | جمعیت | +۰.۱/ثانیه | غذا×۰.۰۵ | تالار شهر | — |
| SATISFACTION | رضایت | ۱۰۰ پایه | — | میخانه+معبد+موزه | — |

### ۳.۲. Production Formula

```
net_production = base_production × (1 + level_bonus + commander_bonus)
                × (1 - corruption_%) - consumption
                
level_bonus = level × 0.1
corruption_% = min(cities_outside_capital × 0.05, 0.5)
                - governor_residence_level × 0.05
```

### ۳.۳. Population Formula

```
max_population = town_hall_level × 50 + Σ(farm_level × 10)
growth_rate = food_surplus × 0.1 + satisfaction × 0.002 - housing_ratio × 0.05
housing_ratio = current_population / max_population

if food < 0: population -= abs(food) × 0.01  (starvation)
if satisfaction < 30: growth_rate × 0.5       (unrest)
```

### ۳.۴. Satisfaction Formula

```
satisfaction = base(100)
    + tavern_level × 5  (consuming wine)
    + temple_level × 4
    + museum_level × 3
    - corruption_% × 10
    - overcrowding × 20
    - city_count × 2
    
min: 0 | max: 200
```

---

## ۴. Building System

### ۴.۱. Building Categories

| Category | Count | رنگ Placeholder | مثال |
|----------|-------|-----------------|------|
| RESOURCE | ۴ | 🟢 سبز | چوب‌بر، معدن، مزرعه |
| PRODUCTION | ۶ | 🟡 زرد | تاکستان، شیشه‌گر، کارگاه بخار |
| RESEARCH | ۱ | 🟣 بنفش | آکادمی |
| STORAGE | ۱ | 🔵 آبی | انبار |
| MILITARY | ۸ | 🔴 قرمز | پادگان، کارخانه کشتی، توپ |
| INFRASTRUCTURE | ۵ | 🔵 آبی | تالار شهر، بندر، بازار |
| CULTURE | ۳ | 🟠 طلایی | معبد، میخانه، موزه |
| SPECIAL | ۴ | ⚪ سفید | کاخ، مخفیگاه، اقامتگاه |
| REDUCTION | ۵ | 🟤 قهوه‌ای | نجار، معمار، عینک‌ساز |

### ۴.۲. Construction Time

| Tier | Base Time | با Builder Lv1 | با Builder Lv2 |
|------|-----------|----------------|----------------|
| 1 | ۵ ثانیه | ۵ ثانیه | ۳ ثانیه |
| 2 | ۱۲ ثانیه | ۱۲ ثانیه | ۸ ثانیه |
| 3 | ۲۵ ثانیه | ۲۰ ثانیه | ۱۵ ثانیه |
| 4 | ۴۵ ثانیه | ۳۵ ثانیه | ۲۵ ثانیه |
| 5 | ۷۵ ثانیه | ۵۵ ثانیه | ۴۰ ثانیه |

```
formula: actual_time = base_time × (1 - builder_level × 0.1)
```

### ۴.۳. Worker Allocation

| Tier | Workers Needed | Production Boost per Worker |
|------|---------------|---------------------------|
| 1 | ۲ | +۵۰٪ |
| 2 | ۴ | +۲۵٪ |
| 3 | ۶ | +۱۵٪ |
| 4 | ۱۰ | +۱۰٪ |
| 5 | ۱۵ | +۵٪ |

---

## ۵. Research Tree

### ۵.۱. Branches

| Branch | Technologies | Focus |
|--------|-------------|-------|
| 🛡️ Economy | ۸ tech | تولید مواد، ظرفیت انبار |
| ⚔️ Military | ۱۰ tech | واحدها، دفاع، توپ |
| 🔬 Science | ۶ tech | کریستال، کارگاه بخار، پرواز |
| ⚓ Naval | ۶ tech | کشتی، کاوش، استعمار |

### ۵.۲. Economy Branch

```
Lumber Supremacy (T1)        → sawmill unlock
  │                              
  ├─Market Economy (T2)      → marketplace unlock
  │   └─Trade Empires (T3)   → trade contracts +1
  │
  ├─Wine Culture (T2)        → vineyard unlock
  │   └─Hospitality (T3)     → tavern unlock
  │       └─Cultural Heritage (T4) → museum unlock
  │
  ├─Improved Lumber (T2)     → lumberjack +50% prod
  │   └─Carpentry (T3)       → carpenter unlock
  │
  └─Marble Usage (T2)        → marble_quarry unlock
      └─Architecture (T3)    → architect unlock
```

### ۵.۳. Military Branch

```
Fortification (T1)           → wall unlock
  │
  ├─Military Training (T2)   → barracks + slinger
  │   ├─Iron Weapons (T3)    → swordsman unlock
  │   │   └─Steam Power (T4) → steam_giant + workshop
  │   └─Gunpowder (T3)       → cannon + sulphur_carabineer
  │
  ├─Espionage (T2)           → hideout + spy missions
  │   └─Sabotage (T3)        → sabotage mission
  │
  └─Aerial Warfare (T5)      → flying machine workshop
```

### ۵.۴. Research Cost

| Tier | Research Points Needed | Duration (seconds) |
|------|----------------------|-------------------|
| T1 | ۵۰ | ۳۰ |
| T2 | ۱۵۰ | ۶۰ |
| T3 | ۴۰۰ | ۱۲۰ |
| T4 | ۱۰۰۰ | ۳۰۰ |
| T5 | ۲۵۰۰ | ۶۰۰ |

---

## ۶. Combat System

### ۶.۱. Unit Definitions

| Unit | Tier | Type | ATK | DEF | HP | Cost | Row | Special |
|------|------|------|-----|-----|----|------|-----|---------|
| Slinger | ۱ | Ranged | ۵ | ۲ | ۲۰ | W:10, G:5 | Back | — |
| Spearman | ۱ | Infantry | ۵ | ۶ | ۲۵ | W:8, G:6 | Front | Anti-cavalry |
| Militia | ۱ | Infantry | ۳ | ۱ | ۱۵ | W:5, G:2 | Front | Cheap |
| Swordsman | ۲ | Infantry | ۶ | ۵ | ۳۰ | W:12, G:10 | Front | Versatile |
| Archer | ۲ | Ranged | ۷ | ۳ | ۲۰ | W:15, G:8 | Back | Range bonus |
| Hoplite | ۲ | Heavy | ۸ | ۸ | ۴۰ | W:15, G:15 | Front | Shield wall |
| Catapult | ۳ | Siege | ۲۰ | ۳ | ۴۰ | W:40, G:30 | Art | Wall dmg×۳ |
| Mortar | ۴ | Siege | ۳۰ | ۴ | ۳۵ | W:50, G:50 | Art | Wall dmg×۵ |
| Steam Giant | ۴ | Heavy | ۲۰ | ۱۵ | ۸۰ | W:40, G:60 | Front | AoE |
| Ram | ۳ | Siege | ۱۵ | ۱۰ | ۶۰ | W:35, G:25 | Front | Wall dmg×۴ |
| S. Carabineer | ۴ | Ranged | ۱۸ | ۶ | ۳۰ | W:30, G:40 | Back | Snipe |
| Gyrocopter | ۵ | Flying | ۱۵ | ۵ | ۳۰ | W:50, G:80 | Back | Fast |
| Balloon Bomb | ۵ | Flying | ۲۵ | ۲ | ۲۵ | W:60, G:100 | Art | AoE |
| Cook | ۲ | Support | ۱ | ۱ | ۱۵ | W:5, G:10 | Back | Morale +۵ |
| Doctor | ۳ | Support | ۱ | ۲ | ۲۰ | W:10, G:25 | Back | Heal ۱۵% |

### ۶.۲. Damage Formula

```
raw_damage = attacker_attack × formation_attack_mod × commander_attack_mod
effective_defense = defender_defense × formation_def_mod × commander_def_mod
                + wall_defense

damage_per_unit = raw_damage × random(0.85, 1.15)
losses_per_unit = max(1, ceil(damage_per_unit / effective_defense))
```

### ۶.۳. Counter System

| Attacker | vs | Bonus |
|----------|----|-------|
| Swordsman | Spearman | +۲۰٪ |
| Spearman | Cavalry | +۳۰٪ |
| Cavalry | Archer | +۲۵٪ |
| Archer | Slinger | +۱۵٪ |
| Hoplite | Swordsman | +۱۰٪ |
| Steam Giant | Infantry | +۲۵٪ (AoE) |
| Gyrocopter | Siege | +۳۰٪ |

### ۶.۴. Formations

| Formation | ATK Mod | DEF Mod | Special |
|-----------|---------|---------|---------|
| Standard | ۱.۰ | ۱.۰ | Balanced |
| Phalanx | ۰.۸ | ۱.۲ | Defense |
| Flanking | ۱.۲ | ۰.۸ | Attack |
| Charge | ۱.۴ | ۰.۵ | First round only |
| Turtle | ۰.۶ | ۱.۵ | Siege defense |
| Ambush | ۱.۳ | ۰.۹ | Surprise round 1 |

### ۶.۵. Battle Resolution

```
for round in 1..12:
    attacker_damage = calculate_damage(attacker)
    defender_damage = calculate_damage(defender)
    
    apply_damage(defender, attacker_damage)
    apply_damage(attacker, defender_damage)
    
    if any_army_wiped():
        winner = other_army
        end_battle()
    
    300s timer per round

if timeout:
    winner = army_with_more_units
```

---

## ۷. Commander System

### ۷.۱. Commander Table

| Commander | Type | Rarity | Base Skill 1 (T1) | Base Skill 2 (T5) | Ultimate (T20) |
|-----------|------|--------|-------------------|-------------------|----------------|
| ناخدا | Naval | Rare | Fleet speed +۱۰٪ | Naval Atk +۱۵٪ | Kraken summon |
| جنگ‌سالار | Ground | Epic | Infantry ATK +۱۰٪ | Charge mode | Warlord frenzy |
| تاکتیسین | Ground | Common | Formation +۵٪ | Retreat cost -۵۰٪ | Perfect strategy |
| معمار | Support | Common | Build speed +۱۵٪ | Resource cost -۱۰٪ | Wonder building |
| جاسوس | Support | Rare | Spy success +۱۵٪ | Mission time -۲۰٪ | Triple agent |
| دریادار | Naval | Legendary | Naval SPD +۲۰٪ | Blockade chance | Storm caller |

### ۷.۲. Leveling

```
EXP_needed(level) = 100 × level
max_level = 50
total_EXP = 127,500

Skill unlock tiers: T1 (Lv1), T2 (Lv5), T3 (Lv10), T4 (Lv20), T5 (Lv35)
```

### ۷.۳. Shard System (برای گاچا)

```
Rarity      Shards to Unlock    Drop Rate
─────────────────────────────────────────
Common      ۱۰                  ۵۰٪
Rare        ۲۵                  ۳۰٪
Epic        ۵۰                  ۱۵٪
Legendary   ۱۰۰                 ۵٪
```

---

## ۸. NPC Factions

### ۸.۱. Faction Table

| Faction | Difficulty | Army Size | Aggression | Economy | Islands | Special |
|---------|-----------|-----------|------------|---------|---------|---------|
| دزدان دریایی | آسان | ۵۰-۲۰۰ | ۰.۷ | Low | ۱-۲ | Raid civ players |
| بربرها | متوسط | ۲۰۰-۵۰۰ | ۰.۴ | Med | ۲-۴ | Infantry focus |
| امپراتوری | سخت | ۵۰۰-۱۰۰۰ | ۰.۶ | High | ۴-۶ | Navy + siege |

### ۸.۲. Hostility System

```
actions_that_increase_hostility:
    colonize_island_near_npc: +۲۰
    attack_npc: +۳۰
    spy_on_npc: +۱۰
    trade_near_npc: +۵

hostility_thresholds:
    ۰-۳۰: Neutral (no action)
    ۳۱-۶۰: Unfriendly (blockade chance)
    ۶۱-۹۰: Hostile (raid chance)
    ۹۱-۱۰۰: War (full assault)

natural_decay: -۱ per 60 seconds (max ۵۰)
```

---

## ۹. Victory & Loss Conditions

### ۹.۱. Win Conditions (هرکدام)

| Condition | Requirement | Approx Time |
|-----------|-------------|-------------|
| Conqueror | Control ۵ islands | ۴-۸ hrs |
| Warlord | Defeat ۳ NPC factions | ۸-۲۴ hrs |
| Developer | City level reaches ۲۰ | ۸-۱۲ hrs |
| Collector | All ۳۸ buildings in one city | ۱۲-۲۴ hrs |

### ۹.۲. Loss Conditions

| Condition | Timer | Grace Period |
|-----------|-------|-------------|
| All cities destroyed | Instant | Beginner Protection ۷۲h |
| Population = ۰ | ۵ days | — |
| Treasury negative | ۳ days | — |

---

## ۱۰. Mobile UX Specs

### ۱۰.۱. Touch Targets

| Element | Min Size | Actual | Notes |
|---------|----------|--------|-------|
| Advisor button | ۸۸×۸۸ | ۸۸×۸۸ | Right column |
| Building on grid | ۴۰-۷۲px | Dynamic | Zoom-dependent |
| Action button | ۸۸×۴۸ | ۸۸×۴۸ | Full width OK |
| Close button | ۴۴×۴۴ | ۴۴×۴۴ | Top-right corner |
| Tab button | ۸۸×۳۶ | ۸۸×۳۶ | Tab container |
| Slider/SpinBox | ۸۸×۳۶ | ۸۸×۳۶ | Input fields |

### ۱۰.۲. Safe Area

```
top_margin = DisplayServer.safe_area().top
bottom_margin = DisplayServer.safe_area().bottom
left_margin = DisplayServer.safe_area().left
right_margin = DisplayServer.safe_area().right
```

**Implementation:** SafeAreaManager autoload — همه پنل‌ها با anchor + margin گوش کنند

### ۱۰.۳. Gesture Map

| Gesture | Action | Scene |
|---------|--------|-------|
| Tap | Select | All |
| Drag (۱ انگشت) | Pan camera | CityView, WorldMap |
| Pinch (۲ انگشت) | Zoom | WorldMap |
| Double-tap | Center on city | WorldMap |
| Swipe down | Close panel | Modal panels |
| Long-press | Tooltip | Buildings, Resources |

---

## ۱۱. Retention Systems

### ۱۱.۱. Daily Rewards (۷ روز)

| Day | Reward | Value |
|-----|--------|-------|
| ۱ | Gold | ۱۰۰ |
| ۲ | Wood | ۱۵۰ |
| ۳ | Research Points | ۵۰ |
| ۴ | Stone | ۱۰۰ |
| ۵ | Wine | ۲۰ |
| ۶ | Crystal | ۱۵ |
| ۷ | Commander Shard (Rare) | ۵ |

### ۱۱.۲. Daily Quests (۶ نوع)

| Quest | Objective | Reward |
|-------|-----------|--------|
| Gatherer | Collect ۵۰۰ wood | Gold ۵۰ |
| Builder | Construct ۱ building | Stone ۱۰۰ |
| Scholar | Gain ۱۰۰ RP | Crystal ۱۰ |
| Recruiter | Train ۱۰ units | Gold ۲۰۰ |
| Explorer | Visit World Map | Wine ۱۰ |
| Loyal | Login | Research ۲۵ |

### ۱۱.۳. Periodic Events

| Event | Duration | Effect |
|-------|----------|--------|
| جشن برداشت | ۲۴h | Food +۵۰٪ |
| تمرین نظامی | ۲۴h | Train time -۳۰٪ |
| بادهای تجاری | ۴۸h | Trade speed ×۲ |
| الهام | ۲۴h | Research +۵۰٪ |

---

## ۱۲. Monetization Hooks (غیرفعال در MVP)

| Hook | Product | Price | Purpose |
|------|---------|-------|---------|
| Gem Pack S | ۵۰۰ gems | $۱.۹۹ | Accelerate |
| Gem Pack L | ۲۰۰۰ gems | $۴.۹۹ | Accelerate |
| Builder Bundle | ۲nd builder | $۲.۹۹ | QoL |
| Monthly Pass | ۳۰d rewards | $۹.۹۹ | Retention |
| Remove Ads | Permanent | $۳.۹۹ | UX |

> **Policy:** قیمت‌ها فقط در production فعال شوند. در Internal/Alpha testing مقدار `0` با LOG نشان دهد.

---

## ۱۳. Performance Targets

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| FPS | ۶۰ | <۳۰ | <۲۰ |
| Frame time | <۱۶ms | >۳۳ms | >۵۰ms |
| RAM | <۵۰۰MB | >۷۰۰MB | >۱GB |
| Nodes/frame | <۲۰۰۰ | >۳۰۰۰ | >۵۰۰۰ |
| Draw calls | <۲۰۰ | >۴۰۰ | >۷۰۰ |
| APK size | <۱۵۰MB | >۲۰۰MB | >۳۰۰MB |
| First load | <۵s | >۱۰s | >۲۰s |

---

## ۱۴. State Serialization Schema

```gdscript
# Save file structure
save_data = {
    version: "0.4.0",
    save_time: 1234567890,
    offline_seconds: 3600,
    
    cities: {
        "city_123": {
            id, name, island_id, player,
            grid_size, resources, buildings{grid_pos: building_data},
            production{}, consumption{},
            research_completed[], research_in_progress,
            units{unit_type: {count, training, training_progress}},
            population, satisfaction,
            warehouse_capacity, defense, position_index, created_at
        }
    },
    islands: {
        "island_0": {
            id, name, index,
            primary_resource, secondary_resource,
            city_positions[], player_cities[], npc_cities[],
            explored
        }
    },
    npc_cities: {
        "npc_0": {
            id, name, island_id, player, grid_size,
            buildings{}, units{}, defense_level,
            army_size, aggression, resources{}
        }
    },
    research: {tech_id: progress},
    units: {},
    trades[], trade_routes{},
    completed_research[],
    game_time, current_day, player_gold, player_gems,
    time_speed, selected_city_id,
    tutorial: {completed_tutorials[]},
    
    # NEW in v0.4:
    army_travels: [{origin, target, units[], commander_id, departure, arrival}],
    training_queues: [{city_id, unit_type, quantity, finish_time}],
    npc_hostility: {npc_id: hostility_level},
    event_timers: [{event_id, remaining_seconds}],
    commander_progress: {commander_id: {level, exp, unlocked_skills[]}},
    daily_reward: {last_claim_day, claim_count, streak}
}
```

---

## ۱۵. System Dependency Graph

```
                          EventBus 🔌
                            │
        ┌───────────────────┼────────────────────┐
        │                   │                    │
   GameState ◄───► EconomyManager           TimeManager
        │                   │                    │
        │            ┌──────┼──────┐            │
        │            │      │      │            │
   BuildingManager  NPC    Spy    Market        │
        │            │      │      │            │
        ├──► ResearchMgr  │      │              │
        │         │       │      │              │
        │         ├──► MilitaryMgr              │
        │         │       │                     │
        │         │  ┌───┴───┐                  │
        │         │  │       │                  │
        └──► CommSys  CombatSystem ◄── FormConfig
                      │
                  BattleScene ◄── ArmyTravel
                  
  Legend:
  ───► = signal dependency
  ◄──► = bidirectional
  ──── = direct call
```

---

## ۱۶. Glossary

| Term | Definition |
|------|------------|
| Polis | شهر-کشور، واحد اصلی بازی |
| Commander | فرمانده با مهارت‌های passive و active |
| Formation | آرایش نظامی مؤثر در نبرد |
| Builder | سازنده (max 2 هم‌زمان) |
| Research Points | امتیاز پژوهش (RP) |
| Satisfaction | رضایت شهروندان (۰-۲۰۰) |
| Corruption | فساد ناشی از شهرهای دور از پایتخت |
| NPC Faction | اردوگاه هوش مصنوعی (دزد، بربر، امپراتوری) |
| Travel Time | زمان حرکت کشتی بین جزایر |
| Offline Catchup | جبران زمان آفلاین (max ۳ روز) |
| Save Slot | اسلات ذخیره (max ۳) |
| Shard | تکه‌های فرمانده برای باز کردن/ارتقا |
| Hostility | سطح خصومت NPC (۰-۱۰۰) |

---

## ۱۷. Appendices

### A. version History

| Version | Date | Changes |
|---------|------|---------|
| ۰.۱.۰ | 2026-03 | Project init, basic economy |
| ۰.۲.۰ | 2026-04 | UI panels + research |
| ۰.۳.۰ | 2026-05 | Combat + Commander + World Map |
| ۰.۴.۰ | 2026-06 | NPC + Tutorial + Battle Animation + Roadmap |

### B. File Map

```
AtlasGame/
├── Globals/          EventBus, GameState, Globals, UITheme
├── Scripts/
│   ├── Core/         Economy, Building, Research, World, Save, Time, Audio
│   ├── Systems/      Combat, Commander, NPC, Spy, Market, Quest, Event, Tutorial
│   ├── Military/     MilitaryManager
│   └── Utils/        ObjectPool
├── Scenes/
│   ├── Game/         Main game scene, CityView, WorldMap, HUD, all panels
│   ├── Menu/         MainMenu
│   └── Building/     Building scene
├── Assets/
│   ├── Textures/     Buildings, Environment, UI, Resources, World
│   ├── Audio/        Music, SFX, Ambient
│   └── Fonts/        GameTheme.tres
└── project.godot
```

---

> **Next Revision Goal:** v0.5 — Early Access Release
> Focus: Fase 0-1 Roadmap (Save Integrity + NPC Faction + Army Deployment + Economy Balance)
