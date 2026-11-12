class_name Terrain
extends RefCounted
## Deterministic procedural terrain for the Eldoria valley.
##
## Replaces the old flat plane. Constraints that keep the vertical slice intact:
##  * the village (r < FLAT_RADIUS) is exactly y = 0, so every existing prop,
##    NPC, spawn point and collider keeps its authored position;
##  * the western forest band (x <= FOREST_WEST_X) is also flat, so the
##    MultiMesh trees and forest creature spawns stay grounded;
##  * relief only appears between FLAT_RADIUS and RIDGE_END, then a mountain
##    ring gives the horizon a real silhouette.
## Generation is seeded, so saved worlds reload identically.

const SIZE := 200.0
const RES := 60
const FLAT_RADIUS := 50.0
const HILL_END := 78.0
const RIDGE_END := 100.0
const MAX_HILL := 7.5
const MAX_RIDGE := 24.0
const FOREST_WEST_X := -18.0

const GRASS := Color(0.19, 0.30, 0.12)
const GRASS_DRY := Color(0.30, 0.33, 0.16)
const DIRT := Color(0.26, 0.19, 0.13)
const ROCK := Color(0.27, 0.25, 0.23)
const ROCK_LIGHT := Color(0.38, 0.36, 0.33)
const SNOW := Color(0.78, 0.81, 0.85)

static var _noise: FastNoiseLite
static var _detail: FastNoiseLite

static func _ensure_noise() -> void:
	if _noise != null:
		return
	_noise = FastNoiseLite.new()
	_noise.seed = 20261112
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 0.0085
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.fractal_gain = 0.5
	_detail = FastNoiseLite.new()
	_detail.seed = 991
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_detail.frequency = 0.09
	_detail.fractal_octaves = 2

## Ground height at a world position. Safe to call from anywhere (static, seeded).
static func height_at(x: float, z: float) -> float:
	_ensure_noise()
	var radius := sqrt(x * x + z * z)
	if radius <= FLAT_RADIUS:
		return 0.0
	# Keep the western forest flat so trees/creatures/props stay authored.
	var west_flat := smoothstep(FOREST_WEST_X, FOREST_WEST_X - 26.0, x)
	var flatten := 1.0 - west_flat
	if flatten <= 0.001:
		return 0.0
	var hill_mask := smoothstep(FLAT_RADIUS, HILL_END, radius)
	var ridge_mask := smoothstep(HILL_END, RIDGE_END, radius)
	var base := _noise.get_noise_2d(x, z)                       # -1..1
	var height := hill_mask * MAX_HILL * (0.35 + 0.65 * (0.5 + 0.5 * base))
	# Sharp, believable peaks: invert the noise distance into a ridge.
	var ridge := pow(1.0 - absf(_noise.get_noise_2d(x * 1.7 + 120.0, z * 1.7 - 80.0)), 2.2)
	height += ridge_mask * MAX_RIDGE * ridge
	height += (hill_mask + ridge_mask) * 0.45 * _detail.get_noise_2d(x, z)
	return maxf(0.0, height * flatten)

## Terrain vertex colour: grass → dry grass → rock by slope, snow at altitude.
static func color_at(x: float, z: float, height: float) -> Color:
	var step := 1.6
	var dx := height_at(x + step, z) - height_at(x - step, z)
	var dz := height_at(x, z + step) - height_at(x, z - step)
	var slope := sqrt(dx * dx + dz * dz) / (2.0 * step)        # 0 = flat, 1 = 45°
	var color := GRASS.lerp(GRASS_DRY, clampf(_detail.get_noise_2d(x, z) * 0.5 + 0.5, 0.0, 1.0))
	if height < 1.2:
		color = color.lerp(DIRT, clampf(1.0 - height / 1.2, 0.0, 1.0) * 0.35)
	color = color.lerp(ROCK.lerp(ROCK_LIGHT, 0.5), smoothstep(0.35, 0.75, slope))
	color = color.lerp(SNOW, smoothstep(18.5, 23.0, height) * 0.8)
	return color

## Builds the terrain mesh + a static trimesh collider. Returns the body.
static func build(parent: Node3D, size: float = SIZE, resolution: int = RES) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Terrain"
	body.collision_layer = 1
	body.collision_mask = 0

	var step := size / float(resolution)
	var half := size * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in resolution:
		for ix in resolution:
			var x0 := -half + float(ix) * step
			var z0 := -half + float(iz) * step
			var x1 := x0 + step
			var z1 := z0 + step
			var p00 := Vector3(x0, height_at(x0, z0), z0)
			var p10 := Vector3(x1, height_at(x1, z0), z0)
			var p01 := Vector3(x0, height_at(x0, z1), z1)
			var p11 := Vector3(x1, height_at(x1, z1), z1)
			_tri(st, p00, p10, p11)
			_tri(st, p00, p11, p01)
	st.generate_normals()
	var mesh := st.commit()
	mesh.resource_name = "TerrainMesh"

	var instance := MeshInstance3D.new()
	instance.name = "TerrainMesh"
	instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.96
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	instance.material_override = mat
	body.add_child(instance)

	var shape := CollisionShape3D.new()
	shape.name = "TerrainShape"
	var concave := ConcavePolygonShape3D.new()
	concave.set_faces(mesh.get_faces())
	shape.shape = concave
	body.add_child(shape)

	parent.add_child(body)
	body.global_position = Vector3.ZERO
	return body

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	# Counter-clockwise from above so normals point up.
	st.set_color(color_at(a.x, a.z, a.y))
	st.add_vertex(a)
	st.set_color(color_at(b.x, b.z, b.y))
	st.add_vertex(b)
	st.set_color(color_at(c.x, c.z, c.y))
	st.add_vertex(c)

## Highest point of the terrain ring — used for sky/horizon framing.
static func peak_height() -> float:
	var best := 0.0
	for probe in 48:
		var angle := TAU * float(probe) / 48.0
		var radius := RIDGE_END - 2.0
		best = maxf(best, height_at(cos(angle) * radius, sin(angle) * radius))
	return best
