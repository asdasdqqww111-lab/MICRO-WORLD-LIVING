class_name WorldBuilder
extends RefCounted
## Procedural & curated assembly of the 240x240m Eldoria Starting Region:
##   - Eldoria Village (Square, Guild Castle Hall, Tavern, Chapel, Market,
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
	var node := AssetLibrary.instantiate(path, model_scale)
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
	var lod_dist := 78.0 if is_hero else 40.0
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

static func build_village(parent: Node3D, terrain: Terrain = null) -> Dictionary:
	var hex := AssetLibrary.HEXAGON_DIR
	var vdir := AssetLibrary.HEXAGON_DIR
	var vprop := AssetLibrary.HEXAGON_DIR
	var rbuild := AssetLibrary.REALISTIC_BUILDINGS_DIR
	var rnat := AssetLibrary.REALISTIC_NATURE_DIR
	var nprop := "res://assets/environments/villages/"
	var b := AssetLibrary.SCALE_BUILDING

	# Major Royal City Districts (Upgraded to Realistic Medieval PBR Architecture):
	var buildings: Array = [
		# Grand Adventurers Guild Hall (North Plaza Anchor — door preserved at (0, 0, -18.4))
		{"path": rbuild + "guild_grand_hall.glb", "fallback": vdir + "building_castle_blue.gltf",
			"pos": Vector3(0.0, 0.0, -24.5), "rot": PI, "scale": 6.4,
			"collider": Vector3(13.5, 12.0, 11.5), "name": "AdventurersGuildExterior"},
		# Royal Sovereign Citadel Keep (Northwest Crown Anchor!)
		{"path": rbuild + "citadel_keep.glb", "fallback": hex + "building_castle_red.gltf",
			"pos": Vector3(-27.5, 0.0, -24.0), "rot": deg_to_rad(140.0), "scale": 5.6,
			"collider": Vector3(12.2, 12.0, 11.0), "name": "RoyalCitadelKeep"},
		# Royal Belfry Clocktower (Flanking Guild Plaza)
		{"path": rbuild + "bell_tower.glb", "fallback": hex + "building_tower_B_blue.gltf",
			"pos": Vector3(9.4, 0.0, -26.5), "rot": deg_to_rad(-165.0), "scale": 2.75,
			"collider": Vector3(5.6, 15.0, 5.6), "name": "RoyalClocktower"},
		# Hearthstone Tavern & Inn (Northwest Boulevard)
		{"path": rbuild + "inn.glb", "fallback": vdir + "building_tavern_yellow.gltf",
			"pos": Vector3(-15.5, 0.0, -20.5), "rot": deg_to_rad(155.0), "scale": 2.35,
			"collider": Vector3(9.4, 10.5, 10.2), "name": "Tavern"},
		# Sanctuary Cathedral (Northeast)
		{"path": rbuild + "cathedral_temple.glb", "fallback": hex + "building_church_blue.gltf",
			"pos": Vector3(16.5, 0.0, -19.5), "rot": deg_to_rad(-148.0), "scale": 3.05,
			"collider": Vector3(9.0, 12.0, 10.4), "name": "Chapel"},
		# Royal Alchemist & Arcane Conservatory (East-Northeast)
		{"path": rbuild + "house_2.glb", "fallback": hex + "building_castle_green.gltf",
			"pos": Vector3(28.5, 0.0, -15.5), "rot": deg_to_rad(-120.0), "scale": 2.45,
			"collider": Vector3(9.6, 10.0, 9.2), "name": "ArcaneConservatory"},
		# Player's Cottage (Preserved at (-16, 0, -8) with door at (-16, 0, -2.4))
		{"path": rbuild + "house_1.glb", "fallback": hex + "building_home_A_green.gltf",
			"pos": Vector3(-16.0, 0.0, -8.0), "rot": 0.0, "scale": 2.45,
			"collider": Vector3(7.2, 7.9, 7.6), "name": "HouseA"},
		# Noble Townhouse East
		{"path": rbuild + "house_2.glb", "fallback": hex + "building_home_B_green.gltf",
			"pos": Vector3(17.8, 0.0, -7.5), "rot": deg_to_rad(-35.0), "scale": 2.35,
			"collider": Vector3(7.0, 7.1, 7.6), "name": "HouseB"},
		# Noble Townhouse West
		{"path": rbuild + "house_3.glb", "fallback": hex + "building_home_A_green.gltf",
			"pos": Vector3(-25.5, 0.0, -4.2), "rot": deg_to_rad(75.0), "scale": 2.95,
			"collider": Vector3(6.8, 6.9, 7.4), "name": "HouseC"},
		# Ironforge Royal Blacksmith & Smelter (Southwest)
		{"path": rbuild + "blacksmith.glb", "fallback": hex + "building_blacksmith_red.gltf",
			"pos": Vector3(-19.0, 0.0, 11.0), "rot": deg_to_rad(-18.0), "scale": 2.55,
			"collider": Vector3(11.5, 8.4, 11.0), "name": "Blacksmith"},
		# Royal Bakery & Red Lion Feast Hall (West-Southwest)
		{"path": rbuild + "inn.glb", "fallback": hex + "building_tavern_red.gltf",
			"pos": Vector3(-28.5, 0.0, 11.5), "rot": deg_to_rad(52.0), "scale": 2.20,
			"collider": Vector3(8.8, 9.6, 9.2), "name": "RoyalBakeryHall"},
		# Grand Spice & Silk Bazaar (Southeast)
		{"path": rbuild + "stable.glb", "fallback": hex + "building_market_red.gltf",
			"pos": Vector3(12.5, 0.0, 9.5), "rot": deg_to_rad(14.0), "scale": 2.30,
			"collider": Vector3(12.8, 7.2, 9.6), "name": "Market"},
		# Royal Jeweler & East Trade Exchange (East Boulevard)
		{"path": rbuild + "gazebo.glb", "fallback": hex + "building_market_blue.gltf",
			"pos": Vector3(24.5, 0.0, 2.5), "rot": deg_to_rad(-78.0), "scale": 4.6,
			"collider": Vector3(10.5, 7.0, 8.8), "name": "EastTradeBazaar"},
		# Royal Guard Barracks & Archery Garrison (South-Southeast)
		{"path": rbuild + "barracks_fort.glb", "fallback": hex + "building_barracks_blue.gltf",
			"pos": Vector3(24.5, 0.0, 15.0), "rot": deg_to_rad(-65.0), "scale": 4.7,
			"collider": Vector3(8.5, 8.2, 8.5), "name": "Barracks"},
		{"path": rbuild + "barracks_fort.glb", "fallback": hex + "building_archeryrange_blue.gltf",
			"pos": Vector3(16.0, 0.0, 25.0), "rot": deg_to_rad(160.0), "scale": 4.4,
			"collider": Vector3(8.6, 6.8, 8.4), "name": "ArcheryGarrison"},
		# Farming District Windmill & Lumber/Grain Hall (South-Southwest)
		{"path": rbuild + "mill.glb", "fallback": vdir + "building_windmill_yellow.gltf",
			"pos": Vector3(-13.5, 0.0, 23.5), "rot": deg_to_rad(25.0), "scale": 2.40,
			"collider": Vector3(7.4, 12.5, 7.4), "name": "Windmill"},
		{"path": rbuild + "sawmill.glb", "fallback": hex + "building_lumbermill_green.gltf",
			"pos": Vector3(-24.5, 0.0, 22.5), "rot": deg_to_rad(38.0), "scale": 2.05,
			"collider": Vector3(8.2, 7.5, 8.0), "name": "CityGranary"},
	]
	for entry: Dictionary in buildings:
		var chosen := String(entry["path"]) if AssetLibrary.has_model(String(entry["path"])) else String(entry["fallback"])
		place_model(parent, chosen, entry["pos"] as Vector3, float(entry["rot"]),
			float(entry["scale"]), entry["collider"] as Vector3, String(entry["name"]))

	# Realistic Medieval Market Stalls around Bazaar Plaza
	place_model(parent, rbuild + "market_stand_1.glb", Vector3(8.8, 0.0, 6.8), deg_to_rad(-25.0), 2.4, Vector3.ZERO, "MarketStallA")
	place_model(parent, rbuild + "market_stand_2.glb", Vector3(16.2, 0.0, 5.8), deg_to_rad(-115.0), 2.4, Vector3.ZERO, "MarketStallB")

	# Batched MultiMesh Residential Townhouses & Noble Manors (16 extra city buildings in ONLY 2 Draw Calls!)
	var townhouse_spots := [
		{"pos": Vector3(-31.5, 0.0, -12.0), "rot": 68.0, "s": 2.30},
		{"pos": Vector3(-31.5, 0.0, 20.0), "rot": 45.0, "s": 2.25},
		{"pos": Vector3(-8.5, 0.0, 30.5), "rot": 172.0, "s": 2.30},
		{"pos": Vector3(8.5, 0.0, 30.5), "rot": -172.0, "s": 2.30},
		{"pos": Vector3(30.5, 0.0, -24.5), "rot": -135.0, "s": 2.25},
		{"pos": Vector3(-19.0, 0.0, -30.5), "rot": 165.0, "s": 2.25},
	]
	var th_xforms: Array = []
	for ts: Dictionary in townhouse_spots:
		var tp := ts["pos"] as Vector3
		var tr := deg_to_rad(float(ts["rot"]))
		var sc := float(ts["s"])
		th_xforms.append(Transform3D(Basis(Vector3.UP, tr).scaled(Vector3.ONE * sc), tp))
		add_box_body(parent, tp, Vector3(6.4, 6.8, 6.8), "TownhouseCol")
	build_multimesh(parent, rbuild + "house_1.glb", th_xforms, "CityTownhouses", true, 88.0)

	var manor_spots := [
		{"pos": Vector3(-8.2, 0.0, -28.0), "rot": 180.0},
		{"pos": Vector3(23.5, 0.0, -27.0), "rot": -150.0},
		{"pos": Vector3(31.0, 0.0, 9.5), "rot": -85.0},
		{"pos": Vector3(27.5, 0.0, 24.0), "rot": -125.0},
		{"pos": Vector3(-29.5, 0.0, -1.0), "rot": 90.0},
	]
	var manor_xforms: Array = []
	for ms: Dictionary in manor_spots:
		var mp := ms["pos"] as Vector3
		var mr := deg_to_rad(float(ms["rot"]))
		manor_xforms.append(Transform3D(Basis(Vector3.UP, mr).scaled(Vector3.ONE * 2.30), mp))
		add_box_body(parent, mp, Vector3(6.6, 7.6, 6.6), "ManorCol")
	build_multimesh(parent, rbuild + "house_2.glb", manor_xforms, "CityNobleManors", true, 90.0)

	# Fortified Royal City Perimeter Stone Ramparts (r = 37.2m) + 4 Monumental Cardinal Gatehouses + 8 Bastion Watchtowers!
	var gate_defs := [
		{"pos": Vector3(0.0, 0.0, 36.8), "rot": 0.0, "name": "SouthGateArch"},
		{"pos": Vector3(0.0, 0.0, -36.8), "rot": PI, "name": "NorthGateArch"},
		{"pos": Vector3(36.8, 0.0, -4.0), "rot": deg_to_rad(90.0), "name": "EastGateArch"},
		{"pos": Vector3(-36.8, 0.0, 2.0), "rot": deg_to_rad(-90.0), "name": "WestGateArch"},
	]
	for gd: Dictionary in gate_defs:
		if AssetLibrary.has_model(rbuild + "city_gate.glb"):
			place_model(parent, rbuild + "city_gate.glb", gd["pos"] as Vector3, float(gd["rot"]), 5.2,
				Vector3.ZERO, String(gd["name"]))
		elif AssetLibrary.has_model(vprop + "wall_straight_gate.gltf"):
			place_model(parent, vprop + "wall_straight_gate.gltf", gd["pos"] as Vector3, float(gd["rot"]), 5.6,
				Vector3.ZERO, String(gd["name"]))
		if AssetLibrary.has_model("res://assets/environments/medieval_megakit/Wall_Arch.gltf"):
			place_model(parent, "res://assets/environments/medieval_megakit/Wall_Arch.gltf",
				(gd["pos"] as Vector3), float(gd["rot"]), 1.35)

	var wall_xforms: Array = []
	var tower_xforms: Array = []
	var wall_r := 37.2
	var seg_count := 32
	for i: int in seg_count:
		var ang := (float(i) / float(seg_count)) * TAU
		var wx := cos(ang) * wall_r
		var wz := sin(ang) * wall_r
		var wpos := Vector3(wx, 0.0, wz)
		var near_gate := false
		for gd: Dictionary in gate_defs:
			if wpos.distance_to(gd["pos"] as Vector3) < 6.4:
				near_gate = true
				break
		if near_gate:
			continue
		var tangent_yaw := -ang + PI * 0.5
		wall_xforms.append(Transform3D(Basis(Vector3.UP, tangent_yaw).scaled(Vector3(3.8, 11.2, 8.8)), wpos))
		add_box_body(parent, wpos, Vector3(4.2, 4.8, 4.2), "CityRampartCol_%d" % i)
		if i % 4 == 2:
			tower_xforms.append(Transform3D(Basis(Vector3.UP, tangent_yaw).scaled(Vector3(3.3, 11.8, 9.2)), wpos))
	build_multimesh(parent, rbuild + "city_wall.glb", wall_xforms, "CityStoneRamparts", true, 110.0)
	build_multimesh(parent, rbuild + "city_tower.glb", tower_xforms, "CityBastionTowers", true, 115.0)

	# Quaternius PBR Brick Plazas & Ornamental Wagons!
	if AssetLibrary.has_model("res://assets/environments/medieval_megakit/Floor_UnevenBrick.gltf"):
		var brick_xforms: Array = []
		for bx: int in range(-2, 3):
			for bz: int in range(-2, 3):
				brick_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.9, 1.0, 1.9)), Vector3(float(bx) * 3.6, 0.015, 2.0 + float(bz) * 3.6)))
		build_multimesh(parent, "res://assets/environments/medieval_megakit/Floor_UnevenBrick.gltf", brick_xforms, "RoyalPlazaBricks", false, 58.0)

	if AssetLibrary.has_model("res://assets/environments/medieval_megakit/Prop_Wagon.gltf"):
		place_model(parent, "res://assets/environments/medieval_megakit/Prop_Wagon.gltf",
			Vector3(17.5, 0.0, 6.2), deg_to_rad(32.0), 1.05, Vector3(2.2, 1.8, 3.4), "BazaarWagonA")
		place_model(parent, "res://assets/environments/medieval_megakit/Prop_Wagon.gltf",
			Vector3(-9.5, 0.0, 15.0), deg_to_rad(-48.0), 1.05, Vector3(2.2, 1.8, 3.4), "SmithyWagonB")

	if AssetLibrary.has_model("res://assets/environments/crypt_bits/arch_gate.gltf"):
		place_model(parent, "res://assets/environments/crypt_bits/arch_gate.gltf",
			Vector3(13.2, 0.0, -12.8), deg_to_rad(-32.0), 1.15, Vector3.ZERO, "CathedralIronArch")

	# Central Royal Square: Realistic Textured Sculpted Stone Fountain + Well + Benches + Obelisk
	var fountain_path := rnat + "royal_fountain.glb"
	if AssetLibrary.has_model(fountain_path):
		place_model(parent, fountain_path, Vector3(0.0, 0.0, 2.0), 0.0, 0.62,
			Vector3(3.8, 1.9, 3.8), "CentralWell")
	else:
		place_model(parent, rbuild + "well.glb", Vector3(0.0, 0.0, 2.0), 0.0, 1.8,
			Vector3(1.8, 2.1, 1.8), "CentralWell")
	if AssetLibrary.has_model("res://assets/environments/tinytreats_house/bench_A.gltf"):
		place_model(parent, "res://assets/environments/tinytreats_house/bench_A.gltf",
			Vector3(-4.6, 0.0, 2.0), deg_to_rad(90.0), 0.98, Vector3(0.9, 1.0, 1.8), "PlazaBenchW")
		place_model(parent, "res://assets/environments/tinytreats_house/bench_A.gltf",
			Vector3(4.6, 0.0, 2.0), deg_to_rad(-90.0), 0.98, Vector3(0.9, 1.0, 1.8), "PlazaBenchE")
	place_model(parent, "res://assets/environments/dungeons/statue-obelisk.glb", Vector3(0.0, 0.0, -6.2), 0.0, 2.5,
		Vector3(1.2, 3.2, 1.2), "PlazaObelisk")

	# Outer Valley Anti-Out-of-Bounds Physics Perimeter Colliders (±116m)
	add_box_body(parent, Vector3(0.0, -4.0, -116.0), Vector3(240.0, 38.0, 2.0), "NorthValleyWall")
	add_box_body(parent, Vector3(0.0, -4.0, 116.0), Vector3(240.0, 38.0, 2.0), "SouthValleyWall")
	add_box_body(parent, Vector3(-116.0, -4.0, 0.0), Vector3(2.0, 38.0, 240.0), "WestValleyWall")
	add_box_body(parent, Vector3(116.0, -4.0, 0.0), Vector3(2.0, 38.0, 240.0), "EastValleyWall")

	# Royal City Evening Street Lanterns (16 posts batched in 1 MultiMesh + warm dusk lights!)
	var lantern_spots := [
		Vector3(-4.8, 0.0, -14.5), Vector3(4.8, 0.0, -14.5),
		Vector3(-5.6, 0.0, 2.0), Vector3(5.6, 0.0, 2.0),
		Vector3(-3.8, 0.0, 33.5), Vector3(3.8, 0.0, 33.5),
		Vector3(-3.8, 0.0, -33.5), Vector3(3.8, 0.0, -33.5),
		Vector3(33.2, 0.0, -7.2), Vector3(33.2, 0.0, -0.8),
		Vector3(-33.2, 0.0, -1.2), Vector3(-33.2, 0.0, 5.2),
		Vector3(-14.5, 0.0, 7.5), Vector3(10.5, 0.0, 6.5),
		Vector3(-22.0, 0.0, -16.5), Vector3(21.5, 0.0, -12.5),
	]
	var lantern_xforms: Array = []
	for lp: Vector3 in lantern_spots:
		lantern_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.80), lp))
	if AssetLibrary.has_model("res://assets/environments/tinytreats_park/street_lantern.gltf"):
		build_multimesh(parent, "res://assets/environments/tinytreats_park/street_lantern.gltf", lantern_xforms, "CityStreetLanternPosts", false, 68.0)
	for i: int in lantern_spots.size():
		if i < 6:
			_build_street_lantern_light_only(parent, lantern_spots[i])

	# Heraldic Royal Banners along Gates, Citadel & Guild Keep (1 MultiMesh!)
	var flag_xforms: Array = []
	for fp: Vector3 in [
		Vector3(-4.2, 0.0, -18.2), Vector3(4.2, 0.0, -18.2),
		Vector3(-23.0, 0.0, -19.0), Vector3(-31.0, 0.0, -19.0),
		Vector3(-4.4, 0.0, 35.5), Vector3(4.4, 0.0, 35.5),
		Vector3(-4.4, 0.0, -35.5), Vector3(4.4, 0.0, -35.5),
		Vector3(35.5, 0.0, -7.8), Vector3(35.5, 0.0, -0.2),
	]:
		flag_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * (AssetLibrary.SCALE_PROP * 1.18)), fp))
	build_multimesh(parent, vprop + "flag_blue.gltf", flag_xforms, "CityRoyalBanners", false, 68.0)

	# Village Props & Farm Crop Rows
	var prop_scale := AssetLibrary.SCALE_PROP
	var props: Array = [
		{"model": hex + "barrel.gltf", "pos": Vector3(-15.0, 0.0, 6.5), "s": prop_scale},
		{"model": hex + "barrel.gltf", "pos": Vector3(-14.0, 0.0, 5.4), "s": prop_scale},
		{"model": hex + "crate_A_big.gltf", "pos": Vector3(-12.6, 0.0, 7.2), "s": prop_scale},
		{"model": hex + "crate_A_small.gltf", "pos": Vector3(11.6, 0.0, 5.2), "s": prop_scale},
		{"model": hex + "sack.gltf", "pos": Vector3(12.4, 0.0, 6.0), "s": prop_scale},
		{"model": hex + "weaponrack.gltf", "pos": Vector3(-17.4, 0.0, 6.2), "s": prop_scale},
		{"model": hex + "target.gltf", "pos": Vector3(26.0, 0.0, 10.0), "s": prop_scale},
		{"model": hex + "tent.gltf", "pos": Vector3(6.5, 0.0, 15.0), "s": prop_scale},
		{"model": hex + "wheelbarrow.gltf", "pos": Vector3(-16.0, 0.0, 17.5), "s": prop_scale},
		{"model": nprop + "sign.glb", "pos": Vector3(3.2, 0.0, 5.5), "s": 2.2},
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 901
	for prop: Dictionary in props:
		if AssetLibrary.has_model(String(prop["model"])):
			place_model(parent, String(prop["model"]), prop["pos"] as Vector3, rng.randf_range(0.0, TAU), float(prop["s"]))

	# Farming District Wheat & Pumpkin Rows beside Granary Mill (batched MultiMesh)
	var wheat_xforms: Array = []
	var pumpkin_xforms: Array = []
	for rx: int in 4:
		for rz: int in 4:
			var fx := -20.5 + float(rx) * 1.65
			var fz := 16.2 + float(rz) * 1.55
			wheat_xforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * 2.55), Vector3(fx, 0.0, fz)))
	for px: int in 4:
		pumpkin_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 2.0), Vector3(-20.0 + float(px) * 1.5, 0.0, 23.2)))
	build_multimesh(parent, "res://assets/environments/villages/crops-wheatstagea.glb", wheat_xforms, "FarmWheat", false, 42.0)
	build_multimesh(parent, "res://assets/environments/villages/crop-pumpkin.glb", pumpkin_xforms, "FarmPumpkins", false, 42.0)

	# Interactive World Stations in Village: Quest Board, Blacksmith Forge, Alchemy Table
	var ext_board := QuestBoardProp.new()
	ext_board.name = "VillageQuestBoard"
	ext_board.setup("Inspect Adventurers Guild Quest Board")
	parent.add_child(ext_board)
	ext_board.global_position = Vector3(5.6, 0.0, -17.2)

	var forge := CraftingStation.new()
	forge.name = "BlacksmithForge"
	forge.setup("forge", "Blacksmith Anvil Forge")
	parent.add_child(forge)
	forge.global_position = Vector3(-13.8, 0.0, 10.2)

	var alchemy := CraftingStation.new()
	alchemy.name = "ChapelAlchemyBench"
	alchemy.setup("alchemy", "Alchemist's Workbench")
	parent.add_child(alchemy)
	alchemy.global_position = Vector3(13.2, 0.0, -14.0)

	# River, Crystal Lake, East Stone Bridge, Waterfall, Ruins, Cave, Camp, Sacred Grove & Dungeon Entrance!
	var outer := _build_water_and_outer_landmarks(parent, terrain)

	return {
		"spawn": Vector3(0.0, 0.6, 14.0),
		"plaza": Vector3(0.0, 0.0, 2.0),
		"guild_door": Vector3(0.0, 0.0, -18.4),
		"house_door": Vector3(-16.0, 0.0, -2.4),
		"dungeon_entrance": outer["dungeon_entrance"],
		"dungeon_stairs": outer["dungeon_stairs"],
		"ruins": outer["ruins"],
		"cave": outer["cave"],
		"monster_camp": outer["monster_camp"],
		"sacred_grove": outer["sacred_grove"],
		"bridge": outer["bridge"],
		"lake": Vector3(16.0, 0.0, 54.0),
		"raid_spawn": Vector3(0.0, 0.5, 41.0),
		"blacksmith_pos": Vector3(-15.0, 0.0, 10.5),
		"blacksmith_sleep": Vector3(-19.0, 0.0, 8.0),
		"farmer_pos": Vector3(-6.0, 0.0, 18.0),
		"farmer_rest": Vector3(-4.0, 0.0, 12.0),
		"farmer_sleep": Vector3(-16.0, 0.0, -4.0),
		"guard_pos": Vector3(31.5, 0.0, -2.5),
		"guard_sleep": Vector3(25.0, 0.0, 12.0),
	}

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

static func _build_street_lantern(parent: Node3D, pos: Vector3) -> void:
	var lantern_gltf := "res://assets/environments/tinytreats_park/street_lantern.gltf"
	if AssetLibrary.has_model(lantern_gltf):
		place_model(parent, lantern_gltf, pos, 0.0, 0.78, Vector3(0.32, 3.2, 0.32), "VillageLanternPost")
	_build_street_lantern_light_only(parent, pos)

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

	# 2. East Stone Arch Bridge across Eldoria River + Solid Walkable Deck Collider
	var bridge_x := terrain.river_center_x(-4.0) if terrain != null else 45.0
	var bridge_pos := Vector3(bridge_x, 0.0, -4.0)
	place_model(parent, AssetLibrary.HEXAGON_DIR + "building_bridge_A.gltf", bridge_pos, 0.0, 7.8,
		Vector3.ZERO, "EastStoneBridge")
	add_box_body(parent, bridge_pos + Vector3(0.0, -0.35, 0.0), Vector3(15.5, 0.55, 4.6), "BridgeDeckCollider")

	# Riverside Watermill & Northern Waterfall Cliff
	var mill_z := -18.0
	var mill_x := (terrain.river_center_x(mill_z) - 5.2) if terrain != null else 39.5
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

	for i: int in 320:
		var x := rng.randf_range(-108.0, 108.0)
		var z := rng.randf_range(-108.0, 108.0)
		var r := Vector2(x, z).length()
		if r < 41.5:
			continue
		if terrain != null:
			if terrain.is_road_at(x, z) or terrain.is_water_at(x, z):
				continue
			if terrain.river_distance(x, z) < 5.5 or terrain.lake_distance(x, z) < 1.12:
				continue
			if terrain.slope_at(x, z) > 0.56:
				continue
		# Keep clearings around outer landmarks
		if Vector2(x - 66.0, z + 18.0).length() < 11.0 or Vector2(x - 58.0, z - 22.0).length() < 10.5:
			continue
		if Vector2(x + 62.0, z + 24.0).length() < 10.0 or Vector2(x + 56.0, z - 44.0).length() < 8.5:
			continue
		if Vector2(x + 14.0, z + 64.0).length() < 9.5:
			continue

		var y := terrain.height_at(x, z) if terrain != null else 0.0
		if y > 17.5:
			continue
		var biome := terrain.biome_at(x, z) if terrain != null else "dense_woodland"
		var yaw := rng.randf_range(0.0, TAU)
		var pos := Vector3(x, y - 0.06, z)

		match biome:
			"pine_highlands", "alpine":
				var sp := rng.randf_range(2.35, 3.45)
				pine_xforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * sp), pos))
				trunk_positions.append(pos)
			"lakeside_birch":
				var sb := rng.randf_range(1.75, 2.45)
				birch_xforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * sb), pos))
				trunk_positions.append(pos)
			"dense_woodland", "ancient_grove":
				if rng.randf() < 0.52:
					var sd := rng.randf_range(0.56, 0.82)
					dense_xforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * sd), pos))
				else:
					var so := rng.randf_range(0.58, 0.86)
					oak_xforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * so), pos))
				trunk_positions.append(pos)
			"rocky_hills":
				if rng.randf() < 0.35:
					var srp := rng.randf_range(2.15, 3.10)
					pine_xforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * srp), pos))
					trunk_positions.append(pos)
			_:
				if rng.randf() < 0.55:
					var sm := rng.randf_range(0.54, 0.78)
					oak_xforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * sm), pos))
					trunk_positions.append(pos)

	# Rocks, Undergrowth Bushes, Wildflowers, Lush 3D Grass Clumps & Shoreline Reeds
	var grass_xforms: Array = []
	var rock_positions: Array[Vector3] = []
	for i: int in 160:
		var rx := rng.randf_range(-104.0, 104.0)
		var rz := rng.randf_range(-104.0, 104.0)
		if Vector2(rx, rz).length() < 40.5:
			continue
		if terrain != null and (terrain.is_road_at(rx, rz) or terrain.is_water_at(rx, rz)):
			continue
		if terrain != null and terrain.slope_at(rx, rz) > 0.65:
			continue
		var ry := terrain.height_at(rx, rz) if terrain != null else 0.0
		var yaw := rng.randf_range(0.0, TAU)
		if i < 55:
			var rs := rng.randf_range(0.62, 1.28)
			var rpos := Vector3(rx, ry - 0.08, rz)
			rock_xforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * rs), rpos))
			rock_positions.append(rpos)
		elif i < 110:
			var bs := rng.randf_range(0.75, 1.22)
			bush_xforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * bs), Vector3(rx, ry, rz)))
		else:
			var fs := rng.randf_range(1.35, 2.15)
			flower_xforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * fs), Vector3(rx, ry, rz)))

	# Natural Non-Grid 3D Grass Scatter across Meadows, Royal Parks & Woodland Clearings (1 Draw Call!)
	for i: int in 140:
		var gx := rng.randf_range(-86.0, 86.0)
		var gz := rng.randf_range(-86.0, 86.0)
		if Vector2(gx, gz).length() < 39.5 and Vector2(gx, gz).length() > 14.0:
			continue
		if Vector2(gx, gz).length() <= 14.0:
			continue
		if terrain != null:
			if terrain.is_road_at(gx, gz) or terrain.is_water_at(gx, gz):
				continue
			if terrain.slope_at(gx, gz) > 0.52 or terrain.height_at(gx, gz) > 13.5:
				continue
		var gy := terrain.height_at(gx, gz) if terrain != null else 0.0
		var gyaw := rng.randf_range(0.0, TAU)
		var gscale := rng.randf_range(1.05, 1.75)
		grass_xforms.append(Transform3D(Basis(Vector3.UP, gyaw).scaled(Vector3.ONE * gscale), Vector3(gx, gy - 0.02, gz)))

	# Shoreline Reeds around Crystal Lake
	for i: int in 28:
		var ang := float(i) / 28.0 * TAU
		var lx := 16.0 + cos(ang) * 15.6
		var lz := 54.0 + sin(ang) * 12.2
		var ly := terrain.height_at(lx, lz) if terrain != null else -0.3
		reed_xforms.append(Transform3D(Basis(Vector3.UP, ang).scaled(Vector3.ONE * 1.6), Vector3(lx, ly, lz)))

	var rtree := AssetLibrary.REALISTIC_TREES_DIR
	var rnat := AssetLibrary.REALISTIC_NATURE_DIR
	build_multimesh(parent, rtree + "realistic_oak_01.glb", oak_xforms, "ForestOaks", true, 78.0)
	build_multimesh(parent, rtree + "realistic_oak_02.glb", dense_xforms, "ForestCanopyTrees", true, 74.0)
	build_multimesh(parent, rtree + "medieval_tree_01.glb", pine_xforms, "HighlandPines", false, 106.0)
	build_multimesh(parent, rtree + "birch_tree_01.glb", birch_xforms, "LakesideBirches", true, 76.0)
	build_multimesh(parent, rnat + "realistic_rock_01.glb", rock_xforms, "WorldRocks", true, 76.0)
	build_multimesh(parent, rnat + "realistic_bush_01.glb", bush_xforms, "ForestBushes", false, 52.0)
	build_multimesh(parent, "res://assets/environments/tinytreats_park/flower_A.gltf", flower_xforms, "MeadowFlowers", false, 42.0)
	build_multimesh(parent, "res://assets/environments/tinytreats_park/grass_A.gltf", grass_xforms, "MeadowGrass", false, 34.0)
	build_multimesh(parent, "res://assets/environments/rivers/lily-large.glb", reed_xforms, "LakeReeds", false, 60.0)

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

	# Columns, Rubble, Banners & Torches
	for p_off: Vector3 in [Vector3(1.0, 0.0, 1.0), Vector3(7.0, 0.0, 1.0), Vector3(-2.5, 0.0, 30.0), Vector3(10.5, 0.0, 30.0), Vector3(-2.5, 0.0, 38.0), Vector3(10.5, 0.0, 38.0)]:
		place_model(parent, AssetLibrary.DUNGEON_DIR + "pillar.glb", origin + p_off, 0.0, 1.1, Vector3(0.8, 4.0, 0.8))
	place_model(parent, "res://assets/environments/dungeons/banner_red.glb", origin + Vector3(0.5, 2.2, 39.6), PI, 1.4)
	place_model(parent, "res://assets/environments/dungeons/banner_red.glb", origin + Vector3(7.5, 2.2, 39.6), PI, 1.4)

	for torch_pos: Vector3 in [Vector3(0.4, 2.0, 2.0), Vector3(5.6, 2.0, 12.0), Vector3(0.4, 2.0, 20.0), Vector3(14.5, 2.0, 20.0), Vector3(-3.4, 2.0, 34.0), Vector3(11.4, 2.0, 34.0)]:
		place_model(parent, AssetLibrary.DUNGEON_DIR + "torch_lit.glb", origin + torch_pos, 0.0, 1.0)

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
