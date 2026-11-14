class_name InteriorKit
extends RefCounted
## Building blocks for hand-laid interiors (cottage, guild hall, tower floors).
##
## Everything decorative goes into a Batch: boxes, cylinders and flat pieces
## with per-vertex colour, committed as ONE mesh, so a furnished room costs a
## handful of draw calls on a phone. Solid things get their collider from
## solid()/solid_cyl() next to the visual.

const DAYLIGHT_GROUP := "interior_daylight"

static var _mat_lit: StandardMaterial3D
static var _mat_glow: StandardMaterial3D
static var _flame_mesh: QuadMesh

# --- Batch --------------------------------------------------------------------

class Batch extends RefCounted:
	var _st := SurfaceTool.new()
	var _used := false

	func _init() -> void:
		_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	## One flat four-sided face. a,b are the lower edge, c,d the upper edge
	## (a-b-c-d going round). Winding is fixed up from the wanted normal.
	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3,
			col_low: Color, col_high: Color) -> void:
		_used = true
		var flip := (b - a).cross(c - a).dot(normal) > 0.0
		var pts := [a, c, b, a, d, c] if flip else [a, b, c, a, c, d]
		var cols := [col_low, col_high, col_low, col_low, col_high, col_high] if flip \
			else [col_low, col_low, col_high, col_low, col_high, col_high]
		for i in 6:
			_st.set_normal(normal)
			_st.set_color(cols[i])
			_st.add_vertex(pts[i])

	## Box standing on `base` (centre of its underside). `shade` darkens the
	## foot of the side faces - a cheap stand-in for ambient occlusion.
	func box(base: Vector3, size: Vector3, color: Color, yaw: float = 0.0, shade: float = 0.22) -> void:
		var hx := size.x * 0.5
		var hz := size.z * 0.5
		var basis := Basis(Vector3.UP, yaw)
		var low := Color(color.r * (1.0 - shade), color.g * (1.0 - shade), color.b * (1.0 - shade), color.a)
		var p: Array[Vector3] = []
		for corner: Vector2 in [Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)]:
			p.append(base + basis * Vector3(corner.x, 0.0, corner.y))
		var up := Vector3(0.0, size.y, 0.0)
		var normals := [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)]
		var tint := [0.94, 0.88, 1.0, 0.90]
		for i in 4:
			var j := (i + 1) % 4
			var t: float = tint[i]
			quad(p[i], p[j], p[j] + up, p[i] + up, basis * (normals[i] as Vector3),
				Color(low.r * t, low.g * t, low.b * t, color.a), Color(color.r * t, color.g * t, color.b * t, color.a))
		var top := Color(minf(color.r * 1.06, 1.0), minf(color.g * 1.06, 1.0), minf(color.b * 1.06, 1.0), color.a)
		quad(p[0] + up, p[1] + up, p[2] + up, p[3] + up, Vector3.UP, top, top)
		quad(p[0], p[1], p[2], p[3], Vector3.DOWN, low, low)

	## Upright cylinder / cone / spike standing on `base`.
	func cyl(base: Vector3, r_bottom: float, r_top: float, height: float, color: Color,
			sides: int = 8, shade: float = 0.22, lean: Vector3 = Vector3.ZERO) -> void:
		var low := Color(color.r * (1.0 - shade), color.g * (1.0 - shade), color.b * (1.0 - shade), color.a)
		var top_c := base + Vector3(0.0, height, 0.0) + lean
		for i in sides:
			var a0 := TAU * float(i) / float(sides)
			var a1 := TAU * float(i + 1) / float(sides)
			var d0 := Vector3(cos(a0), 0.0, sin(a0))
			var d1 := Vector3(cos(a1), 0.0, sin(a1))
			var n := (d0 + d1).normalized()
			var t := 0.86 + 0.14 * (0.5 + 0.5 * n.z)
			var cl := Color(low.r * t, low.g * t, low.b * t, color.a)
			var ch := Color(color.r * t, color.g * t, color.b * t, color.a)
			quad(base + d0 * r_bottom, base + d1 * r_bottom, top_c + d1 * r_top, top_c + d0 * r_top, n, cl, ch)
			if r_top > 0.001:
				var cap := Color(minf(color.r * 1.06, 1.0), minf(color.g * 1.06, 1.0), minf(color.b * 1.06, 1.0), color.a)
				_tri(top_c, top_c + d0 * r_top, top_c + d1 * r_top, Vector3.UP, cap)

	## Flat disc lying on the floor.
	func disc(center: Vector3, radius: float, color: Color, sides: int = 20) -> void:
		for i in sides:
			var a0 := TAU * float(i) / float(sides)
			var a1 := TAU * float(i + 1) / float(sides)
			_tri(center, center + Vector3(cos(a0), 0.0, sin(a0)) * radius,
				center + Vector3(cos(a1), 0.0, sin(a1)) * radius, Vector3.UP, color)

	## Flat ring lying on the floor.
	func ring(center: Vector3, r_in: float, r_out: float, color: Color, sides: int = 28) -> void:
		for i in sides:
			var a0 := TAU * float(i) / float(sides)
			var a1 := TAU * float(i + 1) / float(sides)
			var d0 := Vector3(cos(a0), 0.0, sin(a0))
			var d1 := Vector3(cos(a1), 0.0, sin(a1))
			quad(center + d0 * r_in, center + d1 * r_in, center + d1 * r_out, center + d0 * r_out, Vector3.UP, color, color)

	## Flat rectangle lying on the floor (x0..x1, z0..z1) at height y.
	func slab(x0: float, z0: float, x1: float, z1: float, y: float, color: Color, o: Vector3 = Vector3.ZERO) -> void:
		quad(o + Vector3(x0, y, z0), o + Vector3(x1, y, z0), o + Vector3(x1, y, z1), o + Vector3(x0, y, z1),
			Vector3.UP, color, color)

	## Upright rectangle facing `normal`, centred on `center`.
	func panel(center: Vector3, width: float, height: float, normal: Vector3, col_low: Color, col_high: Color) -> void:
		var n := normal.normalized()
		var side := Vector3.UP.cross(n).normalized() * (width * 0.5)
		var up := Vector3(0.0, height * 0.5, 0.0)
		quad(center - side - up, center + side - up, center + side + up, center - side + up, n, col_low, col_high)

	func _tri(a: Vector3, b: Vector3, c: Vector3, normal: Vector3, color: Color) -> void:
		_used = true
		var flip := (b - a).cross(c - a).dot(normal) > 0.0
		var pts := [a, c, b] if flip else [a, b, c]
		for v: Vector3 in pts:
			_st.set_normal(normal)
			_st.set_color(color)
			_st.add_vertex(v)

	func is_empty() -> bool:
		return not _used

	## Turns everything added so far into one MeshInstance3D under `parent`.
	func commit(parent: Node3D, node_name: String, glow: bool = false) -> MeshInstance3D:
		var mi := MeshInstance3D.new()
		mi.name = node_name
		if _used:
			mi.mesh = _st.commit()
		mi.material_override = InteriorKit.glow_material() if glow else InteriorKit.lit_material()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		return mi

# --- materials ----------------------------------------------------------------

static func lit_material() -> StandardMaterial3D:
	if _mat_lit == null:
		_mat_lit = StandardMaterial3D.new()
		_mat_lit.vertex_color_use_as_albedo = true
		_mat_lit.vertex_color_is_srgb = true
		_mat_lit.roughness = 0.92
		_mat_lit.metallic_specular = 0.25
	return _mat_lit

static func glow_material() -> StandardMaterial3D:
	if _mat_glow == null:
		_mat_glow = StandardMaterial3D.new()
		_mat_glow.vertex_color_use_as_albedo = true
		_mat_glow.vertex_color_is_srgb = true
		_mat_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _mat_glow

## Own material for see-through additive pieces (light shafts, window panes).
static func shaft_material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return m

static func tone(c: Color, f: float) -> Color:
	return Color(clampf(c.r * f, 0.0, 1.0), clampf(c.g * f, 0.0, 1.0), clampf(c.b * f, 0.0, 1.0), c.a)

# --- colliders ----------------------------------------------------------------

## Solid box standing on `base`.
static func solid(parent: Node3D, base: Vector3, size: Vector3, node_name: String, yaw: float = 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = CollisionLayers.ENVIRONMENT
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = Vector3(0.0, size.y * 0.5, 0.0)
	body.add_child(shape)
	parent.add_child(body)
	body.position = base
	body.rotation.y = yaw
	return body

static func solid_cyl(parent: Node3D, base: Vector3, radius: float, height: float, node_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = CollisionLayers.ENVIRONMENT
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var c := CylinderShape3D.new()
	c.radius = radius
	c.height = height
	shape.shape = c
	shape.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(shape)
	parent.add_child(body)
	body.position = base
	return body

## Walkable slope from (z_low, 0) up to (z_high, rise): the collider under a
## flight of drawn steps, so the hero walks up instead of bumping into a ledge.
static func ramp(parent: Node3D, center_x: float, width: float, z_low: float, z_high: float,
		rise: float, o: Vector3, node_name: String) -> StaticBody3D:
	var run := absf(z_high - z_low)
	var length := sqrt(run * run + rise * rise)
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = CollisionLayers.ENVIRONMENT
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 0.2, length)
	shape.shape = box
	shape.position = Vector3(0.0, -0.1, 0.0)
	body.add_child(shape)
	parent.add_child(body)
	body.position = o + Vector3(center_x, rise * 0.5, (z_low + z_high) * 0.5)
	var angle := atan2(rise, run)
	body.rotation.x = angle if z_high < z_low else -angle
	return body

# --- floors ---------------------------------------------------------------------

static func plank_floor(b: Batch, o: Vector3, rect: Rect2, base: Color, rng: RandomNumberGenerator,
		plank_width: float = 0.42) -> void:
	b.slab(rect.position.x, rect.position.y, rect.end.x, rect.end.y, 0.0, tone(base, 0.55), o)
	var z := rect.position.y
	while z < rect.end.y - 0.01:
		var z1 := minf(z + plank_width, rect.end.y)
		var x := rect.position.x - rng.randf_range(0.0, 1.4)
		while x < rect.end.x - 0.01:
			var x1 := x + rng.randf_range(1.6, 3.0)
			var col := tone(base, rng.randf_range(0.86, 1.10))
			b.slab(maxf(x, rect.position.x) + 0.012, z + 0.012, minf(x1, rect.end.x) - 0.012, z1 - 0.012, 0.006, col, o)
			x = x1
		z = z1

static func tile_floor(b: Batch, o: Vector3, rect: Rect2, base: Color, rng: RandomNumberGenerator,
		tile: float = 1.25, gap: float = 0.035) -> void:
	b.slab(rect.position.x, rect.position.y, rect.end.x, rect.end.y, 0.0, tone(base, 0.52), o)
	var row := 0
	var z := rect.position.y
	while z < rect.end.y - 0.01:
		var z1 := minf(z + tile, rect.end.y)
		var x := rect.position.x - (tile * 0.5 if row % 2 == 1 else 0.0)
		while x < rect.end.x - 0.01:
			var x1 := x + tile
			var f := rng.randf_range(0.88, 1.08)
			if rng.randf() < 0.08:
				f *= 0.86
			b.slab(maxf(x, rect.position.x) + gap, z + gap, minf(x1, rect.end.x) - gap, z1 - gap, 0.006, tone(base, f), o)
			x = x1
		z = z1
		row += 1

## Carpet with a contrasting border, lying on the floor.
static func rug(b: Batch, o: Vector3, rect: Rect2, body: Color, border: Color, y: float = 0.014) -> void:
	b.slab(rect.position.x, rect.position.y, rect.end.x, rect.end.y, y, border, o)
	var m := minf(0.16, minf(rect.size.x, rect.size.y) * 0.18)
	b.slab(rect.position.x + m, rect.position.y + m, rect.end.x - m, rect.end.y - m, y + 0.004, body, o)
	var m2 := m * 2.2
	if rect.size.x > m2 * 3.0 and rect.size.y > m2 * 3.0:
		b.slab(rect.position.x + m2, rect.position.y + m2, rect.end.x - m2, rect.end.y - m2, y + 0.008, tone(body, 0.82), o)
		b.slab(rect.position.x + m2 + 0.06, rect.position.y + m2 + 0.06, rect.end.x - m2 - 0.06, rect.end.y - m2 - 0.06,
			y + 0.012, body, o)

# --- furniture (all drawn into the batch) -------------------------------------

static func table(b: Batch, base: Vector3, size: Vector3, wood: Color, yaw: float = 0.0) -> void:
	var basis := Basis(Vector3.UP, yaw)
	b.box(base + Vector3(0.0, size.y - 0.08, 0.0), Vector3(size.x, 0.08, size.z), wood, yaw, 0.08)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var off := basis * Vector3(sx * (size.x * 0.5 - 0.09), 0.0, sz * (size.z * 0.5 - 0.09))
			b.box(base + off, Vector3(0.09, size.y - 0.08, 0.09), tone(wood, 0.78), yaw)

static func round_table(b: Batch, base: Vector3, radius: float, height: float, wood: Color) -> void:
	b.cyl(base, 0.22, 0.10, height - 0.06, tone(wood, 0.74), 8)
	b.cyl(base + Vector3(0.0, height - 0.06, 0.0), radius, radius, 0.06, wood, 12, 0.06)

static func stool(b: Batch, base: Vector3, wood: Color, height: float = 0.36) -> void:
	b.cyl(base, 0.10, 0.13, height - 0.04, tone(wood, 0.74), 6)
	b.cyl(base + Vector3(0.0, height - 0.04, 0.0), 0.17, 0.17, 0.04, wood, 8, 0.05)

static func bench(b: Batch, base: Vector3, length: float, wood: Color, yaw: float = 0.0) -> void:
	var basis := Basis(Vector3.UP, yaw)
	b.box(base + Vector3(0.0, 0.32, 0.0), Vector3(length, 0.06, 0.32), wood, yaw, 0.06)
	for s: float in [-1.0, 1.0]:
		b.box(base + basis * Vector3(s * (length * 0.5 - 0.14), 0.0, 0.0), Vector3(0.08, 0.32, 0.28), tone(wood, 0.76), yaw)

static func barrel(b: Batch, base: Vector3, wood: Color, scale: float = 1.0) -> void:
	var h := 0.72 * scale
	b.cyl(base, 0.25 * scale, 0.30 * scale, h * 0.5, wood, 10, 0.25)
	b.cyl(base + Vector3(0.0, h * 0.5, 0.0), 0.30 * scale, 0.25 * scale, h * 0.5, wood, 10, 0.0)
	var iron := Color(0.20, 0.19, 0.20)
	b.cyl(base + Vector3(0.0, h * 0.16, 0.0), 0.285 * scale, 0.295 * scale, 0.04 * scale, iron, 10, 0.0)
	b.cyl(base + Vector3(0.0, h * 0.80, 0.0), 0.280 * scale, 0.268 * scale, 0.04 * scale, iron, 10, 0.0)

static func crate(b: Batch, base: Vector3, size: float, wood: Color, yaw: float = 0.0) -> void:
	b.box(base, Vector3(size, size, size), wood, yaw, 0.2)
	var trim := tone(wood, 0.70)
	var basis := Basis(Vector3.UP, yaw)
	for s: float in [-1.0, 1.0]:
		b.box(base + basis * Vector3(s * size * 0.5, 0.0, size * 0.5), Vector3(0.06, size + 0.01, 0.05), trim, yaw, 0.0)
		b.box(base + basis * Vector3(s * size * 0.5, 0.0, -size * 0.5), Vector3(0.06, size + 0.01, 0.05), trim, yaw, 0.0)

static func sack(b: Batch, base: Vector3, cloth: Color, scale: float = 1.0) -> void:
	b.cyl(base, 0.22 * scale, 0.26 * scale, 0.30 * scale, cloth, 8, 0.2)
	b.cyl(base + Vector3(0.0, 0.30 * scale, 0.0), 0.26 * scale, 0.09 * scale, 0.18 * scale, cloth, 8, 0.0)
	b.cyl(base + Vector3(0.0, 0.48 * scale, 0.0), 0.07 * scale, 0.11 * scale, 0.07 * scale, tone(cloth, 0.8), 6, 0.0)

## Open shelf unit against a wall, stocked with books or bottles.
static func shelf(b: Batch, base: Vector3, width: float, height: float, wood: Color, yaw: float,
		rng: RandomNumberGenerator, stock: String = "books") -> void:
	var basis := Basis(Vector3.UP, yaw)
	var depth := 0.32
	b.box(base + basis * Vector3(0.0, 0.0, -depth * 0.5 + 0.02), Vector3(width, height, 0.04), tone(wood, 0.66), yaw)
	for s: float in [-1.0, 1.0]:
		b.box(base + basis * Vector3(s * (width * 0.5 - 0.03), 0.0, 0.0), Vector3(0.06, height, depth), wood, yaw)
	var levels := int(height / 0.42)
	for l in levels + 1:
		var y := minf(float(l) * 0.42, height - 0.04)
		b.box(base + Vector3(0.0, y, 0.0), Vector3(width - 0.06, 0.04, depth), wood, yaw, 0.05)
		if l >= levels:
			continue
		var x := -width * 0.5 + 0.10
		while x < width * 0.5 - 0.14:
			if rng.randf() < 0.16:
				x += 0.10
				continue
			if stock == "books":
				var bw := rng.randf_range(0.04, 0.07)
				var bh := rng.randf_range(0.22, 0.32)
				var col := Color.from_hsv(rng.randf(), rng.randf_range(0.35, 0.65), rng.randf_range(0.35, 0.70))
				b.box(base + basis * Vector3(x, y + 0.04, 0.02), Vector3(bw, bh, 0.20), col, yaw, 0.1)
				x += bw + 0.008
			else:
				var hue := [0.0, 0.58, 0.33, 0.12, 0.78][rng.randi_range(0, 4)] as float
				var col2 := Color.from_hsv(hue, 0.72, 0.86)
				var p := base + basis * Vector3(x + 0.05, y + 0.04, 0.02)
				b.cyl(p, 0.05, 0.05, 0.13, col2, 6, 0.1)
				b.cyl(p + Vector3(0.0, 0.13, 0.0), 0.022, 0.022, 0.06, Color(0.78, 0.74, 0.62), 6, 0.0)
				x += 0.15

## Service counter: panelled front, lighter top slab.
static func counter(b: Batch, base: Vector3, size: Vector3, wood: Color, yaw: float = 0.0) -> void:
	b.box(base, Vector3(size.x, size.y - 0.07, size.z), tone(wood, 0.82), yaw, 0.25)
	b.box(base + Vector3(0.0, size.y - 0.07, 0.0), Vector3(size.x + 0.14, 0.07, size.z + 0.14), tone(wood, 1.18), yaw, 0.04)
	b.box(base, Vector3(size.x + 0.05, 0.12, size.z + 0.05), tone(wood, 0.6), yaw, 0.0)
	var basis := Basis(Vector3.UP, yaw)
	var long_x := size.x >= size.z
	var span := size.x if long_x else size.z
	var panels := maxi(2, int(span / 0.85))
	for i in panels:
		var t := (float(i) + 0.5) / float(panels) - 0.5
		for s: float in [-1.0, 1.0]:
			var off := Vector3(t * span, 0.2, s * (size.z * 0.5 + 0.012)) if long_x \
				else Vector3(s * (size.x * 0.5 + 0.012), 0.2, t * span)
			var psize := Vector3(span / float(panels) - 0.16, size.y - 0.5, 0.02) if long_x \
				else Vector3(0.02, size.y - 0.5, span / float(panels) - 0.16)
			b.box(base + basis * off, psize, tone(wood, 0.98), yaw, 0.1)

## Cloth banner hanging flat against a wall. `normal` points into the room.
static func banner(b: Batch, top_center: Vector3, normal: Vector3, width: float, length: float,
		cloth: Color, emblem: Color) -> void:
	var n := normal.normalized()
	var side := Vector3.UP.cross(n).normalized()
	var p := top_center + n * 0.03
	b.box(top_center - Vector3(0.0, 0.03, 0.0) + n * 0.03, Vector3(absf(side.x) * (width + 0.2) + 0.05, 0.05, absf(side.z) * (width + 0.2) + 0.05),
		Color(0.30, 0.22, 0.14), 0.0, 0.0)
	var a := p - side * width * 0.5
	var c := p + side * width * 0.5
	var down := Vector3(0.0, -length, 0.0)
	b.quad(a + down, c + down, c, a, n, tone(cloth, 0.78), cloth)
	# swallow tail
	b._tri(a + down, p + down * 0.86, a + down * 1.14, n, tone(cloth, 0.74))
	b._tri(c + down, c + down * 1.14, p + down * 0.86, n, tone(cloth, 0.74))
	# emblem: a diamond in the upper half
	var ec := p + down * 0.42 + n * 0.012
	var r := width * 0.26
	b.quad(ec - Vector3(0.0, r, 0.0), ec + side * r, ec + Vector3(0.0, r, 0.0), ec - side * r, n, emblem, emblem)
	# trim along the top
	b.quad(a + down * 0.07 + n * 0.012, c + down * 0.07 + n * 0.012, c + n * 0.012, a + n * 0.012, n, emblem, emblem)

## Round shield hung on a wall.
static func wall_shield(b: Batch, center: Vector3, normal: Vector3, radius: float, face: Color, rim: Color) -> void:
	var n := normal.normalized()
	var side := Vector3.UP.cross(n).normalized()
	var sides := 10
	for i in sides:
		var a0 := TAU * float(i) / float(sides)
		var a1 := TAU * float(i + 1) / float(sides)
		var d0 := side * cos(a0) + Vector3.UP * sin(a0)
		var d1 := side * cos(a1) + Vector3.UP * sin(a1)
		b._tri(center + n * 0.05, center + d0 * radius * 0.82 + n * 0.04, center + d1 * radius * 0.82 + n * 0.04, n, face)
		b.quad(center + d0 * radius * 0.82 + n * 0.04, center + d1 * radius * 0.82 + n * 0.04,
			center + d1 * radius + n * 0.02, center + d0 * radius + n * 0.02, n, rim, tone(rim, 0.8))
	b.quad(center + n * 0.07 - side * radius * 0.16 - Vector3.UP * radius * 0.16, center + n * 0.07 + side * radius * 0.16 - Vector3.UP * radius * 0.16,
		center + n * 0.07 + side * radius * 0.16 + Vector3.UP * radius * 0.16, center + n * 0.07 - side * radius * 0.16 + Vector3.UP * radius * 0.16,
		n, tone(rim, 1.15), tone(rim, 1.15))

## Framed painting on a wall.
static func painting(b: Batch, center: Vector3, normal: Vector3, width: float, height: float, sky: Color, land: Color) -> void:
	var n := normal.normalized()
	b.panel(center + n * 0.02, width + 0.14, height + 0.14, n, Color(0.42, 0.30, 0.14), Color(0.56, 0.42, 0.20))
	b.panel(center + n * 0.035 + Vector3(0.0, height * 0.22, 0.0), width, height * 0.56, n, tone(sky, 0.9), sky)
	b.panel(center + n * 0.035 - Vector3(0.0, height * 0.28, 0.0), width, height * 0.44, n, tone(land, 0.8), land)

## Door set into a wall, seen from inside the room. `normal` points into the room.
static func door(b: Batch, base: Vector3, normal: Vector3, width: float, height: float, wood: Color, double_leaf: bool = false) -> void:
	var n := normal.normalized()
	var side := Vector3.UP.cross(n).normalized()
	var frame := tone(wood, 0.62)
	var sx := absf(side.x)
	var sz := absf(side.z)
	for s: float in [-1.0, 1.0]:
		b.box(base + side * s * (width * 0.5 + 0.09) + n * 0.04, Vector3(sx * 0.18 + sz * 0.22, height + 0.1, sz * 0.18 + sx * 0.22), frame, 0.0)
	b.box(base + Vector3(0.0, height, 0.0) + n * 0.04, Vector3(sx * (width + 0.5) + sz * 0.24, 0.2, sz * (width + 0.5) + sx * 0.24), frame, 0.0, 0.05)
	b.quad(base - side * width * 0.5 + n * 0.02, base + side * width * 0.5 + n * 0.02,
		base + side * width * 0.5 + n * 0.02 + Vector3(0.0, height, 0.0), base - side * width * 0.5 + n * 0.02 + Vector3(0.0, height, 0.0),
		n, tone(wood, 0.72), wood)
	var planks := maxi(3, int(width / 0.28))
	for i in range(1, planks):
		var t := float(i) / float(planks) - 0.5
		b.panel(base + side * t * width + n * 0.026 + Vector3(0.0, height * 0.5, 0.0), 0.025, height, n, tone(wood, 0.5), tone(wood, 0.6))
	var iron := Color(0.16, 0.16, 0.18)
	for hy: float in [0.22, 0.78]:
		b.panel(base + n * 0.032 + Vector3(0.0, height * hy, 0.0), width, 0.07, n, iron, iron)
	if double_leaf:
		b.panel(base + n * 0.034 + Vector3(0.0, height * 0.5, 0.0), 0.05, height, n, iron, iron)
		for s2: float in [-1.0, 1.0]:
			b.box(base + side * s2 * 0.14 + n * 0.05 + Vector3(0.0, height * 0.46, 0.0), Vector3(0.07, 0.07, 0.07), Color(0.80, 0.66, 0.28), 0.0, 0.0)
	else:
		b.box(base + side * (width * 0.34) + n * 0.05 + Vector3(0.0, height * 0.46, 0.0), Vector3(0.07, 0.07, 0.07), Color(0.80, 0.66, 0.28), 0.0, 0.0)

## Training dummy: post, crossbar, straw body and head.
static func dummy(b: Batch, base: Vector3, yaw: float = 0.0) -> void:
	var wood := Color(0.42, 0.30, 0.18)
	var straw := Color(0.80, 0.68, 0.36)
	b.cyl(base, 0.24, 0.20, 0.08, tone(wood, 0.8), 8)
	b.cyl(base + Vector3(0.0, 0.08, 0.0), 0.05, 0.05, 1.05, wood, 6)
	b.box(base + Vector3(0.0, 0.84, 0.0), Vector3(0.86, 0.07, 0.07), wood, yaw, 0.0)
	b.cyl(base + Vector3(0.0, 0.50, 0.0), 0.17, 0.21, 0.52, straw, 8)
	b.cyl(base + Vector3(0.0, 1.06, 0.0), 0.14, 0.15, 0.24, tone(straw, 1.08), 8)
	b.cyl(base + Vector3(0.0, 0.70, 0.0), 0.215, 0.215, 0.05, Color(0.62, 0.20, 0.16), 8, 0.0)

# --- light and fire -----------------------------------------------------------

static func flicker_light(parent: Node3D, pos: Vector3, color: Color, energy: float, light_range: float,
		amount: float = 0.16, node_name: String = "FireLight") -> FlickerLight:
	var light := FlickerLight.new()
	light.name = node_name
	light.light_color = color
	light.base_energy = energy
	light.amount = amount
	light.omni_range = light_range
	light.omni_attenuation = 1.3
	light.shadow_enabled = false
	parent.add_child(light)
	light.position = pos
	return light

static func steady_light(parent: Node3D, pos: Vector3, color: Color, energy: float, light_range: float,
		node_name: String = "Light") -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = node_name
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.omni_attenuation = 1.3
	light.shadow_enabled = false
	parent.add_child(light)
	light.position = pos
	return light

static func _ensure_flame_mesh() -> void:
	if _flame_mesh != null:
		return
	_flame_mesh = QuadMesh.new()
	_flame_mesh.size = Vector2(0.30, 0.30)
	var tex := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	g.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 32
	tex.height = 32
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_flame_mesh.material = m

## Flames: a few soft additive puffs rising and fading.
static func flame(parent: Node3D, pos: Vector3, color: Color, size: float = 1.0, node_name: String = "Flame") -> CPUParticles3D:
	_ensure_flame_mesh()
	var p := CPUParticles3D.new()
	p.name = node_name
	p.mesh = _flame_mesh
	p.amount = 10
	p.lifetime = 0.75
	p.preprocess = 0.8
	p.local_coords = true
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.07 * size
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3(0.0, 0.9 * size, 0.0)
	p.initial_velocity_min = 0.25 * size
	p.initial_velocity_max = 0.55 * size
	p.scale_amount_min = 0.9 * size
	p.scale_amount_max = 1.5 * size
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.55))
	curve.add_point(Vector2(0.25, 1.0))
	curve.add_point(Vector2(1.0, 0.12))
	p.scale_amount_curve = curve
	var ramp_g := Gradient.new()
	ramp_g.set_color(0, Color(1.0, 0.96, 0.78, 0.0).lerp(Color(color.r, color.g, color.b, 0.0), 0.3))
	ramp_g.add_point(0.15, Color(1.0, 0.92, 0.66, 0.9).lerp(Color(color.r, color.g, color.b, 0.9), 0.45))
	ramp_g.add_point(0.6, Color(color.r, color.g, color.b, 0.6))
	ramp_g.set_color(ramp_g.get_point_count() - 1, Color(color.r * 0.7, color.g * 0.3, color.b * 0.3, 0.0))
	p.color_ramp = ramp_g
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.position = pos
	return p

## Slow drifting specks of dust or embers that give a room some air.
static func motes(parent: Node3D, center: Vector3, extents: Vector3, color: Color, count: int = 18,
		rise: float = 0.05, node_name: String = "Motes") -> CPUParticles3D:
	_ensure_flame_mesh()
	var p := CPUParticles3D.new()
	p.name = node_name
	p.mesh = _flame_mesh
	p.amount = count
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.local_coords = true
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = Vector3(0.3, 1.0, 0.2)
	p.spread = 60.0
	p.gravity = Vector3(0.0, rise * 0.2, 0.0)
	p.initial_velocity_min = rise * 0.4
	p.initial_velocity_max = rise * 1.6
	p.scale_amount_min = 0.10
	p.scale_amount_max = 0.24
	var g := Gradient.new()
	g.set_color(0, Color(color.r, color.g, color.b, 0.0))
	g.add_point(0.25, Color(color.r, color.g, color.b, 0.55))
	g.add_point(0.75, Color(color.r, color.g, color.b, 0.45))
	g.set_color(g.get_point_count() - 1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = g
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.position = center
	return p

## Wall torch: iron bracket and cup drawn into the batch, live flame on top.
static func torch(b: Batch, parent: Node3D, wall_point: Vector3, normal: Vector3, flame_color: Color,
		lit: bool = true) -> Vector3:
	var n := normal.normalized()
	var iron := Color(0.17, 0.16, 0.17)
	b.box(wall_point - Vector3(0.0, 0.12, 0.0) + n * 0.03, Vector3(0.10, 0.30, 0.10), iron, 0.0, 0.0)
	b.box(wall_point + n * 0.14 - Vector3(0.0, 0.03, 0.0), Vector3(0.06 + absf(n.x) * 0.24, 0.05, 0.06 + absf(n.z) * 0.24), iron, 0.0, 0.0)
	var cup := wall_point + n * 0.26
	b.cyl(cup - Vector3(0.0, 0.02, 0.0), 0.04, 0.08, 0.16, iron, 6, 0.0)
	b.cyl(cup + Vector3(0.0, 0.10, 0.0), 0.05, 0.03, 0.10, Color(0.36, 0.22, 0.10), 6, 0.0)
	var tip := cup + Vector3(0.0, 0.24, 0.0)
	if lit:
		flame(parent, tip, flame_color, 0.75, "TorchFlame")
	return tip

## Standing brazier with a live fire. Returns the flame position.
static func brazier(b: Batch, parent: Node3D, base: Vector3, flame_color: Color, stone: Color) -> Vector3:
	b.cyl(base, 0.26, 0.12, 0.16, stone, 8)
	b.cyl(base + Vector3(0.0, 0.16, 0.0), 0.08, 0.08, 0.50, tone(stone, 0.8), 6)
	b.cyl(base + Vector3(0.0, 0.66, 0.0), 0.14, 0.34, 0.20, Color(0.18, 0.17, 0.18), 8, 0.0)
	b.cyl(base + Vector3(0.0, 0.84, 0.0), 0.30, 0.20, 0.04, Color(0.10, 0.06, 0.04), 8, 0.0)
	var tip := base + Vector3(0.0, 0.98, 0.0)
	flame(parent, tip, flame_color, 1.25, "BrazierFlame")
	return tip

## Fireplace against a wall. `normal` points into the room. Returns the fire position.
static func fireplace(b: Batch, glow: Batch, parent: Node3D, base: Vector3, normal: Vector3,
		width: float, height: float, ceiling: float, stone: Color) -> Vector3:
	var n := normal.normalized()
	var side := Vector3.UP.cross(n).normalized()
	var depth := 0.72
	var sx := absf(side.x)
	var sz := absf(side.z)
	var along := func(len_side: float, len_depth: float, h: float) -> Vector3:
		return Vector3(sx * len_side + sz * len_depth, h, sz * len_side + sx * len_depth)
	# hearth slab
	b.box(base + n * (depth * 0.5 + 0.12), along.call(width + 0.5, depth + 0.5, 0.12), tone(stone, 0.9), 0.0, 0.1)
	# jambs
	for s: float in [-1.0, 1.0]:
		b.box(base + side * s * (width * 0.5 - 0.20) + n * depth * 0.5 + Vector3(0.0, 0.12, 0.0),
			along.call(0.40, depth, height - 0.12), stone, 0.0)
	# lintel and mantel
	b.box(base + n * depth * 0.5 + Vector3(0.0, height, 0.0), along.call(width, depth, 0.34), tone(stone, 1.05), 0.0, 0.08)
	b.box(base + n * (depth * 0.5 + 0.06) + Vector3(0.0, height + 0.34, 0.0), along.call(width + 0.4, depth + 0.22, 0.09),
		Color(0.36, 0.25, 0.15), 0.0, 0.05)
	# chimney breast
	b.box(base + n * (depth * 0.32) + Vector3(0.0, height + 0.43, 0.0), along.call(width - 0.5, depth * 0.64, maxf(0.1, ceiling - height - 0.43)),
		tone(stone, 0.94), 0.0, 0.0)
	# fire box (dark back and floor)
	var soot := Color(0.07, 0.06, 0.06)
	b.box(base + n * 0.06 + Vector3(0.0, 0.12, 0.0), along.call(width - 0.8, 0.10, height - 0.12), soot, 0.0, 0.0)
	b.slab(-0.5, -0.5, 0.5, 0.5, 0.0, soot, base + n * (depth * 0.5) + Vector3(0.0, 0.125, 0.0))
	# logs and embers
	var fire := base + n * (depth * 0.52) + Vector3(0.0, 0.12, 0.0)
	var log_col := Color(0.26, 0.16, 0.09)
	b.box(fire + side * 0.0, along.call(0.70, 0.13, 0.12), log_col, 0.0, 0.3)
	b.box(fire + n * 0.14 + Vector3(0.0, 0.07, 0.0), along.call(0.56, 0.12, 0.11), tone(log_col, 1.15), 0.0, 0.3)
	b.box(fire - n * 0.12 + Vector3(0.0, 0.07, 0.0), along.call(0.50, 0.12, 0.11), tone(log_col, 0.9), 0.0, 0.3)
	glow.slab(-0.30, -0.16, 0.30, 0.16, 0.0, Color(1.0, 0.42, 0.10), fire + Vector3(0.0, 0.006, 0.0))
	glow.box(fire + Vector3(0.0, 0.11, 0.0), along.call(0.34, 0.08, 0.05), Color(1.0, 0.58, 0.16), 0.0, 0.0)
	flame(parent, fire + Vector3(0.0, 0.30, 0.0), Color(1.0, 0.50, 0.14), 1.7, "HearthFlame")
	return fire + Vector3(0.0, 0.55, 0.0) + n * 0.35

## Wheel chandelier hanging from the ceiling. Returns the light position.
static func chandelier(b: Batch, glow: Batch, center: Vector3, ceiling: float, radius: float, candles: int = 8) -> Vector3:
	var iron := Color(0.20, 0.17, 0.14)
	b.cyl(center + Vector3(0.0, 0.05, 0.0), 0.02, 0.02, ceiling - center.y - 0.05, iron, 4, 0.0)
	b.cyl(center, 0.10, 0.10, 0.07, iron, 6, 0.0)
	for i in candles:
		var a := TAU * float(i) / float(candles)
		var a1 := TAU * float(i + 1) / float(candles)
		var p0 := center + Vector3(cos(a), 0.0, sin(a)) * radius
		var p1 := center + Vector3(cos(a1), 0.0, sin(a1)) * radius
		var mid := (p0 + p1) * 0.5
		var yaw := -atan2(p1.z - p0.z, p1.x - p0.x)
		b.box(mid, Vector3(p0.distance_to(p1) + 0.04, 0.06, 0.07), iron, yaw, 0.0)
		if i % 2 == 0:
			var spoke_mid := (center + p0) * 0.5
			b.box(spoke_mid, Vector3(radius, 0.04, 0.04), iron, -a, 0.0)
		b.cyl(p0 + Vector3(0.0, 0.06, 0.0), 0.028, 0.028, 0.14, Color(0.92, 0.88, 0.76), 5, 0.0)
		glow.cyl(p0 + Vector3(0.0, 0.20, 0.0), 0.030, 0.0, 0.085, Color(1.0, 0.86, 0.50), 5, 0.0)
	return center + Vector3(0.0, -0.35, 0.0)

# --- windows and daylight -----------------------------------------------------

## A window in a wall. The pane and the shaft of light go into their own
## batches so their brightness can follow the clock.
static func window(b: Batch, panes: Batch, shafts: Batch, center: Vector3, normal: Vector3,
		width: float, height: float, shaft_length: float = 2.6) -> void:
	var n := normal.normalized()
	var side := Vector3.UP.cross(n).normalized()
	var frame := Color(0.30, 0.21, 0.13)
	var sx := absf(side.x)
	var sz := absf(side.z)
	for s: float in [-1.0, 1.0]:
		b.box(center + side * s * (width * 0.5 + 0.04) - Vector3(0.0, height * 0.5 + 0.04, 0.0) + n * 0.03,
			Vector3(sx * 0.09 + sz * 0.10, height + 0.08, sz * 0.09 + sx * 0.10), frame, 0.0, 0.0)
	b.box(center + Vector3(0.0, height * 0.5, 0.0) + n * 0.03, Vector3(sx * (width + 0.26) + sz * 0.10, 0.09, sz * (width + 0.26) + sx * 0.10), frame, 0.0, 0.0)
	b.box(center - Vector3(0.0, height * 0.5 + 0.10, 0.0) + n * 0.06, Vector3(sx * (width + 0.36) + sz * 0.18, 0.08, sz * (width + 0.36) + sx * 0.18),
		tone(frame, 1.2), 0.0, 0.0)
	# glazing bars
	b.panel(center + n * 0.03, 0.04, height, n, frame, frame)
	b.panel(center + n * 0.03, width, 0.04, n, frame, frame)
	panes.panel(center + n * 0.012, width, height, n, Color(0.82, 0.86, 0.92), Color(1.0, 1.0, 1.0))
	if shaft_length > 0.0:
		var top_l := center - side * width * 0.5 + Vector3(0.0, height * 0.5, 0.0) + n * 0.05
		var top_r := center + side * width * 0.5 + Vector3(0.0, height * 0.5, 0.0) + n * 0.05
		var bot_l := center - side * width * 0.5 - Vector3(0.0, height * 0.5, 0.0) + n * 0.05
		var bot_r := center + side * width * 0.5 - Vector3(0.0, height * 0.5, 0.0) + n * 0.05
		var fall := n * shaft_length - Vector3(0.0, minf(bot_l.y - 0.02, shaft_length * 0.75), 0.0)
		var clear := Color(1.0, 1.0, 1.0, 0.0)
		var lit := Color(1.0, 1.0, 1.0, 0.11)
		shafts.quad(top_l + fall, top_r + fall, top_r, top_l, Vector3.UP, clear, lit)
		shafts.quad(bot_l + fall, bot_r + fall, bot_r, bot_l, Vector3.UP, clear, lit)
		shafts.quad(bot_l + fall, top_l + fall, top_l, bot_l, side, clear, lit)
		shafts.quad(bot_r + fall, top_r + fall, top_r, bot_r, side, clear, lit)

## Commits pane and shaft batches and registers them for apply_daylight().
static func commit_daylight(parent: Node3D, panes: Batch, shafts: Batch, sun_lights: Array = []) -> void:
	if not panes.is_empty():
		var pane_node := panes.commit(parent, "WindowPanes", true)
		var pm := StandardMaterial3D.new()
		pm.vertex_color_use_as_albedo = true
		pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pane_node.material_override = pm
		pane_node.set_meta("daylight_kind", "pane")
		pane_node.add_to_group(DAYLIGHT_GROUP)
	if not shafts.is_empty():
		var shaft_node := shafts.commit(parent, "LightShafts", true)
		shaft_node.material_override = shaft_material(Color(1.0, 0.94, 0.78))
		shaft_node.set_meta("daylight_kind", "shaft")
		shaft_node.add_to_group(DAYLIGHT_GROUP)
	for l: Variant in sun_lights:
		var light := l as OmniLight3D
		if light != null:
			light.set_meta("daylight_kind", "light")
			light.set_meta("daylight_energy", light.light_energy)
			light.add_to_group(DAYLIGHT_GROUP)

## 0 at night, 1 in full day, with soft dawn and dusk.
static func daylight_at(hour: float) -> float:
	return clampf(sin((hour / 24.0 - 0.25) * TAU) * 1.65 + 0.34, 0.0, 1.0)

## Makes every interior window follow the time of day.
static func apply_daylight(tree: SceneTree, hour: float) -> void:
	if tree == null:
		return
	var day := daylight_at(hour)
	var dusk := clampf(1.0 - absf(hour - 18.6) / 1.6, 0.0, 1.0)
	var pane_col := Color(0.07, 0.10, 0.22).lerp(Color(0.86, 0.93, 1.0), day).lerp(Color(1.0, 0.66, 0.38), dusk * 0.6)
	var shaft_col := Color(1.0, 0.95, 0.80).lerp(Color(1.0, 0.70, 0.42), dusk * 0.7)
	for node: Node in tree.get_nodes_in_group(DAYLIGHT_GROUP):
		match String(node.get_meta("daylight_kind", "")):
			"pane":
				((node as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = pane_col
			"shaft":
				(node as MeshInstance3D).visible = day > 0.25
				((node as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = Color(
					shaft_col.r, shaft_col.g, shaft_col.b, clampf(day * 1.2, 0.0, 1.0))
			"light":
				var light := node as OmniLight3D
				light.light_energy = float(node.get_meta("daylight_energy", 1.0)) * maxf(day, 0.06)
				light.light_color = Color(0.36, 0.46, 0.80).lerp(Color(1.0, 0.96, 0.88), day)
