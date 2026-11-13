class_name Terrain
extends StaticBody3D
## Seeded procedural multi-biome terrain for the Eldoria Valley (240m x 240m).
## Features:
##   - Level village plateau + cobbled/dirt road network
##   - Carved Eldoria River channel + southern Crystal Lake basin
##   - Rolling meadows, western/southern forests, eastern rocky crags
##   - Full 360-degree alpine perimeter ring (no flat horizon cutoff)
##   - Smooth slope-and-altitude vertex splat blending across 9 surface tones

const WATER_LEVEL := -0.35
const VILLAGE_RADIUS := 38.0
const VILLAGE_BLEND := 49.0

@export var size: float = 240.0
@export var subdivisions: int = 124
@export var max_height: float = 23.0
@export var world_seed: int = 1337

var _noise: FastNoiseLite
var _detail_noise: FastNoiseLite
var _biome_noise: FastNoiseLite

static func build(parent: Node3D, ground_size: float = 240.0) -> Terrain:
	var t := Terrain.new()
	t.name = "Terrain"
	t.size = maxf(240.0, ground_size)
	parent.add_child(t)
	return t

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_setup_noise()
	_build()

func _setup_noise() -> void:
	if _noise != null:
		return
	_noise = FastNoiseLite.new()
	_noise.seed = world_seed
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.011
	_noise.fractal_octaves = 4
	_noise.fractal_lacunarity = 2.05
	_noise.fractal_gain = 0.48

	_detail_noise = FastNoiseLite.new()
	_detail_noise.seed = world_seed + 97
	_detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail_noise.frequency = 0.055
	_detail_noise.fractal_octaves = 2

	_biome_noise = FastNoiseLite.new()
	_biome_noise.seed = world_seed + 409
	_biome_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_biome_noise.frequency = 0.014

## River centerline X coordinate for a given Z between z=-60 (north falls) and z=+46 (Crystal Lake).
func river_center_x(z: float) -> float:
	return 45.5 + sin(z * 0.055) * 4.5 - maxf(0.0, z - 22.0) * 0.65

func river_distance(x: float, z: float) -> float:
	if z < -62.0 or z > 48.0:
		return 999.0
	return absf(x - river_center_x(z))

func lake_distance(x: float, z: float) -> float:
	var dx := (x - 16.0) / 16.5
	var dz := (z - 54.0) / 13.0
	return sqrt(dx * dx + dz * dz)

func is_water_at(x: float, z: float) -> bool:
	return height_at(x, z) < WATER_LEVEL - 0.08

func is_road_at(x: float, z: float) -> bool:
	# Grand Royal City Plaza & Ring Boulevards
	var r_sq := sqrt(x * x + z * z)
	if r_sq < 10.5 or (r_sq > 20.5 and r_sq < 23.2):
		return true
	# North-South Royal Boulevard (North Gate z=-38 to South Gate z=+38)
	if absf(x) < 3.0 and z >= -42.0 and z <= 42.0:
		return true
	# East Boulevard from Royal Square through East Gate & across Stone Bridge (x=0..60)
	var bridge_z := -4.0 * clampf(x / 36.0, 0.0, 1.0)
	if x >= -2.0 and x <= 60.0 and absf(z - bridge_z) < 2.6:
		return true
	# West Boulevard through Residential & Citadel Quarter toward Whispering Woods (x=-54..2)
	if x >= -54.0 and x <= 2.0 and absf(z - 2.0) < 2.6:
		return true
	# Citadel & Cathedral Diagonal Promenade
	if absf(z + 18.0) < 2.2 and x >= -28.0 and x <= 26.0:
		return true
	return false

func height_at(x: float, z: float) -> float:
	_setup_noise()
	var radial := Vector2(x, z).length()
	var village_mask := smoothstep(VILLAGE_RADIUS, VILLAGE_BLEND, radial)

	var base := (_noise.get_noise_2d(x, z) * 0.5 + 0.5) * 6.8
	var detail := _detail_noise.get_noise_2d(x, z) * 0.85
	var h := (base + detail) * village_mask

	# Eastern rocky hills & northern crags
	var east_hill := smoothstep(46.0, 92.0, x) * 10.5
	var north_ridge := smoothstep(-44.0, -92.0, z) * 15.5
	h += maxf(east_hill, north_ridge) * (0.68 + 0.32 * (_noise.get_noise_2d(x * 0.75, z * 0.75) * 0.5 + 0.5))

	# Full 360-degree surrounding alpine rim so no flat horizon edge is ever exposed
	var edge_dist := maxf(absf(x), absf(z))
	var rim := smoothstep(78.0, 116.0, edge_dist)
	var rim_var := 0.72 + 0.42 * (_noise.get_noise_2d(x * 0.9 + 50.0, z * 0.9 - 30.0) * 0.5 + 0.5)
	h += rim * 19.5 * rim_var

	# Flatten key adventure clearings slightly for clean architectural placement
	var clearings := [
		Vector3(66.0, 4.2, -18.0),   # Ancient Ruins terrace
		Vector3(58.0, 2.4, 22.0),    # Sunken Crypt plaza
		Vector3(-62.0, 2.6, -24.0),  # Western Monster Camp
		Vector3(-56.0, 2.2, 44.0),   # Sacred Ancient Grove
	]
	for c: Vector3 in clearings:
		var d := Vector2(x - c.x, z - c.z).length()
		if d < 13.0:
			var w := 1.0 - smoothstep(6.0, 13.0, d)
			h = lerpf(h, c.y, w * 0.78)

	# Carve Eldoria River & Crystal Lake (outside the Walled Royal City)
	var r_dist := river_distance(x, z)
	if r_dist < 7.0 and z > -56.0 and z < 52.0 and radial > VILLAGE_RADIUS + 1.5:
		var bank_t := 1.0 - smoothstep(2.4, 7.0, r_dist)
		h = lerpf(h, -1.55, bank_t)

	var l_dist := lake_distance(x, z)
	if l_dist < 1.30 and radial > VILLAGE_RADIUS + 1.5:
		var lake_t := 1.0 - smoothstep(0.66, 1.30, l_dist)
		h = lerpf(h, -2.15, lake_t)

	# Ensure the entire Walled Royal City plateau stays level and dry
	if radial <= VILLAGE_RADIUS:
		h = 0.0
	return h

func slope_at(x: float, z: float) -> float:
	var e := 0.75
	var dx := (height_at(x + e, z) - height_at(x - e, z)) / (2.0 * e)
	var dz := (height_at(x, z + e) - height_at(x, z - e)) / (2.0 * e)
	return sqrt(dx * dx + dz * dz)

func biome_at(x: float, z: float) -> String:
	var h := height_at(x, z)
	if h < WATER_LEVEL:
		return "water"
	var r := Vector2(x, z).length()
	if r < VILLAGE_RADIUS + 2.0:
		return "village"
	if h >= 13.5:
		return "alpine"
	if x > 44.0 and z < 8.0:
		return "rocky_hills"
	if z < -34.0:
		return "pine_highlands"
	if x < -28.0 and z > 18.0:
		return "ancient_grove"
	if x < -26.0:
		return "dense_woodland"
	if z > 24.0:
		return "lakeside_birch"
	return "temperate_meadow"

func _build() -> void:
	for child: Node in get_children():
		child.queue_free()

	var n := subdivisions + 1
	var step := size / float(subdivisions)
	var half := size * 0.5

	var heights := PackedFloat32Array()
	heights.resize(n * n)
	for gz: int in n:
		for gx: int in n:
			var wx := -half + float(gx) * step
			var wz := -half + float(gz) * step
			heights[gz * n + gx] = height_at(wx, wz)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for gz: int in subdivisions:
		for gx: int in subdivisions:
			var i00 := gz * n + gx
			var i10 := i00 + 1
			var i01 := (gz + 1) * n + gx
			var i11 := i01 + 1
			_emit_vertex(st, gx, gz, heights[i00], step, half, heights, n)
			_emit_vertex(st, gx + 1, gz, heights[i10], step, half, heights, n)
			_emit_vertex(st, gx, gz + 1, heights[i01], step, half, heights, n)

			_emit_vertex(st, gx + 1, gz, heights[i10], step, half, heights, n)
			_emit_vertex(st, gx + 1, gz + 1, heights[i11], step, half, heights, n)
			_emit_vertex(st, gx, gz + 1, heights[i01], step, half, heights, n)
	st.generate_normals()
	st.generate_tangents()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.name = "TerrainMesh"
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = ArtDirection.terrain_detail_texture()
	if DisplayServer.get_name() != "headless":
		mat.normal_enabled = true
		mat.normal_texture = ArtDirection.terrain_normal_texture()
		mat.normal_scale = 0.88
		mat.roughness_texture = ArtDirection.terrain_roughness_texture()
	mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
	mat.roughness = 0.90
	mat.metallic = 0.0
	mi.material_override = mat
	add_child(mi)

	var shape := HeightMapShape3D.new()
	shape.map_width = n
	shape.map_depth = n
	shape.map_data = heights
	var collider := CollisionShape3D.new()
	collider.name = "TerrainCollider"
	collider.shape = shape
	collider.scale = Vector3(step, 1.0, step)
	add_child(collider)

func _emit_vertex(st: SurfaceTool, gx: int, gz: int, h: float, step: float, half: float, heights: PackedFloat32Array, n: int) -> void:
	var wx := -half + float(gx) * step
	var wz := -half + float(gz) * step
	var slope := _grid_slope(gx, gz, heights, n, step)
	st.set_color(_color_for(wx, wz, h, slope))
	st.set_uv(Vector2(wx * 0.16, wz * 0.16))
	st.add_vertex(Vector3(wx, h, wz))

func _grid_slope(gx: int, gz: int, heights: PackedFloat32Array, n: int, step: float) -> float:
	var xl := heights[gz * n + maxi(0, gx - 1)]
	var xr := heights[gz * n + mini(n - 1, gx + 1)]
	var zd := heights[maxi(0, gz - 1) * n + gx]
	var zu := heights[mini(n - 1, gz + 1) * n + gx]
	var dx := (xr - xl) / (2.0 * step)
	var dz := (zu - zd) / (2.0 * step)
	return sqrt(dx * dx + dz * dz)

func _color_for(wx: float, wz: float, h: float, slope: float) -> Color:
	var patch := _biome_noise.get_noise_2d(wx * 1.8, wz * 1.8) * 0.5 + 0.5
	var meadow := Color(0.27, 0.46, 0.22).lerp(Color(0.35, 0.53, 0.25), patch)
	var forest_humus := Color(0.20, 0.34, 0.17).lerp(Color(0.28, 0.25, 0.17), patch * 0.6)
	var cobble := Color(0.47, 0.45, 0.42).lerp(Color(0.53, 0.50, 0.46), patch)
	var dirt_road := Color(0.46, 0.37, 0.26).lerp(Color(0.52, 0.43, 0.30), patch)
	var sand_bank := Color(0.58, 0.52, 0.39)
	var riverbed := Color(0.24, 0.30, 0.28)
	var cliff_rock := Color(0.40, 0.39, 0.38).lerp(Color(0.48, 0.46, 0.44), patch)
	var snow_cap := Color(0.89, 0.92, 0.95)

	# Underwater & shoreline silt
	if h < WATER_LEVEL + 0.28:
		var shore_t := clampf((h - (WATER_LEVEL - 1.4)) / 1.68, 0.0, 1.0)
		return riverbed.lerp(sand_bank, shore_t)

	var c := meadow
	if wx < -22.0 or (wz < -28.0 and h < 10.0):
		var fw := clampf((-wx - 18.0) / 20.0, 0.0, 1.0) if wx < -18.0 else clampf((-wz - 26.0) / 18.0, 0.0, 0.75)
		c = c.lerp(forest_humus, fw)

	# Royal City cobblestone boulevards & outer dirt roads
	var radial := Vector2(wx, wz).length()
	if radial < 11.5:
		c = c.lerp(cobble, 1.0 - smoothstep(7.5, 11.5, radial))
	elif is_road_at(wx, wz):
		var road_col := cobble if radial < 37.5 else dirt_road
		c = c.lerp(road_col, 0.90)
	elif radial < VILLAGE_RADIUS:
		c = c.lerp(Color(0.32, 0.46, 0.24), 0.38)

	# Steep slope -> exposed granite rock
	var rock_w := clampf((slope - 0.42) * 2.1, 0.0, 1.0)
	var alt_rock := smoothstep(9.5, 15.0, h)
	c = c.lerp(cliff_rock, maxf(rock_w, alt_rock * 0.85))

	# Alpine snow strictly restricted to high peaks (y >= 18.5m) on moderate slopes
	if h >= 18.5:
		var snow_w := smoothstep(18.5, 22.5, h) * (1.0 - clampf((slope - 0.85) * 1.4, 0.0, 0.75))
		c = c.lerp(snow_cap, snow_w)

	return c
