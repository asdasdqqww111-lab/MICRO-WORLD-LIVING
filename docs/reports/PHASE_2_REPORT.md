# PHASE 2 — COMBAT FOUNDATION

**الحالة: IMPLEMENTED / TESTED (منطقيًا) — VERIFIED: BLOCKED**

## 1) المهام

| # | المهمة | النتيجة | المكان |
|---|---|---|---|
| 1 | هجوم خفيف بمدى قوسي + Cooldown + نافذة كومبو | ✅ ضربتان، كومبو 0.9 ث، كل ضربة 0.46 ث، الثانية ×1.3 | `player.gd`, `combat/combat.gd` |
| 2 | HealthComponent | ✅ Node + إشارات damaged/healed/died + invulnerable + revive | `combat/health_component.gd` |
| 3 | DamageComponent | ✅ بديل مكافئ: `GameManager.compute_damage(attack, defense, crit)` كدالة مركزية تُستخدم من اللاعب والأعداء والفخاخ | `core/game_manager.gd` |
| 4 | عدو Skeleton من KayKit + AI (chase/attack/death) | ✅ Skeleton_Minion + leash + aggro + loot | `creatures/creature.gd` |
| 5 | AnimationTree للعدو (idle/walk/attack/hit/death) | ✅ نفس باني الحالات (`CharacterVisual`) | `core/character_visual.gd` |
| 6 | HUD: HP + Stamina | ✅ + XP + Gold + ساعة + Loot/إشعارات | `ui/hud.gd` |
| 7 | Loot يطفو ويُجمع بالتفاعل | ✅ `LootDrop` (Interactable) بتقارب مسافي | `world/loot_drop.gd` |
| 8 | Inventory شبكي | ✅ 20 خانة + 3 تجهيز (الواجهة الكاملة في Phase 4) | `inventory/inventory.gd` |

### صيغة الضرر (موثّقة لأنها تُختبر)

```
raw    = max(1, attack − defense × 0.5)
variance = rand(0.92 … 1.08)
crit   = rand() < clamp(0.04 + agility × 0.0025, 0 … 0.35)   (إن كان مسموحًا)
damage = max(1, raw × variance × (1.6 if crit else 1.0))
```

## 2) الملفات المنشأة

`scripts/combat/{combat,health_component}.gd`, `scripts/creatures/creature.gd`,
`scripts/world/loot_drop.gd`, `scripts/ui/{hud,stat_bar}.gd`,
`resources/creatures/skeleton_forest.tres`, `resources/items/{bone,iron_ore}.tres`.

## 3) الأصول

| الاسم | المصدر | ترخيص | مسار |
|---|---|---|---|
| Skeleton_Minion.glb (عدو) | KayKit Character Pack — Skeletons | CC0 | `assets/models/characters/` |

## 4) الأنظمة

- استعلام إصابة: `PhysicsDirectSpaceState3D.intersect_shape` بكرة نصف قطرها 2.3م أمام اللاعب
  مع فحص قوس 120° (dot ≥ cos(60°)) — حتمي وسهل الاختبار، ولا يعتمد على توقيت Area3D.
- الذكاء: idle/wander → chase (عند دخول نصف قطر 13م) → attack (مدى 1.9م، 1.5ث) →
  hit (لا يقطع الهجوم) → death (إسقاط Loot + XP + Gold + تسجيل UID).
- Leash: يعود idle إذا ابتعد > 26م عن موطنه.

## 5) الاختبارات

| اختبار | النتيجة |
|---|---|
| `compute_damage` لا يقل عن 1 مهما كان الدفاع | PASS |
| الضرر يزيد مع الهجوم | PASS |
| تعطيل الكريت يعمل | PASS |
| ضربة اللاعب تُنقص HP السكلتون فعليًا | PASS |
| السكلتون يصبح Aggro بعد الإصابة | PASS |
| Loot منفصل يُجمع للحقيبة | PASS |
| HUD يقرأ HP/SP/XP/Gold من `EventBus` | PASS (بناءً على إشارات الاختبار) |

## 6) الأداء

هدف: FPS ≥ 30 مع 3 أعداء. **غير مقيس** (لا Renderer). كل عدو ~9 draw calls،
الذكاء يعمل فقط عند `_physics_process` بلا استعلامات مكانية ثقيلة (لا raycasts دورية).

## 7) مشكلات متبقية

- لا يوجد "stagger" كامل (المقاطعة البصرية للهجوم غير معطلة) — مقصود لتبسيط.
- الأعداء لا يهربون ولا يستخدمون مهارات.

## 8) الحالة

`IMPLEMENTED` + `TESTED` منطقيًا. `VERIFIED`: ❌ (لا APK/جهاز).

---

## تحديث 2026-11-12 — نتيجة تشغيل المحرك الحقيقي

المحرك: `4.3.stable.custom_build` (بُني من المصدر). **هذه المرحلة: IMPLEMENTED + TESTED (headless)**،
وما زالت **NOT VERIFIED على جهاز حقيقي**.

ما أُثبت آليًا في هذه المرحلة: الضربة تستهلك ستامينا، الهيكل يستقبل 46→33.7 ضررًا، يصبح عدائيًا، 3 قتلات تُكمل الهدف، الـ loot يُلتقط فعليًا في المخزن.

Commit: `ba7749f` · القياس الكامل: `docs/reports/headless_test_results.txt` (113/113) ·
سجل التشغيل والعيوب المُصلحة: `docs/reports/TEST_RUN_LOG.md`.
