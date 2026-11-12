class_name AssetLibrary
extends RefCounted
## Central model loader, PackedScene cache, and PBR material harmonizer.
## Preserves all original constants & static methods while harmonizing
## multi-pack assets into Eldoria's unified semi-realistic stylized palette.

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
	ArtDirection.harmonize_node(node)
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
	if root is MeshInstance3D and (root as MeshInstance3D).mesh != null:
		return root as MeshInstance3D
	for child: Node in root.get_children():
		var found := first_mesh_instance(child)
		if found != null:
			return found
	return null

## Extracts a harmonized single-draw-call Mesh suitable for MultiMeshInstance3D.
static func first_mesh(path: String, category_hint: String = "") -> Mesh:
	var key := path + "|" + category_hint
	if _mesh_cache.has(key):
		return _mesh_cache[key] as Mesh
	var scene := get_scene(path)
	if scene == null:
		return null
	var node := scene.instantiate()
	if node == null:
		return null
	var mi := first_mesh_instance(node)
	var out_mesh: Mesh = null
	if mi != null and mi.mesh != null:
		out_mesh = mi.mesh.duplicate(true) as Mesh
		for s: int in out_mesh.get_surface_count():
			var mat := out_mesh.surface_get_material(s)
			if mat == null:
				mat = mi.get_surface_override_material(s)
			var hint := category_hint if not category_hint.is_empty() else path + "_" + String(mi.name) + "_s" + str(s)
			var hmat := ArtDirection.harmonize_material(mat, hint)
			if hmat != null:
				out_mesh.surface_set_material(s, hmat)
	node.free()
	_mesh_cache[key] = out_mesh
	return out_mesh

static func clear_cache() -> void:
	_cache.clear()
	_mesh_cache.clear()
