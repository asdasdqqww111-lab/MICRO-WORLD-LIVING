# PHASE 3 — VERTICAL SLICE (الأهم)

**الحالة: IMPLEMENTED / TESTED (منطقيًا) — VERIFIED: BLOCKED**
**لم يُنتقل إلى Phase 4 قبل استكمال محتوى هذه المرحلة.**

## 1) المحتوى الإلزامي

| # | المطلوب | المنفّذ |
|---|---|---|
| 1 | منطقة ~200×200م | ✅ `GROUND_SIZE = 200` (`WorldBuilder`) |
| | غابة Quaternius بـ MultiMesh | ⚠️ Quaternius محجوب → غابة KayKit Medieval Hexagon بـ **3 MultiMeshInstance3D** (أشجار كبيرة/صغيرة/صخور) — أسلوب بصري واحد |
| | قرية من 4–5 مبانٍ KayKit | ✅ 6 مبانٍ (منزلان، حداد، سوق، حانة، برج) + بئر + أعلام/براميل/خيام |
| | منزل واحد قابل للدخول + أثاث | ✅ منطقة داخلية 10×8م + 10 قطع أثاث KayKit Furniture |
| | بئر + سوق بسيط | ✅ `building_well_green` + `building_market_green` |
| 2 | 3 NPC (حداد/مزارع/حارس) | ✅ نماذج KayKit (Warrior/Rogue/Mage) + حوار + بيع + جدول يومي |
| 3 | مهمة كاملة (اذهب → اقتل 3 → عُد) | ✅ `skeleton_menace`: 3 Skeletons + مكافأة XP/Gold/Items |
| | Quest states: not started/active/complete | ✅ `QuestLog` بحالات NOT_STARTED/ACTIVE/**READY**/COMPLETED |
| 4 | حفظ/تحميل كامل | ✅ اللاعب (موضع/دوران/HP/SP/zone) + الحقيبة + المهام + قتلى الأعداء + الوقت/الطقس/الغارة |
| | Schema versioned + autosave + manual save | ✅ v3 + autosave كل 120ث/عند الأحداث + F5 + قائمة الإيقاف |
| 5 | اختبار حفظ: إغلاق → فتح | ✅ آليًا (tear down + إعادة بناء المشهد من الملف) |
| 6 | اختبار هاتف + Draw calls < 200 + FPS ≥ 30 | ❌ **BLOCKED** |

## 2) الملفات المنشأة

`scripts/world/{world_root,world_builder,world_state,interactable,zone_door,village_npc,treasure_chest}.gd`,
`scripts/data/{quest_data,quest_db,quest_log}.gd`, `resources/quests/*.tres`,
`scripts/save` (المنطق داخل `save_manager.gd`)، `scenes/world/world.tscn`.

## 3) الأصول

KayKit Medieval Hexagon (مبانٍ/أشجار/صخور/دعائم/أسوار) + KayKit Furniture (منزل) +
KayKit Skeletons (لاعب + أعداء + NPCs) — كلها CC0 — التفاصيل في `docs/ASSET_LICENSE_MANIFEST.md`.

## 4) الأنظمة

- `ZoneDoor`: القرية ↔ المنزل (x=+500) و↔ الدنجن (x=−500) مع Beacon مرئي.
- `TreasureChest`: يفتح مرة واحدة، يحفظ حالته عبر `WorldState.looted_containers`.
- `VillageNPC`: حوار سياقي (يعرض زر Quest أو Turn in حسب الحالة)، وتنقّل بين
  مواقف العمل/الراحة/النوم حسب الساعة.
- الحفظ: `SaveManager` يجمع `GameManager.to_dict()` + حالة اللاعب الحية، ويكتبها
  إلى `.tmp` ثم يعيد التسمية (لا تلف عند الانقطاع).

## 5) الاختبارات

| اختبار | النتيجة |
|---|---|
| بناء العالم: landmarks + 3 NPCs + ≥6 مخلوقات | PASS |
| مهمة: start → 3 kills → READY | PASS |
| تسليم لدى المزارع → COMPLETED + XP/Gold/Items | PASS |
| حفظ → إغلاق المشهد → تحميل → اللاعب في موضعه | PASS |
| الأعداء الموتى لا يعودون بعد التحميل | PASS |
| حالة المهمة والحقيبة تعود بعد التحميل | PASS |
| ملف حفظ v1 يُهاجَر ويُحمَّل | PASS |
| ملف تالف/نسخة أحدث تُرفض برسالة | PASS |

## 6) الأداء

| موقع | الهدف | المقيس |
|---|---|---|
| القرية | < 200 draw call | غير مقيس |
| الغابة | — | غير مقيس (3 MultiMesh + 7 شخصيات) |

## 7) مشكلات متبقية

- Loot العائم لا يُحفظ (الأعداء الموتى يُحفظون).
- لا انتقال سلس بين النطاقات (Teleport فوري).
- الأشجار بلا تصادم.

## 8) الحالة

`IMPLEMENTED` + `TESTED` منطقيًا. `VERIFIED`: ❌ — شرط المرحلة (APK على جهاز) غير ممكن هنا.

---

## تحديث 2026-11-12 — نتيجة تشغيل المحرك الحقيقي

المحرك: `4.3.stable.custom_build` (بُني من المصدر). **هذه المرحلة: IMPLEMENTED + TESTED (headless)**،
وما زالت **NOT VERIFIED على جهاز حقيقي**.

ما أُثبت آليًا في هذه المرحلة: 3 NPCs + 6 مبانٍ + منزل + دنجن، مهمة كاملة من البداية للتسليم والمكافأة، حفظ/تحميل يُعيد الموضع والمهمة والقتلى.

Commit: `ba7749f` · القياس الكامل: `docs/reports/headless_test_results.txt` (113/113) ·
سجل التشغيل والعيوب المُصلحة: `docs/reports/TEST_RUN_LOG.md`.
