# ARCHITECTURE — Micro World: Living 0.1

## المبادئ

1. **الحالة في مكان واحد.** `GameManager` (Autoload) يملك التقدّم: المستوى، XP،
   الحقيبة، التجهيز، المهام، المهارات، والذهب. كل شيء آخر (Player, HUD, World)
   *عرض* على هذه الحالة. هذا يجعل الحفظ والتحميل والاختبار مباشرًا.
2. **قنوات أحداث.** كل الأنظمة تتحدث عبر `EventBus` (Autoload) بدلًا من
   الإشارات المتشابكة. مثال: `creature_died(creature_id, uid, position)` يستهلكها
   `GameManager` (تقدّم المهمة + تسجيل الموت) و`RaidEvent` (نهاية الغارة) و`HUD`.
3. **بناء بالكود.** المشاهد `.tscn` رقيقة (جذر + سكربت). العالم يبنى في
   `WorldRoot._ready()` عبر `WorldBuilder`، والواجهة في `UIRoot._ready()`.
   الفائدة: لا "magic node paths" في ملفات نصية، والاختبار الآلي يبني المشهد كاملًا.
4. **بيانات في موارد.** العناصر/المهام/المهارات/المخلوقات في
   `resources/**/*.tres` تُحمَّل تلقائيًا (`ItemDB`, `QuestDB`, `SkillDB`,
   `CreatureDB`) باستخدام `DirAccess.get_files_at()`. إضافة عنصر جديد = ملف `.tres`.
5. **قابلية الاختبار أولًا.** لا منطق في `_process` غير قابل للاستدعاء من الاختبار؛
   الدوال الحساسة (`Combat.melee_targets`, `Market.price`, `QuestLog.record_event`,
   `VillageNPC.activity_for_hour`, `Progression.add_xp`) مستقلة ونقية.

## المخطط

```
Game (scenes/game/game.tscn)
├── World (WorldRoot)                    ← يبني كل شيء
│   ├── WorldEnvironment + Sun
│   ├── Ground / Village / Forest (MultiMesh) / Interior zone / Dungeon zone
│   ├── NPCs (VillageNPC ×3)  · Creatures (Creature) · Chests · ZoneDoors
│   └── DayNightCycle · WeatherSystem · RaidEvent
├── Player (CharacterBody3D)
│   ├── CollisionShape3D · Visual (CharacterVisual + AnimationTree)
│   ├── CameraRig (SpringArm3D + Camera3D)
│   └── HealthComponent
└── UI (UIRoot, CanvasLayer)
    ├── HUD · TouchComponents (Joystick + CameraDragArea + Buttons)
    ├── InventoryScreen · JournalScreen · CharacterScreen
    └── ShopScreen · DialogScreen · PauseScreen
```

## تدفق البيانات (مثال: قتل عدو)

1. `Player.try_attack()` → `Combat.melee_targets()` (استعلام فيزيائي نصف كروي أمام اللاعب).
2. لكل هدف: `GameManager.compute_damage(attack, defense)` → `Creature.take_hit()`.
3. `HealthComponent.died` → `Creature._die()`:
   - `GameManager.world.mark_dead(uid)` (استمرارية)
   - `GameManager.gain_xp/gain_gold`
   - `EventBus.creature_died(id, uid, pos)`
4. `GameManager` → `QuestLog.record_event("kill", id)`.
5. `HUD` يتحدّث عبر `quest_updated`، و`RaidEvent` يتحقق من نهاية الغارة.

## الحفظ

`SaveManager` يكتب JSON إلى `user://saves/<slot>.json` (كتابة إلى `.tmp` ثم إعادة
تسمية = لا تلف عند الانقطاع). البنية:

```json
{
  "schema_version": 3,
  "saved_at": "2026-11-12T17:20:00",
  "meta": { "zone": "village", "version_name": "0.1", "engine": "4.3.stable" },
  "game": { "gold": 30, "level": 2, "xp": 12, "stats": {...},
            "inventory": {...}, "quests": {...}, "skills": {...}, "world": {...} },
  "player": { "position": [x,y,z], "rotation_y": 0.0, "health": 100, "stamina": 80, "zone": "village" }
}
```

- الهجرة: `_migrate()` v1→v2 (إضافة skills)، v2→v3 (نقل حالة العالم إلى `game.world`).
- الإصدارات الأحدث من المدعوم **تُرفض** بدلًا من تخمينها.
- الحفظ التلقائي: كل 120 ثانية + عند إكمال مهمة + عند رفع المستوى + بداية يوم جديد.

## الأداء

- الأشجار/الصخور: `MultiMeshInstance3D` (3 نداءات رسم لكل الغابة).
- الدنجن: الأرضيات والجدران MultiMesh + `StaticBody3D` واحد للتّصادم.
- الشخصيات: كل نموذج KayKit ~9 أسطح (≈9 draw calls لكل شخصية) — 7 شخصيات في 0.1.
- `SettingsManager` يوفّر 3 مستويات: MSAA، مسافة ظل، ضباب، مسافة رؤية للكاميرا.
- قياس فعلي على الجهاز: `F3` يعرض FPS/Draw Calls/Triangles/Nodes/Memory.

## ما لم يُنفَّذ ولماذا

- **NavigationMesh**: الذكاء يعتمد على steering مباشر (رخيص، بلا bake، كافٍ لساحة مفتوحة).
- **أصوات**: لا مصدر CC0 متاح للوصول (kenney.nl محجوب من بيئة البناء) — انظر KNOWN_ISSUES.
- **اختبار بصري**: البيئة بلا GPU؛ Godot يعمل `--headless` فقط.
