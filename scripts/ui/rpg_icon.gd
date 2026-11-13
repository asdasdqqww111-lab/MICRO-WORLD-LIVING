class_name RpgIcon
extends Control
## Crisp full-color RPG iconography baked ONCE into ONE shared 256x320 ImageTexture atlas
## so all 24+ HUD & TouchControls icons render in 1 single draw_texture_rect_region each!

const CELL := 64
const COLS := 4
const KINDS := [
	"star_gold", "heart_red", "star_blue", "boot_sp",
	"bag", "quests", "skills", "life",
	"map", "lock", "guide", "swords",
	"sprint", "sparkle", "stone", "book",
	"burst", "hand", "potion", "default",
]

static var _atlas_tex: ImageTexture = null
static var _kind_uv: Dictionary = {}

var kind: String = "swords"
var accent: Color = Color.WHITE

func setup(p_kind: String, p_size: Vector2 = Vector2(26, 26), p_accent: Color = Color.WHITE) -> RpgIcon:
	kind = p_kind
	accent = p_accent
	custom_minimum_size = p_size
	size = p_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self

static func _ensure_atlas() -> void:
	if _atlas_tex != null:
		return
	var rows := int(ceil(float(KINDS.size()) / float(COLS)))
	var img := Image.create(COLS * CELL, rows * CELL, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for idx in KINDS.size():
		var k: String = KINDS[idx]
		var cx := (idx % COLS) * CELL
		var cy := int(idx / COLS) * CELL
		_rasterize_icon(img, cx, cy, k)
		_kind_uv[k] = Rect2(float(cx + 1), float(cy + 1), float(CELL - 2), float(CELL - 2))
	_atlas_tex = ImageTexture.create_from_image(img)

static func _put(img: Image, x: int, y: int, col: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	var dst := img.get_pixel(x, y)
	var out_a := col.a + dst.a * (1.0 - col.a)
	if out_a <= 0.001:
		return
	var out_rgb := (Color(col.r, col.g, col.b, 1.0) * col.a + Color(dst.r, dst.g, dst.b, 1.0) * dst.a * (1.0 - col.a)) / out_a
	img.set_pixel(x, y, Color(out_rgb.r, out_rgb.g, out_rgb.b, out_a))

static func _disc(img: Image, ox: int, oy: int, cx: float, cy: float, r: float, col: Color) -> void:
	var x0 := maxi(0, int(floor(cx - r - 1.5)))
	var x1 := mini(CELL - 1, int(ceil(cx + r + 1.5)))
	var y0 := maxi(0, int(floor(cy - r - 1.5)))
	var y1 := mini(CELL - 1, int(ceil(cy + r + 1.5)))
	for py in range(y0, y1 + 1):
		for px in range(x0, x1 + 1):
			var d := Vector2(float(px) + 0.5 - cx, float(py) + 0.5 - cy).length()
			var cov := clampf(r + 0.65 - d, 0.0, 1.0)
			if cov > 0.0:
				_put(img, ox + px, oy + py, Color(col.r, col.g, col.b, col.a * cov))

static func _ring(img: Image, ox: int, oy: int, cx: float, cy: float, r: float, half_w: float, col: Color, a0: float = -PI, a1: float = PI) -> void:
	for py in range(2, CELL - 2):
		for px in range(2, CELL - 2):
			var v := Vector2(float(px) + 0.5 - cx, float(py) + 0.5 - cy)
			var ang := atan2(v.y, v.x)
			if ang < a0 or ang > a1:
				continue
			var d := absf(v.length() - r)
			var cov := clampf(half_w + 0.65 - d, 0.0, 1.0)
			if cov > 0.0:
				_put(img, ox + px, oy + py, Color(col.r, col.g, col.b, col.a * cov))

static func _seg(img: Image, ox: int, oy: int, a: Vector2, b: Vector2, half_w: float, col: Color) -> void:
	var ab := b - a
	var len_sq := maxf(0.001, ab.length_squared())
	var x0 := maxi(1, int(floor(minf(a.x, b.x) - half_w - 2.0)))
	var x1 := mini(CELL - 2, int(ceil(maxf(a.x, b.x) + half_w + 2.0)))
	var y0 := maxi(1, int(floor(minf(a.y, b.y) - half_w - 2.0)))
	var y1 := mini(CELL - 2, int(ceil(maxf(a.y, b.y) + half_w + 2.0)))
	for py in range(y0, y1 + 1):
		for px in range(x0, x1 + 1):
			var p := Vector2(float(px) + 0.5, float(py) + 0.5)
			var t := clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
			var d := p.distance_to(a + ab * t)
			var cov := clampf(half_w + 0.65 - d, 0.0, 1.0)
			if cov > 0.0:
				_put(img, ox + px, oy + py, Color(col.r, col.g, col.b, col.a * cov))

static func _box(img: Image, ox: int, oy: int, rx: float, ry: float, rw: float, rh: float, col: Color) -> void:
	for py in range(maxi(1, int(ry)), mini(CELL - 1, int(ry + rh))):
		for px in range(maxi(1, int(rx)), mini(CELL - 1, int(rx + rw))):
			_put(img, ox + px, oy + py, col)

static func _star_shape(img: Image, ox: int, oy: int, pts_n: int, r_out: float, r_in: float, col: Color) -> void:
	var c := Vector2(32.0, 32.0)
	var poly := PackedVector2Array()
	for i in range(pts_n * 2):
		var a := -PI * 0.5 + float(i) * PI / float(pts_n)
		var rad := r_out if (i % 2 == 0) else r_in
		poly.append(c + Vector2(cos(a), sin(a)) * rad)
	for py in range(3, CELL - 3):
		for px in range(3, CELL - 3):
			if Geometry2D.is_point_in_polygon(Vector2(float(px) + 0.5, float(py) + 0.5), poly):
				_put(img, ox + px, oy + py, col)

static func _rasterize_icon(img: Image, ox: int, oy: int, k: String) -> void:
	var gold := Color(0.98, 0.80, 0.24, 1.0)
	var cream := Color(0.96, 0.92, 0.82, 1.0)
	var dark := Color(0.18, 0.16, 0.20, 0.96)
	match k:
		"star_gold":
			_star_shape(img, ox, oy, 5, 24.0, 10.2, gold)
		"star_blue":
			_star_shape(img, ox, oy, 5, 24.0, 10.2, Color(0.24, 0.68, 1.0, 1.0))
		"heart_red":
			var red := Color(0.94, 0.26, 0.30, 1.0)
			_disc(img, ox, oy, 22.5, 24.0, 11.5, red)
			_disc(img, ox, oy, 41.5, 24.0, 11.5, red)
			var tri := PackedVector2Array([Vector2(11.5, 27.0), Vector2(52.5, 27.0), Vector2(32.0, 53.0)])
			for py in range(25, 55):
				for px in range(10, 54):
					if Geometry2D.is_point_in_polygon(Vector2(px + 0.5, py + 0.5), tri):
						_put(img, ox + px, oy + py, red)
		"boot_sp":
			var boot_c := Color(0.84, 0.90, 0.96, 1.0)
			_box(img, ox, oy, 21, 12, 14, 29, boot_c)
			_box(img, ox, oy, 18, 37, 29, 13, boot_c)
		"bag":
			_disc(img, ox, oy, 32.0, 36.5, 17.0, Color(0.68, 0.45, 0.24, 1.0))
			_box(img, ox, oy, 24, 13, 16, 8, Color(0.86, 0.64, 0.34, 1.0))
			_box(img, ox, oy, 27, 33, 3, 7, cream)
			_box(img, ox, oy, 34, 33, 3, 7, cream)
		"quests":
			_box(img, ox, oy, 16, 11, 32, 42, Color(0.95, 0.88, 0.70, 1.0))
			_box(img, ox, oy, 21, 20, 22, 3, dark)
			_box(img, ox, oy, 21, 29, 22, 3, dark)
			_box(img, ox, oy, 21, 38, 15, 3, dark)
			_disc(img, ox, oy, 46.0, 15.0, 6.0, Color(1.0, 0.52, 0.22, 1.0))
		"skills":
			_box(img, ox, oy, 15, 11, 34, 42, cream)
			_box(img, ox, oy, 19, 15, 26, 34, Color(0.54, 0.36, 0.88, 1.0))
			_seg(img, ox, oy, Vector2(32, 23), Vector2(32, 39), 2.3, cream)
			_seg(img, ox, oy, Vector2(24, 31), Vector2(40, 31), 2.3, cream)
		"life":
			_box(img, ox, oy, 28, 35, 8, 18, Color(0.62, 0.40, 0.22, 1.0))
			_disc(img, ox, oy, 32.0, 23.0, 14.5, Color(0.32, 0.78, 0.36, 1.0))
			_disc(img, ox, oy, 22.5, 29.0, 10.5, Color(0.26, 0.68, 0.30, 1.0))
			_disc(img, ox, oy, 41.5, 29.0, 10.5, Color(0.26, 0.68, 0.30, 1.0))
		"map":
			_box(img, ox, oy, 12, 15, 13, 34, Color(0.84, 0.74, 0.54, 1.0))
			_box(img, ox, oy, 26, 13, 12, 36, Color(0.95, 0.87, 0.68, 1.0))
			_box(img, ox, oy, 39, 15, 13, 34, Color(0.84, 0.74, 0.54, 1.0))
			_disc(img, ox, oy, 32.0, 29.0, 5.0, Color(0.92, 0.32, 0.26, 1.0))
		"lock":
			var silv := Color(0.86, 0.90, 0.95, 1.0)
			_ring(img, ox, oy, 32.0, 24.0, 10.5, 3.0, silv, -PI, 0.0)
			_box(img, ox, oy, 17, 25, 30, 26, silv)
			_disc(img, ox, oy, 32.0, 37.0, 3.8, dark)
		"guide":
			_box(img, ox, oy, 14, 12, 36, 40, Color(0.76, 0.58, 0.30, 1.0))
			_ring(img, ox, oy, 32.0, 25.0, 7.5, 2.6, cream, -PI * 0.85, PI * 0.30)
			_seg(img, ox, oy, Vector2(32, 32), Vector2(32, 38), 2.4, cream)
			_disc(img, ox, oy, 32.0, 45.0, 2.8, cream)
		"swords":
			_seg(img, ox, oy, Vector2(14, 48), Vector2(48, 14), 3.0, cream)
			_seg(img, ox, oy, Vector2(50, 48), Vector2(16, 14), 3.0, cream)
			_seg(img, ox, oy, Vector2(15, 37), Vector2(27, 49), 2.6, gold)
			_seg(img, ox, oy, Vector2(49, 37), Vector2(37, 49), 2.6, gold)
		"sprint":
			_disc(img, ox, oy, 39.0, 15.0, 5.2, cream)
			_seg(img, ox, oy, Vector2(36, 21), Vector2(27, 35), 2.8, cream)
			_seg(img, ox, oy, Vector2(33, 25), Vector2(46, 29), 2.3, cream)
			_seg(img, ox, oy, Vector2(27, 35), Vector2(16, 49), 2.6, cream)
			_seg(img, ox, oy, Vector2(27, 35), Vector2(41, 47), 2.6, cream)
		"sparkle":
			_star_shape(img, ox, oy, 4, 23.0, 6.8, Color(0.68, 0.94, 1.0, 1.0))
			_disc(img, ox, oy, 45.0, 18.0, 3.2, Color(0.88, 0.98, 1.0, 1.0))
		"stone":
			_disc(img, ox, oy, 32.0, 32.0, 16.0, Color(0.86, 0.88, 0.92, 1.0))
			_disc(img, ox, oy, 27.0, 27.0, 7.0, Color(0.96, 0.98, 1.0, 1.0))
		"book":
			_box(img, ox, oy, 15, 13, 34, 38, Color(0.76, 0.62, 0.34, 1.0))
			_box(img, ox, oy, 20, 18, 24, 28, Color(0.22, 0.20, 0.18, 1.0))
			_box(img, ox, oy, 24, 22, 16, 20, Color(0.82, 0.68, 0.38, 1.0))
		"burst":
			_star_shape(img, ox, oy, 8, 22.0, 11.0, Color(0.88, 0.66, 0.24, 1.0))
			_disc(img, ox, oy, 32.0, 32.0, 5.5, dark)
		"hand":
			_box(img, ox, oy, 20, 26, 24, 21, Color(0.96, 0.84, 0.62, 1.0))
			for fi in 4:
				_box(img, ox, oy, 20 + fi * 6, 13, 4, 15, Color(0.96, 0.84, 0.62, 1.0))
			_seg(img, ox, oy, Vector2(20, 34), Vector2(13, 27), 2.6, Color(0.96, 0.84, 0.62, 1.0))
		"potion":
			_disc(img, ox, oy, 32.0, 38.0, 14.0, Color(0.94, 0.24, 0.30, 1.0))
			_ring(img, ox, oy, 32.0, 38.0, 14.2, 2.0, Color(0.86, 0.92, 0.96, 1.0))
			_box(img, ox, oy, 27, 13, 10, 12, Color(0.86, 0.92, 0.96, 1.0))
		_:
			_disc(img, ox, oy, 32.0, 32.0, 16.0, cream)

func _draw() -> void:
	_ensure_atlas()
	var uv: Rect2 = _kind_uv.get(kind, _kind_uv["default"])
	draw_texture_rect_region(_atlas_tex, Rect2(Vector2.ZERO, size), uv)
