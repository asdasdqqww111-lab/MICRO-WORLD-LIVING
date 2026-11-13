class_name AssetLibrary
extends RefCounted
## Central model loader, PackedScene cache, MultiMesh surface baker, and PBR material harmonizer.
## Integrates res://assets_realistic/ (Realistic Medieval Architecture, Human-Proportioned Rigs,
## Textured Botanical Trees, PBR Normal/Roughness Textures & Cinematic HDRI Skies).

const REALISTIC_DIR := "res://assets_realistic/"
const REALISTIC_MODELS_DIR := "res://assets_realistic/models/"
const REALISTIC_BUILDINGS_DIR := "res://assets_realistic/models/buildings/"
const REALISTIC_CHARACTERS_DIR := "res://assets_realistic/models/characters/"
const REALISTIC_TREES_DIR := "res://assets_realistic/models/trees/"
const REALISTIC_NATURE_DIR := "res://assets_realistic/models/nature/"
const REALISTIC_WEAPONS_DIR := "res://assets_realistic/models/weapons/"
const REALISTIC_TEXTURES_DIR := "res://assets_realistic/textures/"
const REALISTIC_HDRI_DIR := "res://assets_realistic/hdri/"

const CHARACTER_DIR := "res://assets/models/characters/"
const PLAYER_DIR := "res://assets/characters/player/"
const NPC_DIR := "res://assets/characters/npcs/"
const GEAR_DIR := "res://assets/characters/gear/"
const HEXAGON_DIR := "res://assets/models/hexagon/"
const DUNGEON_DIR := "res://assets/models/dungeon/"
const FURNITURE_DIR := "res://assets/models/furniture/"
const NATURE_TREES_DIR := "res://assets/nature/trees/"
const NATURE_ROCKS_DIR := "res://assets/nature/rocks/"
const NATURE_BUSHES_DIR := "res://assets/nature/bushes/"
const NATURE_PROPS_DIR := "res://assets/nature/props/"

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

static func has_model(path: String) -> bool:
	return ResourceLoader.exists(path)

## Returns normalized meter-height scale for character rigs (e.g. knight_hero.glb is 5.6m raw -> 0.34 = 1.90m).
static func character_base_scale(path: String) -> float:
	if path.ends_with("knight_hero.glb"):
		return 0.34
	return 1.0

static func instantiate(path: String, model_scale: float = 1.0) -> Node3D:
	var scene := get_scene(path)
	if scene == null:
		push_warning("AssetLibrary: cannot load %s" % path)
		return null
	var node := scene.instantiate() as Node3D
	if node == null:
		return null
	if not is_equal_approx(model_scale, 1.0):
		node.scale = Vector3.ONE * model_scale
	ArtDirection.harmonize_node(node, path.get_file().get_basename())
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

	var merged := ArrayMesh.new()
	var stack: Array = [[root, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var n: Node = item[0]
		var xf: Transform3D = item[1]
		var cur_xf := xf
		if n != root and n is Node3D:
			cur_xf = xf * (n as Node3D).transform
		for c: Node in n.get_children():
			stack.append([c, cur_xf])
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var low_n := String(mi.name).to_lower()
			if mi.mesh == null or low_n.contains("collider") or low_n.contains("outline"):
				continue
			var src_mesh := mi.mesh
			var is_identity := cur_xf.is_equal_approx(Transform3D.IDENTITY)
			var normal_basis := cur_xf.basis.inverse().transposed()
			for s: int in src_mesh.get_surface_count():
				var orig_mat := src_mesh.surface_get_material(s)
				if orig_mat == null:
					orig_mat = mi.get_surface_override_material(s)
				var mat_name := orig_mat.resource_name.to_lower() if orig_mat != null else ""
				if mat_name.contains("blackoutline") or mat_name.contains("collider"):
					continue
				var arrays := src_mesh.surface_get_arrays(s)
				if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
					continue
				if not is_identity:
					arrays = arrays.duplicate(true)
					var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
					for vi: int in verts.size():
						verts[vi] = cur_xf * verts[vi]
					arrays[Mesh.ARRAY_VERTEX] = verts
					if arrays[Mesh.ARRAY_NORMAL] != null:
						var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
						for ni: int in norms.size():
							norms[ni] = (normal_basis * norms[ni]).normalized()
						arrays[Mesh.ARRAY_NORMAL] = norms
				merged.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
				var hint := category_hint if not category_hint.is_empty() else path.get_file().get_basename()
				var hmat := ArtDirection.harmonize_material(orig_mat, hint)
				if hmat != null:
					merged.surface_set_material(merged.get_surface_count() - 1, hmat)

	root.free()
	var out_mesh: Mesh = merged if merged.get_surface_count() > 0 else null
	_mesh_cache[key] = out_mesh
	return out_mesh

static func clear_cache() -> void:
	_cache.clear()
	_mesh_cache.clear()
