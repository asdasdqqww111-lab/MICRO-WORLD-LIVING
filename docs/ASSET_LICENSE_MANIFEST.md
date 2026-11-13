# Asset License & Provenance Manifest — MICRO WORLD: LIVING (Eldoria Edition v1.0)

Every external 3D model, rig, animation library, surface texture, font, sound effect, and music track in **MICRO WORLD: LIVING — Chronicles of Eldoria** is **100% free, commercial-safe, and legally verified** (**CC0 1.0 Public Domain**, **SIL Open Font License 1.1**, or **100% in-repo procedural CC0 synthesis**).

Untouched original copies of every downloaded asset and upstream `LICENSE` file are archived outside the live game directory at:
- `/home/user/ORIGINAL_ASSETS/curated_source_archive.tar.gz` (verified against `/home/user/ORIGINAL_ASSETS/ARCHIVE_SHA256.txt`)
- `/home/user/ORIGINAL_ASSETS/licenses/`

---

## 1. 3D Character Rigs, Animation Libraries, Props & Architecture (CC0 1.0)

| Pack / Collection | Author / Upstream Repository | License | Destination in Project | Asset Count & Usage |
|---|---|---|---|---|
| **KayKit Character Pack: Adventures** | Kay Lousberg — `https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0` | **CC0 1.0 Public Domain** | `assets/models/characters/` (`Knight.glb`, `Mage.glb`, `Rogue.glb`, `Rogue_Hooded.glb`, `Barbarian.glb`) & `assets/models/animations/` (`Rig_Medium_General.glb`, `Rig_Medium_MovementBasic.glb`) | Playable Knight hero, 18 living Village & Guild NPCs, shared skeletal animation clips (`idle`, `walk`, `run`, `jump`, `attack`, `hit`, `death`, `interact`) |
| **KayKit Character Pack: Skeletons** | Kay Lousberg (existing repo CC0 pack) | **CC0 1.0 Public Domain** | `assets/models/characters/` (`Skeleton_Warrior.glb`, `Skeleton_Rogue.glb`, `Skeleton_Mage.glb`, `Skeleton_Minion.glb`) | Undead forest patrols, Eastern Ruins, Sunken Crypt guards & Boss Malakor |
| **Gobkit Monster Pack** | `https://github.com/emptyflask/Gobkit` | **CC0 1.0 Public Domain** | `assets/models/monsters/Goblin.gltf` (+ `.bin` & `goblin_Albedo.png`) | Goblin Scouts, Goblin Raiders, Orc Berserker & Forest Troll variants |
| **KayKit Medieval Hexagon Pack** | Kay Lousberg — `https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0` | **CC0 1.0 Public Domain** | `assets/models/medieval/` (33 `.gltf` buildings, castle walls/towers, church/guild hall, blacksmith, market, tavern, watermill, stone bridge, trees, rocks, clouds + shared `medieval_texture.png` atlas) | Eldoria Village architecture, Grand Adventurers Guild Hall exterior, East Stone Arch Bridge, Watermill, Mountain peaks & volumetric clouds |
| **KayKit Dungeon Remastered** | Kay Lousberg — `https://github.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.1` | **CC0 1.0 Public Domain** | `assets/models/dungeon_remastered/` (29 `.gltf` modular stone walls, arches, pillars, stairs, banners, crates, barrels, tables, chairs, chests, beds, torches, keys + shared `dungeon_texture.png` atlas) | Adventurers Guild Grand Hall interior, Hero Cottage interior, Sunken Crypt multi-room dungeon, traps & Boss Sanctum |
| **Hidencod TGE Foliage & Props (CC0)** | `https://github.com/Hidencod/tge-assets` | **CC0 1.0 Public Domain** | `assets/models/nature_tge/` (`oak_trees.glb`, `Grass.glb`, `Flowers.glb`, `DeadTree.glb`, `Rock.glb`, `Fence.glb`, `Lantern.glb`, `WoodLog.glb`, `SignBoard.glb`) | MultiMesh multi-species woodland canopy, ground grass, wildflower patches, deadwood & trail props |
| **Kenney Nature & Graveyard Props** | Kenney.nl (existing repo CC0 pack) | **CC0 1.0 Public Domain** | `assets/models/nature/`, `assets/models/village/`, `assets/models/dungeon/` | Pine groves, river boulders, mushrooms, campfires, crypt pillars & iron fences |
| **Tiny Treats: Homely House 1.0** | Isa Lousberg — `https://github.com/TinyTreats-Game-Assets/Tiny-Treats-Homely-House-1.0` | **CC0 1.0 Public Domain** | `assets/environments/tinytreats_house/` (`house.gltf`, `bench_A.gltf`, `cobblestones.gltf`, `fence_straight.gltf`, `mailbox.gltf`, `tree_large.gltf` + `tiny_treats_texture_1.png`) | Detailed shingle-roofed residential cottages, plaza benches, fences & woodland canopy |
| **Tiny Treats: Pretty Park 1.0** | Isa Lousberg — `https://github.com/TinyTreats-Game-Assets/Tiny-Treats-Pretty-Park-1.0` | **CC0 1.0 Public Domain** | `assets/environments/tinytreats_park/` (`fountain.gltf`, `street_lantern.gltf`, `cobble_stones_large.gltf`, `bush_large.gltf`, `flower_A.gltf`, `grass_A.gltf`, `tree.gltf`, `tree_large.gltf` + `tiny_treats_texture_1.png`) | Village Plaza stone fountain, iron street lanterns, MultiMesh trees, bushes, wildflowers & 3D meadow grass |
| **Procedural Wildlife & Boss Adornments** | In-repo `scripts/creatures/procedural_models.gd` | **CC0 1.0 (Original Code)** | Runtime `ArrayMesh` | Forest Deer, Grey Wolf, Dire Wolf, Meadow Rabbit & Elder Treant |

---

## 2. World & Architectural Surface Textures (CC0 1.0)

| Pack / Asset | Upstream Repository | License | Destination in Project | Usage |
|---|---|---|---|---|
| **Stylized PBR Albedo Textures** | `https://github.com/Sweatersjpg/Free-Game-Dev-Assets` (AmbientCG / PolyHaven CC0) | **CC0 1.0 Public Domain** | `assets/textures/world/` (`cobblestone_albedo.jpg`, `rock_cliff_albedo.jpg`, `plaster_wall_albedo.jpg`, `wood_planks_albedo.jpg`) | Eldoria village cobblestone roads, Guild & cottage interior timber floors, alpine cliff accents |
| **KayKit Shared Palette Atlases** | Kay Lousberg (`KayKit-*`) | **CC0 1.0 Public Domain** | `assets/models/medieval/medieval_texture.png`, `assets/models/dungeon_remastered/dungeon_texture.png` | Single-atlas batching across medieval buildings & dungeon modules |

---

## 3. UI Typography — English & Arabic RTL (SIL Open Font License 1.1)

| Font | Upstream Repository | License | Destination in Project | Usage |
|---|---|---|---|---|
| **Cairo Variable (Arabic + Latin)** | Mohamed Gaber / Google Fonts — `https://github.com/google/fonts/tree/main/ofl/cairo` | **SIL OFL 1.1** (`assets/ui/fonts/LICENSE_Cairo_OFL.txt`) | `assets/ui/fonts/Cairo-Variable.ttf` | Primary Glassmorphism UI & HUD Arabic + English geometric typography |
| **Noto Sans Bold & Regular** | Google Noto Fonts — `https://github.com/notofonts/latin-greek-cyrillic` | **SIL OFL 1.1** (`assets/fonts/OFL_LICENSE.txt`) | `assets/ui/fonts/NotoSans-Bold.ttf`, `assets/ui/fonts/NotoSans-Medium.ttf` | Fallback Latin typography |
| **Noto Sans Arabic Bold & Regular** | Google Noto Fonts — `https://github.com/notofonts/arabic` | **SIL OFL 1.1** (`assets/fonts/OFL_LICENSE.txt`) | `assets/fonts/NotoSansArabic-Bold.ttf`, `assets/fonts/NotoSansArabic-Regular.ttf` | Native Arabic script shaping + RTL fallback across all UI menus & dialogues |

---

## 4. Sound Effects & Ambient Music (CC0 1.0 — Deterministic In-Repo Synthesis)

Generated deterministically via `tools/generate_audio_cc0.py` (100% original mathematical synthesis, zero third-party samples, **CC0 1.0 Public Domain**):

- **16 Sound Effects (`assets/sounds/*.wav`)**:
  `sword_swing_1.wav`, `sword_swing_2.wav`, `heavy_slash.wav`, `hit_flesh.wav`, `hit_armor.wav`, `shield_block.wav`, `dodge_roll.wav`, `spell_cast.wav`, `footstep_grass.wav`, `footstep_stone.wav`, `chest_open.wav`, `coin_pickup.wav`, `level_up.wav`, `quest_complete.wav`, `ui_click.wav`, `equip_gear.wav`
- **3 Seamless Ambient Music Loops (`assets/music/*.wav`)**:
  `eldoria_village_theme.wav` (Pastoral Harp & Flute), `guild_hall_theme.wav` (Warm Lute & Brass Chords), `dungeon_crypt_theme.wav` (Dark Ambient Crypt Drone)

---

## 5. Verification Summary
- **Commercial / Redistribution Restrictions:** None (all CC0 1.0 or SIL OFL 1.1 with bundled `OFL_LICENSE.txt`).
- **Paid / Proprietary / Watermarked Assets:** `0`.
- **Missing License Files:** `0`.
