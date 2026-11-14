class_name MinimapControl
extends Control
## Square Top-Right Stylized Valley Minimap backed by ONE baked 192x192 ImageTexture
## (4 Vulkan Mobile draw calls total instead of 55+ primitive calls!), with live Camera FOV Cone.

const MAP_RANGE := 34.0
const TEX_SIZE := 224
const WORLD_EXTENT := 120.0

static var _valley_tex: ImageTexture = null

var player: Player
var world_root: WorldRoot
var _accum: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(126, 126)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	_ensure_valley_texture()

static func _ensure_valley_texture() -> void:
	if _valley_tex != null:
		return
	# Baked once from CityPlan (streets, lots, wall ring) plus the river, the
	# lake and the western woods, so the minimap matches the real town.
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var wall_in := CityPlan.WALL_RADIUS - 1.4
	var wall_out := CityPlan.WALL_RADIUS + 1.4
	for py in TEX_SIZE:
		var wz := ((float(py) + 0.5) / float(TEX_SIZE) * 2.0 - 1.0) * WORLD_EXTENT
		for px in TEX_SIZE:
			var wx := ((float(px) + 0.5) / float(TEX_SIZE) * 2.0 - 1.0) * WORLD_EXTENT
			var r := Vector2(wx, wz).length()
			var col := Color(0.35, 0.50, 0.24, 1.0)
			if r < wall_in:
				col = Color(0.47, 0.60, 0.32, 1.0)
			elif wx < -40.0 and wz > -48.0 and wz < 28.0:
				col = Color(0.21, 0.36, 0.17, 1.0)
			var river_x := 45.5 + sin(wz * 0.055) * 4.5 - maxf(0.0, wz - 22.0) * 0.65
			if (absf(wx - river_x) < 3.6 and r > CityPlan.WALL_RADIUS + 3.0 and wz < 48.0) \
					or Vector2((wx - 16.0) / 16.0, (wz - 54.0) / 12.5).length() < 1.0:
				col = Color(0.24, 0.58, 0.86, 1.0)
			if CityPlan.is_street(wx, wz):
				col = Color(0.80, 0.74, 0.62, 1.0)
			elif CityPlan.country_road_distance(wx, wz) < 2.2:
				col = Color(0.57, 0.46, 0.32, 1.0)
			if r >= wall_in and r <= wall_out and not CityPlan.is_street(wx, wz):
				col = Color(0.30, 0.28, 0.27, 1.0)
			img.set_pixel(px, py, col)
	for lot_entry: Dictionary in CityPlan.lots():
		var lpos: Vector3 = lot_entry["pos"]
		var lhalf: Vector2 = lot_entry["half"]
		var roof: Color = lot_entry["roof"]
		var x0 := clampi(int(((lpos.x - lhalf.x) / WORLD_EXTENT * 0.5 + 0.5) * float(TEX_SIZE)), 0, TEX_SIZE - 1)
		var x1 := clampi(int(((lpos.x + lhalf.x) / WORLD_EXTENT * 0.5 + 0.5) * float(TEX_SIZE)), 0, TEX_SIZE - 1)
		var y0 := clampi(int(((lpos.z - lhalf.y) / WORLD_EXTENT * 0.5 + 0.5) * float(TEX_SIZE)), 0, TEX_SIZE - 1)
		var y1 := clampi(int(((lpos.z + lhalf.y) / WORLD_EXTENT * 0.5 + 0.5) * float(TEX_SIZE)), 0, TEX_SIZE - 1)
		for ry in range(y0, y1 + 1):
			for rx in range(x0, x1 + 1):
				img.set_pixel(rx, ry, roof)
	_valley_tex = ImageTexture.create_from_image(img)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			EventBus.screen_changed.emit("request_map")

func _process(delta: float) -> void:
	_accum += delta
	if _accum >= 0.12:
		_accum = 0.0
		queue_redraw()

func _clamp_box(pt: Vector2, rect: Rect2) -> Vector2:
	return Vector2(
		clampf(pt.x, rect.position.x, rect.position.x + rect.size.x),
		clampf(pt.y, rect.position.y, rect.position.y + rect.size.y)
	)

func _draw() -> void:
	_ensure_valley_texture()
	var box := Rect2(Vector2.ZERO, size)
	var inner := box.grow(-2.0)
	var c := size * 0.5
	var half_w := minf(inner.size.x, inner.size.y) * 0.5

	var p := player
	if p == null or not is_instance_valid(p):
		p = get_tree().get_first_node_in_group("player") as Player
	if p != null and p.zone == "village" and _valley_tex != null:
		var ppos := p.global_position
		var u0 := clampf((ppos.x - MAP_RANGE + WORLD_EXTENT) / (2.0 * WORLD_EXTENT), 0.0, 1.0 - MAP_RANGE / WORLD_EXTENT)
		var v0 := clampf((ppos.z - MAP_RANGE + WORLD_EXTENT) / (2.0 * WORLD_EXTENT), 0.0, 1.0 - MAP_RANGE / WORLD_EXTENT)
		var span := (2.0 * MAP_RANGE / (2.0 * WORLD_EXTENT)) * float(TEX_SIZE)
		var src := Rect2(u0 * float(TEX_SIZE), v0 * float(TEX_SIZE), span, span)
		draw_texture_rect_region(_valley_tex, inner, src)
	else:
		draw_rect(inner, Color(0.24, 0.30, 0.24, 0.95), true)

	if p != null:
		var cam_yaw := p.camera_rig.yaw if p.camera_rig != null else p.rotation.y
		var look_dir := Vector2(-sin(cam_yaw), -cos(cam_yaw))
		var look_ang := atan2(look_dir.y, look_dir.x)
		var half_fov := deg_to_rad(27.5)
		var cone_pts := PackedVector2Array([c])
		for ci in 7:
			var a := look_ang - half_fov + float(ci) / 6.0 * (half_fov * 2.0)
			cone_pts.append(_clamp_box(c + Vector2(cos(a), sin(a)) * (half_w * 0.68), inner))
		draw_colored_polygon(cone_pts, Color(0.98, 1.0, 0.84, 0.25))
		draw_circle(c, 3.2, Color(1.0, 0.96, 0.82))

	draw_rect(box, Color(0.78, 0.75, 0.62, 0.88), false, 2.0)
