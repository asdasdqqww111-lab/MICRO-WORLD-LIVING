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
static func harmonize_mesh(source: Mesh, variant: String = "") -> Mesh:
	if source == null or DisplayServer.get_name() == "headless":
		return source
	var cache_key := "%s::%s" % [source.resource_path, variant]
	if _mat_cache.has(cache_key):
		return _mat_cache[cache_key] as Mesh
	var out := ArrayMesh.new()
	var surf_count := source.get_surface_count()
	for i in surf_count:
		var arrays := source.surface_get_arrays(i)
		if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
			continue
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var orig := source.surface_get_material(i)
		var mat := _adapt_surface_material(orig, variant, i)
		out.surface_set_material(out.get_surface_count() - 1, mat)
	var result: Mesh = out if out.get_surface_count() > 0 else source
	_mat_cache[cache_key] = result
	return result

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
	var fn := FastNoiseLite.new()
	fn.seed = 4242
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn.frequency = 0.085
	fn.fractal_octaves = 4
	var img := Image.create(128, 128, true, Image.FORMAT_RGBA8)
	var h_img := Image.create(128, 128, false, Image.FORMAT_RF)
	var r_img := Image.create(128, 128, true, Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128:
			# Tileable 4D torus noise for zero visible seams!
			var u := float(x) / 128.0 * TAU
			var v := float(y) / 128.0 * TAU
			var n := fn.get_noise_3d(cos(u) * 18.0 + sin(v) * 4.0, sin(u) * 18.0, cos(v) * 18.0) * 0.5 + 0.5
			var blade := fn.get_noise_3d(cos(u) * 52.0, sin(u) * 52.0, sin(v) * 52.0) * 0.5 + 0.5
			var lum := clampf(0.80 + n * 0.24 + (blade - 0.5) * 0.14, 0.65, 1.12)
			img.set_pixel(x, y, Color(lum * 0.98, lum * 1.01, lum * 0.95, 1.0))
			h_img.set_pixel(x, y, Color(clampf(n * 0.65 + blade * 0.35, 0.0, 1.0), 0.0, 0.0, 1.0))
			var rough := clampf(0.76 + (1.0 - n) * 0.20, 0.62, 0.98)
			r_img.set_pixel(x, y, Color(rough, rough, rough, 1.0))
	img.generate_mipmaps()
	r_img.generate_mipmaps()
	h_img.bump_map_to_normal_map(3.2)
	h_img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_mat_cache["terrain_detail_tex"] = tex
	_mat_cache["terrain_normal_tex"] = ImageTexture.create_from_image(h_img)
	_mat_cache["terrain_rough_tex"] = ImageTexture.create_from_image(r_img)
	return tex

static func terrain_normal_texture() -> ImageTexture:
	if not _mat_cache.has("terrain_normal_tex"):
		terrain_detail_texture()
	return _mat_cache.get("terrain_normal_tex", null) as ImageTexture

static func terrain_roughness_texture() -> ImageTexture:
	if not _mat_cache.has("terrain_rough_tex"):
		terrain_detail_texture()
	return _mat_cache.get("terrain_rough_tex", null) as ImageTexture

static func water_shader_material() -> Material:
	if DisplayServer.get_name() == "headless":
		return water_material()
	if _mat_cache.has("water_shader_mat"):
		return _mat_cache["water_shader_mat"] as Material
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_schlick_ggx;

uniform vec4 deep_color : source_color = vec4(0.09, 0.34, 0.48, 0.84);
uniform vec4 shallow_color : source_color = vec4(0.20, 0.54, 0.66, 0.76);

float wave_h(vec2 p, float t) {
	return sin(p.x * 1.35 + t * 1.6) * cos(p.y * 1.15 - t * 1.2) * 0.5
		+ sin((p.x + p.y) * 2.4 - t * 2.1) * 0.25;
}

void fragment() {
	vec2 wp = UV * 48.0;
	float e = 0.08;
	float h0 = wave_h(wp, TIME);
	float hx = wave_h(wp + vec2(e, 0.0), TIME);
	float hy = wave_h(wp + vec2(0.0, e), TIME);
	vec3 n = normalize(vec3((h0 - hx) * 0.55, (h0 - hy) * 0.55, 1.0));
	NORMAL_MAP = n * 0.5 + 0.5;
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 col = mix(deep_color.rgb, shallow_color.rgb, clamp(h0 * 0.5 + 0.5, 0.0, 1.0));
	col = mix(col, vec3(0.72, 0.86, 0.96), fresnel * 0.42);
	ALBEDO = col;
	ROUGHNESS = 0.09;
	METALLIC = 0.14;
	SPECULAR = 0.75;
	ALPHA = mix(deep_color.a, 0.92, fresnel * 0.5);
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	_mat_cache["water_shader_mat"] = sm
	return sm

## Creates a zero-shadow-cost Ground Contact Ambient Occlusion (AO) quad decal.
static func make_contact_ao(radius: float = 0.65, opacity: float = 0.42) -> MeshInstance3D:
	if not _mat_cache.has("contact_ao_mat"):
		var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for y in 32:
			for x in 32:
				var dx := (float(x) - 15.5) / 15.5
				var dy := (float(y) - 15.5) / 15.5
				var d := sqrt(dx * dx + dy * dy)
				var a := pow(clampf(1.0 - d, 0.0, 1.0), 1.85)
				img.set_pixel(x, y, Color(0.0, 0.0, 0.0, a))
		var tex := ImageTexture.create_from_image(img)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_texture = tex
		mat.albedo_color = Color(0.02, 0.03, 0.04, opacity)
		_mat_cache["contact_ao_mat"] = mat
	var mi := MeshInstance3D.new()
	mi.name = "ContactAO"
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius * 2.0, radius * 2.0)
	mi.mesh = plane
	mi.position = Vector3(0.0, 0.025, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 34.0
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	mi.material_override = _mat_cache["contact_ao_mat"] as Material
	return mi

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
