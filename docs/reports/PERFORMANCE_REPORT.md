# PERFORMANCE REPORT — v0.1

الحالة: **NOT MEASURED** (لا يوجد GPU في بيئة البناء).

## الميزانية المستهدفة (كما في البرومبت)

| مقياس | الهدف | الحد الأقصى |
|---|---|---|
| Draw calls / frame | < 200 | 300 |
| Triangles / frame | < 150,000 | — |
| Texture memory | < 200 MB | — |
| FPS (Snapdragon 6xx / 4GB) | ≥ 30 | — |

## ما تم قياسه فعلًا (headless)

`godot --headless --path . tests/test_runner.tscn` مع مشغّل dummy:
`RENDER_TOTAL_DRAW_CALLS_IN_FRAME = 0` و`RENDER_TOTAL_PRIMITIVES_IN_FRAME = 0`.
هذه ليست نتيجة أداء — هي تأكيد أن القياس يحتاج جهازًا.

## التحسينات المنفّذة مسبقًا (استعدادًا للميزانية)

| تقنية | أين | الأثر المتوقع |
|---|---|---|
| MultiMesh للأشجار (90+40 شجرة/صخرة) | `WorldBuilder.build_forest` | 3 draw calls للغابة كلها |
| MultiMesh لأرضيات وجدران الدنجن | `WorldBuilder.build_dungeon` | 2 draw calls للدنحن |
| جسم تصادم واحد لكل جدار دنجن | `_add_dungeon_colliders` | مئات أشكال التصادم داخل StaticBody واحد |
| كاميرا SpringArm بـ collision mask محدود (الطبقة 1 فقط) | `CameraRig` | لا استعلامات غير ضرورية |
| 3 مستويات رسوميات (MSAA / مسافة ظل / ضباب / مدى الرؤية) | `SettingsManager` | خفض تكلفة fill-rate على الأجهزة الضعيفة |
| حلقة فيزياء 60Hz وحركة steering بدون NavMesh | `Creature` | بلا تكلفة bake/pathfinding |
| عدد الشخصيات 7 فقط (9 أسطح لكل واحدة ≈ 63 draw call) | `WorldRoot` | ضمن الميزانية |

## المخاطرة الأكبر

الشخصيات: كل نموذج KayKit يحتوي ~9–10 أسطح Material، أي ~9 draw calls لكل شخصية.
7 شخصيات = ~63 draw call قبل البيئة. على Snapdragon 6xx هذا مقبول، لكن إضافة
10 أعداء في نفس الشاشة سترفع الرقم سريعًا. الحل المقترح للمرحلة القادمة:
دمج أسطح النموذج الواحد (SurfaceTool + material atlas واحد) أو استخدام
`MultiMesh` للأعداء المتطابقين.

## كيف تُقاس على الجهاز

1. شغّل اللعبة، اضغط `F3` (أو Settings > Performance overlay).
2. اذهب إلى: القرية (وسط 6 مبانٍ)، الغابة (بين الأشجار)، الدنجن (الغرفة الأخيرة).
3. سجّل FPS + Draw calls + Triangles + Memory في كل موقع.
4. قارن بالجدول أعلاه. أي مشهد يتجاوز الحد → يُحسَّن أو يُرفض (قاعدة البرومبت).
