# Final Engineering Report — Chronicles of Eldoria v1.1 (Phase 1 Expansion)

## 1. Executive Summary

`MICRO WORLD: LIVING` has been upgraded from the `v1.0` Eldoria baseline to **Chronicles of Eldoria v1.1 (Phase 1 Complete)**, delivering all four Phase 1 expansion pillars requested:

1. **Character Creation & 4 Playable 3D Hero Classes + Target-Lock Combat (`HeroClassDB`, `ClassSelectScreen`, `Player`)**
2. **Articulated Multi-Limb 3D Creature Rigs & Physics Obstacle-Avoidance AI (`ProceduralModels`, `Creature`)**
3. **100% Arabic (`RTL`) Content Translation + Interactive 3-Chapter Story Prologue (`Localization`, `StoryIntroOverlay`)**
4. **3D World Quest Waypoint Beacon, Minimap/HUD Tracking & Ergonomic Mobile Touch Controls (`QuestWaypoint3D`, `HUD`, `MinimapControl`, `TouchControls`)**

---

## 2. Architecture Delivered in Phase 1 (`v1.1`)

| Subsystem | Key Scripts | Highlights |
|---|---|---|
| **4 Hero Classes & Creation** | `scripts/data/hero_class_db.gd`, `scripts/ui/class_select_screen.gd`, `scripts/core/character_visual.gd`, `scripts/core/game_manager.gd` | Playable **Knight**, **Battlemage**, **Ranger**, and **Barbarian** with real KayKit `.glb` rigs, class stat bonuses, starting loadouts, unlocked starter skills, custom hero name, and full save/load persistence. |
| **Target Lock-On & Mobile Controls** | `scripts/player/player.gd`, `scripts/camera/camera_rig.gd`, `scripts/ui/touch_controls.gd`, `scripts/ui/hud.gd` | `KEY_T` / `Btn_lock_target` (`◎ LCK`), 3D golden target ring, melee/spell auto-facing, auto-retarget on kill, soft camera tracking, HUD Locked-Target HP card, and responsive curved mobile button arc. |
| **Articulated 3D Creatures & Smart AI** | `scripts/creatures/procedural_models.gd`, `scripts/creatures/creature.gd` | Multi-part articulated 3D rigs for `Wolf`, `Stag`, and `Slime` (hip-pivoted legs, head/antler/jaw/tail pivots, translucent dome + glowing nucleus) with diagonal-stride animation + cached 5-angle raycast obstacle avoidance (`_steer_direction`). |
| **Full Arabic (`RTL`) & Story Prologue** | `scripts/core/localization.gd`, `scripts/ui/story_intro_overlay.gd`, `scripts/world/village_npc.gd`, `scripts/ui/*_screen.gd` | 100% Arabic translation across UI, 3-chapter narrative prologue, 27 items, 11 quests/contracts, 24 skills, 11 creatures/bosses, and 18 NPCs. |
| **3D Quest Waypoint Beacon** | `scripts/world/quest_waypoint.gd`, `scripts/world/world_root.gd`, `scripts/ui/minimap_control.gd` | Floating 3D golden diamond + ground halo + live meter distance in 3D space, HUD Quest Tracker, and Minimap (`◆`), resolving cross-zone doors, objective coordinates, and turn-in NPCs. |

---

## 3. Verification Artifacts

- **Automated Headless Acceptance Suite:** `tests/test_runner.tscn` -> `docs/reports/headless_test_results.txt`
- **Real GLES3 Performance Probe (7 Zones):** `tests/perf_probe.tscn` -> `docs/reports/perf_probe_results.txt`
- **12 Visual Verification Captures:** `tests/visual_probe.tscn` -> `docs/screenshots/*.png`
- **Signed Debug Android APK (`v1.1.0`, `versionCode=2`):** `.github/workflows/android.yml` -> GitHub Release `v1.1-debug`
