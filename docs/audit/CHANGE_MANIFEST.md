# Complete Change Manifest — MICRO WORLD: LIVING (Eldoria Edition v1.0)

## 1. Phase 0 Backup & Rollback Artifacts (Outside Live Repo)
- **Full Verified Backup Root**: `/home/user/BACKUPS/micro-world-living-20261112-212200/`
  - `micro-world-living-pre-upgrade-20261112-212200.tar.gz` (`25 MB`, `392/392` files SHA-256 verified `OK`)
  - `BACKUP_VERIFICATION_REPORT.md` & `RECOVERY_PROCEDURE.md`
- **Untouched Original Asset Archive**: `/home/user/ORIGINAL_ASSETS/`
  - `curated_source_archive.tar.gz` (`29 MB`, SHA-256 verified `OK` via `ARCHIVE_SHA256.txt`)
  - `licenses/` (Upstream CC0 1.0 & SIL OFL 1.1 license files)

---

## 2. Added Files

### Documentation & Tooling
- `docs/ART_DIRECTION.md` — Visual style guide, color palette, lighting, proportions & mobile GPU budgets
- `docs/ASSET_LICENSE_MANIFEST.md` — Complete CC0 / OFL provenance & license table
- `docs/audit/PROJECT_AUDIT.md` — Baseline vs. Eldoria v1.0 technical audit
- `docs/audit/CHANGE_MANIFEST.md` — Complete file-by-file change manifest
- `tools/generate_audio_cc0.py` — Deterministic CC0 `.wav` SFX & ambient loop synthesizer

### Curated CC0 / OFL Assets
- `assets/fonts/` — `NotoSans-Regular.ttf`, `NotoSans-Bold.ttf`, `NotoSansArabic-Regular.ttf`, `NotoSansArabic-Bold.ttf`, `OFL_LICENSE.txt`
- `assets/models/characters/` — `Mage.glb`, `Rogue.glb`, `Rogue_Hooded.glb`, `Barbarian.glb`
- `assets/models/monsters/` — `Goblin.gltf`, `Goblin.bin`, `goblin_Albedo.png`
- `assets/models/medieval/` — 33 KayKit Medieval Hexagon `.gltf`/`.bin` buildings, walls, bridges, watermill, trees, clouds & `medieval_texture.png`
- `assets/models/dungeon_remastered/` — 29 KayKit Dungeon Remastered `.gltf`/`.bin` structural/furniture/prop models & `dungeon_texture.png`
- `assets/models/nature_tge/` — 9 Hidencod CC0 foliage & prop `.glb` models (`oak_trees`, `Grass`, `Flowers`, `DeadTree`, `Rock`, `Fence`, `Lantern`, `WoodLog`, `SignBoard`)
- `assets/textures/world/` — 4 CC0 stylized surface textures (`cobblestone_albedo.jpg`, `rock_cliff_albedo.jpg`, `plaster_wall_albedo.jpg`, `wood_planks_albedo.jpg`)
- `assets/sounds/` — 16 CC0 `.wav` combat, movement, gathering, chest, quest & UI sound effects
- `assets/music/` — 3 CC0 `.wav` ambient zone music loops (`eldoria_village_theme`, `guild_hall_theme`, `dungeon_crypt_theme`)

### New Core, Data, World & UI Scripts + Resources
- `scripts/core/art_direction.gd` — Shared PBR material cache, river/lake shader materials & lighting palette
- `scripts/core/localization.gd` — Bilingual English & Arabic (`ar` RTL) string dictionary + layout helper
- `scripts/core/audio_manager.gd` — Autoload SFX pool + crossfaded zone music controller
- `scripts/data/guild_system.gd` — Adventurers Guild Ranks `F–S`, reputation, promotions & contract limits
- `scripts/data/crafting_db.gd` — Blacksmith Forge & Apothecary Alchemy crafting recipes
- `scripts/world/resource_node.gd` — Harvestable Iron Ore, Timber, Moonpetal & Sunleaf nodes with timed respawn
- `scripts/world/crafting_station.gd` — Interactive Forge Anvil & Alchemy Table props
- `scripts/world/quest_board_prop.gd` — Interactive Village & Guild Hall Contract Boards
- `scripts/world/dungeon_trap.gd` — Timed floor spike traps in Sunken Crypt corridors
- `scripts/ui/minimap_control.gd` — Live top-right Eldoria radar with cardinal markers, landmarks, NPCs & hostiles
- `scripts/ui/skill_tree_screen.gd` — Zoomable 24-node 4-branch Skill Tree with `_draw()` connectors & reset dialog
- `scripts/ui/guild_screen.gd` — Official Adventurers Guild Hall ledger, rank promotion & contracts UI
- `scripts/ui/crafting_screen.gd` — Blacksmith & Alchemy crafting interface
- `scripts/ui/world_map_screen.gd` — Illustrated Eldoria Regional Map with live player & landmark markers
- `resources/items/*.tres` — 13 new weapons, shields, armor, accessories, potions & herbs (27 total items)
- `resources/creatures/*.tres` — 7 new wildlife, monster, elite & boss resources (11 total creature types)
- `resources/quests/*.tres` — 9 new Main Story, Village Side & Guild Rank `F–B` contracts (11 total quests)

---

## 3. Upgraded Existing Files (Preserving Save Schema v1–v3 & Core Contracts)
- `project.godot` — Version `1.0`, `AudioManager` autoload, compatibility renderer polish
- `scripts/core/{event_bus,settings_manager,asset_library,input_setup,character_visual,game_manager,save_manager,game}.gd`
- `scripts/data/{character_stats,item_data,item_db,skill_data,skill_db,skill_tree,quest_data,quest_db,quest_log,creature_data,creature_db,progression}.gd`
- `scripts/inventory/inventory.gd` — Expanded to 5 equipment slots (`weapon`, `armor`, `helmet`, `shield`, `accessory`) + magic/crit totals
- `scripts/camera/camera_rig.gd`, `scripts/player/{player,player_input}.gd`, `scripts/creatures/{creature,procedural_models}.gd`
- `scripts/world/{terrain,cloud_layer,day_night_cycle,weather_system,market,village_npc,treasure_chest,loot_drop,world_state,world_builder,world_root}.gd`
- `scripts/ui/{ui_factory,menu_screen,hud,touch_controls,inventory_screen,character_screen,journal_screen,shop_screen,dialog_screen,pause_screen,main_menu,ui_root}.gd`
- `tests/{test_runner,perf_probe,screenshot_probe}.gd` & `.github/workflows/{probe,android}.yml`
