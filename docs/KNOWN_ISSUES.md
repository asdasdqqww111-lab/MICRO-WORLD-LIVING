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

## Engineering pass 2026-11-14 (branch `arena/a78be979-micro-world-living`)

### Resolved
- **Touch controls were single-pointer.** The combat cluster used stock `Button` nodes, which only react to mouse events; the engine emulates the mouse from one finger at a time, so buttons could not be pressed while another finger held the joystick. The cluster now uses `TouchActionButton` (finger-index ownership, TAP / HOLD / TOGGLE). Covered by 20 headless checks; **not yet verified on a physical touchscreen**.
- **LOW graphics preset was overridden.** `WorldRoot` forced MSAA 4X + FXAA every time the world was built. Viewport anti-aliasing and render scale are now set only by `SettingsManager.apply_graphics()`; LOW also disables glow.
- **`TowerDB.mob_stats()` type-inference error** that cascaded into `tower_floor_builder.gd`, `tower_manager.gd` and `core/game.gd` at load time.
- **Tower acceptance suite never ran in CI.** `tests/tower_test_runner.tscn` is now executed by both workflows (62 checks).
- **HUD notifications overlapped the district panel** (fixed y offset); they now flow below the top-right stack.

### Open (measured)
- **HUD draw calls dominate the frame.** CI probe (software rasteriser, Hero Cottage Interior): 324 draw calls per frame, of which HUD 258, touch controls 48, 3D scene 18. Godot 4.3's Mobile renderer does not batch 2D, so every glyph and panel is its own draw call. This is why every zone exceeds the probe's 300 draw-call budget. See `docs/reports/perf_probe_results.txt` for the per-panel table.
- **Triangle budget exceeded** in Village Square (182,654) and Active Combat (200,474) against a 180k budget.
- **No on-device measurements exist.** All numbers come from a software rasteriser in CI; FPS, frame time and thermal behaviour on Android hardware are unmeasured.

### Open (by inspection, not yet addressed)
- HUD top-centre dock, minimap and menu screens still use stock `Button` input (single pointer). They work when no other finger is down.
- Quick-slot squares in the touch layout are decorative; `TouchControls.menu_action` is never emitted.
- `Continue` in the main menu loads only the manual slot, never the autosave slot.
- Saving removes the previous file before the temporary file is renamed; there is no backup copy.
- `CollisionLayers` bit values do not match the layer names declared in `project.godot`.
- SSAO is enabled in the environment but is ignored by the Mobile renderer (engine warning in CI logs).
- Volume sliders write the settings file on every slider step.
- Several UI strings bypass `Localization` (main menu, pause screen, HUD).
- Release signing: CI produces a debug-signed APK only.
