# Phase 1 Expansion Report — Chronicles of Eldoria v1.1

## Scope Completed (All 4 Pillars)

1. **Classes & Combat (`HeroClassDB` + `ClassSelectScreen` + `Target Lock`)**
   - Added 4 playable hero classes (`knight`, `mage`, `ranger`, `barbarian`) backed by rigged KayKit `.glb` models (`Knight.glb`, `Mage.glb`, `Rogue_Hooded.glb`, `Barbarian.glb`) and class-specific weapon/shield/hat/cape submesh toggling in `CharacterVisual`.
   - Built `ClassSelectScreen` modal on New Adventure with custom Hero Name input, class stat preview, starting equipment preview, and signature starter skill unlock.
   - Implemented full 3D `Target Lock` (`KEY_T` on desktop, `◎ LCK` on mobile touch) with 3D target ring, auto-facing attacks/spells, camera soft tracking, auto-retarget on kill, and HUD Target HP card.

2. **Articulated 3D Creatures & Obstacle-Avoidance AI (`ProceduralModels` + `Creature`)**
   - Upgraded `wolf`, `stag`, and `slime` procedural rigs into articulated multi-limb 3D models (`HeadPivot`, `LegFL`, `LegFR`, `LegBL`, `LegBR`, `TailPivot`, translucent `Dome` + `Core`) with `SHADOW_CASTING_SETTING_OFF` on sub-parts to preserve mobile GLES3 draw-call headroom and diagonal-stride limb animation.
   - Added cached 5-angle physics raycast steering (`_steer_direction`, `0.12s` interval, `1.65m` lookahead) so creatures smoothly skirt around trees, boulders, fences, and walls during patrol and combat pursuit.

3. **Full Arabic (`RTL`) Localization & Eldoria Story Prologue (`Localization` + `StoryIntroOverlay`)**
   - Translated 100% of game content into Arabic (`RTL`): all 27 items, all 11 quests & guild contracts (titles, descriptions, objectives), all 24 skills, all 11 creatures/bosses, and all 18 NPC names, titles, prompts, and dialogues.
   - Added 3-chapter interactive `StoryIntroOverlay` prologue when starting a new adventure.

4. **Mobile UX & 3D Quest Waypoints (`QuestWaypoint3D` + `TouchControls` + `HUD` + `MinimapControl`)**
   - Added `QuestWaypoint3D` golden 3D world beacon + ground halo + billboard distance label, synchronized with HUD Quest Tracker distance readout and Minimap pulsing golden diamond (`◆`).
   - Upgraded `TouchControls` with larger ergonomic action arc, `◎ LCK` Target-Lock button, and touch press-glow feedback.
