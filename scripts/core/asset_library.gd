class_name AssetLibrary
extends RefCounted
## Central model loader, PackedScene cache, MultiMesh surface baker, and PBR material harmonizer.
## Integrates res://assets_realistic/ (Realistic Medieval Architecture, Human-Proportioned Rigs,
## Textured Botanical Trees, PBR Normal/Roughness Textures & Cinematic HDRI Skies).

const REALISTIC_ROOT := "res://assets_realistic/"
const REALISTIC_DIR := "res://assets_realistic/"
const REALISTIC_MODELS_DIR := "res://assets_realistic/models/"
const REALISTIC_BUILDINGS_DIR := "res://assets_realistic/models/buildings/"
const REALISTIC_CHARACTERS_DIR := "res://assets_realistic/models/characters/"
const REALISTIC_TREES_DIR := "res://assets_realistic/models/trees/"
const REALISTIC_NATURE_DIR := "res://assets_realistic/models/nature/"
const REALISTIC_WEAPONS_DIR := "res://assets_realistic/models/weapons/"
const REALISTIC_TEXTURES_DIR := "res://assets_realistic/textures/"
const REALISTIC_HDRI_DIR := "res://assets_realistic/hdri/"
const KAYKIT_ADVENTURERS_DIR := "res://assets/kaykit_adventurers/"
const STYLIZED_NATURE_DIR := "res://assets/stylized_nature/"
const STYLIZED_TREES_DIR := "res://assets/stylized_nature/trees/"
const STYLIZED_ROCKS_DIR := "res://assets/stylized_nature/rocks/"
const STYLIZED_FOLIAGE_DIR := "res://assets/stylized_nature/foliage/"

const CHARACTER_DIR := "res://assets/models/characters/"
const PLAYER_DIR := "res://assets/characters/player/"
const NPC_DIR := "res://assets/characters/npcs/"
const GEAR_DIR := "res://assets/characters/gear/"
const HEX_DIR := "res://assets/models/hexagon/"
const HEXAGON_DIR := "res://assets/models/hexagon/"
const DUNGEON_DIR := "res://assets/models/dungeon/"
const FURNITURE_DIR := "res://assets/models/furniture/"
const NATURE_TREES_DIR := "res://assets/nature/trees/"
const NATURE_ROCKS_DIR := "res://assets/nature/rocks/"
const NATURE_BUSHES_DIR := "res://assets/nature/bushes/"
const NATURE_PROPS_DIR := "res://assets/nature/props/"
const MONSTER_DIR := "res://assets/creatures/monsters/"
const ELITE_DIR := "res://assets/creatures/elites/"
const BOSS_DIR := "res://assets/creatures/bosses/"
const WILDLIFE_DIR := "res://assets/creatures/wildlife/"
const VILLAGE_ENV_DIR := "res://assets/environments/villages/"
const FOREST_ENV_DIR := "res://assets/environments/forests/"
const MOUNTAIN_ENV_DIR := "res://assets/environments/mountains/"
const RIVER_ENV_DIR := "res://assets/environments/rivers/"
const DUNGEON_ENV_DIR := "res://assets/environments/dungeons/"
const WEAPON_DIR := "res://assets/weapons/"
const ARMOR_DIR := "res://assets/armor/"

const SCALE_BUILDING := 8.5
const SCALE_PROP := 4.0
const SCALE_TREE := 5.0
const SCALE_ROCK := 6.0
const SCALE_FENCE := 3.5
const SCALE_DUNGEON := 1.0
const SCALE_FURNITURE := 1.0

static var _cache: Dictionary = {}
static var _mesh_cache: Dictionary = {}

static func get_scene(path: String) -> PackedScene:
	if _cache.has(path):
		return _cache[path] as PackedScene
	var packed: Resource = null
	if ResourceLoader.exists(path):
		packed = ResourceLoader.load(path)
	var scene := packed as PackedScene
	_cache[path] = scene
	return scene

static func load_scene(path: String) -> PackedScene:
	return get_scene(path)

static func has_model(path: String) -> bool:
	return ResourceLoader.exists(path)

## Returns normalized meter-height scale for character rigs (~1.86m realistic adult human height).
static func character_base_scale(path: String) -> float:
	if path.begins_with(REALISTIC_CHARACTERS_DIR):
		return 1.0
	return 1.0

static func instantiate(path: String, model_scale: float = 1.0, harmonize_variant: String = "") -> Node3D:
	var scene := get_scene(path)
	if scene == null:
		push_warning("AssetLibrary: cannot load %s" % path)
		return null
	var node := scene.instantiate() as Node3D
	if node == null:
		return null
	if not is_equal_approx(model_scale, 1.0):
		node.scale = Vector3.ONE * model_scale
	var variant := harmonize_variant if not harmonize_variant.is_empty() else path.get_file().get_basename()
	ArtDirection.harmonize_node(node, variant)
	return node

static func instantiate_gltf(path: String, scale_factor: float = 1.0) -> Node3D:
	return instantiate(path, scale_factor)

static func instantiate_gltfs(candidates: Array, scale_factor: float = 1.0) -> Node3D:
	for p: Variant in candidates:
		var path := String(p)
		if has_model(path):
			var inst := instantiate(path, scale_factor)
			if inst != null:
				return inst
	return null

static func first_mesh_instance(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		var low := String(mi.name).to_lower()
		if mi.mesh != null and not low.contains("collider") and not low.contains("outline"):
			return mi
	for child: Node in root.get_children():
		var found := first_mesh_instance(child)
		if found != null:
			return found
	return null

## Extracts a unified, transform-baked, PBR-harmonized ArrayMesh suitable for 60 FPS MultiMeshInstance3D.
## Merges surfaces sharing the same resolved PBR Material so MultiMeshes require minimal GLES3 draw calls!
static func first_mesh(path: String, category_hint: String = "") -> Mesh:
	var key := path + "|" + category_hint
	if _mesh_cache.has(key):
		return _mesh_cache[key] as Mesh
	var scene := get_scene(path)
	if scene == null:
		return null
	var root := scene.instantiate() as Node3D
	if root == null:
		return null

	var hint := category_hint if not category_hint.is_empty() else path.get_file().get_basename()
	var mat_order: Array[Material] = []
	var st_by_mat: Dictionary = {}
	var stack: Array = [[root, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var n: Node = item[0]
		var xf: Transform3D = item[1]
		var low_n := String(n.name).to_lower()
		if low_n.contains("collider") or low_n.contains("collision") or low_n.contains("outline"):
			continue
		var cur_xf := xf
		if n != root and n is Node3D:
			cur_xf = xf * (n as Node3D).transform
		for c: Node in n.get_children():
			stack.append([c, cur_xf])
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh == null:
				continue
			var src_mesh := mi.mesh
			for s: int in src_mesh.get_surface_count():
				var orig_mat := src_mesh.surface_get_material(s)
				if orig_mat == null:
					orig_mat = mi.get_surface_override_material(s)
				var mat_name := orig_mat.resource_name.to_lower() if orig_mat != null else ""
				if mat_name.contains("blackoutline") or mat_name.contains("outline") or mat_name.contains("collider"):
					continue
				var hmat: Material = ArtDirection.harmonize_material(orig_mat, hint)
				if not st_by_mat.has(hmat):
					var st := SurfaceTool.new()
					st.begin(Mesh.PRIMITIVE_TRIANGLES)
					st_by_mat[hmat] = st
					mat_order.append(hmat)
				(st_by_mat[hmat] as SurfaceTool).append_from(src_mesh, s, cur_xf)

	var merged := ArrayMesh.new()
	for idx in mat_order.size():
		var mat: Material = mat_order[idx]
		var st: SurfaceTool = st_by_mat[mat]
		merged = st.commit(merged)
		if mat != null:
			merged.surface_set_material(idx, mat)

	root.free()
	var out_mesh: Mesh = merged if merged.get_surface_count() > 0 else null
	_mesh_cache[key] = out_mesh
	return out_mesh

static func clear_cache() -> void:
	_cache.clear()
	_mesh_cache.clear()
