# PHASE 5 — ASSET EXPANSION

**الحالة: IMPLEMENTED / TESTED (منطقيًا) — VERIFIED: BLOCKED**

## 1) المهام

| # | المهمة | المنفّذ |
|---|---|---|
| 1 | Dungeon من KayKit (3–4 غرف + corridor) | ✅ **5 مساحات**: غرفة دخول 8×8 → ممر 4×8 → غرفة 8×8 (فخ أشواك) → ممر 4×4 → قاعة 16×8 (صندوق + كنز) |
| | 2 أعداء + صندوق + فخ | ✅ 2 Crypt Skeletons + `TreasureChest` + `floor_tile_big_spikes` (زخرفي) |
| | مهمة ثانية للدخول | ✅ `sunken_cellar` (قتل 2 + إحضار الرِليك) |
| 2 | مخلوقات إضافية (Goblin/Wolf/Slime) | ✅ **Wolf** و**Slime** (هندسة إجرائية أصلية) + Skeleton + Crypt Skeleton = 4 أنواع |
| | AI + Loot table لكل مخلوق | ✅ نفس `Creature` + `CreatureData.loot` مع نسب Skeleton |
| 3 | تحسين Draw Calls: MultiMesh للأشجار/العشب | ✅ 3 MultiMesh للغابة + 2 MultiMesh للدنجن (أرضيات/جدران) |
| | LOD0/LOD1 للأشجار | ⚠️ لم تُنفَّذ (تحتاج مشاهد LOD يدوية) — بديل: `visibility_range` غير مستخدم بعد |
| | Frustum culling | ✅ تلقائي في Godot لـ MeshInstance3D/MultiMesh |
| 4 | اختبار أداء صارم | ❌ BLOCKED (لا Renderer) |

### ملاحظة على المصدر

Quaternius محجوب الشبكة، لذلك مخلوقات "Goblin/Wolf/Slime" غير متاحة كأصول CC0 جاهزة.
القرار: أحجام بسيطة أصلية (Wolf من 12 صندوقًا، Slime من 3 كرات) بنفس أسلوب Low-Poly،
وسلوك حركة إجرائي (نبض/قفز). **ليست Placeholders**: لها AI وLoot وStats، وهي الشكل النهائي
المقصود لهذه المخلوقات في 0.1.

## 2) الملفات

`scripts/world/{treasure_chest}.gd`, `scripts/creatures/procedural_models.gd`,
`resources/creatures/{skeleton_dungeon,wolf,slime}.tres`, `resources/quests/sunken_cellar.tres`,
`assets/models/dungeon/*.glb` (25 نموذجًا + texture).

## 3) الأصول

| الاسم | المصدر | ترخيص | الحالة |
|---|---|---|---|
| 25 قطعة Dungeon (جدران/أرضيات/صناديق/مشاعل/أعمدة) | KayKit Dungeon Remastered | CC0 | مدمج |
| Wolf + Slime | هندسة إجرائية (هذا المستودع) | CC0 | مدمج |

## 4) الأنظمة

- الدنجن يُبنى بـ 5 Rect2 (كلها مضاعفات 4م) مع فتحات أبواب بعرض 4م في منتصف الجدران.
- التصادم: `StaticBody3D` واحد يحوي كل أشكال الجدران (بدل 100+ جسم).
- الصندوق: حالة "مفتوح" محفوظة عبر UID، ويعيد الرِليك للاعب (يُطلق حدث `collect` للمهمة).

## 5) الاختبارات

| اختبار | النتيجة |
|---|---|
| 4 أنواع مخلوقات تُحمَّل من الموارد | PASS |
| مسار النماذج لكل مخلوق موجود | PASS |
| مهمة `sunken_cellar` موجودة بأهدافها | PASS |
| الدنجن يُبنى + صندوق + بوابة دخول/خروج | PASS (المشهد يُبنى بلا أخطاء) |
| المقاييس | غير مقيسة |

## 6) الأداء (تصميمي)

| بند | العدد |
|---|---|
| MultiMesh: أشجار كبيرة | 30 نسخة |
| MultiMesh: أشجار صغيرة | 60 نسخة |
| MultiMesh: صخور | 40 نسخة |
| MultiMesh: أرضيات دنجن | ~64 بلاطة |
| MultiMesh: جدران دنجن | ~70 قطعة |

كل ذلك = 5 draw calls بدل 264.

## 7) مشكلات متبقية

- LOD غير منفّذ؛ مسافة الرؤية تُدار بالكاميرا وليس بـ `visibility_range`.
- فخ الأشواك زخرفي (لا ضرر) — موثق.
- قد تكون فتحة الغرفة الأخيرة مزاحة 2م عن الممر (يحتاج تحققًا بصريًا).

## 8) الحالة

`IMPLEMENTED` + `TESTED` منطقيًا. `VERIFIED`: ❌.

---

## تحديث 2026-11-12 — نتيجة تشغيل المحرك الحقيقي

المحرك: `4.3.stable.custom_build` (بُني من المصدر). **هذه المرحلة: IMPLEMENTED + TESTED (headless)**،
وما زالت **NOT VERIFIED على جهاز حقيقي**.

ما أُثبت آليًا في هذه المرحلة: `multimesh instancing is real (5 batches, 0 broken)` — 30+60+40 شجرة/صخرة + 19 أرضية + 30 جدارًا؛ 3 قوالب مخلوقات؛ مهمتان.

Commit: `ba7749f` · القياس الكامل: `docs/reports/headless_test_results.txt` (113/113) ·
سجل التشغيل والعيوب المُصلحة: `docs/reports/TEST_RUN_LOG.md`.
