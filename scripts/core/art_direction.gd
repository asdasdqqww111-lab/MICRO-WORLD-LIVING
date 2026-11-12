class_name ArtDirection
extends RefCounted
## Central palette, PBR-inspired stylized material factory, and cross-pack
## asset harmonizer (see docs/ART_DIRECTION.md).

# --- Grounded Eldoria Palette ------------------------------------------------
const GRASS_LUSH := Color(0.21, 0.33, 0.15)
const GRASS_MEADOW := Color(0.31, 0.36, 0.17)
const FOREST_HUMUS := Color(0.16, 0.22, 0.12)
const SOIL_FARM := Color(0.30, 0.22, 0.15)
const MUD_WET := Color(0.23, 0.19, 0.15)
const SAND_SHORE := Color(0.56, 0.50, 0.38)
const ROAD_COBBLE := Color(0.43, 0.41, 0.38)
const ROCK_GRANITE := Color(0.34, 0.32, 0.30)
const ROCK_CLIFF := Color(0.42, 0.40, 0.37)
const SNOW_PEAK := Color(0.84, 0.87, 0.91)
const WATER_DEEP := Color(0.12, 0.32, 0.44, 0.86)
const WATER_SHALLOW := Color(0.19, 0.44, 0.54, 0.80)

# Botanical foliage & bark
const LEAF_OAK := Color(0.22, 0.38, 0.16)
const LEAF_ANCIENT := Color(0.17, 0.32, 0.14)
const LEAF_PINE := Color(0.13, 0.27, 0.15)
const LEAF_FIR := Color(0.16, 0.31, 0.18)
const LEAF_BIRCH := Color(0.34, 0.45, 0.18)
const LEAF_AUTUMN := Color(0.58, 0.42, 0.16)
const LEAF_BUSH := Color(0.20, 0.35, 0.15)
const LEAF_FERN := Color(0.24, 0.40, 0.18)
const BARK_OAK := Color(0.29, 0.21, 0.15)
const BARK_BIRCH := Color(0.62, 0.58, 0.52)
const BARK_DEAD := Color(0.34, 0.28, 0.22)

static var _mat_cache: Dictionary = {}

static func stylized_material(key: String, albedo: Color, roughness: float = 0.88,
		metallic: float = 0.0, cull: int = BaseMaterial3D.CULL_BACK) -> StandardMaterial3D:
	if _mat_cache.has(key):
		return _mat_cache[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = roughness
	mat.metallic = metallic
	mat.cull_mode = cull
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	_mat_cache[key] = mat
	return mat

static func water_material() -> StandardMaterial3D:
	if _mat_cache.has("water_eldoria"):
		return _mat_cache["water_eldoria"] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = WATER_DEEP
	mat.roughness = 0.16
	mat.metallic = 0.08
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_cache["water_eldoria"] = mat
	return mat

## Adapts Kenney Nature/Castle GLB surfaces (which export with metallic=1.0 and
## bright teal foliage) into Eldoria's natural matte botanical/stone palette.
static func harmonize_mesh(source: Mesh, variant: String = "") -> ArrayMesh:
	if source == null:
		return null
	var cache_key := "%s::%s" % [source.resource_path, variant]
	if _mat_cache.has(cache_key):
		return _mat_cache[cache_key] as ArrayMesh
	var out := ArrayMesh.new()
	var surf_count := source.get_surface_count()
	for i in surf_count:
		var arrays := source.surface_get_arrays(i)
		if arrays.is_empty():
			continue
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var orig := source.surface_get_material(i)
		var mat := _adapt_surface_material(orig, variant, i)
		out.surface_set_material(out.get_surface_count() - 1, mat)
	_mat_cache[cache_key] = out
	return out

static func _adapt_surface_material(orig: Material, variant: String, surf_idx: int) -> StandardMaterial3D:
	var m_name := orig.resource_name.to_lower() if orig != null else ""
	var base_col := Color(0.5, 0.5, 0.5)
	var tex: Texture2D = null
	if orig is BaseMaterial3D:
		var bm := orig as BaseMaterial3D
		base_col = bm.albedo_color
		tex = bm.albedo_texture
	if tex != null:
		var textured := StandardMaterial3D.new()
		textured.albedo_texture = tex
		textured.albedo_color = Color(0.96, 0.95, 0.92)
		textured.roughness = 0.88
		textured.metallic = 0.0
		return textured

	# Classify untextured PBR surfaces by material name or color channel dominance
	if m_name.contains("leaf") or m_name.contains("grass") or m_name.contains("plant") or (base_col.g > base_col.r * 1.15 and base_col.g > 0.35):
		match variant:
			"pine":
				return stylized_material("foliage_pine", LEAF_PINE, 0.88)
			"fir":
				return stylized_material("foliage_fir", LEAF_FIR, 0.87)
			"ancient":
				return stylized_material("foliage_ancient", LEAF_ANCIENT, 0.89)
			"birch":
				return stylized_material("foliage_birch", LEAF_BIRCH, 0.85)
			"autumn":
				return stylized_material("foliage_autumn", LEAF_AUTUMN, 0.86)
			"bush":
				return stylized_material("foliage_bush", LEAF_BUSH, 0.88)
			"fern":
				return stylized_material("foliage_fern", LEAF_FERN, 0.86, 0.0, BaseMaterial3D.CULL_DISABLED)
			_:
				return stylized_material("foliage_oak", LEAF_OAK, 0.87)
	if m_name.contains("wood") or m_name.contains("bark") or m_name.contains("trunk") or m_name.contains("dirt"):
		if variant == "birch":
			return stylized_material("bark_birch", BARK_BIRCH, 0.90)
		if variant == "dead":
			return stylized_material("bark_dead", BARK_DEAD, 0.93)
		return stylized_material("bark_oak", BARK_OAK, 0.92)
	if m_name.contains("rock") or m_name.contains("stone") or m_name.contains("cliff"):
		return stylized_material("stone_granite", ROCK_GRANITE if surf_idx == 0 else ROCK_CLIFF, 0.94)
	if m_name.contains("flower") or m_name.contains("mushroom") or m_name.contains("crop") or m_name.contains("wheat"):
		var toned := Color(
			clampf(base_col.r * 0.82, 0.08, 0.88),
			clampf(base_col.g * 0.78, 0.08, 0.82),
			clampf(base_col.b * 0.78, 0.06, 0.82),
			1.0
		)
		return stylized_material("flora_%s_%d" % [variant, surf_idx], toned, 0.86)
	var fallback_col := Color(
		clampf(base_col.r * 0.85, 0.1, 0.88),
		clampf(base_col.g * 0.85, 0.1, 0.88),
		clampf(base_col.b * 0.85, 0.1, 0.88),
		1.0
	)
	return stylized_material("generic_%s_%d_%s" % [variant, surf_idx, m_name], fallback_col, 0.90)

static func harmonize_material(orig: Material, variant: String = "") -> StandardMaterial3D:
	return _adapt_surface_material(orig, variant, 0)

static func terrain_detail_texture() -> ImageTexture:
	if _mat_cache.has("terrain_detail_tex"):
		return _mat_cache["terrain_detail_tex"] as ImageTexture
	var img := Image.create(64, 64, true, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for y in 64:
		for x in 64:
			var n := 0.88 + rng.randf() * 0.22
			img.set_pixel(x, y, Color(n, n * 0.99, n * 0.97, 1.0))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_mat_cache["terrain_detail_tex"] = tex
	return tex

## Harmonizes an instantiated Node3D hierarchy in-place (strips metallic=1 glare).
static func harmonize_node(root: Node, variant: String = "") -> void:
	if root == null:
		return
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c: Node in n.get_children():
			stack.append(c)
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh != null:
				mi.mesh = harmonize_mesh(mi.mesh, variant)
