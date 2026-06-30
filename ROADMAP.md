# 🗺️ Roadmap انتشار AtlasGame در Google Play

## مسیر ۴۰ مرحله‌ای از پروتوتایپ تا انتشار

```
MVP Ready ──────────────► Early Access ─────────────► v1.0 Release
    │                         │                            │
  فاز ۰-۱                   فاز ۲-۳                      فاز ۴
  (قدم ۱-۱۵)               (قدم ۱۶-۳۰)                 (قدم ۳۱-۴۰)
  Core Loop                Content + Balance           Mobile Polish
```

---

## فاز ۰ — بنیاد (قدم ۱-۵)
> هدف: بازی کرش‌نکند، تایمرها درست کار کنند، سیو/لود سالم باشد

### قدم ۱ — GameStateManager ادغام
- سیستم جدید `GameStateManager.gd` وضعیت کلی بازی را رصد کند
- شرط برد: کنترل ۵ جزیره + شکست ۳ اردوگاه NPC + سطح شهر ۲۰
- شرط باخت: ۳ روز منفی خزانه / ۵ روز صفر جمعیت / نابودی همه شهرها
- `game_won`, `game_lost`, `city_expanded`, `npc_faction_defeated` سیگنال‌ها
- **ادغام** با `GameState.gd` فعلی (داده‌های ذخیره را از GameState بخواند)

### قدم ۲ — Crash Safety Layer
- try/catch در تمام `_process` و `_physics_process` سیستم‌های بحرانی
- null-check بر روی تمام `Engine.get_singleton()` و `get_node()` در BattleScene
- `is_instance_valid()` قبل از هر emit روی EventBus
- autoload startup order: Globals → EventBus → GameState → EconomyManager → BuildingManager → ResearchManager → باقی

### قدم ۳ — Save Integrity + Offline Protection
- ذخیره dual-slot (slot A write, slot B = backup)
- CRC32 checksum درون فایل ذخیره
- `save_game()` قبل از هر emit → `before_save` signal
- آفلاین: `offline_seconds` ذخیره شود؛ در `load_game` TimeManager `catch_up(offline_seconds)` صدا بزند
- کرک: تولید هر ثانیه نباید از ۲× سرعت عادی تجاوز کند (anti-exploit: `min(offline_seconds, 86400 * 3)`)

### قدم ۴ — TimeManager Refactor
- تمرکز delta accumulation: فقط TimeManager `_process(delta)` داشته باشد، بقیه Tick بشنوند
- `tick_1s` (اقتصاد), `tick_10s` (NPC), `tick_60s` (Day change)
- `offline_catchup(seconds)` با کرک anti-exploit بالا
- `time_speed` فقط در TimeManager بماند، بقیه از `TimeManager.time_speed` بخوانند

### قدم ۵ — Mobile Renderer Lock
- projector.godot: `rendering/driver=opengl3_es` (بازگشت兼容)
- `window/size/viewport_width=1920, viewport_height=1080`
- `rendering/textures/vram_compression/import_etc2_astc=true`
- تایید `screen/immersive_mode=true` + `screen/keep_on=true`

---

## فاز ۱ — Core Gameplay Loop (قدم ۶-۱۲)
> هدف: بازیکن از منو تا استعمار جزیره بدون بن‌بست پیش برود

### قدم ۶ — NPC Faction System
- `NPCFactionManager.gd` با حداقل ۳ اردوگاه (آسان، متوسط، سخت)
- هر اردوگاه: `faction_id, aggression_level, economy_power, army_strength, island_count, hostility_map`
- تیک ۶۰ ثانیه: `if player_army < npc_army * 0.6 → launch raid`
- `npc_attack, npc_trade_blockade, npc_spy_action` اکشن‌ها
- ادغام با `NPCSystem.gd` موجود

### قدم ۷ — Army Deployment + Travel
- `send_army(origin_city, target_island, units, commander_id)`
- اعتبارسنجی: واحد کافی + commander unlocked + محدوده دریایی
- محاسبه `travel_time = distance * base_speed / (1 + ship_level_bonus)`
- لاک واحدها در origin
- `ArmyTravel` object: `start_time, arrival_time, units, origin, target`
- پس از arrival: شروع نبرد `CombatSystem.create_battle()`
- بازماندگان برگردند، loot اعمال شود، battle report ذخیره

### قدم ۸ — Military Training Pipeline
- `MilitaryManager.train_unit(unit_type, quantity)`
- `validate_research_requirement()` — بررسی `research_completed`
- `deduct_costs()` از EconomyManager
- صف آموزش: `queue_training(unit_type, quantity, finish_time)`
- تکمیل: `unit_training_completed` سیگنال + افزایش `city_units[unit_type].count`
- ذخیره کامل صف (برای reload)

### قدم ۹ — Research → Content Unlock
- `ResearchManager.research_completed` → همه سیستم‌ها بشنوند
- `BuildingManager`: unlock_units + unlock_buildings از research
- `MilitaryManager.get_available_units()` فقط تحقیق‌شده را برگرداند
- `bronze_weapons` → `unlock_units: swordsman, attack_bonus: 10%`

### قدم ۱۰ — Economy Stability Formula
```
population_growth = food_surplus * 0.1 + happiness * 0.02 - housing_deficit * 0.05
if food < 0: population -= abs(food) * 0.01/tic
gold_consumption = sum(unit_upkeep)
corruption_penalty = corruption_% / 100 * total_production
```
- مصرف غذا در اولویت: جمعیت → تولید → نظامی
- `EconomyManager.get_resource_snapshot()` برای ذخیره صحیح

### قدم ۱۱ — Tutorial اولیه کار کند
- `TutorialManager.gd` (قدم ۱-۵): چوب‌بر → کارگر → تحقیق → سرباز → حمله
- مراحل گام‌به‌گام با progressive UI disclosure
- detect completed: `EventBus.building_constructed`, `EventBus.research_completed`
- `tutorial_completed` سیگنال + ذخیره

### قدم ۱۲ — Main Menu → Game → Exit Circle
- منو: دکمه‌های ۸۸px با فاصله ۱۶px
- `MainMenu.gd`: New Game → Tutorial Skip → Load Game → Settings → Exit
- `SaveManager.get_save_slots()` نمایش ۳ اسلات با info
- Settings: Music/SFX volume, Reset Game, About
- خروج: ذخیره خودکار + `get_tree().quit()`

---

## فاز ۲ — اتصال سیستم‌ها و ریتنشن (قدم ۱۳-۲۰)
> هدف: بازیکن انگیزه بازگشت روزانه داشته باشد

### قدم ۱۳ — Daily Rewards Full Cycle
- تأیید `DailyReward.gd` چرخه ۷ روزه ذخیره شود
- `claim_reward(day_index)` → اعمال پاداش به EconomyManager
- ذخیره: `last_claim_day, claim_count, current_streak`
- نوتیفیکیشن: NotificationManager.schedule_daily()

### قدم ۱۴ — Quests و Event tracking
- `QuestSystem.gd` بررسی: quest tracking کامل + تکمیل → پاداش
- `EventSystem.gd`: auto-start در روز مشخص، duration, پایان → cleanup
- پاداش: منابع + buff موقت speed_build, discount, attack_bonus
- ذخیره: `active_quests, completed_quest_ids, event_timers`

### قدم ۱۵ — Commander System Complete
- `CommanderSystem.level_up(commander_id, exp_gained)`
- آنلاک مهارت در Tiers: level 1, 5, 10, 20, 35
- `CommanderPanel`: tab CommanderList + SkillTree + Stats
- اتصال به `CombatSystem._get_commander_mods()` — نرخ اعمال modifier بررسی شود

### قدم ۱۶ — Spy System Complete
- `SpySystem`: بررسی success_rate محاسبه (`spy_level * 10 - target_defense * 2`)
- ۶ مأموریت باید در UI قابل انتخاب باشند
- Mission duration: `dispatch → timer → result`
- کارایی: `hideout` level = max concurrent missions

### قدم ۱۷ — Trade Routes → Economy Integration
- `WorldManager.add_trade_route()` → `EconomyManager`:
  - `schedule_shipment(interval_days, resource_type, amount)`
  - در روز مقرر: کم از مبدأ + زیاد به مقصد
  - `trade_ship_arrived` signal
- `TradePanel`: لیست مسیرها، remove, مقدار و بازه قابل تنظیم
- ذخیره: `trade_routes` در GameState

### قدم ۱۸ — Battle Result → Economy Integration
- `battle_completed` signal → `EconomyManager`:
  - `apply_loot(winner_city_id, loot_dictionary)`
  - `apply_casualties(loser_city_id, casualties)`
- پیروز: `winner gains resources from defender`
- شکست: `loser loses units + resources stolen`

### قدم ۱۹ — HUD Real-time
- `HUD.gd`: اتصال به `EventBus.resource_changed` (نه poll)
- نمایش: طلا، چوب، جمعیت، جمعیت نظامی، رضایت
- آیکون‌های ۳۲px با tooltip مختصر
- `_update_display()` فقط وقتی visible = true

### قدم ۲۰ — Advisor Tips در HUD
- `AdvisorPanel` پیام‌ها متصل به `EventBus.notification_added`
- نمایش در HUD با auto-dismiss ۵ ثانیه
- چرخش پیام‌ها در صورت queue طولانی

---

## فاز ۳ — محتوا و بالانس (قدم ۲۱-۲۸)
> هدف: بازی حداقل ۳۰ دقیقه گیم‌پلی بدون تکرار داشته باشد

### قدم ۲۱ — Balance Pass: Economy
- جدول منابع: `production_rate, consumption_rate, storage_default`
- `TIER_BUILD_TIME`: tier 1 = 5s, tier 2 = 12s, tier 3 = 25s, tier 4 = 45s, tier 5 = 75s
- `MILITARY_COST_BALANCE`: سرباز tier 1 = چوب ۵ + طلا ۲ + ۵ ثانیه
- جمعیت اولیه: ۱۰ نفر → با food surplus هر تیک +۰.۵

### قدم ۲۲ — Balance Pass: Combat
- `DAMAGE_FORMULA: attack_power / (defense + wall_defense) * random(0.8, 1.2)`
- commander modifier: `attack +10% per tier, defense +5% per tier`
- formation modifier: `falang = defense +20%, attack -10%`
- `UNIT_COUNTERS`: hoplite > cavalry > archer > slinger

### قدم ۲۳ — ۵ جزیره جدید + City Variations
- `WorldManager.ISLAND_COUNT = 25`
- شهرهای NPC: `level = distance_from_player_city * 0.5 + 1`
- `ENEMY_TYPES`: Barbarian (easy), Pirate (medium), Empire (hard)
- city defense: `base_defense + wall_level * 5 + garrison * 2`

### قدم ۲۴ — Sound Effect Full Coverage
- AudioManager: ۲۰+ SFX مسیر (آموزش، ساخت، ارتقا، نبرد، کلیک، خطا، نوتیفیکیشن، استعمار)
- `play_sfx(name)` با volume sliders
- Preload در `_ready()` → `preload("res://Assets/Audio/SFX/*.wav")`
- priority queue برای SFX (نظامی > اقتصادی > UI)

### قدم ۲۵ — Notification Manager Android
- `NotificationManager.schedule(timestamp, title, body, channel)`
- کانال‌ها: `daily_reward`, `attack_warning`, `building_complete`, `trade_arrival`
- `schedule_building_completion(city_id, building_id, finish_time)`
- `schedule_npc_attack(npc_id, eta_seconds)`

### قدم ۲۶ — World Event + Seasonal Content
- `EventSystem`: ۴ رویداد با duration 24-72h
- `harvest_festival: food_production +50%`
- `military_drill: unit_train_time -30%`
- UI: نشان badge روی EventPanel در advisor bar
- رویدادها در save ذخیره شوند

### قدم ۲۷ — Commanders Pool Expansion
- ۶ فرمانده فعلی → ۱۰ فرمانده
- `RARITY_DISTRIBUTION`: 3 common, 4 rare, 2 epic, 1 legendary
- Commander `shard system`: `shards_to_unlock = rarity_base * multiplier`
- ذخیره: `owned_commanders, shards, equipped_id`

### قدم ۲۸ — String Table (Persian)
- `Globals.STRING_TABLE`: تمام متن‌های UI
- `tr(key)` wrapper برای راست‌چین
- RTL confirmation: `Window.fallback_stretch` + Label `text_direction = "rtl"`
- تاریخ: `ShamsiDate` از روی timestamp

---

## فاز ۴ — انتشار موبایل (قدم ۲۹-۴۰)
> هدف: APK سایز < ۱۵۰MB، رتبه A در Google Console

### قدم ۲۹ — Texture Optimization
- ETC2/ASTC اجباری
- `texture_import` settings: `compress/hint=3d` برای ساختمان، `detect_3d=false` برای UI
- `atlas` ساختن: `TexturePacker` → یک atlas 2048×2048 برای ساختمان‌ها
- حذف فایل‌های unused از Assets

### قدم ۳۰ — APK Size < 150MB
- حذف فایل‌های .import بلااستفاده
- `export_presets.cfg`: `binary_format/embed_pck=false`
- فشرده‌سازی: `gapws` + ZIP
- `split apk`: جدا کردن assets معمولی و HD

### قدم ۳۱ — Low-end Device Testing
- Godot profiler: `rendering/vram`, `physics/collision_count`, `nodes/frame`
- حداقل: GPU Mali-400, RAM 2GB
- کاهش: `max_particles=50`, `shader_quality=low`, `shadow_atlas=512`

### قدم ۳۲ — Gesture Polish
- Swipe HUD → scroll panel
- Tap-hold → tooltip اطلاعات دقیق
- Double-tap → zoom to city
- Edge pan → camera در CityView
- همه gestureها با `InputEventScreen*` و `InputEventMagnifyGesture`

### قدم ۳۳ — Input Debounce
- `Button` wrapper: `_pressed` با cooldown 200ms
- `touch_target_check`: `rect_size >= Vector2(88, 88)` validation در scene root
- `event_accepted = false` تا double-fire نشود

### قدم ۳۴ — Crash Logging
- `CrashHandler.gd`: `Godot.crash_handler` راپورت
- `_on_crash()` → save `crash_log.txt` → upload در next launch
- (اختیاری) Firebase Crashlytics Godot plugin

### قدم ۳۵ — Google Play Console Setup
- Developer account: $25
- `pkg_name`: `com.gamemb.ikariam`
- Content rating questionnaire
- Privacy policy URL
- Test tracks: Internal → Closed Alpha → Open Beta → Production

### قدم ۳۶ — Monetization Hooks (غیرفعال)
- `IAPManager.gd`: `shop_products = [gem_pack_small, gem_pack_large, builder_bundle]`
- `RewardedAd.gd`: `reward_daily_boost()`
- `Subscription.gd`: `builder_queue_2, worker_speed`
- **فقط hook** — `is_iap_enabled = false` در Build
- `StoreButton` در HUD + `StorePanel` stub

### قدم ۳۷ — Rate App Dialog
- `RateDialog.gd`: بعد از روز ۳ یا island colonization
- `native_rate()` → Google Play (Android) / App Store (iOS)
- ذخیره: `rate_shown = true`

### قدم ۳۸ — GDPR / Privacy
- `PrivacyDialog.gd`: در اولین لانچ
- Consent: analytics + personalized ads
- `consent_given` ذخیره در ConfigFile

### قدم ۳۹ — CI/CD Pipeline
- GitHub Actions: `export_android.sh` با `gradle build`
- `build.godot` headless export
- محلی: `export_presets.cfg` + `.env` با KEYSTORE_PASSWORD
- خودکار: increment version code

### قدم ۴۰ — Launch Checklist
- [ ] بازی ۱۰ دقیقه بدون بن‌بست
- [ ] Tutorial از منو تا استعمار
- [ ] Save/load ۵ بار متوالی
- [ ] Airplane mode test
- [ ] Low battery test
- [ ] ۵۰ play-through (دستی/اتوماتیک)
- [ ] APK scan (VirusTotal)
- [ ] Privacy Policy live
- [ ] Store listing (Persian + English)
- [ ] Screenshots: ۴ landscape + feature graphic

---

## جدول اولویت

| قدم | عنوان | Priority | Effort | Dependency |
|-----|-------|----------|--------|------------|
| ۱ | GameStateManager | 🔴 Critical | 1d | - |
| ۲ | Crash Safety | 🔴 Critical | 2d | 1 |
| ۳ | Save Integrity | 🔴 Critical | 2d | 1 |
| ۴ | TimeManager | 🔴 Critical | 1d | - |
| ۵ | Renderer Lock | 🔴 Critical | 0.5d | - |
| ۶ | NPC Faction | 🔴 Critical | 3d | 4 |
| ۷ | Army Deployment | 🔴 Critical | 3d | 6 |
| ۸ | Military Pipeline | 🔴 Critical | 2d | 7, 9 |
| ۹ | Research Unlock | 🔴 Critical | 1d | - |
| ۱۰ | Economy Formula | 🔴 Critical | 2d | 4 |
| ۱۱ | Tutorial | 🟡 High | 3d | 6 |
| ۱۲ | Main Menu | 🟡 High | 2d | - |
| ۱۳ | Daily Rewards | 🟡 High | 1d | 10 |
| ۱۴ | Quests | 🟡 High | 2d | 10 |
| ۱۵ | Commander | 🟡 High | 2d | - |
| ۱۶ | Spy System | 🟡 High | 1d | 6 |
| ۱۷ | Trade Routes | 🟡 High | 1d | 10 |
| ۱۸ | Battle Economy | 🟡 High | 1d | 10 |
| ۱۹ | HUD Real-time | 🟡 High | 1d | - |
| ۲۰ | Advisor Tips | 🟡 High | 0.5d | - |
| ۲۱ | Econ Balance | 🟢 Medium | 3d | 10 |
| ۲۲ | Combat Balance | 🟢 Medium | 2d | 7 |
| ۲۳ | Islands | 🟢 Medium | 2d | 6 |
| ۲۴ | Sound Cover | 🟢 Medium | 2d | - |
| ۲۵ | Notifications | 🟢 Medium | 1d | - |
| ۲۶ | Events | 🟢 Medium | 1d | 14 |
| ۲۷ | Commanders | 🟢 Medium | 2d | 15 |
| ۲۸ | String Table | 🟢 Medium | 1d | - |
| ۲۹ | Textures | 🟢 Medium | 2d | - |
| ۳۰ | APK Size | 🟢 Medium | 1d | 29 |
| ۳۱ | Low-end Test | 🔵 Low | 3d | 5 |
| ۳۲ | Gesture UI | 🔵 Low | 2d | - |
| ۳۳ | Input Debounce | 🔵 Low | 1d | - |
| ۳۴ | Crash Logging | 🔵 Low | 1d | - |
| ۳۵ | Google Console | 🔵 Low | 2d | - |
| ۳۶ | Monetization | 🔵 Low | 2d | - |
| ۳۷ | Rate Dialog | 🔵 Low | 0.5d | - |
| ۳۸ | GDPR | 🔵 Low | 1d | - |
| ۳۹ | CI/CD | 🔵 Low | 2d | - |
| ۴۰ | Launch | 🔵 Low | 1d | همه |

**Total Effort:** ~60 days (توسعه‌دهنده full-time)
**MVP Minimum (قدم ۱-۱۲):** ~20 days
