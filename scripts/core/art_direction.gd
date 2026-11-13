class_name ArtDirection
extends RefCounted
## Realistic Cinematic AAA Mobile PBR Material Engine (Eldoria Realistic Edition).
## Applies StandardMaterial3D with real Normal Maps + Roughness Maps (res://assets_realistic/textures/)
## across architecture, terrain, foliage, rocks, armor/weapons, and dual-normal specular water,
## while sharing cached material instances for peak 60 FPS mobile GLES3 performance.

# --- Grounded Cinematic Realistic Palette ------------------------------------
const GRASS_LUSH := Color(0.24, 0.36, 0.18)
const GRASS_MEADOW := Color(0.32, 0.40, 0.21)
const FOREST_HUMUS := Color(0.18, 0.25, 0.14)
const SOIL_FARM := Color(0.32, 0.24, 0.17)
const MUD_WET := Color(0.24, 0.20, 0.16)
const SAND_SHORE := Color(0.58, 0.52, 0.40)
const ROAD_COBBLE := Color(0.50, 0.48, 0.45)
const ROCK_GRANITE := Color(0.44, 0.42, 0.40)
const ROCK_CLIFF := Color(0.50, 0.48, 0.45)
const SNOW_PEAK := Color(0.88, 0.90, 0.94)
const WATER_DEEP := Color(0.06, 0.22, 0.34, 0.88)
const WATER_SHALLOW := Color(0.11, 0.35, 0.46, 0.80)

const LEAF_OAK := Color(0.25, 0.40, 0.18)
const LEAF_ANCIENT := Color(0.20, 0.34, 0.16)
const LEAF_PINE := Color(0.16, 0.29, 0.17)
const LEAF_FIR := Color(0.18, 0.33, 0.19)
const LEAF_BIRCH := Color(0.36, 0.46, 0.20)
const LEAF_AUTUMN := Color(0.64, 0.44, 0.18)
const LEAF_BUSH := Color(0.23, 0.37, 0.17)
const LEAF_FERN := Color(0.26, 0.42, 0.19)
const BARK_OAK := Color(0.34, 0.25, 0.18)
const BARK_BIRCH := Color(0.72, 0.68, 0.62)
const BARK_DEAD := Color(0.38, 0.31, 0.25)

const TEX_DIR := "res://assets_realistic/textures/"

static var _mat_cache: Dictionary = {}
static var _tex_cache: Dictionary = {}

static func get_realistic_tex(file_name: String) -> Texture2D:
	if _tex_cache.has(file_name):
		return _tex_cache[file_name] as Texture2D
	var full := TEX_DIR + file_name
	var tex: Texture2D = null
	if ResourceLoader.exists(full):
		tex = ResourceLoader.load(full) as Texture2D
	_tex_cache[file_name] = tex
	return tex

## Builds a cached triplanar PBR StandardMaterial3D with Albedo + Normal Map + Roughness Map.
static func pbr_material(key: String, set_prefix: String, tint: Color = Color.WHITE,
		uv_scale: float = 0.32, roughness_val: float = 0.86, metallic_val: float = 0.0,
		normal_strength: float = 0.92, triplanar: bool = true) -> StandardMaterial3D:
	if _mat_cache.has(key):
		return _mat_cache[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	var alb := get_realistic_tex(set_prefix + "_albedo.jpg")
	var nrm := get_realistic_tex(set_prefix + "_normal.jpg")
	var rgh := get_realistic_tex(set_prefix + "_roughness.jpg")
	if alb != null:
		mat.albedo_texture = alb
	if nrm != null:
		mat.normal_enabled = true
		mat.normal_texture = nrm
		mat.normal_scale = normal_strength
	if rgh != null:
		mat.roughness_texture = rgh
	mat.roughness = roughness_val
	mat.metallic = metallic_val
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	if triplanar:
		mat.uv1_triplanar = true
		mat.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	_mat_cache[key] = mat
	return mat

static func armor_metal_material(key: String, tint: Color, metallic_val: float = 0.82,
		roughness_val: float = 0.30) -> StandardMaterial3D:
	if _mat_cache.has(key):
		return _mat_cache[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.metallic = metallic_val
	mat.roughness = roughness_val
	var nrm := get_realistic_tex("armor_metal_normal.jpg")
	if nrm != null:
		mat.normal_enabled = true
		mat.normal_texture = nrm
		mat.normal_scale = 0.55
		mat.uv1_triplanar = true
		mat.uv1_scale = Vector3(1.2, 1.2, 1.2)
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	_mat_cache[key] = mat
	return mat

static func stylized_material(key: String, albedo: Color, roughness: float = 0.85,
		metallic: float = 0.0, cull: int = BaseMaterial3D.CULL_BACK) -> StandardMaterial3D:
	if _mat_cache.has(key):
		return _mat_cache[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = roughness
	mat.metallic = metallic
	mat.cull_mode = cull
	var nrm := get_realistic_tex("plaster_normal.jpg")
	var rgh := get_realistic_tex("plaster_roughness.jpg")
	if nrm != null:
		mat.normal_enabled = true
		mat.normal_texture = nrm
		mat.normal_scale = 0.35
		mat.uv1_triplanar = true
		mat.uv1_scale = Vector3(0.5, 0.5, 0.5)
	if rgh != null:
		mat.roughness_texture = rgh
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	_mat_cache[key] = mat
	return mat

static func water_material() -> StandardMaterial3D:
	if _mat_cache.has("water_eldoria"):
		return _mat_cache["water_eldoria"] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = WATER_DEEP
	mat.roughness = 0.10
	mat.metallic = 0.14
	var wn := get_realistic_tex("water_normal_1.jpg")
	if wn != null:
		mat.normal_enabled = true
		mat.normal_texture = wn
		mat.normal_scale = 0.75
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_cache["water_eldoria"] = mat
	return mat

## Upgrades imported GLB meshes with realistic PBR Normal + Roughness StandardMaterial3Ds
## and strips non-realistic cartoon outline shells ("BlackOutline") & invisible colliders.
static func harmonize_mesh(source: Mesh, variant: String = "") -> Mesh:
	if source == null:
		return null
	var cache_key := "%s::%s::%d" % [source.resource_path, variant, source.get_rid().get_id()]
	if not source.resource_path.is_empty():
		cache_key = "%s::%s" % [source.resource_path, variant]
	if _mat_cache.has(cache_key):
		return _mat_cache[cache_key] as Mesh
	var out := ArrayMesh.new()
	var surf_count := source.get_surface_count()
	for i in surf_count:
		var orig := source.surface_get_material(i)
		var orig_name := orig.resource_name.to_lower() if orig != null else ""
		if orig_name.contains("blackoutline") or orig_name.contains("collider"):
			continue
		var arrays := source.surface_get_arrays(i)
		if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
			continue
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mat := _adapt_surface_material(orig, variant, i)
		out.surface_set_material(out.get_surface_count() - 1, mat)
	var result: Mesh = out if out.get_surface_count() > 0 else source
	_mat_cache[cache_key] = result
	return result

static func _adapt_surface_material(orig: Material, variant: String, surf_idx: int) -> StandardMaterial3D:
	var m_name := orig.resource_name.to_lower() if orig != null else ""
	var v_low := variant.to_lower()
	var base_col := Color(0.68, 0.66, 0.62)
	var tex: Texture2D = null
	var orig_nrm: Texture2D = null
	var orig_rgh: Texture2D = null
	var alpha_mode := BaseMaterial3D.TRANSPARENCY_DISABLED
	if orig is BaseMaterial3D:
		var bm := orig as BaseMaterial3D
		base_col = bm.albedo_color
		tex = bm.albedo_texture
		orig_nrm = bm.normal_texture if bm.normal_enabled else null
		orig_rgh = bm.roughness_texture
		alpha_mode = bm.transparency

	# 1. Textured realistic GLB assets (Polygonal Mind Oaks, Fountain, Rocks, Bushes, Ruins)
	if tex != null:
		var tkey := "tex_%s_%s_%d" % [tex.resource_path, m_name, surf_idx]
		if _mat_cache.has(tkey):
			return _mat_cache[tkey] as StandardMaterial3D
		var textured := StandardMaterial3D.new()
		textured.albedo_texture = tex
		textured.albedo_color = Color(0.95, 0.95, 0.93)
		textured.transparency = alpha_mode
		if alpha_mode == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
			textured.alpha_scissor_threshold = 0.42
			textured.cull_mode = BaseMaterial3D.CULL_DISABLED
		if orig_nrm != null:
			textured.normal_enabled = true
			textured.normal_texture = orig_nrm
			textured.normal_scale = 0.90
		else:
			var nrm_pick := "grass_normal.jpg"
			var rgh_pick := "grass_roughness.jpg"
			if m_name.contains("wood") or m_name.contains("bark") or m_name.contains("trunk"):
				nrm_pick = "wood_normal.jpg"
				rgh_pick = "wood_roughness.jpg"
			elif m_name.contains("rock") or m_name.contains("stone") or m_name.contains("path") or m_name.contains("ruin"):
				nrm_pick = "stone_wall_normal.jpg"
				rgh_pick = "stone_wall_roughness.jpg"
			var fallback_nrm := get_realistic_tex(nrm_pick)
			var fallback_rgh := get_realistic_tex(rgh_pick)
			if fallback_nrm != null:
				textured.normal_enabled = true
				textured.normal_texture = fallback_nrm
				textured.normal_scale = 0.62
			if fallback_rgh != null:
				textured.roughness_texture = fallback_rgh
		if orig_rgh != null:
			textured.roughness_texture = orig_rgh
		textured.roughness = 0.86
		textured.metallic = 0.0
		textured.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
		_mat_cache[tkey] = textured
		return textured

	# 2. Armor, Blades, Shields & Forged Metal
	if m_name.contains("armor") or m_name.contains("metal") or m_name.contains("steel") or m_name.contains("blade") or m_name.contains("iron") or m_name.contains("silver"):
		return armor_metal_material("pbr_steel_" + m_name, Color(0.76, 0.78, 0.82), 0.82, 0.28)
	if m_name.contains("gold") or m_name.contains("brass") or m_name.contains("bronze"):
		return armor_metal_material("pbr_gold_" + m_name, Color(0.92, 0.75, 0.36), 0.86, 0.26)

	# 3. Medieval Architectural Surfaces -> Triplanar PBR Albedo + Normal + Roughness!
	if m_name.contains("plaster") or m_name.contains("stucco") or m_name.contains("wall_white"):
		return pbr_material("pbr_plaster", "plaster", Color(0.94, 0.90, 0.83), 0.34, 0.88, 0.0, 0.85)
	if m_name.contains("rooftiles_red") or (m_name.contains("roof") and base_col.r > base_col.b * 1.4):
		return pbr_material("pbr_roof_red", "roof_tiles", Color(0.82, 0.38, 0.28), 0.38, 0.78, 0.02, 0.95)
	if m_name.contains("roof") or m_name.contains("tile") or m_name.contains("shingle"):
		return pbr_material("pbr_roof_slate", "roof_tiles", Color(0.42, 0.50, 0.58), 0.38, 0.76, 0.04, 0.95)
	if m_name.contains("brick") or m_name.contains("cobble"):
		return pbr_material("pbr_cobble", "cobble", Color(0.88, 0.84, 0.80), 0.36, 0.86, 0.0, 0.95)
	if m_name.contains("stone_dark"):
		return pbr_material("pbr_stone_dark", "stone_wall", Color(0.58, 0.58, 0.62), 0.30, 0.88, 0.0, 0.98)
	if m_name.contains("stone") or m_name.contains("rock") or m_name.contains("cliff") or m_name.contains("castle") or v_low.contains("wall") or v_low.contains("tower"):
		return pbr_material("pbr_stone_light", "stone_wall", Color(0.82, 0.80, 0.77), 0.30, 0.86, 0.0, 0.95)
	if m_name.contains("window") or m_name.contains("glass"):
		var wkey := "pbr_window_amber"
		if _mat_cache.has(wkey):
			return _mat_cache[wkey] as StandardMaterial3D
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = Color(0.18, 0.22, 0.28)
		wmat.roughness = 0.14
		wmat.metallic = 0.35
		wmat.emission_enabled = true
		wmat.emission = Color(1.0, 0.72, 0.34)
		wmat.emission_energy_multiplier = 0.32
		_mat_cache[wkey] = wmat
		return wmat

	# 4. Botanical Foliage & Timber Bark with PBR Normal + Roughness
	if m_name.contains("leaf") or m_name.contains("green") or m_name.contains("grass") or m_name.contains("plant") or (base_col.g > base_col.r * 1.15 and base_col.g > 0.10 and not m_name.contains("skin")):
		if v_low.contains("autumn"):
			return pbr_material("pbr_leaf_autumn", "grass", Color(0.95, 0.62, 0.26), 0.55, 0.82, 0.0, 0.72)
		if v_low.contains("birch"):
			return pbr_material("pbr_leaf_birch", "grass", Color(0.68, 0.82, 0.38), 0.55, 0.82, 0.0, 0.72)
		return pbr_material("pbr_leaf_oak", "grass", Color(0.52, 0.72, 0.36), 0.55, 0.84, 0.0, 0.75)

	if m_name.contains("wood_light"):
		return pbr_material("pbr_wood_light", "wood", Color(0.82, 0.64, 0.44), 0.36, 0.84, 0.0, 0.90)
	if m_name.contains("wood") or m_name.contains("bark") or m_name.contains("trunk") or m_name.contains("door") or m_name.contains("barrel") or m_name.contains("crate"):
		if v_low.contains("birch"):
			return pbr_material("pbr_bark_birch", "wood", Color(0.90, 0.86, 0.80), 0.40, 0.86, 0.0, 0.88)
		return pbr_material("pbr_wood_dark", "wood", Color(0.58, 0.42, 0.28), 0.36, 0.86, 0.0, 0.92)

	# 5. Character Skin, Leather, Cloth & Hair with realistic subsurface/roughness response
	if m_name.contains("skin"):
		var sk := stylized_material("char_skin_" + str(base_col.to_html(false)),
			Color(clampf(base_col.r * 1.08, 0.45, 0.92), clampf(base_col.g * 1.04, 0.34, 0.78), clampf(base_col.b * 1.02, 0.26, 0.68)), 0.68, 0.0)
		return sk
	if m_name.contains("leather") or m_name.contains("boots") or m_name.contains("brown"):
		return pbr_material("char_leather_" + m_name, "wood", Color(0.44, 0.28, 0.18), 0.85, 0.62, 0.05, 0.55)

	var boost := Color(
		clampf(pow(maxf(base_col.r, 0.02), 0.72), 0.08, 0.92),
		clampf(pow(maxf(base_col.g, 0.02), 0.72), 0.08, 0.92),
		clampf(pow(maxf(base_col.b, 0.02), 0.72), 0.08, 0.92),
		1.0
	)
	return stylized_material("generic_%s_%d_%s" % [variant, surf_idx, m_name], boost, 0.78)

static func harmonize_material(orig: Material, variant: String = "") -> StandardMaterial3D:
	return _adapt_surface_material(orig, variant, 0)

static func terrain_detail_texture() -> Texture2D:
	var real_grass := get_realistic_tex("grass_albedo.jpg")
	if real_grass != null:
		return real_grass
	if _mat_cache.has("terrain_detail_tex"):
		return _mat_cache["terrain_detail_tex"] as Texture2D
	var img := Image.create(64, 64, true, Image.FORMAT_RGBA8)
	img.fill(Color(0.88, 0.92, 0.84, 1.0))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_mat_cache["terrain_detail_tex"] = tex
	return tex

static func terrain_normal_texture() -> Texture2D:
	var real_nrm := get_realistic_tex("grass_normal.jpg")
	if real_nrm != null:
		return real_nrm
	return null

static func terrain_roughness_texture() -> Texture2D:
	var real_rgh := get_realistic_tex("grass_roughness.jpg")
	if real_rgh != null:
		return real_rgh
	return null

static func water_shader_material() -> Material:
	if DisplayServer.get_name() == "headless":
		return water_material()
	if _mat_cache.has("water_shader_mat"):
		return _mat_cache["water_shader_mat"] as Material
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_schlick_ggx;

uniform vec4 deep_color : source_color = vec4(0.04, 0.18, 0.30, 0.88);
uniform vec4 shallow_color : source_color = vec4(0.08, 0.32, 0.44, 0.78);
uniform sampler2D normal_tex_a : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D normal_tex_b : hint_normal, repeat_enable, filter_linear_mipmap;

void fragment() {
	vec2 uv_a = UV * 28.0 + vec2(TIME * 0.022, TIME * 0.016);
	vec2 uv_b = UV * 21.0 - vec2(TIME * 0.018, TIME * 0.024);
	vec3 na = texture(normal_tex_a, uv_a).rgb * 2.0 - 1.0;
	vec3 nb = texture(normal_tex_b, uv_b).rgb * 2.0 - 1.0;
	vec3 n = normalize(vec3(na.xy + nb.xy, na.z * nb.z));
	NORMAL_MAP = n * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.82;
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.6);
	vec3 col = mix(deep_color.rgb, shallow_color.rgb, clamp(0.45 + n.x * 0.35, 0.0, 1.0));
	col = mix(col, vec3(0.58, 0.74, 0.88), fresnel * 0.38);
	ALBEDO = col;
	ROUGHNESS = 0.08;
	METALLIC = 0.16;
	SPECULAR = 0.78;
	ALPHA = mix(deep_color.a, 0.94, fresnel * 0.45);
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	var wn1 := get_realistic_tex("water_normal_1.jpg")
	var wn2 := get_realistic_tex("water_normal_2.jpg")
	if wn1 != null:
		sm.set_shader_parameter("normal_tex_a", wn1)
	if wn2 != null:
		sm.set_shader_parameter("normal_tex_b", wn2)
	_mat_cache["water_shader_mat"] = sm
	return sm

## Creates a zero-shadow-cost Ground Contact Ambient Occlusion (AO) quad decal.
static func make_contact_ao(radius: float = 0.65, opacity: float = 0.44) -> MeshInstance3D:
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

## Harmonizes an instantiated Node3D hierarchy in-place with realistic PBR materials
## and hides helper collider/outline meshes.
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
			var low_name := String(mi.name).to_lower()
			if low_name.contains("collider") or low_name.contains("outline"):
				mi.visible = false
				continue
			if mi.mesh != null:
				mi.mesh = harmonize_mesh(mi.mesh, variant if not variant.is_empty() else low_name)
