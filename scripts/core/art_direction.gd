class_name ArtDirection
extends RefCounted
## Realistic Cinematic AAA Mobile PBR Material Engine (Eldoria Realistic Edition).
## Applies StandardMaterial3D with real Normal Maps + Roughness Maps (res://assets_realistic/textures/)
## across architecture, terrain, foliage, rocks, armor/weapons, and dual-normal specular water,
## and merges same-material / vertex-colored surfaces for locked 60 FPS mobile GLES3 performance.

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
		mat.uv1_scale = Vector3(1.5, 1.5, 1.5)
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	_mat_cache[key] = mat
	return mat

static func stylized_material(key: String, albedo: Color, roughness: float = 0.80,
		metallic: float = 0.0, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	if _mat_cache.has(key):
		return _mat_cache[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = roughness
	mat.metallic = metallic
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	if emission_energy > 0.001:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	_mat_cache[key] = mat
	return mat

static func character_vertex_pbr_material() -> StandardMaterial3D:
	if _mat_cache.has("char_vertex_pbr"):
		return _mat_cache["char_vertex_pbr"] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.64
	mat.metallic = 0.08
	var nrm := get_realistic_tex("plaster_normal.jpg")
	if nrm != null:
		mat.normal_enabled = true
		mat.normal_texture = nrm
		mat.normal_scale = 0.24
		mat.uv1_triplanar = true
		mat.uv1_scale = Vector3(1.8, 1.8, 1.8)
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	_mat_cache["char_vertex_pbr"] = mat
	return mat

static func water_material() -> StandardMaterial3D:
	if _mat_cache.has("water_pbr"):
		return _mat_cache["water_pbr"] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = WATER_DEEP
	mat.roughness = 0.09
	mat.metallic = 0.18
	var wn := get_realistic_tex("water_normal_1.jpg")
	if wn != null:
		mat.normal_enabled = true
		mat.normal_texture = wn
		mat.normal_scale = 0.68
		mat.uv1_triplanar = true
		mat.uv1_scale = Vector3(0.28, 0.28, 0.28)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_cache["water_pbr"] = mat
	return mat

## Harmonizes a Mesh with realistic PBR Normal/Roughness materials AND merges same-material
## static surfaces (or vertex-colored skinned character surfaces) to slash GLES3 draw calls.
static func harmonize_mesh(mesh: Mesh, variant: String = "") -> Mesh:
	if mesh == null:
		return null
	var count := mesh.get_surface_count()
	if count == 0:
		return mesh

	var arr_src := mesh as ArrayMesh
	var has_bones := false
	if arr_src != null:
		for s in count:
			if (arr_src.surface_get_format(s) & Mesh.ARRAY_FORMAT_BONES) != 0:
				has_bones = true
				break

	# Fast path for skinned character ArrayMeshes: merge untextured solid-color surfaces into 1 vertex-colored PBR draw call!
	if has_bones and arr_src != null and count > 1:
		var merged_skin := _try_merge_skinned_surfaces(arr_src, variant)
		if merged_skin != null:
			return merged_skin

	# Static mesh path: strip BlackOutline & merge surfaces that resolve to the same PBR Material!
	if not has_bones:
		var mat_order: Array[Material] = []
		var st_by_mat: Dictionary = {}
		for s in count:
			var orig := mesh.surface_get_material(s)
			var m_name := orig.resource_name.to_lower() if orig != null else ""
			if m_name.contains("blackoutline") or m_name.contains("outline"):
				continue
			var resolved: Material = _adapt_surface_material(orig, variant, s)
			if not st_by_mat.has(resolved):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				st_by_mat[resolved] = st
				mat_order.append(resolved)
			(st_by_mat[resolved] as SurfaceTool).append_from(mesh, s, Transform3D.IDENTITY)
		if not mat_order.is_empty():
			var merged := ArrayMesh.new()
			for idx in mat_order.size():
				var mat: Material = mat_order[idx]
				var st: SurfaceTool = st_by_mat[mat]
				merged = st.commit(merged)
				merged.surface_set_material(idx, mat)
			return merged

	# Fallback per-surface override
	var dup := mesh.duplicate(false) as Mesh
	for s in count:
		var orig := mesh.surface_get_material(s)
		dup.surface_set_material(s, _adapt_surface_material(orig, variant, s))
	return dup

static func _try_merge_skinned_surfaces(src: ArrayMesh, variant: String) -> ArrayMesh:
	var count := src.get_surface_count()
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var indices := PackedInt32Array()
	var expected_bone_stride := -1

	for s in count:
		if src.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			return null
		var orig := src.surface_get_material(s)
		var orig_std := orig as StandardMaterial3D
		if orig_std != null and orig_std.albedo_texture != null:
			return null
		var arr := src.surface_get_arrays(s)
		var sv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var vc := sv.size()
		if vc == 0:
			continue
		var sb = arr[Mesh.ARRAY_BONES]
		var sw = arr[Mesh.ARRAY_WEIGHTS]
		if typeof(sb) != TYPE_PACKED_INT32_ARRAY or typeof(sw) != TYPE_PACKED_FLOAT32_ARRAY:
			return null
		var sb_int: PackedInt32Array = sb
		var sw_flt: PackedFloat32Array = sw
		var stride := int(sb_int.size() / vc)
		if expected_bone_stride == -1:
			expected_bone_stride = stride
		elif stride != expected_bone_stride or sw_flt.size() != sb_int.size():
			return null

		var resolved := _adapt_surface_material(orig, variant, s)
		var surf_col := resolved.albedo_color if resolved != null else Color(0.75, 0.72, 0.68)
		var v_offset := verts.size()
		verts.append_array(sv)

		var sn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		if sn.size() == vc:
			norms.append_array(sn)
		else:
			for _i in vc:
				norms.append(Vector3.UP)

		var start_c := cols.size()
		cols.resize(start_c + vc)
		for ci in vc:
			cols[start_c + ci] = surf_col

		bones.append_array(sb_int)
		weights.append_array(sw_flt)

		var si = arr[Mesh.ARRAY_INDEX]
		if typeof(si) == TYPE_PACKED_INT32_ARRAY and (si as PackedInt32Array).size() > 0:
			for idx_val: int in (si as PackedInt32Array):
				indices.append(idx_val + v_offset)
		else:
			for idx_val in vc:
				indices.append(idx_val + v_offset)

	if verts.is_empty() or indices.is_empty():
		return null

	var out_arr := []
	out_arr.resize(Mesh.ARRAY_MAX)
	out_arr[Mesh.ARRAY_VERTEX] = verts
	out_arr[Mesh.ARRAY_NORMAL] = norms
	out_arr[Mesh.ARRAY_COLOR] = cols
	out_arr[Mesh.ARRAY_BONES] = bones
	out_arr[Mesh.ARRAY_WEIGHTS] = weights
	out_arr[Mesh.ARRAY_INDEX] = indices

	var flags := Mesh.ARRAY_CUSTOM_RGBA8_UNORM
	var out_mesh := ArrayMesh.new()
	if expected_bone_stride == 8:
		out_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out_arr, [], {}, Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
	else:
		out_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out_arr)
	var _unused := flags
	out_mesh.surface_set_material(0, character_vertex_pbr_material())
	return out_mesh

static func _adapt_surface_material(orig: Material, variant: String, surf_idx: int) -> StandardMaterial3D:
	var orig_std := orig as StandardMaterial3D
	var m_name := orig.resource_name.to_lower() if orig != null else ""
	var v_low := variant.to_lower()
	var base_col := orig_std.albedo_color if orig_std != null else Color(0.75, 0.75, 0.75)

	# 0. Override stylized Polygonal-Mind textures (purple/pink swirl TreeLeaves, TreeWood, Rock01, Path01)
	# with grounded photorealistic PBR Albedo + Normal + Roughness maps!
	if m_name.contains("treeleaves"):
		if v_low.contains("autumn"):
			return pbr_material("pbr_leaf_autumn", "grass", Color(0.86, 0.56, 0.22), 0.55, 0.82, 0.0, 0.72)
		if v_low.contains("birch"):
			return pbr_material("pbr_leaf_birch", "grass", Color(0.56, 0.74, 0.30), 0.55, 0.82, 0.0, 0.72)
		if v_low.contains("pine"):
			return pbr_material("pbr_leaf_pine", "grass", Color(0.26, 0.44, 0.22), 0.55, 0.84, 0.0, 0.76)
		return pbr_material("pbr_leaf_oak", "grass", Color(0.36, 0.56, 0.24), 0.55, 0.84, 0.0, 0.75)
	if m_name.contains("treewood"):
		if v_low.contains("birch"):
			return pbr_material("pbr_bark_birch", "wood", Color(0.86, 0.82, 0.76), 0.40, 0.86, 0.0, 0.88)
		return pbr_material("pbr_wood_dark", "wood", Color(0.46, 0.34, 0.23), 0.36, 0.86, 0.0, 0.92)
	if m_name.contains("rock01") or m_name.contains("rock02") or m_name.contains("statuelion"):
		return pbr_material("pbr_granite_rock", "stone_wall", Color(0.62, 0.60, 0.57), 0.34, 0.88, 0.0, 0.95)
	if m_name.contains("path01"):
		return pbr_material("pbr_fountain_stone", "stone_wall", Color(0.76, 0.74, 0.70), 0.36, 0.85, 0.02, 0.90)

	# 1. Preserve genuine realistic albedo textures (e.g. Medieval MegaKit / KayKit / TinyTreats) and enrich with PBR Normal + Roughness!
	if orig_std != null and orig_std.albedo_texture != null:
		var tkey := "tex_%s_%d_%d" % [variant, orig_std.albedo_texture.get_rid().get_id(), surf_idx]
		if _mat_cache.has(tkey):
			return _mat_cache[tkey] as StandardMaterial3D
		var dup := orig_std.duplicate() as StandardMaterial3D
		dup.albedo_color = Color(
			clampf(orig_std.albedo_color.r, 0.82, 1.0),
			clampf(orig_std.albedo_color.g, 0.82, 1.0),
			clampf(orig_std.albedo_color.b, 0.82, 1.0),
			orig_std.albedo_color.a
		)
		dup.roughness = clampf(orig_std.roughness, 0.45, 0.88)
		if dup.normal_texture == null:
			var nrm := get_realistic_tex("stone_wall_normal.jpg")
			if v_low.contains("tree") or v_low.contains("bush") or v_low.contains("forest"):
				nrm = get_realistic_tex("grass_normal.jpg")
			elif v_low.contains("knight") or v_low.contains("sword") or v_low.contains("shield"):
				nrm = get_realistic_tex("armor_metal_normal.jpg")
			if nrm != null:
				dup.normal_enabled = true
				dup.normal_texture = nrm
				dup.normal_scale = 0.36
		dup.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
		_mat_cache[tkey] = dup
		return dup

	# 2. Water surfaces
	if m_name.contains("water"):
		return water_material()

	# 3. Medieval Knight Armor, Blades, Gold & Metals -> PBR Metallic + Normal
	if m_name.contains("gold") or m_name.contains("brass") or m_name.contains("bell"):
		return armor_metal_material("metal_gold", Color(0.84, 0.68, 0.30), 0.84, 0.28)
	if m_name.contains("armor") or m_name.contains("steel") or m_name.contains("metal") or m_name.contains("blade") or m_name.contains("iron") or m_name.contains("swat") or (v_low.contains("knight") and (m_name.contains("grey") or m_name.contains("black"))):
		if m_name.contains("dark") or m_name.contains("black"):
			return armor_metal_material("metal_dark_steel", Color(0.36, 0.39, 0.44), 0.82, 0.34)
		return armor_metal_material("metal_steel", Color(0.72, 0.75, 0.80), 0.85, 0.26)

	# 4. Architecture: Collapse stone/wood/roof variants into 3 shared PBR materials per building!
	if m_name.contains("rooftiles") or m_name.contains("roof") or (m_name.contains("red") and (v_low.contains("house") or v_low.contains("inn") or v_low.contains("mill") or v_low.contains("gazebo") or v_low.contains("market") or v_low.contains("well"))):
		return pbr_material("pbr_roof_terracotta", "roof_tiles", Color(0.76, 0.36, 0.26), 0.38, 0.80, 0.02, 0.95)
	if m_name.contains("plaster") or m_name.contains("walls") or m_name.contains("beige") or m_name.contains("white"):
		if v_low.contains("birch"):
			return pbr_material("pbr_bark_birch", "wood", Color(0.86, 0.82, 0.76), 0.40, 0.86, 0.0, 0.88)
		return pbr_material("pbr_plaster_warm", "plaster", Color(0.90, 0.85, 0.76), 0.35, 0.86, 0.0, 0.85)
	if m_name.contains("stone") or m_name.contains("rock") or m_name.contains("brick") or m_name.contains("cobble") or m_name.contains("main"):
		return pbr_material("pbr_stone_wall", "stone_wall", Color(0.72, 0.70, 0.66), 0.30, 0.88, 0.0, 0.96)
	if m_name.contains("window"):
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

	# 5. Botanical Foliage & Timber Bark with PBR Normal + Roughness
	if m_name.contains("leaf") or m_name.contains("green") or m_name.contains("grass") or m_name.contains("plant") or (base_col.g > base_col.r * 1.15 and base_col.g > 0.10 and not m_name.contains("skin")):
		if v_low.contains("autumn"):
			return pbr_material("pbr_leaf_autumn", "grass", Color(0.86, 0.56, 0.22), 0.55, 0.82, 0.0, 0.72)
		if v_low.contains("birch"):
			return pbr_material("pbr_leaf_birch", "grass", Color(0.56, 0.74, 0.30), 0.55, 0.82, 0.0, 0.72)
		return pbr_material("pbr_leaf_oak", "grass", Color(0.36, 0.56, 0.24), 0.55, 0.84, 0.0, 0.75)

	if m_name.contains("wood") or m_name.contains("bark") or m_name.contains("trunk") or m_name.contains("door") or m_name.contains("barrel") or m_name.contains("crate") or m_name.contains("bag"):
		if v_low.contains("birch"):
			return pbr_material("pbr_bark_birch", "wood", Color(0.86, 0.82, 0.76), 0.40, 0.86, 0.0, 0.88)
		return pbr_material("pbr_wood_dark", "wood", Color(0.54, 0.39, 0.26), 0.36, 0.86, 0.0, 0.92)

	# 6. Character Skin, Leather, Cloth & Hair
	if m_name.contains("skin"):
		return stylized_material("char_skin_" + str(base_col.to_html(false)),
			Color(clampf(base_col.r * 1.06, 0.48, 0.90), clampf(base_col.g * 1.02, 0.36, 0.76), clampf(base_col.b, 0.28, 0.66)), 0.68, 0.0)
	if m_name.contains("worker_yellow"):
		return stylized_material("char_tunic_leather", Color(0.52, 0.36, 0.20), 0.74, 0.0)
	if m_name.contains("worker_vest"):
		return stylized_material("char_apron_smith", Color(0.34, 0.22, 0.15), 0.72, 0.05)
	if m_name.contains("leather") or m_name.contains("boots") or m_name.contains("brown"):
		return stylized_material("char_leather_" + m_name, Color(0.42, 0.27, 0.17), 0.66, 0.04)

	var boost := Color(
		clampf(pow(maxf(base_col.r, 0.02), 0.78), 0.10, 0.88),
		clampf(pow(maxf(base_col.g, 0.02), 0.78), 0.10, 0.88),
		clampf(pow(maxf(base_col.b, 0.02), 0.78), 0.10, 0.88),
		1.0
	)
	return stylized_material("generic_%s_%d_%s" % [variant, surf_idx, m_name], boost, 0.76)

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
	return get_realistic_tex("grass_normal.jpg")

static func terrain_roughness_texture() -> Texture2D:
	return get_realistic_tex("grass_roughness.jpg")

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
