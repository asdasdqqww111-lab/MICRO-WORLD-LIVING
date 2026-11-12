# PHASE 7 — POLISH + RELEASE

**الحالة: PARTIAL — IMPLEMENTED (جزئي) / BLOCKED (الإصدار)**

## 1) المهام

| # | المهمة | الحالة | ملاحظة |
|---|---|---|---|
| 1 | Bug fixing شامل | ✅ جزئي | 12 خطأ حقيقي أُصلح أثناء المراجعة (انظر أدناه) |
| 2 | تحسين UI (typography/contrast) | ✅ جزئي | ثيم موحّد + Outline للنصوص فوق العالم + أحجام 15–26px |
| 3 | أصوات من Kenney Audio Packs | ❌ **BLOCKED** | kenney.nl محجوب. لا ملفات صوتية مزيفة. |
| 4 | VFX بسيطة (hit spark) | ❌ لم يُنفَّذ | لا يمكن التحقق بصريًا؛ تُرك للمرحلة التالية بدل شحن شكل غير مُختبر |
| 5 | Settings: Low/Medium/High | ✅ | `SettingsManager` + مرآة في القائمة الرئيسية وقائمة الإيقاف |
| 6 | Save/Load شامل (10 جولات) | ⚠️ | 10 جولات **غير منفّذة**؛ نُفِّذت دورة حفظ/تحميل آلية + حالات فشل (تالف، نسخة أحدث، v1) |
| 7 | قائمة Known Issues | ✅ | `docs/KNOWN_ISSUES.md` |
| 8 | Release APK موقّع | ❌ **BLOCKED** | لا SDK/JDK/keystore، انظر `ANDROID_BUILD_REPORT.md` |
| 9 | ANDROID_BUILD_REPORT.md | ✅ | موجود مع أوامر التصدير الدقيقة |
| 10 | FINAL_REPORT.md | ✅ | موجود |

### الأخطاء الحقيقية التي أُصلحت في هذه المرحلة

1. جدران المنزل الداخلي: تعارض بين موضع الـ Collider وموضع الـ Mesh (كانت الجدران وعناصر
   التصادم غير متطابقة) → أُضيف `_solid_box()` يجعل الاثنين من نفس القاعدة.
2. `set_drag_preview` كان يُستدعى من الشاشة لا من زر الخانة → Drag&Drop للحقيبة كان سيفشل.
3. `GameManager.consume_pending()` (غير موجود) بدل `SaveManager.consume_pending()` في الاختبار.
4. `AssetLibrary.first_mesh` كان يستدعي `queue_free()` على عقدة خارج الشجرة → `free()`.
5. التحميل من قائمة الإيقاف أثناء `paused` كان يمكن أن يعلّق الـ Fade → `change_scene` يلغي الإيقاف.
6. `SceneManager.go_to_main_menu` كان يترك `is_playing = true` → حفظ تلقائي بحالة لاعب مفقودة.
7. Inventory Screen كان يعدّل `slots` ويرسل إشارات من خارج الصنف → أُضيف `swap_slots()` و`move_equipment_to_bag()`.
8. `Creature` كان يرسل UID بدل `data.id` في `creature_died` → المهمة ما كانت لتُحسب.
9. `MainMenu` كان ينادي `SaveManager._ready()` يدويًا.
10. `WorldBuilder` كان يضع الأرضية الداخلية بسماكة خاطئة (أعلى من مستوى الأرض).
11. `Tests` كان يقرأ `world.creature_count()` بعد `queue_free()` للعقدة.
12. `InventoryScreen` "Drop" لم يكن يُسقط شيئًا فعليًا في العالم → الآن يُنشئ `LootDrop`.

## 2) الملفات

`scripts/ui/pause_screen.gd`, `docs/KNOWN_ISSUES.md`, `docs/reports/*`, تعديلات إصلاح
في 9 ملفات.

## 3) الأصول

لا أصول جديدة.

## 4) الأنظمة

- 3 مستويات رسوميات: MSAA (0/2x/4x)، ظلال (مطفأ/ناعم منخفض/ناعم عالٍ)، مسافة ظل 45/70م،
  ضباب، MSAA، `scaling_3d_scale` 0.75 على Low.
- طبقة أداء (F3) تعرض FPS/Draw calls/Triangles/Nodes/Memory.
- `Known Issues` صريحة، بدون تجميل.

## 5) الاختبارات

لا اختبارات إضافية في هذه المرحلة عدا إعادة تشغيل الحزمة الكاملة بعد كل إصلاح.
النتائج في `headless_test_results.txt`.

## 6) الأداء

لم يُقس. الإعدادات جاهزة للقياس على الجهاز.

## 7) مشكلات متبقية

انظر `docs/KNOWN_ISSUES.md` (14 بندًا، منها 3 BLOCKED بيئيًا).

## 8) الحالة

`PARTIAL`. لا `VERIFIED` ولا "Release" — الشروط (جهازان مختلفان، 30 دقيقة بلا crash،
توقيع keystore) كلها خارج قدرة هذه البيئة، ولن تُدَّعى.

---

## تحديث 2026-11-12 — نتيجة تشغيل المحرك الحقيقي

المحرك: `4.3.stable.custom_build` (بُني من المصدر). **هذه المرحلة: IMPLEMENTED + TESTED (headless)**،
وما زالت **NOT VERIFIED على جهاز حقيقي**.

ما أُثبت آليًا في هذه المرحلة: 10 دورات حفظ/تحميل متتالية، رفض الحفظ التالف، رفض schema أحدث، هجرة v1→v3. لا APK (بيئي).

Commit: `f4b599e` · القياس الكامل: `docs/reports/headless_test_results.txt` (113/113) ·
سجل التشغيل والعيوب المُصلحة: `docs/reports/TEST_RUN_LOG.md`.

### تحديث 2026-11-12 — APK مبني

`docs/reports/ANDROID_BUILD_REPORT.md` كان يقول BLOCKED. الآن: **debug APK مبني على
GitHub Actions**، موقَّع v1+v2+v3، متحقَّق آليًا بـ apksigner/aapt2، منشور في
Release `v0.1-debug`. توقيع الإصدار النهائي (release keystore) ما زال غير متاح،
وتجربة الجهاز ما زالت **NOT VERIFIED**.
