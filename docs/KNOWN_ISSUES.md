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
- Minimap and menu screens still use stock `Button` input (single pointer). They work when no other finger is down.
- `Continue` in the main menu loads only the manual slot, never the autosave slot.
- Saving removes the previous file before the temporary file is renamed; there is no backup copy.
- `CollisionLayers` bit values do not match the layer names declared in `project.godot`.
- SSAO is enabled in the environment but is ignored by the Mobile renderer (engine warning in CI logs).
- Volume sliders write the settings file on every slider step.
- Several UI strings bypass `Localization` (main menu, pause screen, HUD).
- Release signing: CI produces a debug-signed APK only.

## City, controls, performance and size pass (same branch, second round)

### Resolved
- **Town layout was scattered.** Buildings, streets, walls, gates and gardens now come from one plan (`scripts/world/city_plan.gd`): a round wall (radius 36 m) with east, south and west gates, the citadel closing the north side, a central plaza, two crossing avenues and side streets, and 22 building lots that face their street. Terrain flattening, road material, minimap, world map, NPC routes and door exits read the same plan. The forest no longer grows inside the walls. `docs/screenshots/14_city_overview.png` is a top-down capture of the result.
- **East bridge sat at an angle to its road.** The hexagon-kit bridge model runs along a hex axis; it is now turned 60 degrees so the deck lies on the East Avenue.
- **HUD draw calls.** CI probe, Hero Cottage Interior: 324 -> 119 draw calls per frame (HUD 258 -> 44, touch controls 48 -> 57 with three new working quick slots and the interact prompt, 3D 18). Village Square total 448 -> 271, Active Combat 334 -> 156.
- **Touch layout.** Icon-only round buttons in two arcs around the attack button, working quick slots (health potion, mana elixir, food), a tappable interact prompt, a round sprint toggle and safe-area offsets. The top dock now uses `TouchActionButton`, so menus open while another finger holds the stick.
- **Per-frame work.** NPCs and creatures stop animating and drawing when far away, far AI is throttled, shared player/terrain lookups are cached, day-night atmosphere updates four times a second, FXAA no longer runs on top of MSAA.
- **Phone resolution.** On mobile the 3D image height is capped per preset (LOW 720 px, MEDIUM 900 px, HIGH 1080 px); the HUD stays native. Mobile also uses one shadow split and a 1024 px shadow map.
- **Download size.** Debug APK 96.7 MB -> about 69.5 MB. 311 unreferenced asset files and a duplicate `Knight.glb` were removed, three 2048 px textures were reduced to 512 px, and each character rig keeps only the animation clips the game resolves (76/95 -> 33/36). `assets/` went from 76 MB to 27 MB.
- City ambience never played because the audio code compared against a biome name the terrain no longer returns.

### Open
- **Triangle budget** is still exceeded in the plaza (about 212k in Village Square, 228k in Active Combat, against 180k) on the MEDIUM preset with shadows. Each character rig is 5-7k triangles and the compact town puts more buildings in view. LOW (the phone default) draws no shadow pass.
- **No on-device measurements exist.** Draw-call and triangle counts come from a software rasteriser in CI. Frame rate, frame time and heat on Android hardware are unmeasured, and the mobile-only settings (resolution cap, single shadow split, 1024 px shadow map) are not exercised by CI.
- `TouchControls.menu_action` is still never emitted (the menu button lives in the HUD dock).

## Engine upgrade and 64-bit only build (same branch, third round)

### Done
- **Godot 4.3 -> 4.4.1.** Both workflows install 4.4.1 and its export templates (version set once in the workflow `env` block). Acceptance 215/0 and tower 62/0 on the new engine; no script errors or new engine warnings in the CI logs; all 14 screenshots render.
- **2D batching arrives with 4.4.** CI probe, Hero Cottage Interior: 119 -> 75 draw calls per frame (HUD 44 -> 24, touch controls 57 -> 30). Village Square total 271 -> 171.
- **`arm64-v8a` only.** The Android preset no longer ships `armeabi-v7a`; debug APK about 69.5 MB -> 47.1 MB. 32-bit phones cannot install this build.
- **Engine-generated files.** Godot 4.4 writes a `.uid` file next to every script and shader and refreshes `.import` files. The probe workflow commits them with the evidence so the working tree stays clean.

### Open
- **Not verified on a phone.** The 4.4.1 build has only run on CI (headless and a software Vulkan rasteriser). Start-up, frame rate and the expected reduction in first-appearance shader hitches on Android hardware are unmeasured.
- The probe reports more 3D draw calls in the plaza on 4.4.1 (72 -> 117) while the total fell; whether the engine counts differently or draws more was not investigated.
- Every CI build is signed with a freshly generated debug key, so a new APK cannot be installed over an older one; the old app has to be removed first (its save data goes with it). A fixed keystore stored as a repository secret would fix this.
