# MICRO WORLD: LIVING — v0.1 (Vertical Slice)

> عالم يعيش بعدك. لكنه يبدأ صغيرًا، ويُختبر، ثم يكبر.

لعبة 3D Low-Poly، منظور الشخص الثالث، تعمل على Android أولًا وبشكل أوفلاين،
مبنية بـ **Godot 4.3** و **GDScript (typed)** و **Compatibility (GLES3)** حصرًا.

---

## الحالة الحقيقية (اقرأ هذا أولًا)

| بند | الحالة |
|---|---|
| كود المشروع + 7 مراحل منفّذة | **IMPLEMENTED** |
| اختبارات آلية (headless) | **TESTED — 113 / 113 نجحت** (`docs/reports/headless_test_results.txt`) |
| بناء المحرك + استيراد + فتح المشروع | **TESTED** — `4.3.stable.custom_build`, `--quit` = 0 (`docs/reports/TEST_RUN_LOG.md`) |
| اختبار على هاتف حقيقي | **BLOCKED** — لا يوجد جهاز، ولا GPU في بيئة البناء |
| بناء APK | **BLOCKED** — لا Android SDK / JDK في البيئة، والشبكة تمنع `dl.google.com` |
| الأداء (Draw Calls / FPS) | **NOT MEASURED** — dummy driver أعطى 0 لكل شيء |
| الرسومات/الواجهة بالعين | **NOT VERIFIED** — لا GPU في البيئة |

**لا يوجد في هذا المستودع أي ادعاء "VERIFIED"**. أول تشغيل حقيقي للمحرك موثّق في
`docs/reports/TEST_RUN_LOG.md` (113 فحصًا، 10 عيوب حقيقية اكتُشفت وأُصلحت). كل ما هو مرئي (الرسوم،
الواجهة، الأنيميشن) وكل ما هو خاص بالأداء يحتاج هاتفًا حقيقيًا — انظر
`docs/reports/PHASE_1_REPORT.md` و `docs/reports/ANDROID_BUILD_REPORT.md`.

---

## ما تحتويه النسخة 0.1

- **عالم 200×200 م**: قرية (6 مبانٍ KayKit) + بئر + سوق + بيوت، غابة (MultiMesh)،
  منزل قابل للدخول (منطقة منفصلة + أثاث KayKit Furniture)، دخول Dungeon (5 غرف).
- **لاعب ثالث الشخصية**: `CharacterBody3D` + `SpringArm3D` مع تصادم كاميرا،
  تكبير بالقرص/العجلة، حركة walk/run/jump، AnimationTree مبني من 95 مقطعًا
  من KayKit Skeletons (idle / walk / run / jump / fall / attack×2 / hit / death).
- **قتال**: هجوم خفيف بمدى قوسي (`intersect_shape`)، كومبو من ضربتين، ستامينا،
  ضرر/دفاع/كريت، عدو يطارد ويهاجم ويموت ويسقط Loot.
- **مخلوقات**: Skeleton (KayKit)، Crypt Skeleton (KayKit)، Wolf و Slime
  (هندسة إجرائية أصلية — لا مصدر CC0 متاح للوصول إليه).
- **NPCs**: حداد (يبيع) + مزارع (مهمة) + حارس (مهمة) مع جدول يومي (عمل/راحة/نوم).
- **مهمتان كاملتان** + Quest Log + مكافآت (XP/Gold/Items).
- **RPG**: Inventory شبكي 20 خانة + 3 خانات تجهيز + Drag & Drop + استخدام،
  XP/Level، Stats، Skill Tree (3 مهارات).
- **حفظ**: JSON بإصدار مخطط (schema v3) + هجرة من v1 + حفظ تلقائي + حفظ يدوي،
  يشمل اللاعب/البنية/المهام/القتلى/الوقت/الطقس/الغارة.
- **عالم حي**: دورة ليل/نهار، مطر، أسعار سوق تتغير يوميًا، غارة Skeletons كل 3 أيام.
- **UI/لمس**: Joystick افتراضي + سحب كاميرا + أزرار (ATK/JUMP/USE/RUN/BAG/LOG/STAT/II)
  + HUD (HP/SP/XP/ساعة/ذهب/تتبّع مهام/إشعارات) + طبقة أداء (F3).

---

## التشغيل

```bash
# 1) استيراد الأصول مرة واحدة (ينشئ .godot/ و ملفات .import)
godot --headless --path . --import

# 2) تشغيل الاختبارات الآلية (تُخرج docs/reports/headless_test_results.txt)
godot --headless --path . tests/test_runner.tscn

# 3) تشغيل اللعبة
godot --path .
```

### التحكم

| فعل | لوحة مفاتيح | لمس |
|---|---|---|
| حركة | WASD / الأسهم | Joystick يسار |
| كاميرا | سحب بالزر الأيمن | سحب النصف الأيمن |
| تكبير | عجلة الفأرة | Pinch |
| هجوم | F / زر الفأرة الأيسر | ATK |
| قفز | Space | JUMP |
| تفاعل | E | USE |
| عدو سريع | Shift | RUN (تبديل) |
| حقيبة/مهام/شخصية | I / J / C | BAG / LOG / STAT |
| إيقاف مؤقت | Esc | II |
| حفظ/تحميل سريع | F5 / F9 | قائمة الإيقاف |
| طبقة الأداء | F3 | قائمة الإيقاف |

---

## بنية المشروع

```
scripts/
  core/       game_manager, scene_manager, save_manager, settings_manager,
              event_bus, input_setup, game, asset_library, character_visual
  player/     player, player_input
  camera/     camera_rig
  combat/     combat, health_component
  creatures/  creature, procedural_models
  world/      world_root, world_builder, world_state, day_night_cycle,
              weather_system, raid_event, market, village_npc, zone_door,
              treasure_chest, loot_drop, interactable
  ui/         ui_root, hud, ui_factory, menu_screen, touch_controls,
              virtual_joystick, camera_drag_area, inventory_screen,
              journal_screen, character_screen, dialog_screen,
              shop_screen, pause_screen, main_menu
  inventory/  inventory
  data/       item_data, item_db, quest_data, quest_db, skill_data, skill_db,
              creature_data, creature_db, character_stats, progression,
              quest_log, skill_tree
  save/       (schema documented in save_manager)
  android/    (touch + performance hooks live in ui/ and core/)
resources/{items,quests,creatures,skills}/*.tres   ← بيانات اللعبة (Data-driven)
scenes/{main_menu,game,player,world,ui}            ← مشاهد رقيقة، البناء بالكود
tests/      test_runner.tscn + test_runner.gd
docs/       ASSET_LICENSE_MANIFEST.md, reports/, KNOWN_ISSUES.md, ARCHITECTURE.md
```

قرار معماري أساسي: **بناء العالم والواجهة بالكود** بدلًا من `.tscn` ضخمة.
السبب: قابلية المراجعة، اختبار headless، وتجنّب أخطاء ملفات المشاهد اليدوية.

---

## الترخيص

- الكود: CC0 / ملكية عامة (استخدمه كما تشاء).
- الأصول: KayKit بترخيص CC0 — انظر `docs/ASSET_LICENSE_MANIFEST.md`.
