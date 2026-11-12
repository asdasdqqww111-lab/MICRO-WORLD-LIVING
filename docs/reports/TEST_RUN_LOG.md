# TEST RUN LOG — أول تشغيل حقيقي للمحرك

**التاريخ:** 2026-11-12 · **الفرع:** `arena/886df73a-micro-world-living`
**المحرك:** `4.3.stable.custom_build` — بُني من المصدر داخل هذا الصندوق (لا يوجد ملف جاهز؛ تنزيل
`release-assets.githubusercontent.com` محجوب).

---

## 1. بناء المحرك (لأن البيئة لا تحتوي Godot)

```
cd /tmp/godot-4.3-stable
PATH=/tmp/bin:$PATH scons platform=linuxbsd target=editor -j2 \
  x11=no wayland=no alsa=no pulseaudio=no dbus=no speechd=no udev=no \
  fontconfig=no touch=no debug_symbols=no optimize=size \
  module_openxr_enabled=no module_webxr_enabled=no
```

- الزمن: **~45 دقيقة** (2 vCPU، 3 GB RAM، 2218 ملف `.o`).
- الناتج: `bin/godot.linuxbsd.editor.x86_64` (92 MB) → نُسخ إلى `/usr/local/bin/godot4`.
- `godot4 --version` → `4.3.stable.custom_build` ✅

## 2. خطوات القبول المنفَّذة

| خطوة | الأمر | النتيجة |
|---|---|---|
| استيراد الأصول | `godot4 --headless --path . --import` | ✅ نظيف، 206 ملف مستورد (`.godot/imported`) |
| فتح المشروع | `godot4 --headless --path . --quit` | ✅ **exit 0**، لا أخطاء تحليل ولا أخطاء تحميل |
| اختبارات القبول | `godot4 --headless --path . tests/test_runner.tscn` | ✅ **113 / 113 نجحت** (شُغّل مرتين متتاليتين، نفس النتيجة) |
| محاولة تصدير APK | `godot4 --headless --path . --export-debug "Android" out.apk` | ❌ `A valid Java SDK path is required` + `A valid Android SDK path is required` — **إعداد التصدير `Android` تعرّف عليه المحرك بشكل صحيح**، والفشل بيئي فقط |

النتيجة الكاملة محفوظة في `docs/reports/headless_test_results.txt` (يُعاد توليدها مع كل تشغيل).

## 3. أخطاء حقيقية اكتُشفت عند أول تشغيل وأُصلحت

| # | الملف | الخطأ | الإصلاح |
|---|---|---|---|
| 1 | `scripts/combat/combat.gd:41` | `Cannot infer the type of "to_target"` — `collider` من `PhysicsShapeQueryParameters3D` من نوع Variant | تحويل صريح `collider as Node3D` + `var to_target: Vector3` |
| 2 | `scripts/world/market.gd:22` | `The variable type is being inferred from a Variant value` (`abs(hash(...))`) | `var seed_value: int = absi(...)` |
| 3 | `scripts/ui/ui_root.gd:146` | `Expected statement, found "Indent"` (سطر `EventBus.screen_changed.emit` مُزاح زيادة) | تصحيح الإزاحة |
| 4 | `tests/test_runner.gd:18` | `Could not find type "double"` | `double` → `float` |
| 5 | `resources/items/*.tres` (14 ملفًا) | `Parse Error: Unexpected identifier: 'ancient_relic0'` — مولد الملفات استخدم `$10`/`$11` ففسّرها bash كـ `${1}0`، فصارت `equip_slot = "none1"` و`icon_color = Color(...)0` | أُعيد توليد كل ملفات الأصناف بـ Python (id/category/stack/value/bonuses/slot صحيحة) |
| 6 | `scripts/data/*_db.gd` | كان يستخدم `DirAccess.dir_exists_absolute` + `get_files_at` | `DirAccess.open(...)` + `dir.get_files()` (أوضح وأكثر أمانًا داخل `res://`) |
| 7 | `scripts/ui/hud.gd` | لا يوجد سجل قياس للأداء على الجهاز | `_write_perf_line()` يكتب `user://perf_log.txt` كل 5 ثوانٍ عندما تكون طبقة الأداء مفعّلة |
| 8 | `scripts/world/world_builder.gd` | جدار المنزل الجنوبي كان مصمتًا ⇒ اللاعب محبوس داخل المنزل | فتحة باب 2 م + إضاءة داخلية (`OmniLight3D` بلا ظلال) + 3 مشاعل Dungeon |
| 9 | `tests/test_runner.gd` | اختبار الـ zoom يقارن `distance` الثابت بدل هدف التقريب | `CameraRig.current_distance()` + مقارنة 0.5 م |
| 10 | `tests/test_runner.gd` | اختبار الـ loot كان يعتمد على ترتيب أبناء `world` (قد يمسك قطرة أخرى) ويجري والمخزن ممتلئ | استخدام العقدة المُعادة من `spawn_loot_drop` + `inventory.clear()` أولًا |

**هذه هي قيمة التشغيل الحقيقي**: 5 من 10 عيوب (1،2،3،4،5) كانت تمنع الإقلاع أصلًا،
وعيب 5 كان سيجعل كل أصناف اللعبة غير موجودة في النسخة النهائية رغم أن الكود "سليم" منطقيًا.

## 4. تغطية المراحل داخل الـ 113 فحصًا

| المرحلة | الفحوص التي تغطيها |
|---|---|
| 0 — الأساس | استيراد نظيف، `--quit` = 0، `ItemDB/QuestDB/SkillDB/CreatureDB` تحمّل 14/2/3/4، AutoLoads، قائمة رئيسية |
| 1 — الشخصية الثالثة | `player character model instantiated`, `animation states resolved`, `player lands`, joystick (3.09 م), `camera yaw`, `camera zoom` |
| 2 — القتال | `player can swing with stamina`, `skeleton takes damage`, `aggroes`, `loot drop`, `loot is collected`, شبكة المخزن + التجهيز (11 فحصًا) |
| 3 — Vertical Slice | landmarks (6 مبانٍ + بئر + سوق)، 3 NPCs، مهمة كاملة (kill ×3 → تسليم → مكافأة)، الأبواب/المنزل/الدنجن، حفظ كل شيء + تحميل + بقاء القتلى مقتولين |
| 4 — أنظمة RPG | منحنى XP (60 → مستوى 2، سقف 20)، المخزن الشبكي والتبديل والتجهيز، 3 مهارات، سجل المهام، سمات/ذهب |
| 5 — توسّع الأصول | `multimesh instancing is real (5 batches)` (30+60+40 شجرة/صخرة + 19 أرضية + 30 جدار دنجن)، 7 مخلوقات، 3 قوالب مخلوقات، مهمتان |
| 6 — العالم الحي | الساعة واليوم، ليل/نهار (`01:00 = night`)، جدول NPC (عمل/راحة/نوم)، أسعار تتغير يوميًا (6 أسعار مختلفة)، ثبات الحالة بعد الحفظ |
| 7 — التلميع | هجرة v1→v3، رفض حفظ تالف، رفض schema أحدث، **10 دورات حفظ/تحميل متتالية** |

## 5. ما زال غير مُتحقَّق (بصراحة)

- **الرسومات على شاشة حقيقية**: البيئة headless بلا GPU ⇒ لم يُرَ أي إطار مرسوم. لا يوجد ادعاء "يبدو جيدًا".
- **الأداء**: `draw calls = 0`, `triangles = 0` (dummy driver). الميزانية (<200 draw call، ≥30 FPS) **لم تُقس**.
- **APK**: لا JDK ولا Android SDK ولا قوالب تصدير ⇒ غير مبني.
- **اللمس على شاشة لمس**: `VirtualJoystick` مُختبر منطقيًا عبر mock، لا عبر إصبع حقيقي.
- **الصوت**: لا يوجد (Kenney محجوب) — انظر `docs/KNOWN_ISSUES.md`.

## 6. إعادة التشغيل

```bash
# إن كان لديك Godot 4.3 جاهز:
./tools/import_and_test.sh          # استيراد + 113 فحصًا
godot --headless --path . --quit    # فحص فتح المشروع
./tools/export_android.sh debug     # بعد تثبيت Android SDK + JDK 17
```

متوقَّع: `113 passed, 0 failed`. (التحذيرات المقصودة أثناء التشغيل: `corrupt save`,
`save version 99 is newer`, `unknown item 'does_not_exist'`, و`SceneTreeTimer` leaks
من `create_timer` في الاختبار — كلها أجزاء من فحوص سلبية مقصودة.)

---

## 7. البناء على GitHub Actions (2026-11-12)

بما أن الصندوق بلا JDK/Android SDK/قوالب تصدير، أُضيف `.github/workflows/android.yml`
الذي يبني الـ APK على `ubuntu-latest`:

| خطوة | النتيجة |
|---|---|
| Godot 4.3-stable + export templates | ✅ تنزيل ناجح (شبكة الـ runner كاملة) |
| `--import` | ✅ |
| 113 فحصًا headless | ✅ 113/113 (البناء يفشل لو فشل فحص واحد) |
| debug keystore + `--export-debug "Android"` | ✅ `micro_world_living.apk` (58,386,088 بايت) |
| `apksigner verify` | ✅ v1 + v2 + v3 |
| `aapt2 dump badging` | ✅ `com.microworldliving.game`, SDK 21→34, label "Micro World: Living" |
| نشر Release | ✅ `v0.1-debug` |

زمن الـ workflow: **~60 ثانية**. التفاصيل الكاملة في `docs/reports/ANDROID_BUILD_REPORT.md`.
**الفارق المهم:** هذا يُثبت أن الملف صالح للتثبيت (بنية + توقيع)، **ولا يُثبت أنه يعمل**؛
ذلك يحتاج هاتفًا.
