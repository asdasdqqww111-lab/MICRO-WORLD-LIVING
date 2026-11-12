class_name WorldBuilder
extends RefCounted
## Procedural assembly of the 200x200m slice.
## All geometry is placed from code so layout, colliders and draw-call budgets
## stay reviewable in one file.

const GROUND_SIZE := 200.0
const INTERIOR_ORIGIN := Vector3(500.0, 0.0, 0.0)
const DUNGEON_ORIGIN := Vector3(-500.0, 0.0, 0.0)
const DUNGEON_TILE := 4.0

# --- primitives --------------------------------------------------------------

static func build_ground(parent: Node3D, size: float, center: Vector3 = Vector3.ZERO,
		color: Color = Color(0.41, 0.54, 0.31)) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Ground"
	body.collision_layer = 1
	body.collision_mask = 0
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	mesh_instance.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	mesh_instance.material_override = mat
	mesh_instance.name = "GroundMesh"
	body.add_child(mesh_instance)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size, 2.0, size)
	shape.shape = box
	shape.position = Vector3(0.0, -1.0, 0.0)
	body.add_child(shape)
	parent.add_child(body)
	body.global_position = center
	return body

static func add_box_body(parent: Node3D, position: Vector3, size: Vector3, node_name: String = "Collider") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = Vector3(0.0, size.y * 0.5, 0.0)
	body.add_child(shape)
	parent.add_child(body)
	body.global_position = position
	return body

static func place_model(parent: Node3D, path: String, position: Vector3, rotation_y: float,
		model_scale: float, collider_size: Vector3 = Vector3.ZERO, node_name: String = "") -> Node3D:
	var scene := AssetLibrary.get_scene(path)
	if scene == null:
		return null
	var node := scene.instantiate() as Node3D
	if node == null:
		return null
	if not node_name.is_empty():
		node.name = node_name
	var holder: Node3D
	if collider_size != Vector3.ZERO:
		var body := StaticBody3D.new()
		body.name = "Solid"
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = collider_size
		shape.shape = box
		shape.position = Vector3(0.0, collider_size.y * 0.5, 0.0)
		body.add_child(shape)
		parent.add_child(body)
		body.global_position = position
		body.rotation.y = rotation_y
		holder = body
	else:
		holder = Node3D.new()
		holder.name = "Prop"
		parent.add_child(holder)
		holder.global_position = position
		holder.rotation.y = rotation_y
	node.position = Vector3.ZERO
	node.rotation = Vector3.ZERO
	node.scale = Vector3.ONE * model_scale
	holder.add_child(node)
	# Several KayKit models are authored off-centre (e.g. fence_wood_straight
	# spans x -1.05..-0.95), so rotating them swings the mesh away from its
	# placement point. Centre them horizontally on their pivot. Y is untouched
	# on purpose: dungeon walls/floors rely on their authored vertical offsets.
	var bounds := _model_bounds(node)
	if bounds.size != Vector3.ZERO:
		var centre := bounds.get_center()
		node.position.x -= centre.x * model_scale
		node.position.z -= centre.z * model_scale
	return node

## Combined local AABB of every MeshInstance3D under a node.
static func _model_bounds(root: Node) -> AABB:
	var bounds := AABB()
	var first := true
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			stack.append(child)
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var box := mi.get_aabb()
		if first:
			bounds = box
			first = false
		else:
			bounds = bounds.merge(box)
	return bounds

static func build_multimesh(parent: Node3D, mesh_path: String, transforms: Array,
		node_name: String, cast_shadow: bool = true) -> MultiMeshInstance3D:
	var mesh := AssetLibrary.first_mesh(mesh_path)
	if mesh == null:
		push_warning("WorldBuilder: no mesh for %s" % mesh_path)
		return null
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for i: int in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance

# --- forest ------------------------------------------------------------------

static func build_forest(parent: Node3D, seed_value: int = 1337) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var big_trees: Array = []
	var small_trees: Array = []
	var rocks: Array = []
	var spawns: Array = []
	for i: int in 90:
		var x := rng.randf_range(-96.0, -26.0)
		var z := rng.randf_range(-62.0, 62.0)
		# keep a clearing around the skeleton camps
		var s := rng.randf_range(4.2, 5.8)
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3.ONE * s)
		var transform := Transform3D(basis, Vector3(x, rng.randf_range(-0.1, 0.05), z))
		if i % 3 == 0:
			big_trees.append(transform)
		else:
			small_trees.append(transform)
	for i: int in 40:
		var x := rng.randf_range(-100.0, -20.0)
		var z := rng.randf_range(-70.0, 70.0)
		var s := rng.randf_range(3.0, 7.0)
		rocks.append(Transform3D(Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3.ONE * s),
			Vector3(x, 0.0, z)))
	build_multimesh(parent, AssetLibrary.HEXAGON_DIR + "trees_A_large.gltf", big_trees, "ForestLargeTrees")
	build_multimesh(parent, AssetLibrary.HEXAGON_DIR + "tree_single_A.gltf", small_trees, "ForestSmallTrees")
	build_multimesh(parent, AssetLibrary.HEXAGON_DIR + "rock_single_A.gltf", rocks, "ForestRocks", false)
	spawns.append(Vector3(-56.0, 0.2, -18.0))
	spawns.append(Vector3(-64.0, 0.2, 6.0))
	spawns.append(Vector3(-48.0, 0.2, 24.0))
	spawns.append(Vector3(-38.0, 0.2, -34.0))
	spawns.append(Vector3(-72.0, 0.2, -40.0))
	return spawns

# --- village -----------------------------------------------------------------

static func build_village(parent: Node3D) -> Dictionary:
	var hex := AssetLibrary.HEXAGON_DIR
	var b := AssetLibrary.SCALE_BUILDING
	var buildings: Array = [
		{"model": "building_home_A_green.gltf", "pos": Vector3(-16.0, 0.0, -8.0), "rot": 0.0,
			"scale": b, "collider": Vector3(7.2, 7.9, 7.6), "name": "HouseA"},
		{"model": "building_home_B_green.gltf", "pos": Vector3(16.0, 0.0, -12.0), "rot": deg_to_rad(28.0),
			"scale": b, "collider": Vector3(7.6, 7.9, 7.0), "name": "HouseB"},
		{"model": "building_blacksmith_green.gltf", "pos": Vector3(-19.0, 0.0, 11.0), "rot": deg_to_rad(-18.0),
			"scale": b, "collider": Vector3(11.5, 8.4, 11.0), "name": "Blacksmith"},
		{"model": "building_market_green.gltf", "pos": Vector3(11.0, 0.0, 9.0), "rot": deg_to_rad(12.0),
			"scale": b * 0.85, "collider": Vector3(13.0, 7.2, 9.6), "name": "Market"},
		{"model": "building_tavern_green.gltf", "pos": Vector3(0.0, 0.0, -24.0), "rot": PI,
			"scale": b * 0.9, "collider": Vector3(9.6, 11.0, 10.8), "name": "Tavern"},
		{"model": "building_tower_A_green.gltf", "pos": Vector3(28.0, 0.0, 4.0), "rot": deg_to_rad(-10.0),
			"scale": b, "collider": Vector3(6.4, 14.0, 6.4), "name": "Tower"},
	]
	for entry: Dictionary in buildings:
		place_model(parent, hex + String(entry["model"]), entry["pos"] as Vector3,
			float(entry["rot"]), float(entry["scale"]), entry["collider"] as Vector3, String(entry["name"]))

	# Central well + plaza props.
	place_model(parent, hex + "building_well_green.gltf", Vector3(0.0, 0.0, 2.0), 0.0, 2.4,
		Vector3(1.6, 2.0, 1.8), "Well")
	var prop_scale := AssetLibrary.SCALE_PROP
	var props: Array = [
		{"model": "barrel.gltf", "pos": Vector3(-15.0, 0.0, 6.5)},
		{"model": "barrel.gltf", "pos": Vector3(-14.0, 0.0, 5.4)},
		{"model": "crate_A_big.gltf", "pos": Vector3(-12.6, 0.0, 7.2)},
		{"model": "crate_A_small.gltf", "pos": Vector3(11.6, 0.0, 5.2)},
		{"model": "sack.gltf", "pos": Vector3(12.4, 0.0, 6.0)},
		{"model": "weaponrack.gltf", "pos": Vector3(-17.4, 0.0, 6.2)},
		{"model": "target.gltf", "pos": Vector3(26.0, 0.0, 10.0)},
		{"model": "tent.gltf", "pos": Vector3(6.0, 0.0, 15.0)},
		{"model": "ladder.gltf", "pos": Vector3(-20.0, 0.0, 6.0)},
		{"model": "wheelbarrow.gltf", "pos": Vector3(-9.0, 0.0, 13.0)},
	]
	for prop: Dictionary in props:
		place_model(parent, hex + String(prop["model"]), prop["pos"] as Vector3,
			randf_range(0.0, TAU), prop_scale)

	# Fences around the plaza (segments with gaps for paths).
	var fence_path := hex + "fence_wood_straight.gltf"
	for i: int in 6:
		var x := -12.0 + float(i) * 4.6
		if i == 2 or i == 3:
			continue
		place_model(parent, fence_path, Vector3(x, 0.0, 22.0), 0.0, AssetLibrary.SCALE_FENCE)
	for i: int in 4:
		place_model(parent, fence_path, Vector3(-24.0, 0.0, -2.0 + float(i) * 4.6), PI * 0.5,
			AssetLibrary.SCALE_FENCE)

	# Dungeon entrance: stone stairwell west-south of the village.
	var entrance := Vector3(38.0, 0.0, 26.0)
	place_model(parent, AssetLibrary.DUNGEON_DIR + "stairs.glb", entrance, deg_to_rad(180.0), 1.0,
		Vector3.ZERO, "DungeonStairs")
	place_model(parent, AssetLibrary.DUNGEON_DIR + "wall_doorway.glb", entrance + Vector3(0.0, 0.0, 3.4),
		deg_to_rad(180.0), 1.0, Vector3.ZERO, "DungeonArch")
	place_model(parent, AssetLibrary.DUNGEON_DIR + "torch_lit.glb", entrance + Vector3(1.9, 1.2, 3.4),
		deg_to_rad(180.0), 1.0)

	return {
		"spawn": Vector3(0.0, 0.6, 14.0),
		"blacksmith_pos": Vector3(-15.0, 0.0, 10.5),
		"farmer_pos": Vector3(9.0, 0.0, 14.0),
		"guard_pos": Vector3(24.0, 0.0, 8.0),
		"farmer_rest": Vector3(9.0, 0.0, 14.0),
		"farmer_sleep": Vector3(-16.0, 0.0, -4.0),
		"guard_sleep": Vector3(28.0, 0.0, 8.0),
		"blacksmith_sleep": Vector3(-19.0, 0.0, 8.0),
		"house_door": Vector3(-16.0, 0.0, -2.4),
		"dungeon_entrance": entrance + Vector3(0.0, 0.0, 4.8),
		"dungeon_stairs": entrance,
		"raid_spawn": Vector3(0.0, 0.5, 34.0),
		"plaza": Vector3(0.0, 0.0, 2.0),
	}

# --- house interior ----------------------------------------------------------

static func build_house_interior(parent: Node3D) -> Dictionary:
	var origin := INTERIOR_ORIGIN
	var room := Rect2(-5.0, -4.0, 10.0, 8.0)
	var wall_color := Color(0.72, 0.66, 0.55)
	var floor_color := Color(0.42, 0.3, 0.2)
	var wall_height := 3.0
	var wall_thickness := 0.3
	# Floor + ceiling slabs.
	_solid_box(parent, origin + Vector3(0.0, -0.4, 0.0),
		Vector3(room.size.x, 0.4, room.size.y), floor_color, "HouseFloor")

	var ceiling := MeshInstance3D.new()
	var ceiling_box := BoxMesh.new()
	ceiling_box.size = Vector3(room.size.x, 0.2, room.size.y)
	ceiling.mesh = ceiling_box
	ceiling.material_override = _color_material(Color(0.3, 0.28, 0.26))
	ceiling.position = origin + Vector3(0.0, wall_height, 0.0)
	parent.add_child(ceiling)

	# Walls (4 sides) with a 2m doorway in the south wall so the exit is reachable.
	var south_z := room.position.y + room.size.y
	var half_width := room.size.x * 0.5
	var side_piece := half_width - 1.0
	var walls: Array = [
		{"size": Vector3(room.size.x, wall_height, wall_thickness),
			"pos": Vector3(0.0, 0.0, room.position.y)},
		{"size": Vector3(side_piece, wall_height, wall_thickness),
			"pos": Vector3(-(1.0 + side_piece * 0.5), 0.0, south_z)},
		{"size": Vector3(side_piece, wall_height, wall_thickness),
			"pos": Vector3(1.0 + side_piece * 0.5, 0.0, south_z)},
		{"size": Vector3(wall_thickness, wall_height, room.size.y),
			"pos": Vector3(room.position.x, 0.0, 0.0)},
		{"size": Vector3(wall_thickness, wall_height, room.size.y),
			"pos": Vector3(room.position.x + room.size.x, 0.0, 0.0)},
	]
	for wall: Dictionary in walls:
		_solid_box(parent, origin + (wall["pos"] as Vector3), wall["size"] as Vector3,
			wall_color, "HouseWall")

	# Furniture from KayKit Furniture Bits.
	var fur := AssetLibrary.FURNITURE_DIR
	place_model(parent, fur + "bed_single_A.gltf", origin + Vector3(-3.6, 0.0, -2.6), 0.0, 1.0)
	place_model(parent, fur + "table_small.gltf", origin + Vector3(1.2, 0.0, -2.4), 0.0, 1.0,
		Vector3(1.0, 0.9, 1.0), "HouseTable")
	place_model(parent, fur + "chair_A_wood.gltf", origin + Vector3(2.3, 0.0, -2.4), -PI * 0.5, 1.0)
	place_model(parent, fur + "chair_stool_wood.gltf", origin + Vector3(0.2, 0.0, -2.2), PI, 1.0)
	place_model(parent, fur + "rug_rectangle_A.gltf", origin + Vector3(0.0, 0.02, 0.4), 0.0, 1.8)
	place_model(parent, fur + "cabinet_small.gltf", origin + Vector3(3.8, 0.0, 1.6), -PI * 0.5, 1.0)
	place_model(parent, fur + "shelf_A_small.gltf", origin + Vector3(-4.4, 0.0, 1.8), PI * 0.5, 1.0)
	place_model(parent, fur + "book_set.gltf", origin + Vector3(1.2, 0.62, -2.4), 0.0, 1.0)
	place_model(parent, fur + "lamp_table.gltf", origin + Vector3(-1.4, 0.0, -2.4), 0.0, 1.0)
	place_model(parent, AssetLibrary.DUNGEON_DIR + "candle_lit.glb", origin + Vector3(-1.4, 0.55, -2.4), 0.0, 0.6)

	_add_omni_light(parent, origin + Vector3(0.0, 2.5, 0.0), Color(1.0, 0.82, 0.6), 1.6, 9.0)
	return {
		"spawn": origin + Vector3(0.0, 0.6, 2.2),
		"exit": origin + Vector3(0.0, 0.0, 4.6),
		"origin": origin,
	}

# --- dungeon -----------------------------------------------------------------

static func build_dungeon(parent: Node3D) -> Dictionary:
	var origin := DUNGEON_ORIGIN
	build_ground(parent, 80.0, origin + Vector3(0.0, 0.0, 0.0), Color(0.2, 0.19, 0.18))
	var floor_transforms: Array = []
	var wall_transforms: Array = []
	var rooms: Array = [
		{"rect": Rect2(0.0, 0.0, 8.0, 8.0), "doors": ["south"]},
		{"rect": Rect2(2.0, 8.0, 4.0, 8.0), "doors": ["north", "south"]},
		{"rect": Rect2(0.0, 16.0, 8.0, 8.0), "doors": ["north", "south"]},
		{"rect": Rect2(2.0, 24.0, 4.0, 4.0), "doors": ["north", "south"]},
		{"rect": Rect2(-4.0, 28.0, 16.0, 8.0), "doors": ["north"]},
	]
	for room: Dictionary in rooms:
		_add_dungeon_room(room["rect"] as Rect2, room["doors"] as Array, floor_transforms, wall_transforms)
	for i: int in floor_transforms.size():
		floor_transforms[i] = _offset_transform(floor_transforms[i], origin)
	for i: int in wall_transforms.size():
		wall_transforms[i] = _offset_transform(wall_transforms[i], origin)
	build_multimesh(parent, AssetLibrary.DUNGEON_DIR + "floor_tile_large.glb", floor_transforms, "DungeonFloors", false)
	build_multimesh(parent, AssetLibrary.DUNGEON_DIR + "wall.glb", wall_transforms, "DungeonWalls")
	_add_dungeon_colliders(parent, wall_transforms)

	# Props + light sources.
	place_model(parent, AssetLibrary.DUNGEON_DIR + "pillar.glb", origin + Vector3(1.0, 0.0, 1.0), 0.0, 1.0,
		Vector3(0.8, 4.0, 0.8), "DungeonPillar")
	place_model(parent, AssetLibrary.DUNGEON_DIR + "pillar.glb", origin + Vector3(7.0, 0.0, 1.0), 0.0, 1.0,
		Vector3(0.8, 4.0, 0.8))
	place_model(parent, AssetLibrary.DUNGEON_DIR + "rubble_large.glb", origin + Vector3(3.0, 0.0, 20.0), 0.4, 1.0)
	place_model(parent, AssetLibrary.DUNGEON_DIR + "barrel_large.glb", origin + Vector3(-3.0, 0.0, 30.0), 0.0, 1.0,
		Vector3(1.2, 1.8, 1.2))
	place_model(parent, AssetLibrary.DUNGEON_DIR + "crates_stacked.glb", origin + Vector3(-1.5, 0.0, 32.0), 0.7, 1.0)
	for torch_pos: Vector3 in [Vector3(0.4, 2.0, 2.0), Vector3(7.6, 2.0, 14.0), Vector3(2.4, 2.0, 26.0),
			Vector3(-3.0, 2.0, 33.0)]:
		place_model(parent, AssetLibrary.DUNGEON_DIR + "torch_lit.glb", origin + torch_pos, 0.0, 1.0)
	# Spike trap in the second room.
	place_model(parent, AssetLibrary.DUNGEON_DIR + "floor_tile_big_spikes.glb", origin + Vector3(4.0, 0.0, 20.0),
		0.0, 1.0)

	_add_omni_light(parent, origin + Vector3(4.0, 3.0, 4.0), Color(1.0, 0.7, 0.45), 1.4, 12.0)
	_add_omni_light(parent, origin + Vector3(4.0, 3.0, 20.0), Color(1.0, 0.7, 0.45), 1.4, 12.0)
	_add_omni_light(parent, origin + Vector3(4.0, 3.0, 32.0), Color(0.85, 0.75, 1.0), 1.6, 14.0)
	return {
		"spawn": origin + Vector3(4.0, 0.6, 3.0),
		"exit": origin + Vector3(4.0, 0.0, 7.4),
		"chest": origin + Vector3(4.0, 0.0, 33.0),
		"trap": origin + Vector3(4.0, 0.0, 20.0),
		"enemy_spawns": [origin + Vector3(4.0, 0.4, 18.0), origin + Vector3(6.0, 0.4, 31.0)],
		"origin": origin,
	}

static func _offset_transform(source: Transform3D, offset: Vector3) -> Transform3D:
	return Transform3D(source.basis, source.origin + offset)

static func _add_dungeon_room(rect: Rect2, doors: Array, floor_transforms: Array, wall_transforms: Array) -> void:
	var half_tile := DUNGEON_TILE * 0.5
	var x := rect.position.x
	while x < rect.position.x + rect.size.x - 0.01:
		var z := rect.position.y
		while z < rect.position.y + rect.size.y - 0.01:
			floor_transforms.append(Transform3D(Basis.IDENTITY, Vector3(x + half_tile, 0.0, z + half_tile)))
			z += DUNGEON_TILE
		x += DUNGEON_TILE
	# Perimeter walls; skip the middle segment on sides that have a door.
	var segments_x := int(rect.size.x / DUNGEON_TILE)
	var segments_z := int(rect.size.y / DUNGEON_TILE)
	for i: int in segments_x:
		var cx := rect.position.x + half_tile + float(i) * DUNGEON_TILE
		var skip_middle := doors.has("north") and i == int(segments_x / 2)
		if not skip_middle:
			wall_transforms.append(Transform3D(Basis.IDENTITY, Vector3(cx, 0.0, rect.position.y)))
		var skip_south := doors.has("south") and i == int(segments_x / 2)
		if not skip_south:
			wall_transforms.append(Transform3D(Basis.IDENTITY,
				Vector3(cx, 0.0, rect.position.y + rect.size.y)))
	for i: int in segments_z:
		var cz := rect.position.y + half_tile + float(i) * DUNGEON_TILE
		var door_middle := i == int(segments_z / 2)
		if not (doors.has("west") and door_middle):
			wall_transforms.append(Transform3D(Basis(Vector3.UP, PI * 0.5),
				Vector3(rect.position.x, 0.0, cz)))
		if not (doors.has("east") and door_middle):
			wall_transforms.append(Transform3D(Basis(Vector3.UP, PI * 0.5),
				Vector3(rect.position.x + rect.size.x, 0.0, cz)))

static func _add_dungeon_colliders(parent: Node3D, wall_transforms: Array) -> void:
	var body := StaticBody3D.new()
	body.name = "DungeonWallColliders"
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	for transform: Transform3D in wall_transforms:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(4.0, 4.0, 0.6)
		shape.shape = box
		shape.transform = Transform3D(transform.basis, transform.origin + Vector3(0.0, 2.0, 0.0))
		body.add_child(shape)

## Static box whose collider and mesh share the same base position.
static func _solid_box(parent: Node3D, base_position: Vector3, size: Vector3,
		color: Color, node_name: String = "SolidBox") -> StaticBody3D:
	var body := add_box_body(parent, base_position, size, node_name)
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = _color_material(color)
	mesh_instance.position = Vector3(0.0, size.y * 0.5, 0.0)
	body.add_child(mesh_instance)
	return body

static func _add_omni_light(parent: Node3D, position: Vector3, color: Color,
		energy: float, range_value: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = false
	parent.add_child(light)
	light.global_position = position
	return light

static func _color_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat
