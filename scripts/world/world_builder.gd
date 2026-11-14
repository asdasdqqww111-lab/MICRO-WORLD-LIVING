class_name WorldBuilder
extends RefCounted
## Procedural & curated assembly of the 240x240m Eldoria Starting Region:
##   - Eldoria Royal City (Citadel, guild, market, residential, civic and artisan wards,
##     Blacksmith Forge, Residential Cottages, Windmill Farm, Guarded Gates)
##   - 6 MultiMesh Biome Forest & Flora Zones + Eldoria River, Bridge & Crystal Lake
##   - Outer Landmarks: Ancient Ruins, Shadowfang Cave, Monster Camp, Sacred Grove
##   - Enterable Cottage Interior, Grand Adventurers Guild Hall Interior,
##     and Modular Sunken Crypt Dungeon (Traps, Secret Alcove, Boss Sanctum)

const GROUND_SIZE := 240.0
const INTERIOR_ORIGIN := Vector3(500.0, 0.0, 0.0)
const GUILD_ORIGIN := Vector3(500.0, 0.0, 200.0)
const DUNGEON_ORIGIN := Vector3(-500.0, 0.0, 0.0)
const DUNGEON_TILE := 4.0

# --- Primitives & Placement Helpers ------------------------------------------

static func build_ground(parent: Node3D, size: float, center: Vector3 = Vector3.ZERO,
		color: Color = Color(0.28, 0.34, 0.24)) -> StaticBody3D:
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
	# Merge multi-child static GLTF/GLB props & buildings into ONE single MeshInstance3D (~12x fewer draw calls!)
	var node: Node3D = null
	var merged_mesh: Mesh = AssetLibrary.first_mesh(path)
	if merged_mesh != null:
		var mmi := MeshInstance3D.new()
		mmi.mesh = merged_mesh
		node = mmi
	else:
		node = AssetLibrary.instantiate(path, model_scale)
	if node == null:
		return null
	if not node_name.is_empty():
		node.name = node_name
	var holder: Node3D
	if collider_size != Vector3.ZERO:
		var body := StaticBody3D.new()
		body.name = (node_name + "Body") if not node_name.is_empty() else "Solid"
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
		holder.name = node_name if not node_name.is_empty() else "Prop"
		parent.add_child(holder)
		holder.global_position = position
		holder.rotation.y = rotation_y
	node.position = Vector3.ZERO
	node.rotation = Vector3.ZERO
	node.scale = Vector3.ONE * model_scale
	holder.add_child(node)
	var bounds := _model_bounds(node)
	if bounds.size != Vector3.ZERO:
		var centre := bounds.get_center()
		node.position.x -= centre.x * model_scale
		node.position.z -= centre.z * model_scale
	var is_hero := collider_size.length() >= 4.5
	var lod_dist := 78.0 if is_hero else 36.0
	_apply_model_lod(node, lod_dist, is_hero)
	return node

static func _apply_model_lod(root: Node, dist: float, cast_shadows: bool) -> void:
	if root is GeometryInstance3D:
		var gi := root as GeometryInstance3D
		gi.visibility_range_end = dist
		gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		if not cast_shadows:
			gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c: Node in root.get_children():
		_apply_model_lod(c, dist, cast_shadows)

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
		node_name: String, cast_shadow: bool = true, vis_end: float = 0.0) -> MultiMeshInstance3D:
	if transforms.is_empty():
		return null
	var mesh := AssetLibrary.first_mesh(mesh_path)
	if mesh == null:
		return null
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for i: int in transforms.size():
		multimesh.set_instance_transform(i, transforms[i] as Transform3D)
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if vis_end > 0.0:
		instance.visibility_range_end = vis_end
		instance.visibility_range_end_margin = 0.0
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	parent.add_child(instance)
	return instance

# --- 1. Eldoria Village & Outer Landmarks ------------------------------------

static func build_city(parent: Node3D, terrain: Terrain = null) -> Dictionary:
	# The whole town layout (lots, streets, wall ring) lives in CityPlan.
	_build_city_buildings(parent)
	_build_city_streets(parent)
	_build_city_walls(parent)
	_build_city_furniture(parent)

	# Ancient stone arch on the northern hillside, outside the walls.
	var arch_hill_y := terrain.height_at(-19.0, -47.0) if terrain != null else 3.2
	if AssetLibrary.has_model("res://assets/environments/medieval_megakit/Wall_Arch.gltf"):
		place_model(parent, "res://assets/environments/medieval_megakit/Wall_Arch.gltf",
			Vector3(-19.0, arch_hill_y - 0.15, -47.0), deg_to_rad(18.0), 2.35, Vector3.ZERO, "HillsideStoneArch")

	# Outer valley out-of-bounds perimeter colliders (+/-116 m).
	add_box_body(parent, Vector3(0.0, -4.0, -116.0), Vector3(240.0, 38.0, 2.0), "NorthValleyWall")
	add_box_body(parent, Vector3(0.0, -4.0, 116.0), Vector3(240.0, 38.0, 2.0), "SouthValleyWall")
	add_box_body(parent, Vector3(-116.0, -4.0, 0.0), Vector3(2.0, 38.0, 240.0), "WestValleyWall")
	add_box_body(parent, Vector3(116.0, -4.0, 0.0), Vector3(2.0, 38.0, 240.0), "EastValleyWall")

	# Interactive stations: each one stands next to the building it belongs to.
	var ext_board := QuestBoardProp.new()
	ext_board.name = "VillageQuestBoard"
	ext_board.setup("Inspect Adventurers Guild Quest Board")
	parent.add_child(ext_board)
	ext_board.global_position = Vector3(4.3, 0.0, -10.9)

	var forge := CraftingStation.new()
	forge.name = "BlacksmithForge"
	forge.setup("forge", "Blacksmith Anvil Forge")
	parent.add_child(forge)
	forge.global_position = Vector3(-4.2, 0.0, 9.4)

	var alchemy := CraftingStation.new()
	alchemy.name = "ChapelAlchemyBench"
	alchemy.setup("alchemy", "Alchemist's Workbench")
	parent.add_child(alchemy)
	alchemy.global_position = Vector3(19.0, 0.0, -16.6)

	# River, Crystal Lake, stone bridge, ruins, cave, camp, sacred grove and crypt entrance.
	var outer := _build_water_and_outer_landmarks(parent, terrain)

	var raid_y := terrain.height_at(0.0, 41.0) if terrain != null else 0.0
	return {
		"spawn": CityPlan.SPAWN,
		"plaza": CityPlan.PLAZA,
		"guild_door": CityPlan.GUILD_DOOR,
		"house_door": CityPlan.HOUSE_DOOR,
		"dungeon_entrance": outer["dungeon_entrance"],
		"dungeon_stairs": outer["dungeon_stairs"],
		"ruins": outer["ruins"],
		"cave": outer["cave"],
		"monster_camp": outer["monster_camp"],
		"sacred_grove": outer["sacred_grove"],
		"bridge": outer["bridge"],
		"lake": Vector3(16.0, 0.0, 54.0),
		"raid_spawn": Vector3(0.0, raid_y + 0.5, 41.0),
		"blacksmith_pos": Vector3(-4.5, 0.0, 7.4),
		"blacksmith_sleep": CityPlan.lot_center("Blacksmith"),
		"farmer_pos": Vector3(-13.6, 0.0, 21.0),
		"farmer_rest": Vector3(-5.0, 0.0, 15.0),
		"farmer_sleep": CityPlan.lot_center("SouthHouseWestA"),
		"guard_pos": Vector3(31.5, 0.0, -3.4),
		"guard_sleep": CityPlan.lot_center("Barracks"),
	}

# Compatibility entry point for old save data, tests and external callers.
static func build_village(parent: Node3D, terrain: Terrain = null) -> Dictionary:
	return build_city(parent, terrain)

static func _build_city_buildings(parent: Node3D) -> void:
	for entry: Dictionary in CityPlan.lots():
		var node_name := String(entry["name"])
		var size: Vector3 = entry["size"]
		var pos: Vector3 = entry["pos"]
		var is_castle := node_name == "AdventurersGuildExterior"
		# The hexagonal citadel gets three boxes below; everything else is one
		# box slightly inside its visual footprint so corners are not sticky.
		var collider := Vector3.ZERO if is_castle else Vector3(size.x * 0.9, size.y, size.z * 0.9)
		var node := place_model(parent, String(entry["path"]), pos, float(entry["yaw"]),
			float(entry["scale"]), collider, node_name)
		if is_castle and node != null:
			_apply_model_lod(node, 0.0, true)
			var gi := node as GeometryInstance3D
			if gi != null:
				gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var c := CityPlan.CASTLE_CENTER
	var k := CityPlan.CASTLE_SCALE
	add_box_body(parent, c, Vector3(1.90 * k, 14.0, 1.16 * k), "CitadelBodyMid")
	add_box_body(parent, c + Vector3(0.0, 0.0, 0.83 * k), Vector3(1.00 * k, 14.0, 0.56 * k), "CitadelBodyFront")
	add_box_body(parent, c + Vector3(0.0, 0.0, -0.83 * k), Vector3(1.00 * k, 14.0, 0.56 * k), "CitadelBodyRear")

## Paved streets as one mesh (one draw call). The terrain grid is 4 m, far too
## coarse to paint a 5 m street, so the streets are real geometry laid 5 cm
## above the level town plateau.
static func _build_city_streets(parent: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var paved := Color(0.88, 0.83, 0.76)
	var earth := Color(0.66, 0.54, 0.40)
	var layer := 0
	for rect: Array in CityPlan.street_rects():
		var col := paved if int(rect[4]) == 0 else earth
		var y := 0.05 + float(layer) * 0.004
		layer += 1
		_street_quad(st, float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]), y, col)
	# Royal Plaza disc.
	var plaza_y := 0.09
	var steps := 28
	for i: int in steps:
		var a0 := float(i) / float(steps) * TAU
		var a1 := float(i + 1) / float(steps) * TAU
		var p0 := Vector3(cos(a0), 0.0, sin(a0)) * CityPlan.PLAZA_RADIUS
		var p1 := Vector3(cos(a1), 0.0, sin(a1)) * CityPlan.PLAZA_RADIUS
		for v: Vector3 in [Vector3.ZERO, p0, p1]:
			st.set_normal(Vector3.UP)
			st.set_color(Color(0.93, 0.89, 0.82))
			st.set_uv(Vector2(v.x, v.z) * 0.25)
			st.add_vertex(Vector3(v.x, plaza_y, v.z))
	var mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = ArtDirection.get_realistic_tex("cobble_albedo.jpg")
	mat.roughness = 0.92
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.name = "CityStreets"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)

static func _street_quad(st: SurfaceTool, x0: float, z0: float, x1: float, z1: float, y: float, col: Color) -> void:
	var corners := [Vector3(x0, y, z0), Vector3(x1, y, z0), Vector3(x1, y, z1),
		Vector3(x0, y, z0), Vector3(x1, y, z1), Vector3(x0, y, z1)]
	for v: Vector3 in corners:
		st.set_normal(Vector3.UP)
		st.set_color(col)
		st.set_uv(Vector2(v.x, v.z) * 0.25)
		st.add_vertex(v)

## Closed wall ring with three open gates. Straight segments are one MultiMesh;
## every segment and gate tower has a collider, so the wall really keeps the
## wilderness out and the only ways in are the three gates.
static func _build_city_walls(parent: Node3D) -> void:
	var hex := AssetLibrary.HEXAGON_DIR
	var apothem := CityPlan.wall_apothem()
	var seg_len := CityPlan.wall_segment_length()
	var wall_scale := seg_len * 0.5           # wall_straight.gltf is 2 units long
	var wall_height := 1.10 * wall_scale
	var wall_xforms: Array = []
	var body := StaticBody3D.new()
	body.name = "RoyalWallColliders"
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var seg_shape := BoxShape3D.new()
	seg_shape.size = Vector3(seg_len + 0.3, wall_height, 0.62 * wall_scale)
	for i: int in CityPlan.WALL_SEGMENTS:
		if CityPlan.is_gate_segment(i):
			continue
		var bearing := float(i) * 360.0 / float(CityPlan.WALL_SEGMENTS)
		var pos := CityPlan.bearing_point(bearing, apothem)
		var yaw := -deg_to_rad(bearing)
		wall_xforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * wall_scale), pos))
		var cs := CollisionShape3D.new()
		cs.shape = seg_shape
		cs.position = pos + Vector3(0.0, wall_height * 0.5, 0.0)
		cs.rotation.y = yaw
		body.add_child(cs)
	build_multimesh(parent, hex + "wall_straight.gltf", wall_xforms, "RoyalCityWalls", true, 150.0)

	# Gate towers: two per gate, flanking a 5.6 m wide opening on the avenue.
	var tower_scale := 4.6
	var tower_size := Vector3(1.00, 2.19, 1.15) * tower_scale
	var tower_shape := BoxShape3D.new()
	tower_shape.size = Vector3(tower_size.x * 0.94, tower_size.y, tower_size.z * 0.94)
	var tower_xforms: Array = []
	var offset := CityPlan.GATE_HALF_OPENING + tower_size.x * 0.5
	for g: int in CityPlan.GATE_BEARINGS.size():
		var b := deg_to_rad(float(CityPlan.GATE_BEARINGS[g]))
		var centre := CityPlan.gate_position(g)
		var tangent := Vector3(cos(b), 0.0, sin(b))
		var outward := Vector3(sin(b), 0.0, -cos(b))
		var tower_yaw := atan2(outward.x, outward.z)
		for side: float in [-1.0, 1.0]:
			var tpos := centre + tangent * (offset * side)
			tower_xforms.append(Transform3D(Basis(Vector3.UP, tower_yaw).scaled(Vector3.ONE * tower_scale), tpos))
			var tcs := CollisionShape3D.new()
			tcs.shape = tower_shape
			tcs.position = tpos + Vector3(0.0, tower_size.y * 0.5, 0.0)
			tcs.rotation.y = tower_yaw
			body.add_child(tcs)
	build_multimesh(parent, hex + "building_tower_A_green.gltf", tower_xforms, "RoyalGateTowers", true, 150.0)

## Street furniture, garden trees, farm plots and yard props. Everything is
## either on a pavement edge or inside a garden rectangle from CityPlan.
static func _build_city_furniture(parent: Node3D) -> void:
	var hex := AssetLibrary.HEXAGON_DIR
	var park := "res://assets/environments/tinytreats_park/"
	var nprop := "res://assets/environments/villages/"

	# Fountain in the middle of the Royal Plaza.
	place_model(parent, park + "fountain.gltf", CityPlan.PLAZA, 0.0, 1.1, Vector3(3.8, 1.3, 3.8), "DistrictFountain")

	# Lantern posts on the pavement edge, alternating sides along each avenue.
	# The first six also carry a real light (switched on at dusk).
	var e := CityPlan.AVENUE_HALF + 0.8
	var lantern_spots := [
		Vector3(-8.0, 0.0, -e), Vector3(8.0, 0.0, e), Vector3(e, 0.0, 10.0),
		Vector3(-4.4, 0.0, -7.6), Vector3(17.5, 0.0, -e), Vector3(-17.5, 0.0, e),
		Vector3(4.4, 0.0, -7.6), Vector3(-25.0, 0.0, -e), Vector3(25.0, 0.0, e),
		Vector3(-32.0, 0.0, e), Vector3(32.0, 0.0, -e), Vector3(-e, 0.0, 18.0),
		Vector3(e, 0.0, 25.6), Vector3(-e, 0.0, 32.0),
	]
	var lantern_xforms: Array = []
	for lp: Vector3 in lantern_spots:
		lantern_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.80), lp))
	build_multimesh(parent, park + "street_lantern.gltf", lantern_xforms, "CityStreetLanternPosts", false, 64.0)
	for i: int in mini(6, lantern_spots.size()):
		_build_street_lantern_light_only(parent, lantern_spots[i])

	# Benches around the fountain, facing it.
	var bench_xforms: Array = []
	for i: int in 4:
		var ang := deg_to_rad(45.0 + 90.0 * float(i))
		var bp := Vector3(cos(ang), 0.0, sin(ang)) * (CityPlan.PLAZA_RADIUS - 1.5)
		bench_xforms.append(Transform3D(Basis(Vector3.UP, atan2(-bp.x, -bp.z)).scaled(Vector3.ONE * 0.9), bp))
	build_multimesh(parent, park + "bench.gltf", bench_xforms, "RoyalCityBenches", false, 48.0)

	# Royal banners: citadel forecourt and the town side of every gate.
	var flag_xforms: Array = []
	var flag_scale := AssetLibrary.SCALE_PROP * 1.18
	for fp: Vector3 in [Vector3(-5.6, 0.0, -11.6), Vector3(5.6, 0.0, -11.6)]:
		flag_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * flag_scale), fp))
	for g: int in CityPlan.GATE_BEARINGS.size():
		var b := deg_to_rad(float(CityPlan.GATE_BEARINGS[g]))
		var inward := Vector3(-sin(b), 0.0, cos(b))
		var tangent := Vector3(cos(b), 0.0, sin(b))
		for side: float in [-1.0, 1.0]:
			var fpos := CityPlan.gate_position(g) + inward * 3.6 + tangent * (3.5 * side)
			flag_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * flag_scale), fpos))
	build_multimesh(parent, hex + "flag_blue.gltf", flag_xforms, "CityRoyalBanners", false, 64.0)

	# Garden trees (Royal Garden, chapel herb garden, training yard).
	var tree_spots := [
		Vector3(-24.0, 1.9, -15.0), Vector3(-17.6, 1.7, -19.4), Vector3(-24.2, 2.0, -19.8),
		Vector3(18.6, 1.8, -19.6), Vector3(24.0, 1.7, -16.0), Vector3(23.4, 2.0, -20.2),
		Vector3(17.2, 1.8, 26.6),
	]
	var tree_xforms: Array = []
	var trunks := StaticBody3D.new()
	trunks.name = "CityGardenTrunks"
	trunks.collision_layer = 1
	trunks.collision_mask = 0
	parent.add_child(trunks)
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.45
	trunk_shape.height = 3.0
	for ts: Vector3 in tree_spots:
		var tpos := Vector3(ts.x, 0.0, ts.z)
		tree_xforms.append(Transform3D(Basis(Vector3.UP, ts.x * 0.7).scaled(Vector3.ONE * ts.y), tpos))
		var tc := CollisionShape3D.new()
		tc.shape = trunk_shape
		tc.position = tpos + Vector3(0.0, 1.5, 0.0)
		trunks.add_child(tc)
	build_multimesh(parent, park + "tree.gltf", tree_xforms, "CityGardenTrees", true, 70.0)

	# Farm plots behind the south-west houses, next to the windmill.
	var wheat_xforms: Array = []
	var pumpkin_xforms: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 901
	for rx: int in 2:
		for rz: int in 4:
			var fx := -14.6 + float(rx) * 1.6
			var fz := 18.5 + float(rz) * 1.7
			wheat_xforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * 2.55), Vector3(fx, 0.0, fz)))
	for pp: Vector2 in [Vector2(-16.4, 25.6), Vector2(-14.9, 25.6), Vector2(-13.4, 25.6), Vector2(-15.5, 27.0), Vector2(-14.0, 27.0)]:
		pumpkin_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 2.0), Vector3(pp.x, 0.0, pp.y)))
	build_multimesh(parent, nprop + "crops-wheatstagea.glb", wheat_xforms, "FarmWheat", false, 42.0)
	build_multimesh(parent, nprop + "crop-pumpkin.glb", pumpkin_xforms, "FarmPumpkins", false, 42.0)

	# A handful of working props beside the buildings that use them.
	var prop_scale := AssetLibrary.SCALE_PROP
	var props: Array = [
		{"model": hex + "barrel.gltf", "pos": Vector3(-5.0, 0.0, 12.4), "s": prop_scale},      # smithy
		{"model": hex + "barrel.gltf", "pos": Vector3(-4.4, 0.0, 11.4), "s": prop_scale},
		{"model": hex + "crate_A_big.gltf", "pos": Vector3(-5.0, 0.0, 5.3), "s": prop_scale},
		{"model": hex + "crate_A_small.gltf", "pos": Vector3(8.0, 0.0, 13.0), "s": prop_scale},  # market back door
		{"model": hex + "sack.gltf", "pos": Vector3(9.1, 0.0, 13.0), "s": prop_scale},
		{"model": hex + "weaponrack.gltf", "pos": Vector3(13.4, 0.0, 17.4), "s": prop_scale},   # training yard
		{"model": hex + "target.gltf", "pos": Vector3(13.2, 0.0, 21.5), "s": prop_scale},
		{"model": hex + "target.gltf", "pos": Vector3(13.2, 0.0, 24.0), "s": prop_scale},
		{"model": hex + "wheelbarrow.gltf", "pos": Vector3(-13.4, 0.0, 17.3), "s": prop_scale},  # farm
		{"model": nprop + "sign.glb", "pos": Vector3(-22.7, 0.0, -3.7), "s": 2.2},               # hero cottage
	]
	for prop: Dictionary in props:
		if AssetLibrary.has_model(String(prop["model"])):
			place_model(parent, String(prop["model"]), prop["pos"] as Vector3, rng.randf_range(0.0, TAU), float(prop["s"]))

static func _build_street_lantern_light_only(parent: Node3D, pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.add_to_group("village_lantern")
	light.light_color = Color(1.0, 0.78, 0.44)
	light.light_energy = 1.25
	light.omni_range = 10.5
	light.shadow_enabled = false
	light.visible = false
	parent.add_child(light)
	light.global_position = pos + Vector3(0.0, 3.05, 0.0)

## Exact (triangle mesh) static collider for a placed model. Used where a box
## would be wrong, e.g. the humped deck of the stone bridge.
static func add_mesh_collider(parent: Node3D, path: String, position: Vector3, rotation_y: float,
		model_scale: float, node_name: String) -> StaticBody3D:
	var mesh := AssetLibrary.first_mesh(path)
	if mesh == null:
		return null
	var faces := mesh.get_faces()
	if faces.is_empty():
		return null
	var centre := mesh.get_aabb().get_center()
	var xf := Transform3D(Basis(Vector3.UP, rotation_y).scaled(Vector3.ONE * model_scale), Vector3.ZERO)
	var offset := Vector3(centre.x, 0.0, centre.z)
	for i: int in faces.size():
		faces[i] = xf * (faces[i] - offset)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	parent.add_child(body)
	body.global_position = position
	return body

static func _build_water_and_outer_landmarks(parent: Node3D, terrain: Terrain) -> Dictionary:
	var y_at := func(x: float, z: float) -> float:
		return terrain.height_at(x, z) if terrain != null else 0.0

	# 1. Animated PBR Specular Water Surface for Eldoria River & Crystal Lake
	var river_mesh := MeshInstance3D.new()
	river_mesh.name = "EldoriaRiverAndLake"
	var plane := PlaneMesh.new()
	plane.size = Vector2(106.0, 136.0)
	river_mesh.mesh = plane
	river_mesh.material_override = ArtDirection.water_shader_material()
	river_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	river_mesh.position = Vector3(31.0, Terrain.WATER_LEVEL, -2.0)
	parent.add_child(river_mesh)

	# 2. East Stone Arch Bridge: it carries the East Avenue across the river,
	# so it lies on the avenue axis and spans east-west. The deck is humped,
	# so it gets an exact mesh collider instead of a flat box.
	var bridge_z := CityPlan.BRIDGE_Z
	var bridge_x := terrain.river_center_x(bridge_z) if terrain != null else 45.5
	var bridge_pos := Vector3(bridge_x, 0.0, bridge_z)
	var bridge_path := AssetLibrary.HEXAGON_DIR + "building_bridge_A.gltf"
	# The hexagon-kit bridge runs along a hex axis (60 degrees off the model's
	# X axis), so a 60 degree turn is what lines the deck up with the avenue.
	var bridge_yaw := deg_to_rad(60.0)
	var bridge_node := place_model(parent, bridge_path, bridge_pos, bridge_yaw, 7.8,
		Vector3.ZERO, "EastStoneBridge")
	if bridge_node != null:
		_apply_model_lod(bridge_node, 90.0, false)
	add_mesh_collider(parent, bridge_path, bridge_pos, bridge_yaw, 7.8, "BridgeDeckCollider")

	# Riverside watermill on the west bank, north-east of the walls.
	var mill_z := -30.0
	var mill_x := (terrain.river_center_x(mill_z) - 5.2) if terrain != null else 35.8
	place_model(parent, AssetLibrary.HEXAGON_DIR + "building_watermill_blue.gltf",
		Vector3(mill_x, maxf(0.0, float(y_at.call(mill_x, mill_z))), mill_z), deg_to_rad(90.0), 7.0,
		Vector3(6.8, 7.5, 6.8), "RiversideWatermill")
	place_model(parent, "res://assets/environments/mountains/cliff-steps-rock.glb",
		Vector3(46.0, maxf(0.0, float(y_at.call(46.0, -56.0)) - 1.0), -56.0), 0.0, 5.5, Vector3.ZERO, "NorthernWaterfall")

	# 3. Eastern Ancient Ruins (x=66, z=-18) — Realistic Sculpted Stone Ruins
	var ruins_y: float = float(y_at.call(66.0, -18.0))
	var ruins_pos := Vector3(66.0, ruins_y, -18.0)
	place_model(parent, AssetLibrary.REALISTIC_NATURE_DIR + "ancient_ruins_01.glb", ruins_pos, 0.4, 2.35,
		Vector3(7.5, 5.5, 7.5), "AncientRuinsMain")
	place_model(parent, AssetLibrary.REALISTIC_NATURE_DIR + "ancient_ruins_02.glb", ruins_pos + Vector3(-4.6, 0.0, 3.6), 0.1, 2.0)
	place_model(parent, AssetLibrary.DUNGEON_DIR + "pillar.glb", ruins_pos + Vector3(5.0, 0.0, -4.0), 0.2, 1.2)
	place_model(parent, "res://assets/environments/dungeons/statue-columndamaged.glb", ruins_pos + Vector3(3.5, 0.0, 4.5), 0.6, 2.8)

	# 4. Northern Shadowfang Cave Mouth (x=-14, z=-64)
	var cave_y: float = float(y_at.call(-14.0, -64.0))
	var cave_pos := Vector3(-14.0, cave_y, -64.0)
	place_model(parent, "res://assets/environments/mountains/cliff-cave-rock.glb", cave_pos, 0.0, 5.8,
		Vector3.ZERO, "ShadowfangCave")
	place_model(parent, AssetLibrary.DUNGEON_DIR + "torch_lit.glb", cave_pos + Vector3(-2.6, 1.4, 3.2), 0.0, 1.0)
	place_model(parent, AssetLibrary.DUNGEON_DIR + "torch_lit.glb", cave_pos + Vector3(2.6, 1.4, 3.2), 0.0, 1.0)

	# 5. Western Monster Camp (x=-62, z=-24)
	var camp_y: float = float(y_at.call(-62.0, -24.0))
	var camp_pos := Vector3(-62.0, camp_y, -24.0)
	place_model(parent, "res://assets/environments/villages/tent-detailedopen.glb", camp_pos + Vector3(-3.8, 0.0, -2.5), 0.8, 2.8,
		Vector3(2.8, 2.2, 2.8), "CampTentA")
	place_model(parent, "res://assets/environments/villages/campfire-stones.glb", camp_pos, 0.0, 2.4)
	_add_omni_light(parent, camp_pos + Vector3(0.0, 0.9, 0.0), Color(1.0, 0.52, 0.18), 1.1, 7.5)

	# 6. Southwest Sacred Ancient Grove (Hidden Area: x=-56, z=44)
	var grove_y: float = float(y_at.call(-56.0, 44.0))
	var grove_pos := Vector3(-56.0, grove_y, 44.0)
	place_model(parent, "res://assets/environments/dungeons/statue-obelisk.glb", grove_pos, 0.0, 3.4,
		Vector3(1.5, 4.2, 1.5), "SacredGroveShrine")
	_add_omni_light(parent, grove_pos + Vector3(0.0, 2.2, 0.0), Color(0.42, 0.82, 1.0), 1.3, 9.0)

	# 7. Sunken Crypt Dungeon Entrance + Gothic Mausoleum Sanctuary (East of Stone Bridge: x=58, z=22)
	var crypt_y: float = float(y_at.call(58.0, 22.0))
	var entrance := Vector3(58.0, crypt_y, 22.0)
	if AssetLibrary.has_model("res://assets/environments/crypt_bits/crypt.gltf"):
		place_model(parent, "res://assets/environments/crypt_bits/crypt.gltf", entrance + Vector3(0.0, 0.0, -3.2),
			0.0, 1.45, Vector3(4.5, 4.2, 4.2), "CryptMausoleum")
		place_model(parent, "res://assets/environments/crypt_bits/post_lantern.gltf", entrance + Vector3(-2.6, 0.0, 3.8), 0.0, 1.15)
		place_model(parent, "res://assets/environments/crypt_bits/post_lantern.gltf", entrance + Vector3(2.6, 0.0, 3.8), 0.0, 1.15)
	place_model(parent, AssetLibrary.DUNGEON_DIR + "stairs.glb", entrance, deg_to_rad(180.0), 1.15,
		Vector3.ZERO, "DungeonStairs")
	place_model(parent, AssetLibrary.DUNGEON_DIR + "wall_doorway.glb", entrance + Vector3(0.0, 0.0, 3.4),
		deg_to_rad(180.0), 1.15, Vector3.ZERO, "DungeonArch")
	place_model(parent, AssetLibrary.DUNGEON_DIR + "torch_lit.glb", entrance + Vector3(2.0, 1.3, 3.4),
		deg_to_rad(180.0), 1.0)
	place_model(parent, AssetLibrary.DUNGEON_DIR + "torch_lit.glb", entrance + Vector3(-2.0, 1.3, 3.4),
		deg_to_rad(180.0), 1.0)

	return {
		"bridge": bridge_pos,
		"ruins": ruins_pos,
		"cave": cave_pos + Vector3(0.0, 0.4, 4.0),
		"monster_camp": camp_pos,
		"sacred_grove": grove_pos,
		"dungeon_stairs": entrance,
		"dungeon_entrance": entrance + Vector3(0.0, 0.2, 4.8),
	}

# --- 2. Multi-Biome GPU-Instanced Forests & Flora ----------------------------

static func _make_stylized_grass_tuft_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var angles := [0.0, 0.82, 1.68, 2.48]
	var offsets := [Vector2(-0.08, -0.05), Vector2(0.09, -0.04), Vector2(-0.04, 0.09), Vector2(0.07, 0.08)]
	var heights := [0.54, 0.46, 0.58, 0.42]
	for idx in angles.size():
		var a: float = angles[idx]
		var off: Vector2 = offsets[idx]
		var h: float = heights[idx]
		var dir := Vector3(cos(a), 0.0, sin(a)) * 0.075
		var lean := Vector3(-sin(a), 0.0, cos(a)) * 0.085
		var base := Vector3(off.x, -0.03, off.y)
		var v0 := base - dir
		var v1 := base + dir
		var v2 := base + Vector3(0.0, h, 0.0) + lean
		var nrm := Vector3(0.0, 1.0, 0.0)
		st.set_normal(nrm); st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(v0)
		st.set_normal(nrm); st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(v1)
		st.set_normal(nrm); st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(v2)
	var mesh := st.commit()
	mesh.surface_set_material(0, ArtDirection.wind_grass_shader_material())
	return mesh

static func _add_golden_meadow_motes(parent: Node3D) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var motes := GPUParticles3D.new()
	motes.name = "GoldenMeadowMotes"
	motes.amount = 48
	motes.lifetime = 5.5
	motes.preprocess = 2.0
	motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	motes.position = Vector3(0.0, 2.0, 50.0)   # south meadow, between the gate and the lake
	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(18.0, 1.8, 18.0)
	pmat.direction = Vector3(0.3, 0.4, -0.2)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 0.08
	pmat.initial_velocity_max = 0.24
	pmat.gravity = Vector3(0.0, 0.02, 0.0)
	pmat.scale_min = 0.65
	pmat.scale_max = 1.35
	motes.process_material = pmat
	var q := QuadMesh.new()
	q.size = Vector2(0.065, 0.065)
	var qmat := StandardMaterial3D.new()
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qmat.albedo_color = Color(1.0, 0.90, 0.48, 0.82)
	q.material = qmat
	motes.draw_pass_1 = q
	parent.add_child(motes)

static func build_forest(parent: Node3D, terrain: Terrain = null, seed_value: int = 1337) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var oak_xforms: Array = []
	var dense_xforms: Array = []
	var pine_xforms: Array = []
	var birch_xforms: Array = []
	var rock_xforms: Array = []
	var bush_xforms: Array = []
	var flower_xforms: Array = []
	var reed_xforms: Array = []
	var trunk_positions: Array[Vector3] = []
	var rock_positions: Array[Vector3] = []

	# 1. Western woodland: a real forest belt outside the west gate. Nothing
	# is scattered inside the town walls any more (trees there are planted in
	# the gardens by the city builder).
	for i: int in 24:
		var lx := rng.randf_range(-74.0, -40.0)
		var lz := rng.randf_range(-46.0, 26.0)
		if CityPlan.inside_walls(lx, lz, 5.0) or (terrain != null and terrain.is_road_at(lx, lz)):
			continue
		if Vector2(lx + 62.0, lz + 24.0).length() < 10.0 or Vector2(lx + 52.0, lz - 34.0).length() < 9.0:
			continue
		var ly := terrain.height_at(lx, lz) if terrain != null else 0.0
		if ly > 15.0:
			continue
		var lpos := Vector3(lx, ly - 0.08, lz)
		var ls := rng.randf_range(3.6, 4.8)
		pine_xforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * ls), lpos))
		trunk_positions.append(lpos)

	# Outer Valley Multi-Biome Stylized Trees (natural 7.5-10m forest scale, <160k total triangles!)
	for i: int in 80:
		var x := rng.randf_range(-108.0, 108.0)
		var z := rng.randf_range(-108.0, 108.0)
		if CityPlan.inside_walls(x, z, 6.0):
			continue
		if terrain != null:
			if terrain.is_road_at(x, z) or terrain.is_water_at(x, z):
				continue
			if terrain.river_distance(x, z) < 5.5 or terrain.lake_distance(x, z) < 1.12:
				continue
			if terrain.slope_at(x, z) > 0.56:
				continue
		if Vector2(x - 66.0, z + 18.0).length() < 11.0 or Vector2(x - 58.0, z - 22.0).length() < 10.5:
			continue
		if Vector2(x + 62.0, z + 24.0).length() < 10.0 or Vector2(x + 56.0, z - 44.0).length() < 8.5:
			continue
		if Vector2(x + 14.0, z + 64.0).length() < 9.5 or Vector2(x + 19.0, z + 47.0).length() < 5.5:
			continue
		if Vector2(x + 52.0, z - 34.0).length() < 9.0 or Vector2(x - 55.0, z - CityPlan.BRIDGE_Z).length() < 7.0:
			continue

		var y := terrain.height_at(x, z) if terrain != null else 0.0
		if y > 17.0:
			continue
		var biome := terrain.biome_at(x, z) if terrain != null else "dense_woodland"
		var yaw := rng.randf_range(0.0, TAU)
		var pos := Vector3(x, y - 0.08, z)
		var sp := rng.randf_range(3.5, 4.7)

		match biome:
			"lakeside_birch":
				if birch_xforms.size() < 4:
					birch_xforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * rng.randf_range(1.45, 1.95)), pos))
			"dense_woodland", "ancient_grove":
				oak_xforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * rng.randf_range(3.4, 4.5)), pos))
			_:
				pine_xforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * sp), pos))
		trunk_positions.append(pos)

	# 2. Valley boulders and bushes (outside the walls only).
	for i: int in 80:
		var rx := rng.randf_range(-96.0, 96.0)
		var rz := rng.randf_range(-96.0, 96.0)
		if CityPlan.inside_walls(rx, rz, 4.0):
			continue
		if terrain != null and (terrain.is_road_at(rx, rz) or terrain.is_water_at(rx, rz) or terrain.slope_at(rx, rz) > 0.65):
			continue
		var ry := terrain.height_at(rx, rz) if terrain != null else 0.0
		var yaw := rng.randf_range(0.0, TAU)
		if i < 42:
			var rs := rng.randf_range(0.95, 1.75)
			var rpos := Vector3(rx, ry - 0.08, rz)
			rock_xforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * rs), rpos))
			rock_positions.append(rpos)
		else:
			var bs := rng.randf_range(0.85, 1.30)
			bush_xforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * bs), Vector3(rx, ry - 0.04, rz)))

	# 3. Wind-animated meadow grass (one draw call). It grows on the meadows
	# outside the walls - densest on the south meadow between the south gate
	# and Crystal Lake - and never on a street, a lot or the paved plaza.
	var wind_grass_xforms: Array = []
	var hero_flower_xforms: Array = []
	for i: int in 2000:
		var gx: float
		var gz: float
		if i < 1300:
			gx = rng.randf_range(-34.0, 34.0)
			gz = rng.randf_range(38.0, 66.0)
		else:
			var g_ang := rng.randf() * TAU
			var g_rad := rng.randf_range(39.0, 78.0)
			gx = cos(g_ang) * g_rad
			gz = sin(g_ang) * g_rad
		if CityPlan.inside_walls(gx, gz, 2.6):
			continue
		if terrain != null:
			if terrain.is_water_at(gx, gz) or terrain.slope_at(gx, gz) > 0.52 or terrain.height_at(gx, gz) > 12.5:
				continue
			if terrain.is_road_at(gx, gz):
				continue
		var gy := terrain.height_at(gx, gz) if terrain != null else 0.0
		var gyaw := rng.randf_range(0.0, TAU)
		var gscale := rng.randf_range(0.85, 1.42)
		wind_grass_xforms.append(Transform3D(Basis(Vector3.UP, gyaw).scaled(Vector3(gscale, gscale * rng.randf_range(0.90, 1.28), gscale)), Vector3(gx, gy, gz)))
		if i % 15 == 0 and flower_xforms.size() < 110:
			var fs := rng.randf_range(0.95, 1.45)
			flower_xforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * fs), Vector3(gx, gy - 0.02, gz)))
	# Flower beds inside the town gardens.
	for garden: Array in CityPlan.gardens():
		for i: int in 5:
			var fx := rng.randf_range(float(garden[0]), float(garden[2]))
			var fz := rng.randf_range(float(garden[1]), float(garden[3]))
			if CityPlan.on_lot(fx, fz, 0.8) or CityPlan.is_street(fx, fz):
				continue
			hero_flower_xforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.9, 1.3)), Vector3(fx, -0.02, fz)))

	# Shoreline Reeds around Crystal Lake
	for i: int in 18:
		var ang := float(i) / 18.0 * TAU
		var lx := 16.0 + cos(ang) * 15.6
		var lz := 54.0 + sin(ang) * 12.2
		var ly := terrain.height_at(lx, lz) if terrain != null else -0.3
		reed_xforms.append(Transform3D(Basis(Vector3.UP, ang).scaled(Vector3.ONE * 1.6), Vector3(lx, ly, lz)))

	var stree := AssetLibrary.STYLIZED_TREES_DIR
	var srock := AssetLibrary.STYLIZED_ROCKS_DIR
	var sfol := AssetLibrary.STYLIZED_FOLIAGE_DIR
	var hex_dir := AssetLibrary.HEXAGON_DIR
	build_multimesh(parent, hex_dir + "trees_A_medium.gltf", pine_xforms, "ValleyStylizedPines", false, 88.0)
	build_multimesh(parent, hex_dir + "trees_B_medium.gltf", oak_xforms, "ForestOaks", false, 82.0)
	build_multimesh(parent, stree + "BirchTree_2.glb", birch_xforms, "LakesideBirches", false, 72.0)
	build_multimesh(parent, srock + "Rock_1.glb", rock_xforms, "WorldRocks", false, 64.0)
	build_multimesh(parent, sfol + "Bush_2.glb", bush_xforms, "ForestBushes", false, 44.0)
	build_multimesh(parent, sfol + "Flowers.glb", hero_flower_xforms, "MeadowFlowers", false, 38.0)
	build_multimesh(parent, sfol + "Flower_2.glb", flower_xforms, "ValleyWildflowers", false, 42.0)
	build_multimesh(parent, "res://assets/environments/rivers/lily-large.glb", reed_xforms, "LakeReeds", false, 60.0)

	# Build the 1-draw-call GPU Wind Grass MultiMeshInstance3D!
	if not wind_grass_xforms.is_empty():
		var g_mm := MultiMesh.new()
		g_mm.transform_format = MultiMesh.TRANSFORM_3D
		g_mm.mesh = _make_stylized_grass_tuft_mesh()
		g_mm.instance_count = wind_grass_xforms.size()
		for gi in wind_grass_xforms.size():
			g_mm.set_instance_transform(gi, wind_grass_xforms[gi] as Transform3D)
		var g_inst := MultiMeshInstance3D.new()
		g_inst.name = "MeadowWindGrass"
		g_inst.multimesh = g_mm
		g_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g_inst.visibility_range_end = 42.0
		g_inst.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		parent.add_child(g_inst)

	_add_golden_meadow_motes(parent)

	# Batched StaticBody3D for tree trunks AND large rock boulders within playable elevation
	var trunk_body := StaticBody3D.new()
	trunk_body.name = "ForestTrunkColliders"
	trunk_body.collision_layer = 1
	trunk_body.collision_mask = 0
	var shared_cyl := CylinderShape3D.new()
	shared_cyl.radius = 0.44
	shared_cyl.height = 3.4
	var shared_rock := SphereShape3D.new()
	shared_rock.radius = 0.95
	parent.add_child(trunk_body)
	for tp: Vector3 in trunk_positions:
		if tp.y > 12.0:
			continue
		var cs := CollisionShape3D.new()
		cs.shape = shared_cyl
		cs.position = tp + Vector3(0.0, 1.7, 0.0)
		trunk_body.add_child(cs)
	for rp: Vector3 in rock_positions:
		if rp.y > 12.0:
			continue
		var rcs := CollisionShape3D.new()
		rcs.shape = shared_rock
		rcs.position = rp + Vector3(0.0, 0.7, 0.0)
		trunk_body.add_child(rcs)

	var y_fn := func(px: float, pz: float) -> float:
		return (terrain.height_at(px, pz) + 0.35) if terrain != null else 0.35
	return [
		Vector3(-56.0, y_fn.call(-56.0, -18.0), -18.0),
		Vector3(-64.0, y_fn.call(-64.0, -26.0), -26.0),
		Vector3(-48.0, y_fn.call(-48.0, 16.0), 16.0),
		Vector3(-38.0, y_fn.call(-38.0, -34.0), -34.0),
		Vector3(-68.0, y_fn.call(-68.0, -38.0), -38.0),
	]

# --- 3. Cottage Interior -----------------------------------------------------

static func build_house_interior(parent: Node3D) -> Dictionary:
	var origin := INTERIOR_ORIGIN
	var room := Rect2(-5.0, -4.0, 10.0, 8.0)
	var wall_color := Color(0.68, 0.62, 0.52)
	var floor_color := Color(0.38, 0.27, 0.18)
	var wall_height := 3.2
	var wall_thickness := 0.3
	_solid_box(parent, origin + Vector3(0.0, -0.4, 0.0),
		Vector3(room.size.x, 0.4, room.size.y), floor_color, "HouseFloor")

	var ceiling := MeshInstance3D.new()
	var ceiling_box := BoxMesh.new()
	ceiling_box.size = Vector3(room.size.x, 0.2, room.size.y)
	ceiling.mesh = ceiling_box
	ceiling.material_override = _color_material(Color(0.28, 0.24, 0.20))
	ceiling.position = origin + Vector3(0.0, wall_height, 0.0)
	parent.add_child(ceiling)

	var south_z := room.position.y + room.size.y
	var half_width := room.size.x * 0.5
	var side_piece := half_width - 1.0
	var walls: Array = [
		{"size": Vector3(room.size.x, wall_height, wall_thickness), "pos": Vector3(0.0, 0.0, room.position.y)},
		{"size": Vector3(side_piece, wall_height, wall_thickness), "pos": Vector3(-(1.0 + side_piece * 0.5), 0.0, south_z)},
		{"size": Vector3(side_piece, wall_height, wall_thickness), "pos": Vector3(1.0 + side_piece * 0.5, 0.0, south_z)},
		{"size": Vector3(wall_thickness, wall_height, room.size.y), "pos": Vector3(room.position.x, 0.0, 0.0)},
		{"size": Vector3(wall_thickness, wall_height, room.size.y), "pos": Vector3(room.position.x + room.size.x, 0.0, 0.0)},
	]
	for wall: Dictionary in walls:
		_solid_box(parent, origin + (wall["pos"] as Vector3), wall["size"] as Vector3, wall_color, "HouseWall")

	var fur := AssetLibrary.FURNITURE_DIR
	place_model(parent, fur + "bed_single_A.gltf", origin + Vector3(-3.6, 0.0, -2.6), 0.0, 1.0)
	place_model(parent, fur + "table_small.gltf", origin + Vector3(1.2, 0.0, -2.4), 0.0, 1.0, Vector3(1.0, 0.9, 1.0), "HouseTable")
	place_model(parent, fur + "chair_A_wood.gltf", origin + Vector3(2.3, 0.0, -2.4), -PI * 0.5, 1.0)
	place_model(parent, fur + "chair_stool_wood.gltf", origin + Vector3(0.2, 0.0, -2.2), PI, 1.0)
	place_model(parent, fur + "rug_rectangle_A.gltf", origin + Vector3(0.0, 0.02, 0.4), 0.0, 1.8)
	place_model(parent, fur + "cabinet_small.gltf", origin + Vector3(3.8, 0.0, 1.6), -PI * 0.5, 1.0)
	place_model(parent, fur + "shelf_A_small.gltf", origin + Vector3(-4.4, 0.0, 1.8), PI * 0.5, 1.0)
	place_model(parent, fur + "book_set.gltf", origin + Vector3(1.2, 0.62, -2.4), 0.0, 1.0)
	place_model(parent, fur + "lamp_table.gltf", origin + Vector3(-1.4, 0.0, -2.4), 0.0, 1.0)

	_add_omni_light(parent, origin + Vector3(0.0, 2.6, 0.0), Color(1.0, 0.82, 0.58), 1.5, 10.0)
	return {
		"spawn": origin + Vector3(0.0, 0.6, 2.2),
		"exit": origin + Vector3(0.0, 0.0, 4.4),
		"origin": origin,
	}

# --- 4. Grand Adventurers Guild Hall Interior (Section 13) -------------------

static func build_guild_interior(parent: Node3D) -> Dictionary:
	var origin := GUILD_ORIGIN
	var w := 20.0
	var d := 24.0
	var h := 5.6
	var thick := 0.45

	# Polished Stone Hall Floor + Royal Blue & Gold Carpet Runner + Timber Ceiling
	_solid_box(parent, origin + Vector3(0.0, -0.4, 0.0), Vector3(w, 0.4, d), Color(0.36, 0.35, 0.38), "GuildFloor")
	var carpet := MeshInstance3D.new()
	var cbox := BoxMesh.new()
	cbox.size = Vector3(3.2, 0.03, 18.0)
	carpet.mesh = cbox
	carpet.position = origin + Vector3(0.0, 0.015, 1.0)
	carpet.material_override = _color_material(Color(0.18, 0.34, 0.64))
	parent.add_child(carpet)

	var ceiling := MeshInstance3D.new()
	var ceil_box := BoxMesh.new()
	ceil_box.size = Vector3(w, 0.3, d)
	ceiling.mesh = ceil_box
	ceiling.position = origin + Vector3(0.0, h, 0.0)
	ceiling.material_override = _color_material(Color(0.24, 0.18, 0.13))
	parent.add_child(ceiling)

	# Perimeter Stone Walls with South Entrance Archway
	var half_w := w * 0.5
	var half_d := d * 0.5
	var door_side := half_w - 1.5
	var guild_walls := [
		{"size": Vector3(w, h, thick), "pos": Vector3(0.0, 0.0, -half_d)},
		{"size": Vector3(door_side, h, thick), "pos": Vector3(-(1.5 + door_side * 0.5), 0.0, half_d)},
		{"size": Vector3(door_side, h, thick), "pos": Vector3(1.5 + door_side * 0.5, 0.0, half_d)},
		{"size": Vector3(thick, h, d), "pos": Vector3(-half_w, 0.0, 0.0)},
		{"size": Vector3(thick, h, d), "pos": Vector3(half_w, 0.0, 0.0)},
	]
	for gw: Dictionary in guild_walls:
		_solid_box(parent, origin + (gw["pos"] as Vector3), gw["size"] as Vector3, Color(0.56, 0.53, 0.48), "GuildWall")

	# Stone Pillars & Royal Banners
	for pz: float in [-7.5, -1.5, 4.5]:
		for px: float in [-6.8, 6.8]:
			place_model(parent, AssetLibrary.DUNGEON_DIR + "pillar.glb", origin + Vector3(px, 0.0, pz), 0.0, 1.35,
				Vector3(0.9, 5.2, 0.9), "GuildPillar")
			place_model(parent, "res://assets/environments/dungeons/banner_blue.glb", origin + Vector3(px * 0.92, 2.2, pz),
				PI * 0.5 if px < 0 else -PI * 0.5, 1.2)

	# 1) Reception Counter (West-Center)
	_solid_box(parent, origin + Vector3(-5.2, 0.0, 1.5), Vector3(3.8, 1.05, 1.1), Color(0.38, 0.25, 0.15), "ReceptionDesk")

	# 2) Interactive Guild Quest Board (East-Center)
	var board := QuestBoardProp.new()
	board.name = "GuildHallQuestBoard"
	board.setup("Inspect Official Guild Contracts")
	parent.add_child(board)
	board.global_position = origin + Vector3(4.8, 0.0, 2.0)
	board.rotation.y = -0.35

	# 3) Guild Master's Raised Dais & Command Desk (North End)
	_solid_box(parent, origin + Vector3(0.0, 0.0, -8.8), Vector3(7.6, 0.35, 4.2), Color(0.44, 0.41, 0.38), "MasterDais")
	place_model(parent, AssetLibrary.FURNITURE_DIR + "table_small.gltf", origin + Vector3(0.0, 0.35, -8.8), 0.0, 1.6,
		Vector3(1.8, 1.0, 1.2), "MasterDesk")
	place_model(parent, "res://assets/environments/dungeons/banner_blue.glb", origin + Vector3(0.0, 2.8, -11.6), 0.0, 1.8)

	# 4) Quartermaster Armory Corner (Northwest) & Training Area (Southeast)
	place_model(parent, AssetLibrary.HEXAGON_DIR + "weaponrack.gltf", origin + Vector3(-7.6, 0.0, -5.5), PI * 0.5, 3.6)
	place_model(parent, AssetLibrary.HEXAGON_DIR + "target.gltf", origin + Vector3(7.4, 0.0, 7.2), -PI * 0.5, 3.6)
	place_model(parent, AssetLibrary.FURNITURE_DIR + "table_small.gltf", origin + Vector3(-5.5, 0.0, 7.2), 0.0, 1.4)
	place_model(parent, AssetLibrary.FURNITURE_DIR + "chair_A_wood.gltf", origin + Vector3(-4.2, 0.0, 7.2), -PI * 0.5, 1.1)

	# Warm Chandelier Illumination
	_add_omni_light(parent, origin + Vector3(0.0, 4.4, 4.0), Color(1.0, 0.85, 0.62), 1.5, 16.0)
	_add_omni_light(parent, origin + Vector3(0.0, 4.4, -6.5), Color(1.0, 0.85, 0.62), 1.6, 16.0)

	return {
		"origin": origin,
		"spawn": origin + Vector3(0.0, 0.6, 8.8),
		"exit": origin + Vector3(0.0, 0.0, 11.4),
		"receptionist_pos": origin + Vector3(-5.2, 0.0, 0.2),
		"master_pos": origin + Vector3(0.0, 0.35, -9.8),
		"quartermaster_pos": origin + Vector3(-6.2, 0.0, -4.8),
		"trainer_pos": origin + Vector3(5.8, 0.0, 6.8),
		"veteran_pos": origin + Vector3(3.2, 0.0, -1.2),
		"recruit_pos": origin + Vector3(-3.2, 0.0, 6.8),
	}

# --- 5. Modular Sunken Crypt Dungeon (Traps, Secret Room & Boss Sanctum) -----

static func build_dungeon(parent: Node3D) -> Dictionary:
	var origin := DUNGEON_ORIGIN
	build_ground(parent, 96.0, origin, Color(0.16, 0.16, 0.18))
	var floor_transforms: Array = []
	var wall_transforms: Array = []
	var rooms: Array = [
		# Entry Antechamber
		{"rect": Rect2(0.0, 0.0, 8.0, 8.0), "doors": ["south"]},
		# Trap Gauntlet Corridor
		{"rect": Rect2(2.0, 8.0, 4.0, 8.0), "doors": ["north", "south"]},
		# Crypt Guard Hall (with East Secret Alcove!)
		{"rect": Rect2(0.0, 16.0, 8.0, 8.0), "doors": ["north", "south", "east"]},
		# Hidden Secret Treasure Alcove (East)
		{"rect": Rect2(8.0, 16.0, 8.0, 8.0), "doors": ["west"]},
		# Boss Approach Bridge
		{"rect": Rect2(2.0, 24.0, 4.0, 4.0), "doors": ["north", "south"]},
		# Malakor's Dread Sanctum (16m x 12m Boss Arena!)
		{"rect": Rect2(-4.0, 28.0, 16.0, 12.0), "doors": ["north"]},
	]
	for room: Dictionary in rooms:
		_add_dungeon_room(room["rect"] as Rect2, room["doors"] as Array, floor_transforms, wall_transforms)
	for i: int in floor_transforms.size():
		floor_transforms[i] = _offset_transform(floor_transforms[i], origin)
	for i: int in wall_transforms.size():
		wall_transforms[i] = _offset_transform(wall_transforms[i], origin)

	build_multimesh(parent, AssetLibrary.DUNGEON_DIR + "floor_tile_large.glb", floor_transforms, "DungeonFloors", false)
	build_multimesh(parent, AssetLibrary.DUNGEON_DIR + "wall.glb", wall_transforms, "DungeonWalls", false)
	_add_dungeon_colliders(parent, wall_transforms)
	_solid_box(parent, origin + Vector3(6.0, 4.35, 20.0), Vector3(28.0, 0.35, 44.0), Color(0.11, 0.12, 0.15), "DungeonCeiling")

	# Columns, Banners & Torches (MultiMesh batched for <300 total draw calls!)
	var pillar_xforms: Array = []
	for p_off: Vector3 in [Vector3(1.0, 0.0, 1.0), Vector3(7.0, 0.0, 1.0), Vector3(-2.5, 0.0, 30.0), Vector3(10.5, 0.0, 30.0), Vector3(-2.5, 0.0, 38.0), Vector3(10.5, 0.0, 38.0)]:
		pillar_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 1.1), origin + p_off))
	build_multimesh(parent, AssetLibrary.DUNGEON_DIR + "pillar.glb", pillar_xforms, "DungeonPillars", false)
	place_model(parent, "res://assets/environments/dungeons/banner_red.glb", origin + Vector3(0.5, 2.2, 39.6), PI, 1.4)
	place_model(parent, "res://assets/environments/dungeons/banner_red.glb", origin + Vector3(7.5, 2.2, 39.6), PI, 1.4)

	var torch_xforms: Array = []
	for torch_pos: Vector3 in [Vector3(0.4, 2.0, 2.0), Vector3(5.6, 2.0, 12.0), Vector3(0.4, 2.0, 20.0), Vector3(14.5, 2.0, 20.0), Vector3(-3.4, 2.0, 34.0), Vector3(11.4, 2.0, 34.0)]:
		torch_xforms.append(Transform3D(Basis.IDENTITY, origin + torch_pos))
	build_multimesh(parent, AssetLibrary.DUNGEON_DIR + "torch_lit.glb", torch_xforms, "DungeonTorches", false)

	# Real Timed Spike Traps in the Gauntlet & Guard Hall!
	var trap_offsets := [Vector3(4.0, 0.0, 11.0), Vector3(4.0, 0.0, 14.0), Vector3(4.0, 0.0, 20.0)]
	for ti: int in trap_offsets.size():
		var trap := DungeonTrap.new()
		trap.name = "CryptSpikeTrap_%d" % ti
		trap.phase_offset = float(ti) * 1.15
		parent.add_child(trap)
		trap.global_position = origin + trap_offsets[ti]

	_add_omni_light(parent, origin + Vector3(4.0, 3.2, 4.0), Color(1.0, 0.72, 0.45), 1.4, 13.0)
	_add_omni_light(parent, origin + Vector3(4.0, 3.2, 20.0), Color(1.0, 0.68, 0.42), 1.4, 14.0)
	_add_omni_light(parent, origin + Vector3(12.0, 3.0, 20.0), Color(0.55, 0.82, 1.0), 1.2, 11.0)
	_add_omni_light(parent, origin + Vector3(4.0, 3.8, 34.0), Color(0.92, 0.42, 0.55), 1.65, 18.0)

	return {
		"spawn": origin + Vector3(4.0, 0.6, 2.5),
		"exit": origin + Vector3(4.0, 0.0, 1.0),
		"chest": origin + Vector3(4.0, 0.0, 38.2),
		"secret_chest": origin + Vector3(13.5, 0.0, 20.0),
		"trap": origin + Vector3(4.0, 0.0, 20.0),
		"boss_spawn": origin + Vector3(4.0, 0.4, 34.0),
		"enemy_spawns": [
			origin + Vector3(3.2, 0.4, 18.5),
			origin + Vector3(5.4, 0.4, 22.0),
		],
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
	var segments_x := int(rect.size.x / DUNGEON_TILE)
	var segments_z := int(rect.size.y / DUNGEON_TILE)
	for i: int in segments_x:
		var cx := rect.position.x + half_tile + float(i) * DUNGEON_TILE
		if not (doors.has("north") and i == int(segments_x / 2)):
			wall_transforms.append(Transform3D(Basis.IDENTITY, Vector3(cx, 0.0, rect.position.y)))
		if not (doors.has("south") and i == int(segments_x / 2)):
			wall_transforms.append(Transform3D(Basis.IDENTITY, Vector3(cx, 0.0, rect.position.y + rect.size.y)))
	for i: int in segments_z:
		var cz := rect.position.y + half_tile + float(i) * DUNGEON_TILE
		var door_middle := i == int(segments_z / 2)
		if not (doors.has("west") and door_middle):
			wall_transforms.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(rect.position.x, 0.0, cz)))
		if not (doors.has("east") and door_middle):
			wall_transforms.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(rect.position.x + rect.size.x, 0.0, cz)))

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
	mat.roughness = 0.88
	return mat
