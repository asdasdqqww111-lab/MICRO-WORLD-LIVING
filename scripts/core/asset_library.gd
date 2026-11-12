class_name AssetLibrary
extends RefCounted
## Central place for model paths + cached PackedScene loading.

const CHARACTER_DIR := "res://assets/models/characters/"
const HEXAGON_DIR := "res://assets/models/hexagon/"
const DUNGEON_DIR := "res://assets/models/dungeon/"
const FURNITURE_DIR := "res://assets/models/furniture/"

# KayKit packs are authored at different unit scales; these convert each family
# into metres for the 200x200m slice.
const SCALE_BUILDING := 8.5
const SCALE_PROP := 4.0
const SCALE_TREE := 5.0
const SCALE_ROCK := 6.0
const SCALE_FENCE := 3.5
const SCALE_DUNGEON := 1.0
const SCALE_FURNITURE := 1.0

static var _cache: Dictionary = {}

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
	return node

static func first_mesh_instance(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		return root as MeshInstance3D
	for child: Node in root.get_children():
		var found := first_mesh_instance(child)
		if found != null:
			return found
	return null

static func first_mesh(path: String) -> Mesh:
	var node := instantiate(path)
	if node == null:
		return null
	var mi := first_mesh_instance(node)
	var mesh: Mesh = mi.mesh if mi != null else null
	node.free()
	return mesh

static func clear_cache() -> void:
	_cache.clear()
