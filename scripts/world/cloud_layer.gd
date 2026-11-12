class_name CloudLayer
extends Node3D
## Cheap drifting cloud deck: a dozen unshaded alpha quads with a procedurally
## generated soft noise texture. No external assets, no volumetric raymarching,
## so it stays inside the GLES3 / Android budget.

const CLOUD_COUNT := 12
const ALTITUDE := 78.0
const SPREAD := 190.0
const DRIFT := 1.6

var _quads: Array[MeshInstance3D] = []
var _speeds: Array[float] = []

func _ready() -> void:
	_build()

func _build() -> void:
	var texture := _make_texture()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_texture = texture
	material.albedo_color = Color(1.0, 1.0, 1.0, 0.72)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.vertex_color_use_as_albedo = false

	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in CLOUD_COUNT:
		var mesh := PlaneMesh.new()
		var width := rng.randf_range(90.0, 170.0)
		mesh.size = Vector2(width, width * rng.randf_range(0.35, 0.55))
		var quad := MeshInstance3D.new()
		quad.name = "Cloud%d" % i
		quad.mesh = mesh
		quad.material_override = material
		quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		quad.position = Vector3(
			rng.randf_range(-SPREAD, SPREAD),
			ALTITUDE + rng.randf_range(-6.0, 10.0),
			rng.randf_range(-SPREAD, SPREAD))
		quad.rotation.x = -PI * 0.5
		quad.rotation.z = rng.randf_range(0.0, TAU)
		quad.scale = Vector3.ONE * rng.randf_range(0.85, 1.3)
		add_child(quad)
		_quads.append(quad)
		_speeds.append(rng.randf_range(0.6, 1.5))

func _process(delta: float) -> void:
	for i in _quads.size():
		var quad := _quads[i]
		if not is_instance_valid(quad):
			continue
		quad.position.x += DRIFT * _speeds[i] * delta
		if quad.position.x > SPREAD:
			quad.position.x = -SPREAD

## Soft, irregular cloud sprite built in memory (no image files shipped).
func _make_texture() -> ImageTexture:
	const SIZE := 128
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 77
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.035
	noise.fractal_octaves = 4
	var half := float(SIZE) * 0.5
	for y in SIZE:
		for x in SIZE:
			var nx := (float(x) - half) / half
			var ny := (float(y) - half) / half
			var radial := clampf(1.0 - sqrt(nx * nx + ny * ny), 0.0, 1.0)
			var puff := clampf(noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5, 0.0, 1.0)
			var alpha := clampf(radial * (0.35 + puff * 0.95) - 0.12, 0.0, 1.0)
			var shade := 0.88 + puff * 0.12
			image.set_pixel(x, y, Color(shade, shade, shade * 0.99, alpha))
	return ImageTexture.create_from_image(image)
