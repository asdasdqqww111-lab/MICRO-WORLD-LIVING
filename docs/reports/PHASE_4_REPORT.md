# PHASE 4 — RPG SYSTEMS CORE

**الحالة: IMPLEMENTED / TESTED (منطقيًا) — "مقروء على 5 بوصة": BLOCKED بصريًا**

## 1) المهام

| # | المهمة | المنفّذ |
|---|---|---|
| 1 | Inventory UI (grid + drag-drop) | ✅ 5×4 شبكة، Tap-to-select + Drag&Drop حقيقي (`set_drag_forwarding`) + Swap بين الخانات |
| 2 | Equipment slots (weapon/armor/helmet) | ✅ سحب عنصر على خانة التجهيز أو زر Equip/Unequip |
| 3 | Item Resources (data-driven) | ✅ **14 ملف `.tres`** في `resources/items/` تُحمَّل آليًا |
| 4 | XP + Level (curve) | ✅ `xp = 60 + 45·(l−1) + 10·(l−1)²`، حتى 20، نقطة مهارة لكل مستوى |
| 5 | Stats: HP, MP, STR, DEF, AGI | ✅ HP/STR/DEF/AGI كاملة؛ **MP موجود كحقل (`max_mana`) وغير مستخدم في مهارة** — مهارات 0.1 سلبية (passive). موثق كقيد. |
| 6 | Skill Tree (3 مهارات) | ✅ Mighty Blow (+2 ATK/rank)، Iron Skin (+2 DEF/rank)، Swift Feet (+5% سرعة/rank) |
| 7 | Quest Journal UI | ✅ قائمة نشطة/مكتملة + تفاصيل الأهداف والمكافآت |
| 8 | Character Sheet UI | ✅ Attributes + معدلات + شجرة المهارات في شاشة واحدة |
| 9 | اختبار APK على شاشة 5 بوصة | ❌ BLOCKED |

## 2) الملفات

`scripts/ui/{inventory_screen,journal_screen,character_screen,menu_screen,ui_factory}.gd`,
`scripts/inventory/inventory.gd`, `scripts/data/{item_data,item_db,skill_data,skill_db,character_stats,progression,skill_tree}.gd`,
`resources/items/*.tres` (14), `resources/skills/*.tres` (3).

## 3) الأصول

لا أصول جديدة. أيقونات العناصر تُرسم من `icon_color` + الحرف الأول (لا حاجة لأصول UI خارجية،
Kenney UI Pack كان محجوبًا).

## 4) الأنظمة

- `Inventory`: 20 خانة + أكوام (max_stack لكل عنصر) + Equip/Unequip مع إعادة العنصر السابق
  إلى الحقيبة، ورفض التجهيز إذا كانت الحقيبة ممتلئة (rollback).
- `SkillTree`: نقاط من المستويات، `bonus_total(effect)`، وتُطبَّق فعليًا في
  `GameManager.attack_power()/defense_power()/move_speed_multiplier()/max_health()`.
- `Progression`: إضافة XP بفائض محفوظ بين المستويات، سقف 20.

## 5) الاختبارات

| اختبار | النتيجة |
|---|---|
| 14 عنصرًا تُحمَّل، كل حقل صالح | PASS |
| 3 مهارات تُحمَّل | PASS |
| كومة 30 + فائض إلى خانة ثانية | PASS |
| حقيبة ممتلئة تُرجع leftover | PASS |
| Equip/Unequip + إرجاع العنصر السابق | PASS |
| Serialization للحقيبة والتجهيز | PASS |
| منحنى XP: 60 للمستوى 1، سقف 20 | PASS |
| المكافآت تُطبَّق عند تسليم المهمة | PASS |
| MP غير مستخدم | ⚠️ قيد موثق |

## 6) الأداء

الواجهة كلها `Control` بسيطة (لا Shaders مخصصة). تُبنى مرة واحدة عند الفتح (لا rebuild كل إطار).
عدد العقد في شاشة الحقيبة ~120 — مقبول.

## 7) مشكلات متبقية

- MP بلا استخدام فعلي (لا مهارات نشطة في 0.1).
- الخطوط: الافتراضي فقط (لا خط مخصص)، والعربية غير مدعومة في الواجهة.
- حجم الخط 17–19px منطقي على 1280×720 مع stretch — يحتاج تأكيدًا بصريًا.

## 8) الحالة

`IMPLEMENTED` + `TESTED` منطقيًا. معيار "مقروء على هاتف صغير" غير قابل للتحقق هنا (`BLOCKED`).

---

## تحديث 2026-11-12 — نتيجة تشغيل المحرك الحقيقي

المحرك: `4.3.stable.custom_build` (بُني من المصدر). **هذه المرحلة: IMPLEMENTED + TESTED (headless)**،
وما زالت **NOT VERIFIED على جهاز حقيقي**.

ما أُثبت آليًا في هذه المرحلة: منحنى XP (60→2، سقف 20)، 11 فحص مخزن/تجهيز، 3 مهارات، سجل مهام، سمات وذهب.

Commit: `ba7749f` · القياس الكامل: `docs/reports/headless_test_results.txt` (113/113) ·
سجل التشغيل والعيوب المُصلحة: `docs/reports/TEST_RUN_LOG.md`.
