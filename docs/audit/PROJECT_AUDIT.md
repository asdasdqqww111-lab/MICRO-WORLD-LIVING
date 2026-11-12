# PROJECT AUDIT — MICRO WORLD: LIVING
Generated: 2026-11-12T20:01:27Z · commit cea1171

## 1. Identity
| | |
|---|---|
| Project root | `/home/user/MICRO-WORLD-LIVING` |
| Engine | **Godot 4.3** (project `config/features=PackedStringArray("4.3", "GL Compatibility")`) |
| Renderer | `gl_compatibility` (desktop + mobile) — Forward+/Mobile forbidden by spec |
| Main scene | `run/main_scene="res://scenes/main_menu/main_menu.tscn"` |
| Language | GDScript, typed |
| Android preset | `Android` (`export_presets.cfg`) — arm64-v8a + armeabi-v7a, minSdk 21, targetSdk 34 |
| Branch | `arena/886df73a-micro-world-living` |
| Backup | `/home/user/BACKUPS/micro-world-living-20261112-200118/` (sha256 verified) |

## 2. Inventory
| نوع | عدد |
|---|---|
| Scripts (`scripts/`) | 56 ملف / 6408 سطر |
| Test harness | 3 ملف |
| Scenes | 4 |
| Resource files (.tres) | 23 |
| Asset files | 245 ملف / 21.8 MB |
| Autoloads | 5 |

### Autoloads
- `EventBus="*res://scripts/core/event_bus.gd"`
- `SettingsManager="*res://scripts/core/settings_manager.gd"`
- `GameManager="*res://scripts/core/game_manager.gd"`
- `SaveManager="*res://scripts/core/save_manager.gd"`
- `SceneManager="*res://scripts/core/scene_manager.gd"`

### أكبر السكربتات (نقاط احتمال التعقيد)
- 518 سطر — `tests/test_runner.gd`
- 418 سطر — `scripts/world/world_builder.gd`
- 311 سطر — `scripts/player/player.gd`
- 275 سطر — `scripts/world/world_root.gd`
- 269 سطر — `scripts/ui/hud.gd`
- 238 سطر — `tests/perf_probe.gd`
- 234 سطر — `scripts/creatures/creature.gd`
- 202 سطر — `scripts/inventory/inventory.gd`
- 199 سطر — `scripts/core/game_manager.gd`
- 195 سطر — `scripts/ui/inventory_screen.gd`

### Scenes
- `scenes/game/game.tscn`
- `scenes/main_menu/main_menu.tscn`
- `scenes/player/player.tscn`
- `scenes/world/world.tscn`

### Resources
- `resources/creatures/skeleton_dungeon.tres`
- `resources/creatures/skeleton_forest.tres`
- `resources/creatures/slime.tres`
- `resources/creatures/wolf.tres`
- `resources/items/ancient_relic.tres`
- `resources/items/bone.tres`
- `resources/items/bread.tres`
- `resources/items/health_potion.tres`
- `resources/items/iron_helmet.tres`
- `resources/items/iron_ingot.tres`
- `resources/items/iron_ore.tres`
- `resources/items/iron_sword.tres`
- `resources/items/leather_armor.tres`
- `resources/items/rusty_sword.tres`
- `resources/items/skeleton_key.tres`
- `resources/items/slime_gel.tres`
- `resources/items/wolf_pelt.tres`
- `resources/items/wood.tres`
- `resources/quests/skeleton_menace.tres`
- `resources/quests/sunken_cellar.tres`
- `resources/skills/iron_skin.tres`
- `resources/skills/mighty_blow.tres`
- `resources/skills/swift_feet.tres`

## 3. الحالة الوظيفية (مبنية على اختبارات فعلية)
- **113 فحصًا آليًا ناجحًا** (headless, CI) — `docs/reports/headless_test_results.txt`
- APK مبني وموقَّع v1+v2+v3 — Release `v0.1-debug`
- لا ادعاء VERIFIED على جهاز.

## 4. قياس الأداء الحالي (llvmpipe/GLES3 — أرقام حقيقية من داخل المحرك)
MICRO WORLD: LIVING — performance probe
engine: 4.3-stable (official)
rendering method: gl_compatibility
video adapter: llvmpipe (LLVM 21.1.8, 256 bits)
driver: 4.5 (Core Profile) Mesa 26.0.8-1ubuntu0.3
run at: 2026-11-12T19:53:44

budget: draw calls < 200 (hard cap 300) · triangles < 150k · fps >= 30

Phase 1 · village spawn (player + camera + ground)
  draw calls (max): 205  [OVER]
  triangles (max):  172895  [OVER]
  objects:          272
  static memory:    64.4 MB
  fps (min, this driver): 4.0
  creatures in world: 10
Phase 2 · village + 3 skeletons
  draw calls (max): 259  [OVER]
  triangles (max):  195255  [OVER]
  objects:          326
  static memory:    66.0 MB
  fps (min, this driver): 3.0
Phase 3 · forest (MultiMesh trees)
  draw calls (max): 157  [OK]
  triangles (max):  141775  [OK]
  objects:          223
  static memory:    66.0 MB
  fps (min, this driver): 4.0
Phase 3 · house interior
  draw calls (max): 124  [OK]
  triangles (max):  30748  [OK]
  objects:          214
  static memory:    66.2 MB
  fps (min, this driver): 6.0
Phase 5 · dungeon
  draw calls (max): 86  [OK]
  triangles (max):  71984  [OK]
  objects:          152
  static memory:    66.2 MB
  fps (min, this driver): 4.0

## 5. القيود البيئية الحاكمة
| قيد | الأثر على إعادة البناء |
|---|---|
| الشبكة تسمح فقط بـ `github.com`, `codeload.github.com`, `api.github.com`, `registry.npmjs.org`, `pypi.org`, `files.pythonhosted.org` | **polyhaven.com / ambientcg.com / quaternius.com / itch.io محجوبة**. الأصول الجديدة ممكنة فقط من مستودعات GitHub (KayKit ✓، Quaternius GitHub mirrors ✗ لا يوجد رسمي). |
| لا GPU محليًا | القياس واللقطات تُنتج على CI بـ Mesa llvmpipe (GLES3 حقيقي) |
| لا JDK/SDK محليًا | APK يُبنى على CI فقط |
| لا هاتف | كل ما يتعلق بـ VERIFIED يبقى BLOCKED |

## 6. قرارات تقنية مبنية على التدقيق
1. **Terrain3D مرفوض**: GDExtension يتطلب ترجمة أصلية لكل معمارية (arm64 Android) — لا يوجد NDK. البديل: **تضاريس إجرائية ArrayMesh في GDScript** (حتمية، تعمل على Compatibility، بلا تبعيات).
2. **الأصول الطبيعية الجديدة**: الاعتماد على KayKit Hexagon (trees/rocks/props) + توليد إجرائي (عشب، ضباب، سحب، ماء) بدل Quaternius المحجوب.
3. **السماء**: `ProceduralSkyMaterial` + شمس/قمر متحركان + سحب billboard إجرائية (بلا shaders ثقيلة، متوافقة مع GLES3).
4. **الحفاظ على الواجهات**: `WorldBuilder`/`WorldRoot` API، مسارات المشاهد، صيغة الحفظ v3 — لا تتغير.
