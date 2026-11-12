# PHASE 1 — THIRD PERSON PROTOTYPE

**الحالة: IMPLEMENTED / TESTED (منطقيًا) — VERIFIED: BLOCKED (لا هاتف، لا GPU)**

## 1) المهام المنجزة

| # | المهمة | الملف |
|---|---|---|
| 1 | `CharacterBody3D` + `CollisionShape3D` (كبسولة 2.0×0.36) | `scripts/player/player.gd` |
| 2 | `SpringArm3D` مع تصادم كاميرا + Zoom (عجلة/قرص) + Drag | `scripts/camera/camera_rig.gd` |
| 3 | walk/run/jump/gravity + coyote-free jump + تسريع/تباطؤ | `player.gd` |
| 4 | Input abstraction (keyboard + touch) | `scripts/player/player_input.gd` |
| 5 | Virtual Joystick (يسار) + Camera Drag (يمين) | `scripts/ui/virtual_joystick.gd`, `camera_drag_area.gd`, `touch_controls.gd` |
| 6 | أرضية PlaneMesh + StaticBody3D | `WorldBuilder.build_ground` |
| 7 | WorldEnvironment + ProceduralSky + ضباب + شمس بظلال | `WorldRoot._build_environment` |
| 8 | استيراد شخصية KayKit Skeletons كلاعب | `CharacterVisual` + `assets/models/characters/Skeleton_Warrior.glb` |
| 9 | AnimationTree: idle/walk/run/jump/fall/attack/hit/death | `scripts/core/character_visual.gd` |
| 10 | اختبار على هاتف حقيقي | ❌ **BLOCKED** |

### AnimationTree مبني من الأصول الحقيقية

`Skeleton_Warrior.glb` يحتوي **95 مقطعًا** (تم فحصها بقراءة JSON داخل GLB).
البناء في الكود: `AnimationNodeStateMachine` + ربط كامل بين الحالات مع crossfade،
والاختيار بالاسم مع بدائل:
`idle→Idle`, `walk→Walking_A`, `run→Running_A`, `jump→Jump_Start`,
`fall→Jump_Idle`, `attack_1→1H_Melee_Attack_Slice_Diagonal`,
`attack_2→1H_Melee_Attack_Slice_Horizontal`, `hit→Hit_A`, `death→Death_A`.
تم ضبط `loop_mode = LOOP_LINEAR` للمقاطع الدورية.

### اتجاه النموذج (قرار مبني على قياس لا تخمين)

قراءة مواضع العظام من GLB: `hand.l` عند x=+0.212 و`hand.r` عند x=−0.212
⇒ الشخصية تواجه **+Z**، بينما Godot يعتبر −Z إلى الأمام ⇒ `MODEL_YAW_OFFSET = PI`.
ارتفاع الشبكة 2.166 وحدة، والكبسولة 2.0م.

## 2) الملفات المنشأة

`scripts/player/player.gd`, `player_input.gd`, `scripts/camera/camera_rig.gd`,
`scripts/core/character_visual.gd`, `asset_library.gd`,
`scripts/ui/{virtual_joystick,camera_drag_area,touch_controls}.gd`,
`scenes/player/player.tscn`, `scenes/game/game.tscn`, `scripts/core/game.gd`.

## 3) الأصول المستخدمة

| الاسم | المصدر | الترخيص | المسار المحلي | الحالة |
|---|---|---|---|---|
| Skeleton_Warrior.glb (95 anim) | KayKit-Character-Pack-Skeletons-1.0 | CC0 | `assets/models/characters/` | مدمج كلاعب |

## 4) الأنظمة التي تعمل

- حركة كاميرا-نسبية: `right * move.x + forward * (-move.y)` مع دوران الجسم نحو الحركة.
- ستامينا: الجري يستهلك، الهجوم يستهلك، التجديد تلقائي، والحالة تُرسل عبر `EventBus`.
- الكاميرا: yaw/pitch مع clamp، `SpringArm3D` يستثني جسم اللاعب ويتصادم مع الطبقة 1.
- لمس: Joystick مخصّص (`_gui_input` + draw)، سحب الكاميرا، Pinch، أزرار أفعال.

## 5) الاختبارات + النتائج (آلية، headless)

| اختبار | النتيجة |
|---|---|
| `player.visual.model != null` | PASS — النموذج يُحمَّل من GLB المستورد |
| حالات idle/run موجودة في AnimationTree | PASS |
| اللاعب يهبط ويقف على الأرض (y≈0) | PASS |
| إدخال Joystick (MockTouch) يحرّك اللاعب > 0.5م | PASS |
| دوران الكاميرا بتغيّر yaw | PASS |
| تغيير Zoom للمسافة | PASS |
| `player.is_on_floor()` بعد 60 tick | PASS |
| FPS / Draw calls | **غير مقيس** (dummy renderer = 0) |

الأرقام الفعلية في `docs/reports/headless_test_results.txt`.

## 6) الأداء

| مقياس | الهدف | المقيس |
|---|---|---|
| Draw calls (مشهد اللاعب فقط) | < 50 | **غير مقيس** |
| FPS | ≥ 30 | **غير مقيس** |

## 7) المشكلات المتبقية

- الاتجاه/الأنيميشن لم يُرَ بصريًا؛ تعويض PI مبني على قياس العظام فقط.
- اللمس يمرّر أحداثًا مزدوجة (touch + mouse مُحاكى)؛ يحتاج تأكيدًا على جهاز.
- لا موسيقى/خطوات (لا أصول صوتية متاحة).

## 8) الحالة

`IMPLEMENTED` + `TESTED` (منطقي). `VERIFIED`: ❌ — الشرط كان "APK مثبت ومختبر فعليًا"،
وهذا مستحيل في هذه البيئة، لذا لا يُدّعى.

---

## تحديث 2026-11-12 — نتيجة تشغيل المحرك الحقيقي

المحرك: `4.3.stable.custom_build` (بُني من المصدر). **هذه المرحلة: IMPLEMENTED + TESTED (headless)**،
وما زالت **NOT VERIFIED على جهاز حقيقي**.

ما أُثبت آليًا في هذه المرحلة: اللاعب يظهر ويستقر على الأرض، AnimationTree يحل مقاطع KayKit، الجويستيك يحرّك 3.09 م، الكاميرا تدور وتقرّب.

Commit: `f4b599e` · القياس الكامل: `docs/reports/headless_test_results.txt` (113/113) ·
سجل التشغيل والعيوب المُصلحة: `docs/reports/TEST_RUN_LOG.md`.
