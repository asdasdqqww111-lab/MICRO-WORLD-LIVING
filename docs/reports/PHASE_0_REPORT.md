# PHASE 0 — FOUNDATION

**الحالة: IMPLEMENTED / TESTED (منطقيًا) — التصدير والتحقق البصري BLOCKED**

## 1) المهام المنجزة

| # | المهمة | النتيجة |
|---|---|---|
| 1 | مستودع Git محلي `MICRO-WORLD-LIVING` | ✅ فرع `arena/886df73a-micro-world-living` |
| 2 | مشروع Godot 4.3 Compatibility Renderer | ✅ `rendering_method="gl_compatibility"` (و`.mobile` أيضًا) |
| 3 | بنية المجلدات المطلوبة | ✅ `scripts/{core,player,camera,combat,creatures,world,ui,save,android,data}` + `scenes/…` + `assets/…` + `resources/…` + `docs/reports/` |
| 4 | Autoloads: GameManager, SceneManager, SaveManager, SettingsManager | ✅ + `EventBus` إضافي |
| 5 | Main Menu: New Game / Continue / Settings / Quit | ✅ `scripts/ui/main_menu.gd` (زر Continue معطّل تلقائيًا إن لا يوجد حفظ) |
| 6 | Android Export Preset (Compatibility) | ✅ `export_presets.cfg` (arm64-v8a, immersive, ETC2/ASTC) |
| 7 | Godot Export Templates (.tpz) | ❌ **BLOCKED**: كل تنزيلات GitHub Releases تُعاد توجيهها إلى `objects.githubusercontent.com` وهو محجوب في بيئة البناء. لم يُثبَّت أي template. |
| 8 | أول commit + هذا التقرير | ✅ |

### ملاحظة عن المحرك

تم بناء Godot 4.3 من الشيفرة المصدرية داخل البيئة (لا يوجد binary جاهز):
`scons platform=linuxbsd target=editor x11=no wayland=no alsa=no … module_openxr_enabled=no`
لأن البيئة بلا GPU/X11 وبلا apt. الناتج يعمل `--headless` فقط — وهو كافٍ لاستيراد
الأصول ولتشغيل الاختبارات المنطقية، وغير كافٍ لأي تحقق بصري أو لأداء.

## 2) الملفات المنشأة

- `project.godot` — 1280×720، `canvas_items` stretch، landscape، 60Hz، طبقات فيزياء مسمّاة.
- `export_presets.cfg` — Android، حزمة `com.microworldliving.game`، نسخة 0.1 (code 1).
- `icon.svg`, `.gitignore` (يستثني `.godot/` و`build/` و`*.apk`).
- `scripts/core/{event_bus,settings_manager,scene_manager,game_manager,save_manager,input_setup}.gd`
- `scenes/main_menu/main_menu.tscn` + `scripts/ui/main_menu.gd`

## 3) الأصول

لا أصول في هذه المرحلة. القرارات المتخذة (KayKit للسكلتون/المباني/الأثاث، بيئة Dungeon
من KayKit، Wolf/Slime إجرائية) موثقة في `docs/ASSET_LICENSE_MANIFEST.md` مع سبب
استبعاد Quaternius وKenney وPoly Haven (كلها محجوبة الشبكة من بيئة البناء).

## 4) الأنظمة التي تعمل

- `GameManager` يملك الحالة (stats/inventory/quests/skills/world) ويصدر الحالة عبر `EventBus`.
- `SaveManager` JSON + schema v3 + هجرة v1→v3 + رفض النسخ الأحدث + كتابة ذرّية.
- `SettingsManager` يحفظ `user://settings.cfg` ويطبّق 3 مستويات رسوميات + صوت.
- `SceneManager` انتقالات مع Fade وإلغاء الإيقاف المؤقت قبل التبديل.
- `InputSetup` يبني InputMap كاملة في وقت التشغيل (لوحة مفاتيح + فأرة).
- Main Menu: New Game / Continue / Settings / Delete save / Quit.

## 5) الاختبارات + النتائج

| اختبار | النتيجة |
|---|---|
| `godot --headless --path . --quit` (فتح المشروع) | PASS — لا أخطاء تحميل |
| استيراد الأصول `--headless --import` | PASS (انظر PHASE_1) |
| Main Menu: أزرار + حالة Continue | PASS في اختبار المشهد (الزر يُبنى ويقرأ حالة الحفظ) |
| Export preset موجود | PASS (ملف صالح، لكن التصدير BLOCKED) |
| ASSET_LICENSE_MANIFEST.md | PASS (116 ملفًا، 22.3 MB) |

## 6) الأداء

لا قياس ممكن (لا Renderer). القرارات الجاهزة: MSAA حسب الجودة، مسافة ظل 45/70م،
ضباب معطّل على Low، مدى رؤية 90/140/200م.

## 7) المشكلات المتبقية

- لا export templates → لا تصدير APK من البيئة.
- لا GPU/X11 → لا تحقق بصري.
- لا أدوات صوت (Kenney محجوب).

## 8) الحالة النهائية

`IMPLEMENTED` لكل مهام المرحلة عدا #7 (`BLOCKED` بسبب الشبكة).
`TESTED` منطقيًا عبر الاختبارات الآلية. `VERIFIED`: صفر — لا هاتف، لا APK.

---

## تحديث 2026-11-12 — نتيجة تشغيل المحرك الحقيقي

المحرك: `4.3.stable.custom_build` (بُني من المصدر). **هذه المرحلة: IMPLEMENTED + TESTED (headless)**،
وما زالت **NOT VERIFIED على جهاز حقيقي**.

ما أُثبت آليًا في هذه المرحلة: بناء المحرك من المصدر، استيراد 206 ملفًا، `--quit` = 0، تحميل كل قواعد البيانات، إنشاء `.godot/` نظيف.

Commit: `ba7749f` · القياس الكامل: `docs/reports/headless_test_results.txt` (113/113) ·
سجل التشغيل والعيوب المُصلحة: `docs/reports/TEST_RUN_LOG.md`.
