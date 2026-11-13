# ART DIRECTION SPECIFICATION — MICRO WORLD: LIVING (ELDORIA)

Selected Visual Identity: **HIGH-QUALITY SEMI-REALISTIC STYLIZED FANTASY**

Target Platform & Renderer: **Godot 4.3 · GL Compatibility (GLES3) · Android First**

---

## 1. Color Palette
All environment, architectural, and character materials adhere to a grounded highland fantasy palette with controlled saturation (`<= 0.65` in natural materials) so combat telegraphs, magic VFX, and UI cues read effortlessly:

| Element | Hex | Linear / sRGB Role |
|---|---|---|
| Meadow Grass | `#355228` | Primary valley turf |
| Sunlit Dry Grass | `#545C2E` | Hilltops and clearings |
| Forest Humus | `#26361C` | Dense canopy floor |
| Farmland Soil | `#4D3826` | Tilled crop rows & footpaths |
| Wet Riverbank Mud | `#3B3026` | River & lake shoreline |
| Cobblestone Plaza | `#6E6A63` | Village roads & central square |
| Highland Granite | `#595550` | Cliffs, crags & mountain slopes |
| Alpine Snow | `#DCE3EB` | Peaks strictly above `y >= 18.5m` |
| Eldoria River Water | `#235A75` | Translucent river & Crystal Lake |
| Oak / Broadleaf Canopy | `#385E28` | Deciduous woodland foliage |
| Evergreen Pine / Fir | `#214526` | Northern & highland conifers |
| Golden Birch | `#6E7A2C` | Autumnal accent groves |
| Weathered Bark | `#4A3525` | Tree trunks, logs & stumps |
| Sunlight (Day) | `#FFF0D6` | Warm natural directional key light |
| Sky Horizon Haze | `#8CA6BF` | Aerial perspective & distance fog |

## 2. Material Standards
- **PBR-Inspired Stylized Shading**: `StandardMaterial3D` with `metallic = 0.0` on all organic, stone, plaster, and timber surfaces (`metallic = 0.25–0.45` strictly reserved for forged weapons, plate armor, and gold trim).
- **Roughness Discipline**: Foliage `0.86`, bark/timber `0.90`, terrain/stone `0.94`, water `0.18`, steel/plate `0.42`.
- **Cross-Pack Material Harmonization (`ArtDirection`)**: Imported Kenney Nature Kit GLBs (which ship with exporter default `metallicFactor = 1.0` and saturated teal foliage) are automatically remapped on load by `ArtDirection.harmonize_mesh()` to `metallic = 0.0`, botanical roughness `0.86–0.92`, and species-accurate foliage/bark/stone palettes.

## 3. Texture Resolution
- Shared KayKit atlases (`hexagons_medieval.png`, `dungeon_texture.png`, `furniturebits_texture.png`, character `*_texture.png`): compact `512×512` to `1024×1024` palette/atlas PNGs (`14–16 KB` each), compressed with **ETC2/ASTC** (`import_etc2_astc = true`) for Android GPUs.
- Procedural cloud noise texture: `128×128` RGBA8 (`64 KB`).
- Zero 4K or 8K textures are shipped.

## 4. Geometry Density
- **Playable Scene Budget**: `< 200` draw calls (hard cap `300`), `< 120,000` rendered triangles per frame on GLES3.
- Terrain mesh: `72×72` grid (`10,368` triangles, 1 draw call).
- Botanical trees: `130–400` triangles per tree, batched by species via `MultiMeshInstance3D` (`1–2` draw calls per species across the entire forest).
- Characters: `5,600–6,900` triangles with unused offhand/weapon variants hidden (`7–8` active surfaces per character).

## 5. Character Proportions
- Unified **KayKit Humanoid Proportion Standard** (`~2.0m` world height at `scale = 1.0`, `CapsuleShape3D` `h = 2.0m, r = 0.36m`, feet grounded at `y = 0.0`, forward axis aligned via `MODEL_YAW_OFFSET = PI`).
- Player (`Knight.glb`) and all human NPCs (`Mage.glb`, `Rogue.glb`, `Barbarian.glb`, `Rogue_Hooded.glb`) share identical limb proportions and 76 skeletal animations while maintaining distinct role silhouettes via headwear, capes, tools, weapons, and tabard colors.

## 6. Building Proportions
- Village buildings use `SCALE_BUILDING = 8.5` (`7–11m` roof height for houses/shops, `14m` for guard towers, `18m+` landmark height for the **Grand Adventurers Guild (`building_castle_blue`)** so major landmarks read unmistakably across the valley).
- Roof colors encode district identity: **Royal Slate Blue** (Adventurers Guild, Chapel, Watermill), **Terracotta Red** (Guard Barracks, Bakery, Mine), **Warm Thatch Gold** (Tavern/Inn, Windmill, Farmhouses), **Moss Timber Green** (Blacksmith, Market, Cottages).

## 7. Vegetation Style
- Naturalistic multi-species silhouettes: broad-canopy Oaks (`tree-oak`, `tree-detailed`), conical Pines & Firs (`tree-pinetalla-detailed`, `tree-pinerounda`), slender Birches (`tree-thin`), saplings, stumps, fallen logs, bushes, ferns, wildflowers, and mushroom clusters.
- Deterministic clustered placement with slope/elevation/water/road exclusion masks, random yaw (`0..TAU`), and `±22%` scale variation. Zero grid rows or primitive unshaded cones.

## 8. Lighting
- Filmic tonemapping (`TONE_MAPPER_FILMIC`, `exposure = 0.88`, `contrast = 1.08`, `saturation = 0.96`) prevents highlights on plaster walls and stone floors from clipping.
- Single-pass `SHADOW_ORTHOGONAL` directional sunlight (`max_distance = 58m` on Medium/High, disabled on Low) synchronized with moonrise, sky zenith/horizon gradients, and warm evening village lanterns.

## 9. Atmospheric Effects
- Unified `DayNightCycle` + `CloudLayer` + `WeatherSystem` supporting **Clear, Partly Cloudy, Overcast, Light Rain, Heavy Rain, Fog, and Storm** states.
- Depth fog (`fog_aerial_perspective = 0.38`) blends distant mountain ridges smoothly into the horizon sky with zero volumetric raymarching cost.

## 10. Asset Consistency Rules
- Every humanoid character belongs to the KayKit rigged family.
- Every environmental prop passes through `ArtDirection` roughness/albedo harmonization and AABB ground-contact alignment (`min_y` snapped to terrain elevation `Terrain.height_at(x, z)`).
- Inactive interior/dungeon zones are hidden when the player is in another zone to guarantee zero wasted draw calls and zero sky-void artifacts.
