# تقرير تنفيذ إعادة تصميم واجهة Micro World: Living

**التاريخ:** 2026-11-13
**المحرك:** Godot 4.7.2 في بيئة الاختبار (المشروع يستهدف Godot 4.3 / Mobile)
**النطاق:** واجهة RPG عربية للموبايل، الأداء، الإضاءة والظلال، الكاميرا، وإصلاحات التشغيل.

## 1. النتيجة التنفيذية

تم تحويل طبقة الواجهة الحالية إلى نظام Fantasy RPG عربي مستوحى من المرجع البصري دون نسخ أصوله حرفياً. الواجهة الآن مبنية من طبقات منفصلة: HUD للمعلومات، TouchControls للتحكم، وشاشات modal للتخزين والمهام والمهارات والخريطة. هذا يحافظ على واجهة اللعب ثابتة ويمنع إعادة بناء Canvas بالكامل عند تغير قيمة واحدة.

يتضمن التصميم النهائي لوحة إحصائيات زجاجية أعلى اليسار، شريطاً علوياً من سبعة أزرار أيقونية (الحقيبة، المهام، المهارات، الحياة، الخريطة، القفل، الدليل)، minimap مربعة أعلى اليمين مع مخروط مجال الرؤية، بطاقة اليوم والوقت والطقس، متعقب مهام، بطاقات هدف/Boss، عصا حركة شفافة، وأزرار قتال دائرية ذهبية/برونزية بأسلوب Fantasy. جميع النصوص الجديدة تدعم العربية والإنجليزية عبر `Localization` وRTL.

## 2. الملفات التي تغيرت

| الملف | التغيير |
|---|---|
| `scripts/ui/touch_controls.gd` | تخطيط متكيف مع حجم الشاشة، حماية من غياب إشارة joystick في builds قديمة، وتحديث polling احتياطي. |
| `scripts/ui/virtual_joystick.gd` | إعادة تسمية global class إلى `MobileVirtualJoystick` لتجنب تعارض native class في Godot 4.7. الإشارة `moved` ما زالت موجودة. |
| `scripts/ui/hud.gd` | cache للـquest waypoint، تحديث الهدف كل 120ms والـwaypoint كل 200ms بدلاً من كل إطار. |
| `scripts/ui/minimap_control.gd` | استخدام مرجع اللاعب المحفوظ بدلاً من `get_first_node_in_group()` عند كل redraw. |
| `scripts/camera/camera_rig.gd` | SphereShape3D للـSpringArm، margin = 0.20، near = 0.12، مع الإبقاء على استثناء جسم اللاعب. |
| `scenes/game/game.tscn` | SSAO أخف، ظل DirectionalLight بتقسيمين، bias وnormal bias مضبوطتان، ومسافة ظل 45م. |
| `scripts/world/day_night_cycle.gd` | ambient light ليلاً لا يهبط عن قيمة مقروءة تقريباً 0.42، مع تقليل أثر الطقس على الإضاءة المحيطة. |
| `scripts/core/settings_manager.gd` | كثافة vegetation: منخفض 0.45، متوسط 0.70، مرتفع 0.90. |
| `scripts/player/player.gd` | فحص التفاعلات كل 120ms بدلاً من كل Physics Frame. |
| `scripts/creatures/creature.gd` | cache لمرجع اللاعب وتقليل البحث المتكرر، وإصلاح ترتيب معاملات مؤثر slash arc. |

## 3. تفاصيل التصميم البصري

### لوحة الألوان

- خلفيات زجاجية داكنة: أزرق/رمادي منخفض التشبع مع alpha بين 0.54 و0.76.
- Gold أساسي للعناوين والإطارات: `#FAD15C` تقريباً.
- Health: أحمر دافئ، Mana: أزرق، Stamina: تركوازي، XP: ذهبي.
- عناصر التحكم القتالية تستخدم برونزاً شفافاً مع حافة ذهبية، مع حالة pressed واضحة.

### البطاقات والنصوص

الـ`UIFactory` هو مصدر النمط الموحد للخط، RTL، ألوان النص، progress bars، glass panels، والأزرار. تم الإبقاء على Cairo variable font الموجود بالمشروع، مع أحجام أصغر للنصوص الثانوية داخل الـHUD حتى لا تتداخل على الشاشات الضيقة. البطاقات المهمة تستخدم حدوداً ذهبية رقيقة وظلالاً خفيفة بدلاً من panels معتمة ثقيلة.

### التحكم والتنقل

تم فصل منطقة سحب الكاميرا عن منطقة الـjoystick، والإبقاء على أزرار القتال داخل thumb zones. أضيف تخطيط responsive يحسب `fit` من أبعاد الشاشة ويعيد وضع أزرار القتال والعصا عند `NOTIFICATION_RESIZED`. لذلك لا تعتمد واجهة الهاتف على دقة واحدة فقط. الحد الأدنى للأزرار الدائرية يبقى قريباً من 54–92px في القياس المرجعي، وتتحرك المجموعة تدريجياً على الأجهزة الأضيق بدلاً من الخروج من الشاشة.

## 4. إصلاح خطأ VirtualJoystick

كان التشغيل على Godot الحديث يعطي تعارضاً بين `class_name VirtualJoystick` وnative class، ثم يظهر أثر ذلك كخطأ في property/signal `moved`. تم تغيير الاسم العالمي إلى `MobileVirtualJoystick` وتحديث TouchControls، مع الإبقاء على:

```gdscript
signal moved(vector: Vector2)
```

كما أن TouchControls يتحقق من `has_signal("moved")` ويستخدم `vector()` كمسار احتياطي. بذلك لا يتوقف التشغيل إذا كانت بيانات import القديمة ما زالت في cache.

## 5. إصلاح الكاميرا

الكاميرا كانت تستخدم SpringArm لكن من دون شكل تصادم مخصص. أضيف:

```gdscript
var camera_shape := SphereShape3D.new()
camera_shape.radius = 0.22
spring_arm.shape = camera_shape
spring_arm.margin = 0.20
camera.near = 0.12
```

النتيجة المتوقعة: منع دخول الكاميرا داخل الجدران، تقليل clipping مع رأس الشخصية، والحفاظ على مسافة آمنة عند المرور قرب الزوايا. ما يزال نجاح الحماية النهائي مرتبطاً بوجود colliders صحيحة على المباني؛ لهذا يجب اختبار المناطق الداخلية على جهاز فعلي أيضاً.

## 6. إصلاح الإضاءة والظلال

القيم السابقة كانت تسبب ظلالاً سوداء قاسية بسبب normal bias مرتفع جداً، SSAO قوي، ومسافة ظل أطول من حاجة شاشة الهاتف. تم تطبيق:

| الإعداد | قبل | بعد |
|---|---:|---:|
| SSAO intensity | 1.50 | 0.65 |
| SSAO power | 1.50 | 1.05 |
| shadow bias | 0.03 | 0.08 |
| shadow normal bias | 1.20 | 0.35 |
| shadow mode | Orthogonal | Parallel 2 Splits |
| shadow max distance | 60م | 45م |
| ambient night floor | 0.28 | 0.42 |

تم أيضاً تخفيف تأثير weather darkness على ambient حتى لا تتحول الأمطار والليل إلى شاشة سوداء. تحذير SSAO في Compatibility/Headless متوقع لأن SSAO مدعوم فعلياً في Forward+ وCompatibility وفق إعدادات المحرك، لكن renderer Mobile قد لا يعرضه بنفس الطريقة؛ لذلك لا يعتمد التصميم على SSAO وحده.

## 7. إصلاحات CPU/GPU

نتائج الفحص البنيوية السابقة كانت: 1,976 عقدة، 578 MeshInstance3D، 19 MultiMeshInstance3D، و2,724 MultiMesh instances تقريباً. الإجراءات المنفذة في هذه المرحلة:

1. تخزين مرجع اللاعب داخل Creature بدلاً من البحث عنه في كل Physics Frame.
2. تخفيض مسح interactables إلى مرة كل 120ms.
3. تخفيض تحديث بطاقة الهدف إلى 120ms والـwaypoint إلى 200ms.
4. حفظ مرجع اللاعب داخل Minimap بدلاً من البحث أثناء كل redraw.
5. تخفيض كثافة vegetation حسب preset إلى 0.45/0.70/0.90.
6. إطفاء shadow casting للكائنات الصغيرة/المخلوقات حسب السلوك الموجود سابقاً في Creature LOD.
7. إبقاء MultiMesh instancing للعشب والأشجار بدلاً من تحويلها إلى MeshInstance منفصل.

أما draw calls وtriangles فلا يمكن اعتماد أرقام نهائية لها في headless dummy driver؛ الاختبار السابق أعاد صفراً لهذه القياسات. القياس النهائي يجب أن يكون على هاتف Android حقيقي أو GPU pass-through.

## 8. الاختبارات

### ناجحة

- `godot --headless --path . --editor --quit` — لا توجد Parse Errors بعد إعادة تسمية joystick.
- `godot --headless --path . --scene scenes/main_menu/main_menu.tscn --quit-after 3` — القائمة تعمل دون أخطاء UI، مع تحذير موارد/كائنات leaked عند إغلاق headless.
- `godot --headless --path . --scene tests/test_runner.tscn` — **190 passed, 0 failed**.
- تم إصلاح runtime error في `Creature._try_attack`: ترتيب معاملات `spawn_slash_arc` كان يمرر Color مكان `tilt_deg`.

### حدود الاختبار

- تحذيرات `ObjectDB instances leaked` وموارد مستخدمة عند نهاية headless موجودة عند إغلاق مشاهد الاختبار، ولا تمنع النجاح الوظيفي.
- لا توجد في البيئة الحالية شاشة GPU/هاتف Android لقياس FPS وdraw calls الحقيقيين.
- تصدير APK يحتاج Java SDK وAndroid SDK في البيئة أو GitHub Actions الموجود بالمشروع.

## 9. طريقة التحقق على جهاز Android

1. صدّر Debug APK عبر GitHub Actions أو بيئة تحتوي JDK 17 وAndroid SDK.
2. اختبر دقة 720×1280 و1080×1920 ووضع landscape إن كان مطلوباً.
3. راقب FPS وGPU time وCPU time أثناء القرية، القتال، المطر، والانتقال إلى dungeon.
4. اختبر اقتراب SpringArm من جدار، زاوية مبنى، مدخل المنزل، ورأس الشخصية.
5. جرّب العربية والإنجليزية، فتح كل عناصر الشريط العلوي، تدوير الشاشة، وإظهار/إخفاء TouchControls.
6. إذا كان الجهاز تحت 30 FPS، استخدم Low preset أولاً؛ فهو الآن يخفض vegetation إلى 45% ويستخدم resolution scaling 0.82.

## 10. ملاحظات صريحة

هذه المرحلة نفذت بنية UI والإصلاحات البرمجية القابلة للتحقق، وليست ادعاءً بأن headless يعادل صورة هاتف حقيقية. جودة الإضاءة النهائية، وضوح الألوان تحت HDRI، والميزانية الفعلية للـGPU تحتاج لقطة أو profiler على جهاز Android. الأصول البصرية المستخدمة داخل الواجهة مولدة برمجياً ومملوكة للمشروع؛ لم يتم نسخ أيقونات أو خامات من الصورة المرجعية.
