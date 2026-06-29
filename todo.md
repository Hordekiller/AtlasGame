# GameMB — Roadmap و چک‌لیست کامل پروژه ایکاریم

> **نسخه پروژه:** 0.2.0  
> **موتور:** Godot 4.7  
> **هدف:** بازی استراتژیک شهرسازی الهام‌گرفته از Ikariam با UI فارسی و پشتیبانی Landscape  
> **وضعیت کلی:** ~55–60% — لایه شبیه‌سازی قوی، UI و یکپارچه‌سازی ناقص

---

## فهرست

1. [وضعیت فعلی](#۱-وضعیت-فعلی)
2. [Roadmap فازبندی‌شده](#۲-roadmap-فازبندی‌شده)
3. [منابع تصویری موجود](#۳-منابع-تصویری-موجود)
4. [منابع تصویری گم‌شده / Placeholder](#۴-منابع-تصویری-گم‌شده--placeholder)
5. [منابع تصویری از اینترنت (پیشنهادی)](#۵-منابع-تصویری-از-اینترنت-پیشنهادی)
6. [ریسپانسیو و Landscape — چک‌لیست کامل](#۶-ریسپانسیو-و-landscape--چک‌لیست-کامل)
7. [باگ‌ها و یکپارچه‌سازی فوری](#۷-باگ‌ها-و-یکپارچه‌سازی-فوری)
8. [سیستم‌های بازی — وضعیت و TODO](#۸-سیستم‌های-بازی--وضعیت-و-todo)
9. [صحنه‌ها و UI پنل‌ها](#۹-صحنه‌ها-و-ui-پنل‌ها)
10. [صدا، ذخیره، i18n](#۱۰-صدا-ذخیره-i18n)
11. [اولویت‌بندی اجرا](#۱۱-اولویت‌بندی-اجرا)

---

## ۱. وضعیت فعلی

| بخش | وضعیت | درصد تقریبی |
|-----|--------|-------------|
| منوی اصلی (جدید/بارگذاری/خروج) | ✅ انجام شده | 85% |
| تولید جهان (۲۰ جزیره) | ✅ انجام شده | 80% |
| شبکه شهر و ساختمان | ✅ انجام شده | 75% |
| اقتصاد (تولید/مصرف/جمعیت) | ✅ انجام شده | 75% |
| پژوهش (۴۴ تکنولوژی) | ✅ انجام شده | 75% |
| نقشه جهان | ⚠️ نیمه‌کاره | 55% |
| تجارت بین شهرها | ⚠️ نیمه‌کاره (باگ) | 55% |
| استعمار | ⚠️ نیمه‌کاره | 50% |
| ذخیره/بارگذاری | ⚠️ نیمه‌کاره | 65% |
| نظامی / واحدها | ❌ تقریباً خالی | 10% |
| مشاوران (Advisor UI) | ❌ فقط اسپرایت | 15% |
| صدا | ❌ وجود ندارد | 0% |
| تنظیمات | ❌ Stub | 5% |
| UI ریسپانسیو Landscape | ⚠️ جزئی | 40% |

**Autoloadها:** `Globals`, `GameState`, `EconomyManager`, `BuildingManager`, `ResearchManager`, `WorldManager`, `TimeManager`, `UIManager`, `SaveManager`, `EventBus`, `UITheme`

**ساختار پوشه‌ها:**
```
GameMB/
├── Globals/           # enumها، EventBus، UITheme
├── Scripts/Core/      # مدیران بازی
├── Scripts/Military/  # MilitaryManager (autoload نشده)
├── Scenes/Menu/       # MainMenu
├── Scenes/Game/       # Game, HUD, CityView, WorldMap, پنل‌ها
├── Scenes/Building/   # Building.tscn
└── Assets/
    ├── Textures/      # Buildings, Resources, UI, World, Advisor, Units, Environment
    └── Shaders/       # water, glow, fire (استفاده نشده)
```

---

## ۲. Roadmap فازبندی‌شده

### فاز ۰ — رفع باگ‌های بحرانی (۱–۲ هفته)

- [ ] اضافه کردن `EconomyManager.change_resource(city_id, rtype, delta)` — تجارت و استعمار crash می‌کنند
- [ ] اتصال `BuildingInfo.tscn` به HUD (جایگزینی Panel خالی)
- [ ] اصلاح سیگنال `EventBus.building_selected` → `_on_building_selected_signal(city_id, grid_pos)`
- [ ] فراخوانی `Game.update_all()` در `_ready()` برای بازی جدید
- [ ] افزودن تب‌های SPECIAL و REDUCTION به پالت ساختمان HUD
- [ ] اصلاح map اسپرایت: کلید `workshop` (نه فقط `workshop_crystal`)
- [ ] ذخیره `time_speed` و `selected_city_id` در SaveManager

### فاز ۱ — UI/UX و Landscape (۲–۳ هفته)

- [ ] پیاده‌سازی سیستم Layout ریسپانسیو (جایگزین مقادیر ثابت 1920px)
- [ ] Safe Area برای HUD بالا/پایین روی همه رزولوشن‌ها
- [ ] Scale پنل‌های مودال (Research, Trade, Colonize, BuildingInfo) بر اساس viewport
- [ ] Scroll افقی برای CategoryBar در عرض‌های کم (< 1280px)
- [ ] Grid ساختمان‌ها: تعداد ستون پویا (۴ → ۳ → ۲)
- [ ] CityView: دوربین و background وابسته به viewport (نه 512,384 ثابت)
- [ ] WorldMap: ocean tile grid متناسب با viewport
- [ ] Touch: pinch-zoom، drag، hit area دکمه‌ها ≥ 44px
- [ ] اتصال `UIManager.set_notification_container()` به HUD
- [ ] فعال‌سازی `Assets/Fonts/GameTheme.tres` یا ساخت Theme resource
- [ ] UI سرعت زمان (TimeManager speed 0–10) در HUD

### فاز ۲ — تکمیل منابع تصویری (۲–۴ هفته)

- [ ] اسپرایت اختصاصی برای ۸ ساختمان fallback (construct.png)
- [ ] `island_crystal.jpg` برای جزایر کریستال
- [ ] استفاده از `island_active.png`, `city_red.png` در WorldMap
- [ ] Advisor panel کامل (mayor, scientist, general, diplomat)
- [ ] Scroll UI (scroll_bg, scroll_mid, scroll_open/closed) برای پنل‌ها
- [ ] آیکون Action Points
- [ ] شهروندان: اسپرایت PNG به‌جای procedural 8×12
- [ ] Shader آب برای WorldMap/CityView (`water.gdshader`)
- [ ] Shader glow ساختمان در حال ساخت (`building_glow.gdshader`)
- [ ] انیمیشن کشتی روی نقشه جهان (`ship_transport.png`)

### فاز ۳ — گیم‌پلی اصلی (۳–۵ هفته)

- [ ] محدودیت استعمار بر اساس سطح Palace
- [ ] Marketplace UI با `Globals.MARKETPLACE_RATIOS`
- [ ] نمایش مسیرهای تجاری روی WorldMap
- [ ] الزام Port/Shipyard برای تجارت دریایی
- [ ] اعمال `unlock_unit` از ResearchManager
- [ ] ثبت `MilitaryManager` به autoload
- [ ] UI آموزش واحد در Barracks/Shipyard
- [ ] ۴ واحد اول: slinger, hoplite, ship_raft, ship_cargo
- [ ] CitizenSystem: تأثیر gameplay (رضایت، حرکت واقع‌گرایانه)

### فاز ۴ — Polish و انتشار (۲–۳ هفته)

- [ ] منوی تنظیمات (صدا، زبان، کیفیت)
- [ ] سیستم i18n با فایل‌های `.po` فارسی/انگلیسی
- [ ] ۵ اسلات ذخیره (فعلاً فقط slot 0 کامل)
- [ ] README و CHANGELOG
- [ ] تست Android landscape روی small/normal/large/xlarge
- [ ] بهینه‌سازی texture atlas
- [ ] صداهای UI، ساختمان، دریا، موسیقی پس‌زمینه

---

## ۳. منابع تصویری موجود

### ساختمان‌ها (`Assets/Textures/Buildings/`)
| فایل | استفاده |
|------|---------|
| `1.png`–`19.png` | اسپرایت ساختمان‌ها (ID عددی Ikariam-style) |
| `ground.png` | کاشی زمین شبکه شهر |
| `construct.png` | fallback ساختمان‌های بدون اسپرایت |

### منابع (`Assets/Textures/Resources/`)
| فایل | منبع |
|------|------|
| `wood.png`, `marble.png`, `glass.png`, `wine.png` | منابع اصلی |
| `gold.png`, `food.png`, `stone.png`, `crystal.png`, `sulfur.png` | منابع ثانویه |
| `gold.jpg`, `research_time.png` | طلا، زمان پژوهش |
| `island_wood.jpg`, `island_marble.jpg`, `island_glass.jpg` | پس‌زمینه جزیره |
| `island_wine.jpg`, `island_sulfur.jpg` | پس‌زمینه جزیره |

### محیط (`Assets/Textures/Environment/`)
| فایل | وضعیت استفاده |
|------|---------------|
| `city_bg.jpg`, `city_blue.png` | ✅ CityView |
| `city_red.png`, `city_constr.png` | ❌ preload شده، رسم نشده |
| `forest.png`, `forest_active.png`, `flag.png` | ❌ استفاده نشده |
| `island_0.jpg`, `ocean.jpg` | ⚠️ جزئی |

### نقشه جهان (`Assets/Textures/World/`)
| فایل | وضعیت |
|------|--------|
| `ocean.png` | ✅ |
| `island.png` | ✅ |
| `island_active.png` | ❌ preload، رسم نشده |

### UI (`Assets/Textures/UI/`) — ۳۵+ فایل
`background.jpg`, `nav_bg.png`, `close.png`, `close_hover.png`, `cross.png`, `check.png`,  
`btn_world.png`, `btn_city.png`, `btn_min.png`, `btn_max.png`, `btn_upgrade.jpg`, `btn_downgrade.jpg`, `btn_island.jpg`,  
`ship_transport.png`, `scientist.png`, `citizen.png`, `population.png`, `happy.png`, `time.png`, `city_icon.png`,  
`production.png`, `transport.png`, `military.png`, `income.png`, `growth.png`, `corruption.png`, `upkeep.png`,  
`crown.png`, `premium.png`, `tavern.png`, `msg.png`, `journey_time.png`,  
`scroll_bg.png`, `scroll_mid.png`, `scroll_open.png`, `scroll_closed.png`

### مشاوران (`Assets/Textures/Advisor/`)
`mayor.png`, `mayor_active.png`, `scientist.png`, `scientist_active.png`,  
`general.png`, `general_active.png`, `diplomat.png`, `diplomat_active.png`, `container.png`

### واحدها (`Assets/Textures/Units/`)
`1.png`–`6.png`, `units_mini.png` — **هیچ‌کدام در گیم‌پلی استفاده نشده**

### Shaderها (`Assets/Shaders/`) — **هیچ‌کدام در صحنه‌ها متصل نشده**
`water.gdshader`, `building_glow.gdshader`, `glow_postprocess.gdshader`, `particle_fire.gdshader`

---

## ۴. منابع تصویری گم‌شده / Placeholder

### فایل‌های گم‌شده
- [ ] `Assets/Fonts/GameTheme.tres` — در project.godot کامنت شده، وجود ندارد
- [ ] `Assets/Textures/Resources/island_crystal.jpg` — جزایر کریستال fallback می‌گیرند
- [ ] آیکون `ACTION_POINTS` — در Globals مسیر icon ندارد

### ساختمان‌های با fallback `construct.png`
- [ ] `alchemist_tower` — برج کیمیاگر
- [ ] `dump` — زباله‌دان
- [ ] `sea_chart_archive` — آرشیو نقشه‌های دریایی
- [ ] `pirate_fortress` — قلعه دزدان دریایی
- [ ] `steam_workshop` — کارگاه بخار
- [ ] `flying_machine_workshop` — کارگاه ماشین پرنده
- [ ] `workshop` — کارگاه (کلید map اشتباه: `workshop_crystal`)
- [ ] `hideout` — مخفیگاه

### اسپرایت‌های مشترک / بازیافت‌شده (نیاز به تمایز بصری)
| ساختمان | اسپرایت فعلی | اشتراک با |
|---------|--------------|-----------|
| `marketplace` | 1.png | `town_hall` |
| `shipyard` | 13.png | `port` |
| `carpenter` | 14.png | `quarry` |
| `architect` | 2.png | `lumberjack` |
| `optician` | 6.png | `glassblower` |
| `firework_test` | 17.png | — |
| `wine_press_building` | 5.png | `vineyard` |

### Placeholderهای procedural (جایگزین با asset واقعی)
- [ ] شهروندان: 8×12 pixel procedural (`CitizenSystem.gd`)
- [ ] Highlight/badge ساختمان: ImageTexture procedural (`Building.gd`)
- [ ] PlaceholderTexture2D اگر `ground.png` نباشد

---

## ۵. منابع تصویری از اینترنت (پیشنهادی)

> **توجه:** قبل از استفاده، لایسنس هر منبع را بخوانید. CC0 = بدون attribution اجباری.

### ساختمان‌ها و معماری یونانی (CC0 / رایگان)

| منبع | URL | لایسنس | کاربرد در GameMB |
|------|-----|--------|------------------|
| LPC Ancient Greek Architecture | https://opengameart.org/content/lpc-compatible-ancient-greek-architecture | CC0 | ساختمان‌های temple, barracks, academy |
| Temple and Ruins Assets | https://opengameart.org/content/temple-and-ruins-assets | CC0 | palace, museum, temple |
| CC0 Isometric Tiles Collection | https://opengameart.org/content/cc0-isometric-tiles | CC0 | guard tower, barracks, castle, stable |
| Medieval Strategy Sprite Pack 16x16 | https://opengameart.org/content/toens-medieval-strategy-sprite-pack-v10-16x16 | CC0 | واحدهای کوچک، آیکون نظامی |
| Japanese buildings isometric mockup | https://opengameart.org/content/japanese-buildings-isometric-strategy-game-mockup | CC0 | الهام layout isometric |

### آب، دریا، جزیره (CC0)

| منبع | URL | لایسنس | کاربرد |
|------|-----|--------|--------|
| 1000+ Isometric Floor Tiles (Water) | https://opengameart.org/content/1000-isometric-floor-tiles | CC0 | `ocean.png`، tile دریا WorldMap |
| Water Update Pack | https://opengameart.org/content/1000-isometric-floor-tiles | CC0 | انیمیشن آب Shader |
| 300+ Isometric Overworld Tiles | https://opengameart.org/content/300-isometric-overworld-tiles | CC0 | terrain جزیره |
| Kenney Road Tiles Water Expansion | https://opengameart.org/content/isometric-road-tiles-water-expansion | CC0 | آبشار، پل، رودخانه |
| Kenney Assets (اصلی) | https://kenney.nl/assets | CC0 | UI icons، buttons، panels |

### UI و آیکون (CC0)

| منبع | URL | کاربرد |
|------|-----|--------|
| Kenney Game Icons | https://kenney.nl/assets/game-icons | آیکون resource، action، menu |
| Kenney UI Pack | https://kenney.nl/assets/ui-pack | scroll، panel، button states |
| OpenGameArt UI Collection | https://opengameart.org/art-search-advanced?keys=ui+icons | close، check، cross |

### واحدها و نظامی (CC0)

| منبع | URL | کاربرد |
|------|-----|--------|
| Greek Hypaspist + Persian Archer | https://opengameart.org/content/greek-hypaspist-persian-foot-archer-pegasus-pony | slinger, hoplite |
| LPC Sprites Collection | https://opengameart.org/content/lpc-collection | واحدهای پایه |
| Isometric Ships | جستجو: `isometric ship` در opengameart.org | ship_raft, ship_cargo |

### شهروندان و NPC

| منبع | URL | کاربرد |
|------|-----|--------|
| LPC Base Characters | https://opengameart.org/content/lpc-base-assets-sprites-map-tiles | citizen sprites |
| Universal LPC Spritesheet | https://opengameart.org/content/lpc-medieval-fantasy-character-sprites | شهروندان متحرک |

### صدا (CC0)

| منبع | URL | کاربرد |
|------|-----|--------|
| OpenGameArt Sound Effects | https://opengameart.org/art-search-advanced?keys=&field_art_type_tid=13 | UI click، build، ocean |
| Kenney Audio | https://kenney.nl/assets?q=audio | ambient، UI |
| HuggingFace OpenGameArt-CC0 Dataset | https://huggingface.co/datasets/nyuuzyou/OpenGameArt-CC0 | جستجوی bulk asset |

### پولی / Pay-what-you-want (اختیاری — کیفیت بالاتر)

| منبع | URL | قیمت | توضیح |
|------|-----|------|-------|
| Ancient Buildings 64×64 (NinjaGame_Dev) | https://ninjagame-dev.itch.io/ancient-buildings-30-64x64-isometric-buildings | $5 | 30 ساختمان isometric 64×64 — **سایز دقیق tile پروژه** |
| Ancient Buildings Classical (Beelim) | https://beelim-solutions.itch.io/ancient-buildings-1-classical-building-sprites | $1.50 | 28 ساختمان یونانی/رومی |
| Greek Temple/Statue Pack | https://captainskolot.itch.io/greek-temple-statue-assets-pixelart-pixel-art-sprite-chest-pack-for-rpg-fant | $2.49 | temple، statue، ruins |

### نقشه دانلود → مسیر پروژه

```
دانلود asset → Assets/Textures/[Buildings|Resources|UI|World|Units|Environment]/
→ Import در Godot → به‌روزرسانی Globals.gd sprite_map / UITheme.gd
→ تست در CityView.tscn و HUD.tscn
```

---

## ۶. ریسپانسیو و Landscape — چک‌لیست کامل

### تنظیمات فعلی (`project.godot`)
```ini
viewport: 1920×1080
stretch/mode: canvas_items
stretch/aspect: expand
Android: force_landscape=true, disable_screen_rotation=true
support: small, normal, large, xlarge
allow_hidpi: true
```

### ✅ انجام شده
- [x] Android force landscape
- [x] Stretch mode canvas_items + expand
- [x] Game.tscn root: full rect anchor
- [x] HUD TopBar: anchor چپ/راست
- [x] WorldMap: pinch zoom + touch drag
- [x] UITheme: BUTTON_MIN_SIZE = 44px (touch target)

### ❌ انجام نشده — باید پیاده شود

#### A. زیرساخت Layout
- [ ] ایجاد `Scripts/Core/ResponsiveLayout.gd` یا گسترش UIManager
- [ ] گوش دادن به `NOTIFICATION_WM_SIZE_CHANGED` / `get_viewport().size_changed`
- [ ] محاسبه `scale_factor = min(viewport.x / 1920, viewport.y / 1080)`
- [ ] تعریف breakpoints:
  - [ ] **XL:** ≥ 1920×1080 (design baseline)
  - [ ] **L:** 1600×900 – 1919
  - [ ] **M:** 1280×720 – 1599 (tablet landscape)
  - [ ] **S:** 960×540 – 1279 (phone landscape)
  - [ ] **XS:** < 960 (compact phone)

#### B. MainMenu (`Scenes/Menu/MainMenu.tscn`)
| مورد | مشکل فعلی | اقدام |
|------|-----------|-------|
| Decor bars | عرض ثابت **1920px** | anchor full width + scale |
| دکمه‌ها | 220×48 ثابت | min_size + scale_factor |
| Title icon | 80×80 ثابت | scale با viewport |
| Background | background.jpg | expand_mode + aspect keep |

#### C. HUD (`Scenes/Game/HUD.tscn` + `HUD.gd`)
| مورد | مقدار ثابت فعلی | اقدام |
|------|-----------------|-------|
| TopBar height | 56px | `UITheme.TOP_BAR_HEIGHT * scale` |
| BottomBar height | 88px | `UITheme.BOTTOM_BAR_HEIGHT * scale` |
| ResourceBar | offset ±300px | anchor center + max width |
| CitySection | 200px | shrink/expand |
| CategoryBar | offset_right=**1920** | anchor_right=1.0 |
| Action buttons | 36×36 | min 44×44 touch |
| Building palette grid | 4 col × 64×64 | ستون پویا 2–4 |
| BuildingInfo panel | 350px ثابت | 25–30% viewport width |
| NotificationLabel | center fixed | margin از safe area |

#### D. پنل‌های مودال
| پنل | سایز فعلی | Landscape S | Landscape M | Landscape L/XL |
|-----|-----------|-------------|-------------|----------------|
| ResearchPanel | 500×400 | 90%×80% | 500×400 | 550×450 |
| TradePanel | 500×300 | 90%×70% | 500×300 | 550×350 |
| ColonizeDialog | 350×200 | 85%×60% | 350×200 | 400×220 |
| BuildingInfo | 350×? | slide from right 30% | 350px | 380px |

- [ ] همه پنل‌ها: `anchors_preset = CENTER` + `size` proportional
- [ ] ScrollContainer برای محتوای بلند در TradePanel/ResearchPanel
- [ ] دکمه Close: hit area ≥ 44×44

#### E. CityView (`Scenes/Game/CityView.gd`)
| مورد | مشکل | اقدام |
|------|------|-------|
| TILE_SIZE | 64 ثابت | scale zoom نه tile |
| Camera position | (512, 384) ثابت | center on grid |
| Background | scale 1.5×1.2 ثابت | fit viewport minus HUD bars |
| GRID_SIZE | 16 | OK — logic not visual |
| Zoom default | 0.8 | clamp برای S/M/L |
| HUD overlap | دوربین زیر TopBar/BottomBar | camera limit rect = viewport - bars |

#### F. WorldMap (`Scenes/Game/WorldMap.gd`)
| مورد | مشکل | اقدام |
|------|------|-------|
| Ocean tiles | loop 2000×2000 | dynamic based on camera |
| Island spacing | 200px | scale با zoom |
| Island radius | 80px | min touch target 88px |
| cols | 5 ثابت | responsive grid |
| Labels | font size ثابت | Theme override scaled |

#### G. Building (`Scenes/Building/Building.gd`)
- [ ] Progress bar height 6px → scale
- [ ] Selection highlight → scale با zoom
- [ ] Touch hit area ساختمان ≥ 48×48 در zoom پایین

#### H. Android / Mobile Landscape
- [ ] تست روی 960×540 (small)
- [ ] تست روی 1280×720 (normal)
- [ ] تست روی 1920×1080 (large/xlarge)
- [ ] Safe area insets (notch، navigation bar)
- [ ] `InputEventScreenTouch` برای همه دکمه‌های HUD
- [ ] جلوگیری از accidental back با ui_cancel
- [ ] `display/window/handheld/orientation` = landscape

#### I. UITheme (`Globals/UITheme.gd`)
- [ ] تبدیل constants به functions: `get_top_bar_height() -> int`
- [ ] Font size scaling: title 24→18 on S, body 16→14 on S
- [ ] Resource icon: 20×20 → 16–24 based on scale
- [ ] Building button: 64×64 → 48–72 based on scale

#### J. تست ریسپانسیو — Checklist QA
- [ ] 1920×1080 — baseline
- [ ] 1600×900 — laptop
- [ ] 1366×768 — common laptop
- [ ] 1280×720 — tablet landscape
- [ ] 1024×600 — small tablet
- [ ] 960×540 — phone landscape
- [ ] 2560×1080 — ultrawide
- [ ] تغییر سایز window در runtime — بدون overlap
- [ ] همه متن فارسی readable در S
- [ ] پالت ساختمان scroll افقی در XS
- [ ] BuildingInfo قابل بستن در همه سایزها
- [ ] WorldMap pinch zoom 0.5–2.0

---

## ۷. باگ‌ها و یکپارچه‌سازی فوری

| # | باگ | فایل | اولویت |
|---|-----|------|--------|
| 1 | `change_resource()` وجود ندارد | `EconomyManager.gd` / `WorldManager.gd` | 🔴 Critical |
| 2 | BuildingInfo متصل نیست | `HUD.tscn`, `Game.tscn` | 🔴 Critical |
| 3 | Signal building_selected اشتباه | `HUD.gd` | 🔴 Critical |
| 4 | update_all() در new game | `Game.gd` | 🟠 High |
| 5 | تب SPECIAL/REDUCTION نبود | `HUD.gd` | 🟠 High |
| 6 | workshop sprite key | `Globals.gd` | 🟡 Medium |
| 7 | island_crystal.jpg نبود | `WorldMap.gd` | 🟡 Medium |
| 8 | time_speed save نشده | `SaveManager.gd` | 🟡 Medium |
| 9 | colonize limit palace | `WorldManager.gd` | 🟡 Medium |
| 10 | unlock_unit enforce نشده | `ResearchManager.gd` | 🟡 Medium |
| 11 | MARKETPLACE_RATIOS unused | `Globals.gd` | 🟢 Low |
| 12 | MainMenu v0.1.0 label | `MainMenu.tscn` | 🟢 Low |

---

## ۸. سیستم‌های بازی — وضعیت و TODO

### ۳۳ نوع ساختمان
<details>
<summary>لیست کامل (کلیک برای باز کردن)</summary>

| ID | نام فارسی | دسته | Tier |
|----|-----------|------|------|
| lumberjack | چوب‌بر | RESOURCE | 1 |
| quarry | معدن سنگ | RESOURCE | 1 |
| farm | مزرعه | RESOURCE | 1 |
| vineyard | تاکستان | PRODUCTION | 2 |
| glassblower | شیشه‌گر | PRODUCTION | 2 |
| marble_quarry | معدن مرمر | RESOURCE | 2 |
| academy | آکادمی | RESEARCH | 1 |
| warehouse | انبار | STORAGE | 1 |
| town_hall | تالار شهر | INFRASTRUCTURE | 1 |
| barracks | پادگان | MILITARY | 2 |
| port | بندر | INFRASTRUCTURE | 2 |
| temple | معبد | CULTURE | 2 |
| workshop | کارگاه | PRODUCTION | 3 |
| sawmill | کارگاه چوب‌بری | PRODUCTION | 2 |
| wall | دیوار دفاعی | MILITARY | 2 |
| tavern | میخانه | CULTURE | 2 |
| museum | موزه | CULTURE | 3 |
| palace | کاخ | SPECIAL | 4 |
| governor_residence | اقامتگاه فرماندار | SPECIAL | 3 |
| hideout | مخفیگاه | SPECIAL | 3 |
| marketplace | بازار | INFRASTRUCTURE | 2 |
| shipyard | کارخانه کشتی‌سازی | MILITARY | 3 |
| carpenter | نجار | REDUCTION | 2 |
| architect | معمار | REDUCTION | 2 |
| optician | عینک‌ساز | REDUCTION | 2 |
| firework_test | آتشبازی | REDUCTION | 2 |
| wine_press_building | شراب‌فشاری | REDUCTION | 2 |
| alchemist_tower | برج کیمیاگر | PRODUCTION | 3 |
| dump | زباله‌دان | INFRASTRUCTURE | 1 |
| sea_chart_archive | آرشیو نقشه‌های دریایی | SPECIAL | 3 |
| pirate_fortress | قلعه دزدان دریایی | MILITARY | 4 |
| steam_workshop | کارگاه بخار | PRODUCTION | 4 |
| flying_machine_workshop | کارگاه ماشین پرنده | MILITARY | 5 |

</details>

### ۱۴ نوع منبع
WOOD, MARBLE, GLASS, WINE, GOLD, FOOD, STONE, CRYSTAL, SULFUR, POPULATION, WORKERS, RESEARCH_POINTS, SATISFACTION, ACTION_POINTS

### ۴۴ تکنولوژی (۵ دسته)
Economy, Military, Science, Navigation, Culture — stub: `trade_network`, `diplomacy`

### ۲۷ نوع واحد (enum) — فقط ۴ تا در MilitaryManager
MILITIA, SWORDSMAN, HOPLITE, … — نیاز به UI و autoload

---

## ۹. صحنه‌ها و UI پنل‌ها

| صحنه | مسیر | وضعیت اتصال |
|------|------|-------------|
| MainMenu | `Scenes/Menu/MainMenu.tscn` | ✅ Main scene |
| Game | `Scenes/Game/Game.tscn` | ✅ |
| CityView | `Scenes/Game/CityView.tscn` | ✅ |
| WorldMap | `Scenes/Game/WorldMap.tscn` | ✅ (hidden) |
| HUD | `Scenes/Game/HUD.tscn` | ✅ |
| ResearchPanel | `Scenes/Game/ResearchPanel.tscn` | ✅ |
| TradePanel | `Scenes/Game/TradePanel.tscn` | ✅ |
| ColonizeDialog | `Scenes/Game/ColonizeDialog.tscn` | ✅ |
| Building | `Scenes/Building/Building.tscn` | ✅ dynamic |
| BuildingInfo | `Scenes/Game/BuildingInfo.tscn` | ❌ orphan |
| BuildingPalette | `Scenes/Game/BuildingPalette.tscn` | ❌ orphan |

### پنل‌های UI
1. **TopBar** — شهر، زمان، ۵ منبع، ۴ action
2. **BottomBar** — ۷ تب دسته + grid ساختمان
3. **BuildingInfo** — جزئیات/ارتقا/کارگر (طراحی شده، وصل نشده)
4. **ResearchPanel** — درخت پژوهش
5. **TradePanel** — مسیر تجاری
6. **ColonizeDialog** — نام مستعمره
7. **NotificationLabel** — پیام موقت
8. **Advisor Panel** — ❌ طراحی نشده (فقط texture)

---

## ۱۰. صدا، ذخیره، i18n

### صدا — TODO
- [ ] `Assets/Audio/SFX/` — click, build, upgrade, demolish, notification
- [ ] `Assets/Audio/Ambient/` — ocean, city, tavern
- [ ] `Assets/Audio/Music/` — main menu, city, world map
- [ ] AudioBus: Master, Music, SFX, UI
- [ ] تنظیم volume در Settings

### ذخیره — TODO
- [ ] slot 1–4 UI در MainMenu
- [ ] save: time_speed, selected_city_id, selected_building_pos
- [ ] autosave هر N روز بازی
- [ ] export/import save (اختیاری)

### i18n — TODO
- [ ] `translations/fa.po`, `translations/en.po`
- [ ] فعال‌سازی `locale/translations` در project.godot
- [ ] جایگزینی stringهای hardcoded فارسی با `tr()`

---

## ۱۱. اولویت‌بندی اجرا

### این هفته (Critical Path)
1. `change_resource()` → unblock trade/colonize
2. Wire BuildingInfo → unblock building management
3. Fix building_selected signal
4. `update_all()` on new game

### هفته ۲–۳ (Landscape MVP)
5. ResponsiveLayout + size_changed handler
6. Fix CategoryBar 1920px + modal scaling
7. CityView camera safe area
8. Touch targets 44px

### هفته ۴–۶ (Assets + Gameplay)
9. Download CC0 Greek buildings from OpenGameArt
10. island_crystal + 8 missing building sprites
11. Advisor panel + scroll UI
12. MilitaryManager autoload + barracks UI

### هفته ۷+ (Polish)
13. Shaders (water, glow)
14. Audio CC0 from Kenney/OpenGameArt
15. i18n + Settings + 5 save slots
16. Android device testing matrix

---

## پیوست — ابعاد Hardcoded (مرجع سریع)

```
project.godot          → 1920×1080
UITheme.gd             → TOP 56, BOTTOM 88, BTN 44×36, ICON 20, BUILD 64
HUD.gd / HUD.tscn      → TOP 56, BOTTOM 88, actions 36, category 70×30, palette 64, info 350
MainMenu               → btn 220×48, decor 1920×8, icon 80
CityView               → TILE 64, GRID 16, cam 512×384, zoom 0.8
WorldMap               → spacing 200, radius 80, ocean 200×200, map 2000×2000
Building               → tile 64, progress 6
CitizenSystem          → MAX 20, wander 80, sprite 8×12
ResearchPanel          → 500×400
TradePanel             → 500×300
ColonizeDialog         → 350×200
BuildingInfo           → header 48, icons 44/32/28, btn h=36
```

---

*آخرین بررسی: ۲۹ ژوئن ۲۰۲۶ — بر اساس codebase v0.2.0*
