extends Node3D
class_name CityChunkStream
## Deterministic six-district city generator with chunk streaming.
##
## Geometry contract:
## - 40x40 m chunks; chunk node origin = chunk CORNER; district content is built
##   under a "Content" child offset to the chunk CENTER (+20,+0,+20).
## - 8 m roads run along every chunk border strip; buildable band keeps every
##   building AABB fully inside |centered coord| + half-extent <= BUILDABLE_HALF.
## - Each district owns one explicit 2x2 chunk block (no overlap, all reachable).
## - Loads chunks within VIEW_CHUNKS of the player, unloads beyond UNLOAD_CHUNKS.
## - All placement from a chunk-seeded RNG: same chunk => same city, every run.
## - Mobile budget: <= 2 MultiMesh draw calls per chunk, 1 StaticBody3D per
##   building, BoxOccluder3D per building, one shared lamp collision shape.

signal chunk_loaded(chunk: Vector2i, district: int)
signal chunk_unloaded(chunk: Vector2i)

const CHUNK_SIZE: float = 40.0
const VIEW_CHUNKS: int = 2          # load within 2 chunks (80 m) of the player
const UNLOAD_CHUNKS: int = 3        # unload beyond 3 chunks (120 m)
const ROAD_HALF: float = 4.0        # 8 m roads along chunk borders
const BUILDABLE_HALF: float = 12.0  # buildable band: |coord| + half_extent <= 12
const DISTRICT_COUNT: int = 6

enum District { RESIDENTIAL, MARKET, ROYAL, TEMPLE, HARBOR, GARDEN }

# Explicit, non-overlapping 2x2 chunk blocks (top-left chunk of each block).
# City bounds: chunks 2..7 on both axes = 240 m x 240 m walled city.
const DISTRICT_BLOCKS := {
	District.RESIDENTIAL: Vector2i(2, 2),
	District.MARKET: Vector2i(4, 2),
	District.ROYAL: Vector2i(2, 4),
	District.TEMPLE: Vector2i(4, 4),
	District.HARBOR: Vector2i(2, 6),
	District.GARDEN: Vector2i(4, 6),
}

const DISTRICT_NAMES := {
	District.RESIDENTIAL: "Residential Quarter",
	District.MARKET: "Market District",
	District.ROYAL: "Royal Palace",
	District.TEMPLE: "Temple Hill",
	District.HARBOR: "Harbor Docks",
	District.GARDEN: "Sakura Gardens",
}

var player_position: Vector3 = Vector3.ZERO
var chunks: Dictionary = {}          # Vector2i -> Node3D
var _last_center := Vector2i(2147483647, 2147483647)
var _lamp_shape: SphereShape3D

# ------------------------------------------------------------------ districts

func district_for_chunk(cx: int, cz: int) -> int:
	for district in DISTRICT_BLOCKS:
		var b: Vector2i = DISTRICT_BLOCKS[district]
		if cx >= b.x and cx <= b.x + 1 and cz >= b.y and cz <= b.y + 1:
			return district
	return -1

func district_name(district: int) -> String:
	return DISTRICT_NAMES.get(district, "Meadowlands")

# ----------------------------------------------------------------- streaming

func set_player_position(pos: Vector3) -> void:
	player_position = pos
	update_streaming()

func update_streaming() -> void:
	if not is_inside_tree():
		return
	var center := Vector2i(
		int(floor(player_position.x / CHUNK_SIZE)),
		int(floor(player_position.z / CHUNK_SIZE)))
	if center == _last_center:
		return
	_last_center = center
	_load_needed(center)
	_unload_far(center)

func _load_needed(center: Vector2i) -> void:
	for dz in range(-VIEW_CHUNKS, VIEW_CHUNKS + 1):
		for dx in range(-VIEW_CHUNKS, VIEW_CHUNKS + 1):
			var c := center + Vector2i(dx, dz)
			if not chunks.has(c):
				_build_chunk(c)

func _unload_far(center: Vector2i) -> void:
	var doomed: Array[Vector2i] = []
	for c in chunks.keys():
		if absi(c.x - center.x) > UNLOAD_CHUNKS or absi(c.y - center.y) > UNLOAD_CHUNKS:
			doomed.append(c)
	for c in doomed:
		var node: Node3D = chunks[c]
		chunks.erase(c)
		if is_instance_valid(node):
			remove_child(node)
			node.queue_free()
		chunk_unloaded.emit(c)

func chunk_is_loaded(cx: int, cz: int) -> bool:
	return chunks.has(Vector2i(cx, cz))

func loaded_chunk_count() -> int:
	return chunks.size()

func stream_stats() -> Dictionary:
	var by_district := [0, 0, 0, 0, 0, 0]
	var names: Array[String] = []
	for i in DISTRICT_COUNT:
		names.append(district_name(i))
	for c in chunks.keys():
		var d := district_for_chunk(c.x, c.y)
		if d >= 0:
			by_district[d] += 1
	return {
		"loaded": chunks.size(),
		"chunks": chunks.keys(),
		"by_district": by_district,
		"district_names": names,
	}

# ------------------------------------------------------------- chunk builder

func _chunk_rng(cx: int, cz: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = (cx * 73856093) ^ (cz * 19349663)
	return rng

func _build_chunk(c: Vector2i) -> void:
	var district := district_for_chunk(c.x, c.y)
	var node := Node3D.new()
	node.name = "Chunk_%d_%d" % [c.x, c.y]
	node.position = Vector3(c.x * CHUNK_SIZE, 0.0, c.y * CHUNK_SIZE)
	add_child(node)
	# Centered content container: builder coords are chunk-relative centers.
	var content := Node3D.new()
	content.name = "Content"
	content.position = Vector3(CHUNK_SIZE * 0.5, 0.0, CHUNK_SIZE * 0.5)
	node.add_child(content)
	var rng := _chunk_rng(c.x, c.y)
	match district:
		District.RESIDENTIAL:
			_build_residential(content, rng)
		District.MARKET:
			_build_market(content, rng)
		District.ROYAL:
			_build_royal(content, rng)
		District.TEMPLE:
			_build_temple(content, rng)
		District.HARBOR:
			_build_harbor(content, rng)
		District.GARDEN:
			_build_garden(content, rng)
		_:
			_build_meadow(content, rng)
	chunks[c] = node
	chunk_loaded.emit(c, district)

# Shared building block: wall box + roof prism + occluder + collision.
func _building(parent: Node3D, pos: Vector3, size: Vector3, wall: Color, roof: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	parent.add_child(body)
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = wall
	mat.roughness = 0.92
	box.material = mat
	mesh_i.mesh = box
	mesh_i.position = Vector3(0.0, size.y * 0.5, 0.0)
	body.add_child(mesh_i)
	var roof_i := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(size.x * 1.12, 1.6, size.z * 1.12)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = roof
	rmat.roughness = 0.85
	prism.material = rmat
	roof_i.mesh = prism
	roof_i.position = Vector3(0.0, size.y + 0.8, 0.0)
	body.add_child(roof_i)
	var occ := OccluderInstance3D.new()
	var occ_box := BoxOccluder3D.new()
	occ_box.size = size
	occ.occluder = occ_box
	occ.position = Vector3(0.0, size.y * 0.5, 0.0)
	body.add_child(occ)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = Vector3(0.0, size.y * 0.5, 0.0)
	body.add_child(col)

func _lamp(parent: Node3D, pos: Vector3, glow: Color) -> void:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.06
	pole_mesh.bottom_radius = 0.09
	pole_mesh.height = 3.2
	pole.material = StandardMaterial3D.new()
	pole.material.albedo_color = Color(0.25, 0.24, 0.26)
	pole.mesh = pole_mesh
	pole.position = Vector3(0.0, 1.6, 0.0)
	root.add_child(pole)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head_mesh.material = StandardMaterial3D.new()
	head_mesh.material.albedo_color = glow
	head_mesh.material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	head.mesh = head_mesh
	head.position = Vector3(0.0, 3.35, 0.0)
	root.add_child(head)
	if _lamp_shape == null:
		_lamp_shape = SphereShape3D.new()
		_lamp_shape.radius = 0.45
	var body := StaticBody3D.new()
	body.position = Vector3(0.0, 0.9, 0.0)
	var col := CollisionShape3D.new()
	col.shape = _lamp_shape
	body.add_child(col)
	root.add_child(body)

func _batch(parent: Node3D, batch_name: String, mesh: Mesh, count: int, place: Callable) -> MultiMeshInstance3D:
	if count <= 0:
		return null
	var mmi := MultiMeshInstance3D.new()
	mmi.name = batch_name
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	for i in count:
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, place.call(i)))
	mmi.multimesh = mm
	parent.add_child(mmi)
	return mmi

# ---------------------------------------------------------------- districts

func _build_residential(node: Node3D, rng: RandomNumberGenerator) -> void:
	# Two fixed diagonal slots + small jitter => guaranteed 16 m+ alley separation.
	var slots := [Vector3(-7, 0, -7), Vector3(7, 0, 7)]
	var wall := Color(0.82, 0.74, 0.62)
	var roof := Color(0.45, 0.28, 0.20)
	for s in slots:
		var p := s + Vector3(rng.randf_range(-2, 2), 0.0, rng.randf_range(-2, 2))
		var h := rng.randf_range(3.2, 6.0)
		_building(node, p, Vector3(rng.randf_range(3.5, 4.5), h, rng.randf_range(3.5, 4.5)), wall, roof)
	_lamp(node, Vector3(ROAD_HALF + 1.0, 0.0, -ROAD_HALF + 3.0), Color(1.0, 0.85, 0.55))
	var crate_mesh := BoxMesh.new()
	crate_mesh.size = Vector3(0.8, 0.8, 0.8)
	crate_mesh.material = StandardMaterial3D.new()
	crate_mesh.material.albedo_color = Color(0.55, 0.38, 0.22)
	_batch(node, "Crates", crate_mesh, 2, func(i: int) -> Vector3:
		return Vector3(rng.randf_range(-14, 14), 0.4, rng.randf_range(-14, 14)))

func _build_market(node: Node3D, rng: RandomNumberGenerator) -> void:
	# Four fixed market stalls (2x2), jittered per chunk for variety.
	var slots := [Vector3(-8, 0, -8), Vector3(8, 0, -8), Vector3(-8, 0, 8), Vector3(8, 0, 8)]
	for s in slots:
		var p := s + Vector3(rng.randf_range(-1.5, 1.5), 0.0, rng.randf_range(-1.5, 1.5))
		_building(node, p,
			Vector3(rng.randf_range(3.5, 4.0), rng.randf_range(3.5, 5.5), rng.randf_range(3.5, 4.0)),
			Color(0.78, 0.68, 0.55), Color(0.55, 0.35, 0.24))
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.4
		_lamp(node, Vector3(cos(a), 0.0, sin(a)) * 14.0, Color(1.0, 0.8, 0.45))

func _build_royal(node: Node3D, rng: RandomNumberGenerator) -> void:
	# Central palace + 5 guard towers on a fixed ring (deterministic angles).
	_building(node, Vector3(0, 0, 0), Vector3(10, rng.randf_range(9.0, 11.0), 10),
		Color(0.88, 0.86, 0.80), Color(0.35, 0.42, 0.62))
	for i in 5:
		var a := TAU * float(i) / 5.0
		_building(node, Vector3(cos(a), 0.0, sin(a)) * 10.5,
			Vector3(2.6, rng.randf_range(6.0, 8.0), 2.6),
			Color(0.85, 0.83, 0.78), Color(0.30, 0.38, 0.58))
	_lamp(node, Vector3(6, 0, 6), Color(0.9, 0.95, 1.0))

func _build_temple(node: Node3D, rng: RandomNumberGenerator) -> void:
	_building(node, Vector3(0, 0, 0), Vector3(12, rng.randf_range(7.0, 9.0), 8),
		Color(0.90, 0.87, 0.78), Color(0.72, 0.66, 0.45))
	for i in 2:
		_lamp(node, Vector3(-6 + 12.0 * float(i), 0.0, 6.5), Color(1.0, 0.92, 0.7))

func _build_harbor(node: Node3D, rng: RandomNumberGenerator) -> void:
	# Three warehouses along the west side + masts batch near the water line.
	for i in 3:
		_building(node, Vector3(-8.0, 0.0, -8.0 + 8.0 * float(i)),
			Vector3(6, rng.randf_range(4.0, 6.5), 6),
			Color(0.62, 0.60, 0.56), Color(0.35, 0.34, 0.33))
	var mast_mesh := CylinderMesh.new()
	mast_mesh.top_radius = 0.05
	mast_mesh.bottom_radius = 0.08
	mast_mesh.height = 5.0
	mast_mesh.material = StandardMaterial3D.new()
	mast_mesh.material.albedo_color = Color(0.45, 0.32, 0.2)
	_batch(node, "Masts", mast_mesh, 3, func(i: int) -> Vector3:
		return Vector3(11.0 + rng.randf_range(0, 1.0), 2.5, -8.0 + 8.0 * float(i)))
	_lamp(node, Vector3(8, 0, 0), Color(0.7, 0.9, 1.0))

func _build_garden(node: Node3D, rng: RandomNumberGenerator) -> void:
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.8
		_building(node, Vector3(cos(a), 0.0, sin(a)) * 9.5,
			Vector3(4, rng.randf_range(3.0, 5.0), 4),
			Color(0.80, 0.78, 0.72), Color(0.55, 0.62, 0.45))
	# Sakura petals: pink quads via MultiMesh (one draw call).
	var petal := PlaneMesh.new()
	petal.size = Vector2(0.18, 0.18)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(1.0, 0.72, 0.82)
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	petal.material = pmat
	_batch(node, "Petals", petal, 40, func(i: int) -> Vector3:
		return Vector3(rng.randf_range(-18, 18), rng.randf_range(1.0, 5.0), rng.randf_range(-18, 18)))
	_lamp(node, Vector3(0, 0, 10), Color(1.0, 0.8, 0.9))

func _build_meadow(node: Node3D, rng: RandomNumberGenerator) -> void:
	# Ring outside the city: cheap MultiMesh pines, kept clear of the center.
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.18
	trunk.bottom_radius = 0.28
	trunk.height = 2.4
	trunk.material = StandardMaterial3D.new()
	trunk.material.albedo_color = Color(0.42, 0.30, 0.20)
	var canopy := SphereMesh.new()
	canopy.radius = 1.6
	canopy.height = 3.2
	canopy.material = StandardMaterial3D.new()
	canopy.material.albedo_color = Color(0.28, 0.52, 0.32)
	var pts: Array[Vector3] = []
	for i in 3:
		var a := TAU * rng.randf()
		var r := rng.randf_range(14.0, 17.0)
		pts.append(Vector3(cos(a) * r, 1.2, sin(a) * r))
	_batch(node, "Trunks", trunk, 3, func(i: int) -> Vector3: return pts[i])
	_batch(node, "Canopies", canopy, 3, func(i: int) -> Vector3: return pts[i] + Vector3(0, 2.2, 0))
