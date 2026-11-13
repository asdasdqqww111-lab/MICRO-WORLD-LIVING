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
@export var subdivisions: int = 84
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
	# Winding country dirt trail across the Southern Meadow toward the Blue-Turret Castle
	if z >= -18.0 and z <= 48.0:
		var trail_x := -4.8 * smoothstep(-10.0, 26.0, z) + sin(z * 0.14) * 1.65
		if absf(x - trail_x) < 2.25:
			return true
	# East path toward Stone Bridge (x=0..60)
	var bridge_z := -4.0 * clampf(x / 36.0, 0.0, 1.0)
	if x >= -2.0 and x <= 60.0 and absf(z - bridge_z) < 2.3:
		return true
	# West path through Cottages & Barrel Tavern toward Pine Woods (x=-54..2)
	if x >= -54.0 and x <= 2.0 and absf(z - 2.0) < 2.2:
		return true
	# Castle & Guild Forecourt path
	if absf(z + 18.0) < 2.4 and x >= -24.0 and x <= 22.0:
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
	mi.material_override = ArtDirection.terrain_splat_shader_material()
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
	st.set_color(_splat_weights_for(wx, wz, h, slope))
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

## Smooth 4-channel terrain splat weights:
##   R = Dirt Path / Shoreline Sand, G = Lush Meadow Grass, B = Granite Rock, A = Snow Peaks
func _splat_weights_for(wx: float, wz: float, h: float, slope: float) -> Color:
	var dirt_w := 0.0
	if h < WATER_LEVEL + 0.35:
		dirt_w = 1.0 - smoothstep(WATER_LEVEL - 0.15, WATER_LEVEL + 0.35, h)

	# Smoothly feathered country dirt trails
	if wz >= -18.0 and wz <= 48.0:
		var trail_x := -4.8 * smoothstep(-10.0, 26.0, wz) + sin(wz * 0.14) * 1.65
		dirt_w = maxf(dirt_w, 1.0 - smoothstep(1.15, 3.35, absf(wx - trail_x)))
	var bridge_z := -4.0 * clampf(wx / 36.0, 0.0, 1.0)
	if wx >= -2.0 and wx <= 60.0:
		dirt_w = maxf(dirt_w, 1.0 - smoothstep(1.2, 3.2, absf(wz - bridge_z)))
	if wx >= -54.0 and wx <= 2.0:
		dirt_w = maxf(dirt_w, 1.0 - smoothstep(1.1, 3.0, absf(wz - 2.0)))
	if wx >= -24.0 and wx <= 22.0:
		dirt_w = maxf(dirt_w, 1.0 - smoothstep(1.3, 3.4, absf(wz + 18.0)))

	var rock_w := clampf((slope - 0.36) * 2.2, 0.0, 1.0)
	rock_w = maxf(rock_w, smoothstep(8.2, 14.5, h) * 0.88)

	var snow_w := 0.0
	if h >= 13.8:
		snow_w = smoothstep(13.8, 18.8, h) * (1.0 - clampf((slope - 0.95) * 1.2, 0.0, 0.65))

	var grass_w := clampf(1.0 - maxf(dirt_w, maxf(rock_w, snow_w)), 0.0, 1.0)
	return Color(dirt_w, grass_w, rock_w, snow_w)
