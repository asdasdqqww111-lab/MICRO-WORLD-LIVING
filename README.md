# MICRO WORLD: LIVING — Chronicles of Eldoria (v1.1 · Phase 1 Complete)

A complete **offline 3D Medieval Fantasy Action-RPG** built with **Godot 4.3 (`gl_compatibility` / GLES3)** for Android phones, tablets, and desktop — using **100% permissively licensed (`CC0 1.0` & `SIL OFL 1.1`) 3D & font assets**.

---

## Direct Android APK Download (v1.1)

- **One-Tap APK Download (`v1.1-debug`):**
  `https://github.com/asdasdqqww111-lab/MICRO-WORLD-LIVING/releases/download/v1.1-debug/micro_world_living.apk`
- **GitHub Release Page:**
  `https://github.com/asdasdqqww111-lab/MICRO-WORLD-LIVING/releases/tag/v1.1-debug`

---

## Key Features (Eldoria v1.1 — Phase 1 Expansion)

### 1. Four Playable Hero Classes & Character Creation (`HeroClassDB` + `ClassSelectScreen`)
- **Knight (`Knight.glb`)** — Balanced shield-bearing vanguard (`Iron Sword + Oak Shield + Leather Armor`, starts with **Iron Vanguard**).
- **Battlemage (`Mage.glb`)** — Arcane spellcaster (`Arcane Staff + Apprentice Robe`, elevated Mana & Spell Power, starts with **Firebolt**).
- **Ranger (`Rogue_Hooded.glb`)** — Swift critical skirmisher (`Hunter's Recurve Bow + Leather Armor`, elevated Crit & Speed, starts with **Fleet Foot**).
- **Barbarian (`Barbarian.glb`)** — High-HP heavy berserker (`Steel Broadsword + Iron Helm`, elevated Attack & Vitality, starts with **Sundering Cleave**).
- Custom **Hero Name** entry & full save/load persistence across slots.

### 2. Combat Lock-On (`Target Lock`), Combo Action-RPG & Mobile Touch Controls
- **3-hit melee combo**, **heavy cleave**, **active spellcasting**, **directional dodge-roll with i-frames**, **shield block & timed parry**.
- **Target Lock-On (`T` on keyboard / `◎ LCK` on mobile touch)**:
  - Floating golden 3D target ring beneath locked enemies, auto-facing on melee & spell attacks, soft camera tracking, auto-retarget on kill, and live HUD **Locked Target HP Bar**.
- **Ergonomic Mobile Touch Controls**: virtual left thumbstick + curved right-hand action arc (`⚔ ATK`, `🪓 HVY`, `✦ MAG`, `💨 DGE`, `⬆ JMP`, `🛡 BLK`, `✦ USE`, `⚗ POT`, `◎ LCK`) with visual press feedback.

### 3. Living 3D World, Articulated Creatures & Smart Obstacle-Avoidance AI
- **3 Seamless Zones**:
  1. **Oakhaven Village & Surrounding Biomes** (pine woodland, river & stone bridge, lake, graveyard, ancient ruins, Sunken Crypt arena).
  2. **Adventurers Guild Hall** (Contracts Board, Quartermaster, Alchemy Station, Grandmaster).
  3. **Village Cottage Interior** (bed rest & storage).
- **18 Scheduled NPCs** with day/night routines, lantern lighting, and dynamic economy.
- **11 Enemy & Wildlife Archetypes + 2-Phase Boss (`Malakor, the Bone Warden`)**:
  - KayKit rigged undead (`Skeleton Warrior/Minion/Mage/Rogue`) + **articulated multi-limb 3D rigs** for `Dire Wolf`, `Forest Stag`, `Emerald Slime`, `Ancient Stone Golem`, `Cave Bat`, and `Shadow Wraith` with diagonal-stride limb/tail/core animation.
  - **5-angle raycast obstacle-avoidance steering** (`_steer_direction`) so creatures navigate cleanly around trees, walls, fences, and boulders.

### 4. Full Bilingual Localization (`English` + `العربية RTL`) & Interactive Story Prologue
- **Interactive 3-Chapter Eldoria Story Prologue (`StoryIntroOverlay`)** upon starting a new adventure (with Next / Skip controls).
- **100% Arabic (`RTL`) & English (`LTR`) Localization**:
  - Full UI, HUD, menus, **all 27 items**, **all 11 quests & guild contracts**, **all 24 skill-tree nodes**, **all 11 creatures/bosses**, and **all 18 NPC names, titles, greetings, quests & dialogues** rendered with bundled **Cairo** & **Noto Sans Arabic** (`SIL OFL 1.1`).

### 5. 3D World Quest Waypoint Beacon & Mobile GLES3 Performance
- **3D Quest Waypoint (`QuestWaypoint3D`)**: floating golden 3D diamond beacon + ground halo + live distance readout (`◆ 38m`) in 3D space, HUD Quest Tracker, and Minimap (`◆`) — automatically guiding players across zone doors, active objectives, and quest turn-in NPCs.
- **Mobile GLES3 Optimization**: MultiMesh vegetation/grass batching, static prop visibility-range culling (`VISIBILITY_RANGE_FADE_DISABLED`), shared materials, and `< 350` draw-call discipline across all 7 benchmarked zones.

---

## Running & Building

```bash
# Import assets (first run)
godot --headless --path . --import

# Play on desktop
godot --path .

# Run full headless acceptance suite
godot --headless --path . tests/test_runner.tscn
```

See `THIRD_PARTY_LICENSES.md` for full `CC0 1.0` & `SIL OFL 1.1` attribution and `docs/audit/` for architectural & change manifests.
