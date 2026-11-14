class_name TowerFloorBuilder
extends RefCounted
## Builds the geometry & props of ONE tower floor at a time (streaming-friendly:
## the manager frees the previous floor before building the next — the tower
## never holds more than a single floor's nodes in memory).

const WALL_HEIGHT := 3.6
const RING_LIGHT_RANGE := 60.0

## Builds one floor inside parent and returns a dictionary of key anchors.
static func build_floor(parent: Node3D, floor_num: int) -> Dictionary:
	var origin := TowerDB.floor_origin(floor_num)
	var region_key := TowerDB.region_for_floor(floor_num)
	var region: Dictionary = TowerDB.REGIONS.get(region_key, {})
	var palette: Array = region.get("palette", [Color(0.4, 0.4, 0.4), Color(0.2, 0.2, 0.2)])
	var accent: Color = region.get("accent", Color(1.0, 1.0, 1.0))
	var half := TowerDB.FLOOR_HALF

	var root := Node3D.new()
	root.name = "Floor%d" % floor_num
	parent.add_child(root)
	root.global_position = origin

	# --- Platform (walkable) --------------------------------------------------
	_platform(root, half, palette[0], accent)

	# --- Perimeter walls with an accent trim (solid colliders) ---------------
	_walls(root, half, palette[1], accent)

	# --- Region dressing: pillars + accent floor ring (cheap MultiMesh) -------
	_pillars(root, half, palette[1], accent)

	# --- Boss arena ring (telegraph zone visual, matches Creature boss style) --
	_arena_ring(root, accent)

	# --- Local light so dark floors stay readable on mobile -------------------
	_light(root, accent)

	# --- Ceiling, fires and region dressing ----------------------------------
	_ceiling(root, half, palette[1])
	_dressing(root, half, palette[1], accent, region_key, floor_num)

	# --- Floor sign ------------------------------------------------------------
	_sign(root, floor_num, region_key, origin)

	return {
		"root": root,
		"origin": origin,
		"spawn": TowerDB.floor_spawn(floor_num),
		"master_anchor": origin + Vector3(0.0, 0.0, -5.0),
		"region": region_key,
	}

static func _platform(root: Node3D, half: float, base_color: Color, accent: Color) -> void:
	var body := StaticBody3D.new()
	body.name = "FloorPlatform"
	body.collision_layer = 1
	body.collision_mask = 0
	root.add_child(body)
	body.position = Vector3(0.0, -0.5, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(half * 2.0, 1.0, half * 2.0)
	shape.shape = box
	body.add_child(shape)

	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "FloorMesh"
	var plane := PlaneMesh.new()
	plane.size = Vector2(half * 2.0, half * 2.0)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.roughness = 0.9
	floor_mesh.material_override = mat
	floor_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(floor_mesh)

	# Accent trim ring (thin emissive border for readable arena edges)
	var trim := MeshInstance3D.new()
	trim.name = "AccentTrim"
	var quad := QuadMesh.new()
	quad.size = Vector2(half * 2.0 + 0.3, half * 2.0 + 0.3)
	trim.mesh = quad
	var trim_mat := StandardMaterial3D.new()
	trim_mat.albedo_color = Color(accent.r, accent.g, accent.b, 0.16)
	trim_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trim_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trim_mat.emission_enabled = true
	trim_mat.emission = accent
	trim_mat.emission_energy_multiplier = 0.35
	trim.material_override = trim_mat
	trim.rotation_degrees.x = -90.0
	trim.position.y = 0.02
	trim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(trim)

static func _walls(root: Node3D, half: float, wall_color: Color, accent: Color) -> void:
	# Four walls, each a mesh + matching box collider (mesh and collider share
	# the same size/position base — no mismatched collision like the v1 bug).
	var specs := [
		{"pos": Vector3(0.0, WALL_HEIGHT * 0.5, -half), "size": Vector3(half * 2.0, WALL_HEIGHT, 0.4)},
		{"pos": Vector3(0.0, WALL_HEIGHT * 0.5, half), "size": Vector3(half * 2.0, WALL_HEIGHT, 0.4)},
		{"pos": Vector3(-half, WALL_HEIGHT * 0.5, 0.0), "size": Vector3(0.4, WALL_HEIGHT, half * 2.0)},
		{"pos": Vector3(half, WALL_HEIGHT * 0.5, 0.0), "size": Vector3(0.4, WALL_HEIGHT, half * 2.0)},
	]
	for i in specs.size():
		var body := StaticBody3D.new()
		body.name = "Wall%d" % i
		body.collision_layer = 1
		body.collision_mask = 0
		root.add_child(body)
		body.position = specs[i]["pos"]
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = specs[i]["size"]
		shape.shape = box
		body.add_child(shape)

		var mesh := MeshInstance3D.new()
		mesh.name = "WallMesh%d" % i
		var cube := BoxMesh.new()
		cube.size = specs[i]["size"]
		mesh.mesh = cube
		var mat := StandardMaterial3D.new()
		mat.albedo_color = wall_color
		mat.roughness = 0.85
		mesh.material_override = mat
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(mesh)

		# Accent glow strip at the top of each wall (cheap single quad)
		var strip := MeshInstance3D.new()
		strip.name = "WallStrip%d" % i
		var strip_quad := QuadMesh.new()
		var strip_w: float = maxf(specs[i]["size"].x, specs[i]["size"].z)
		strip_quad.size = Vector2(strip_w, 0.18)
		strip.mesh = strip_quad
		var strip_mat := StandardMaterial3D.new()
		strip_mat.albedo_color = accent
		strip_mat.emission_enabled = true
		strip_mat.emission = accent
		strip_mat.emission_energy_multiplier = 0.6
		strip_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		strip.material_override = strip_mat
		strip.position.y = WALL_HEIGHT + 0.09
		strip.rotation_degrees.x = -90.0
		if specs[i]["size"].x >= specs[i]["size"].z:
			strip.rotation_degrees.y = 90.0
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(strip)

static func _pillars(root: Node3D, half: float, pillar_color: Color, accent: Color) -> void:
	# 4 corner pillars, one MultiMesh batch of decorative mid-wall blocks.
	var corner_positions := [
		Vector3(-half + 0.6, 0.0, -half + 0.6), Vector3(half - 0.6, 0.0, -half + 0.6),
		Vector3(-half + 0.6, 0.0, half - 0.6), Vector3(half - 0.6, 0.0, half - 0.6),
	]
	for i in corner_positions.size():
		var body := StaticBody3D.new()
		body.name = "Pillar%d" % i
		body.collision_layer = 1
		body.collision_mask = 0
		root.add_child(body)
		body.position = corner_positions[i]
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.1, WALL_HEIGHT, 1.1)
		shape.shape = box
		shape.position = Vector3(0.0, WALL_HEIGHT * 0.5, 0.0)
		body.add_child(shape)
		var mesh := MeshInstance3D.new()
		mesh.name = "PillarMesh%d" % i
		var cube := BoxMesh.new()
		cube.size = Vector3(1.1, WALL_HEIGHT, 1.1)
		mesh.mesh = cube
		var mat := StandardMaterial3D.new()
		mat.albedo_color = pillar_color
		mat.roughness = 0.8
		mesh.material_override = mat
		mesh.position = Vector3(0.0, WALL_HEIGHT * 0.5, 0.0)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(mesh)
		var cap := MeshInstance3D.new()
		cap.name = "PillarCap%d" % i
		var cap_cube := BoxMesh.new()
		cap_cube.size = Vector3(1.3, 0.2, 1.3)
		cap.mesh = cap_cube
		var cap_mat := StandardMaterial3D.new()
		cap_mat.albedo_color = accent
		cap_mat.emission_enabled = true
		cap_mat.emission = accent
		cap_mat.emission_energy_multiplier = 0.4
		cap.material_override = cap_mat
		cap.position = Vector3(0.0, WALL_HEIGHT + 0.1, 0.0)
		cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(cap)

static func _arena_ring(root: Node3D, accent: Color) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "BossArenaRing"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 4.6
	cyl.bottom_radius = 4.6
	cyl.height = 0.05
	ring.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(accent.r, accent.g, accent.b, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = accent
	mat.emission_energy_multiplier = 0.5
	ring.material_override = mat
	ring.position = Vector3(0.0, 0.05, -5.0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)

static func _light(root: Node3D, accent: Color) -> void:
	# One shadowless omni light per floor: readable interiors at near-zero cost.
	var lamp := OmniLight3D.new()
	lamp.name = "FloorLight"
	lamp.light_color = Color(accent.r, accent.g, accent.b).lerp(Color.WHITE, 0.4)
	lamp.light_energy = 0.85
	lamp.omni_range = RING_LIGHT_RANGE * 0.35
	lamp.shadow_enabled = false
	lamp.position = Vector3(0.0, WALL_HEIGHT - 0.4, 0.0)
	root.add_child(lamp)

## Flat slab across the top of the floor. The next floor sits FLOOR_STRIDE
## higher, so the ceiling leaves a clear gap to the platform above.
static func _ceiling(root: Node3D, half: float, wall_color: Color) -> void:
	var cy := WALL_HEIGHT + 0.4
	var size := Vector3(half * 2.0 + 0.4, 0.4, half * 2.0 + 0.4)
	var b := InteriorKit.Batch.new()
	b.box(Vector3(0.0, cy, 0.0), size, InteriorKit.tone(wall_color, 0.92), 0.0, 0.34)
	# Underside darker so the room reads as a closed shell.
	b.box(Vector3(0.0, cy - 0.40, 0.0), size * Vector3(1.0, 0.1, 1.0),
		InteriorKit.tone(wall_color, 0.55), 0.0, 0.1)
	b.commit(root, "FloorCeiling")
	InteriorKit.solid(root, Vector3(0.0, cy, 0.0), size, "CeilingBody", 0.0)

## Fires and per-region props around the walls. The middle stays clear: the
## mobs ring the boss arena at radius 7.5 and the portals sit at z = ±11.5.
static func _dressing(root: Node3D, half: float, stone: Color, accent: Color, region_key: String, floor_num: int) -> void:
	var b := InteriorKit.Batch.new()
	var edge := half - 2.2
	# --- Braziers with live fire in three corners ---------------------------
	var braziers := [Vector3(-edge, 0.0, -edge), Vector3(edge, 0.0, -edge), Vector3(-edge, 0.0, edge)]
	for i in braziers.size():
		var tip := InteriorKit.brazier(b, root, braziers[i], accent, stone)
		InteriorKit.flicker_light(root, tip + Vector3(0.0, 0.4, 0.0), accent,
			1.15, 14.0, 0.2, "FloorBrazierLight%d" % i)
	# --- Wall torches (flames, no extra lights) -------------------------------
	var wall := half - 0.25
	for tz in [-4.5, 4.5]:
		InteriorKit.torch(b, root, Vector3(-wall, 1.7, float(tz)), Vector3(1.0, 0.0, 0.0), accent)
		InteriorKit.torch(b, root, Vector3(wall, 1.7, float(tz)), Vector3(-1.0, 0.0, 0.0), accent)
	InteriorKit.torch(b, root, Vector3(float(-4.5), 1.7, -wall), Vector3(0.0, 0.0, 1.0), accent)
	InteriorKit.torch(b, root, Vector3(float(4.5), 1.7, -wall), Vector3(0.0, 0.0, 1.0), accent)
	# --- Wall hangings and shields -------------------------------------------
	InteriorKit.banner(b, Vector3(-wall, 3.3, -6.0), Vector3(1.0, 0.0, 0.0), 2.2, 1.4,
		InteriorKit.tone(stone, 1.0), accent)
	InteriorKit.banner(b, Vector3(wall, 3.3, -6.0), Vector3(-1.0, 0.0, 0.0), 2.2, 1.4,
		InteriorKit.tone(stone, 1.0), accent)
	InteriorKit.wall_shield(b, Vector3(-wall, 1.9, 6.0), Vector3(1.0, 0.0, 0.0), 0.55, accent, stone)
	InteriorKit.wall_shield(b, Vector3(wall, 1.9, 6.0), Vector3(-1.0, 0.0, 0.0), 0.55, accent, stone)
	# --- Storage along the east wall ------------------------------------------
	var shelf_wood := InteriorKit.tone(stone, 1.08)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * floor_num + 104729
	InteriorKit.shelf(b, Vector3(edge * 0.55, 0.0, -6.4), 2.2, 2.0, shelf_wood, 0.0, rng)
	InteriorKit.shelf(b, Vector3(edge * 0.55, 0.0, -4.4), 2.2, 2.0, shelf_wood, 0.0, rng)
	# --- Crates, barrels and sacks near the corners ---------------------------
	InteriorKit.crate(b, Vector3(-edge * 0.7, 0.0, edge * 0.6), 0.7, InteriorKit.tone(stone, 1.1), 0.3)
	InteriorKit.crate(b, Vector3(-edge * 0.5, 0.0, edge * 0.8), 0.5, InteriorKit.tone(stone, 1.0), -0.4)
	InteriorKit.barrel(b, Vector3(edge * 0.7, 0.0, edge * 0.6), InteriorKit.tone(stone, 1.0), 1.1)
	InteriorKit.barrel(b, Vector3(edge * 0.85, 0.0, edge * 0.3), InteriorKit.tone(stone, 0.95), 0.9)
	InteriorKit.sack(b, Vector3(-edge * 0.9, 0.0, -edge * 0.55), accent, 1.2)
	InteriorKit.sack(b, Vector3(-edge * 0.7, 0.0, -edge * 0.8), accent, 0.8)
	InteriorKit.sack(b, Vector3(edge * 0.5, 0.0, -edge * 0.7), accent, 1.0)
	b.commit(root, "FloorDressing")
	InteriorKit.motes(root, Vector3(0.0, 1.6, 0.0), Vector3(half * 0.8, 2.0, half * 0.8),
		accent, 16, 0.04, "FloorMotes")

static func _sign(root: Node3D, floor_num: int, region_key: String, origin: Vector3) -> void:
	var label := Label3D.new()
	label.name = "FloorSign"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var is_ar := Localization.is_arabic()
	label.text = ("%s — الطابق %d" % [TowerDB.region_display_ar(region_key), floor_num]) if is_ar \
			else ("%s — Floor %d" % [TowerDB.region_display(region_key), floor_num])
	label.font_size = 44
	label.outline_size = 10
	label.modulate = Color(1.0, 0.92, 0.65)
	label.position = Vector3(0.0, WALL_HEIGHT - 0.6, -TowerDB.FLOOR_HALF + 0.9)
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(label)
