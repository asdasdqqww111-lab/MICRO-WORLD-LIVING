# Known Issues & Roadmap Notes (Eldoria v1.1)

## Resolved in v1.0 & v1.1 (Phase 1)
- **Resolved:** Playable class selection (`Knight`, `Battlemage`, `Ranger`, `Barbarian`) with real 3D `.glb` rigs & save persistence (`v1.1`).
- **Resolved:** Combat `Target Lock` (`KEY_T` / `◎ LCK`) with 3D ring, camera tracking, and HUD enemy HP card (`v1.1`).
- **Resolved:** Articulated 3D multi-limb rigs for `Wolf`, `Stag`, and `Slime` + 5-ray obstacle avoidance AI (`v1.1`).
- **Resolved:** Full 100% Arabic (`RTL`) translation of all quests, items, skills, creatures, NPC dialogues, and 3-chapter story prologue (`v1.1`).
- **Resolved:** 3D World Quest Waypoint beacon + HUD distance + Minimap objective diamond (`v1.1`).

## Resolved in v4.0 (Celestial Ascent Tower)
- **Resolved:** 100-floor playable dungeon tower with a unique Floor Master per floor (`arena/complete-world-transformation`).
- **Resolved:** Deterministic floor progression saved in `WorldState.flags` — defeated masters stay defeated across save/load.
- **Resolved:** One-floor streaming so the tower never holds more than a single floor in memory (mobile budget).

## Remaining Future Opportunities (Phase 2+)
1. **Play Store Release Keystore:** CI exports an installable debug-signed APK (`v1.1-debug`); Google Play production `.aab` submission requires a private release keystore outside public Git.
2. **Additional Dungeon Floors & Mounts:** Expanding the Sunken Crypt into multi-floor procedural catacombs and adding rideable mounts across Oakhaven's outer biomes.
3. **Voiceover Audio Clips:** Adding optional localized voice barks for Elder Theron, Grandmaster Aldric, and Boss Malakor.
4. **Unique 3D Boss Models:** Floor Masters currently reuse the shipped creature rigs with region tints and scaling; distinct 3D boss models per Floor Master remain a future art upgrade.
5. **On-device Tower performance pass:** The tower ships within the Sunken Crypt's mobile budget, but FPS/draw-call numbers inside the tower on real hardware await the device verification round (same as the rest of the game).
