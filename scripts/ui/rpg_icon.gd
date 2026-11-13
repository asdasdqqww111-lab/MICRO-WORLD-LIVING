class_name RpgIcon
extends Control
## Crisp procedural fantasy RPG vector icons rendered via CanvasItem._draw()
## (100% OS/font independent — zero emoji tofu on Linux Xvfb or Android!).

var icon_kind: String = "star_gold"
var primary_color: Color = Color(1.0, 0.84, 0.28)

func setup(kind: String, sz: Vector2 = Vector2(24, 24), col: Color = Color(1.0, 0.84, 0.28)) -> RpgIcon:
	icon_kind = kind
	primary_color = col
	custom_minimum_size = sz
	size = sz
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self

func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.44
	match icon_kind:
		"star_gold":
			_draw_star5(c, r, Color(1.0, 0.82, 0.20), Color(0.55, 0.36, 0.06))
		"star_blue":
			_draw_star5(c, r, Color(0.32, 0.74, 1.0), Color(0.10, 0.30, 0.58))
		"heart_red":
			var hr := r * 0.52
			draw_circle(c + Vector2(-hr * 0.78, -hr * 0.32), hr, Color(0.92, 0.24, 0.28))
			draw_circle(c + Vector2(hr * 0.78, -hr * 0.32), hr, Color(0.92, 0.24, 0.28))
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-r * 0.92, -hr * 0.10),
				c + Vector2(r * 0.92, -hr * 0.10),
				c + Vector2(0.0, r * 0.95),
			]), Color(0.86, 0.18, 0.22))
			draw_circle(c + Vector2(-hr * 0.85, -hr * 0.48), hr * 0.32, Color(1.0, 0.72, 0.74, 0.75))
		"boot_sp":
			var col_boot := Color(0.66, 0.82, 0.96)
			draw_rect(Rect2(c + Vector2(-r * 0.32, -r * 0.80), Vector2(r * 0.62, r * 1.15)), col_boot, true)
			draw_rect(Rect2(c + Vector2(-r * 0.68, r * 0.20), Vector2(r * 1.10, r * 0.56)), col_boot, true)
			draw_rect(Rect2(c + Vector2(-r * 0.70, r * 0.62), Vector2(r * 1.14, r * 0.22)), Color(0.30, 0.44, 0.62), true)
		"bag":
			draw_circle(c + Vector2(0.0, r * 0.18), r * 0.82, Color(0.56, 0.35, 0.18))
			draw_rect(Rect2(c + Vector2(-r * 0.68, -r * 0.38), Vector2(r * 1.36, r * 0.62)), Color(0.66, 0.43, 0.22), true)
			draw_arc(c + Vector2(0.0, -r * 0.44), r * 0.32, PI, TAU, 12, Color(0.42, 0.25, 0.12), 2.4)
			draw_rect(Rect2(c + Vector2(-r * 0.44, -r * 0.08), Vector2(r * 0.22, r * 0.52)), Color(0.92, 0.76, 0.36), true)
			draw_rect(Rect2(c + Vector2(r * 0.22, -r * 0.08), Vector2(r * 0.22, r * 0.52)), Color(0.92, 0.76, 0.36), true)
		"quests":
			draw_rect(Rect2(c + Vector2(-r * 0.64, -r * 0.78), Vector2(r * 1.24, r * 1.56)), Color(0.92, 0.82, 0.60), true)
			draw_rect(Rect2(c + Vector2(-r * 0.76, -r * 0.84), Vector2(r * 1.48, r * 0.24)), Color(0.76, 0.62, 0.38), true)
			draw_rect(Rect2(c + Vector2(-r * 0.76, r * 0.62), Vector2(r * 1.48, r * 0.24)), Color(0.76, 0.62, 0.38), true)
			for li in 3:
				var ly := -r * 0.30 + float(li) * r * 0.32
				draw_line(c + Vector2(-r * 0.40, ly), c + Vector2(r * 0.36, ly), Color(0.48, 0.36, 0.20), 1.8)
			draw_circle(c + Vector2(r * 0.58, -r * 0.58), r * 0.34, Color(0.95, 0.42, 0.16))
		"skills":
			draw_rect(Rect2(c + Vector2(-r * 0.68, -r * 0.82), Vector2(r * 1.36, r * 1.64)), Color(0.36, 0.24, 0.58), true)
			draw_rect(Rect2(c + Vector2(-r * 0.68, -r * 0.82), Vector2(r * 1.36, r * 1.64)), Color(0.78, 0.62, 0.98), false, 1.8)
			_draw_star4(c, r * 0.52, Color(0.86, 0.72, 1.0))
		"life":
			draw_rect(Rect2(c + Vector2(-r * 0.18, r * 0.10), Vector2(r * 0.36, r * 0.76)), Color(0.48, 0.31, 0.16), true)
			draw_circle(c + Vector2(0.0, -r * 0.24), r * 0.66, Color(0.24, 0.66, 0.26))
			draw_circle(c + Vector2(-r * 0.38, -r * 0.05), r * 0.44, Color(0.32, 0.76, 0.30))
			draw_circle(c + Vector2(r * 0.38, -r * 0.05), r * 0.44, Color(0.20, 0.58, 0.22))
		"map":
			draw_rect(Rect2(c + Vector2(-r * 0.78, -r * 0.64), Vector2(r * 1.56, r * 1.28)), Color(0.86, 0.74, 0.50), true)
			draw_line(c + Vector2(-r * 0.26, -r * 0.64), c + Vector2(-r * 0.26, r * 0.64), Color(0.58, 0.46, 0.28), 1.5)
			draw_circle(c + Vector2(r * 0.36, -r * 0.16), r * 0.44, Color(0.95, 0.92, 0.84))
			draw_circle(c + Vector2(r * 0.36, -r * 0.16), r * 0.44, Color(0.72, 0.56, 0.24), false, 1.8)
			_draw_star4(c + Vector2(r * 0.36, -r * 0.16), r * 0.32, Color(0.84, 0.32, 0.24))
		"lock":
			draw_arc(c + Vector2(0.0, -r * 0.20), r * 0.44, PI, TAU, 16, Color(0.82, 0.85, 0.90), 3.0)
			draw_rect(Rect2(c + Vector2(-r * 0.62, -r * 0.18), Vector2(r * 1.24, r * 1.00)), Color(0.66, 0.70, 0.76), true)
			draw_rect(Rect2(c + Vector2(-r * 0.62, -r * 0.18), Vector2(r * 1.24, r * 1.00)), Color(0.88, 0.78, 0.52), false, 1.6)
			draw_circle(c + Vector2(0.0, r * 0.26), r * 0.16, Color(0.18, 0.20, 0.24))
		"guide":
			draw_rect(Rect2(c + Vector2(-r * 0.66, -r * 0.80), Vector2(r * 1.32, r * 1.60)), Color(0.46, 0.38, 0.28), true)
			draw_rect(Rect2(c + Vector2(-r * 0.66, -r * 0.80), Vector2(r * 1.32, r * 1.60)), Color(0.88, 0.76, 0.46), false, 1.8)
			var f := Localization.ui_font()
			if f != null:
				draw_string(f, c + Vector2(-r * 0.28, r * 0.32), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, int(r * 1.35), Color(1.0, 0.88, 0.48))
		"sprint":
			var col_s := Color(0.96, 0.94, 0.88)
			draw_circle(c + Vector2(r * 0.28, -r * 0.58), r * 0.22, col_s)
			draw_line(c + Vector2(r * 0.18, -r * 0.32), c + Vector2(-r * 0.16, r * 0.18), col_s, 2.6)
			draw_line(c + Vector2(r * 0.08, -r * 0.18), c + Vector2(r * 0.52, -r * 0.04), col_s, 2.2)
			draw_line(c + Vector2(r * 0.08, -r * 0.18), c + Vector2(-r * 0.42, -r * 0.28), col_s, 2.2)
			draw_line(c + Vector2(-r * 0.16, r * 0.18), c + Vector2(r * 0.34, r * 0.66), col_s, 2.4)
			draw_line(c + Vector2(-r * 0.16, r * 0.18), c + Vector2(-r * 0.58, r * 0.52), col_s, 2.4)
		"swords":
			var blade := Color(0.96, 0.86, 0.58)
			var hilt := Color(0.78, 0.58, 0.24)
			draw_line(c + Vector2(-r * 0.72, r * 0.72), c + Vector2(r * 0.72, -r * 0.72), blade, 3.6)
			draw_line(c + Vector2(r * 0.72, r * 0.72), c + Vector2(-r * 0.72, -r * 0.72), blade, 3.6)
			draw_line(c + Vector2(-r * 0.62, r * 0.26), c + Vector2(-r * 0.26, r * 0.62), hilt, 3.2)
			draw_line(c + Vector2(r * 0.62, r * 0.26), c + Vector2(r * 0.26, r * 0.62), hilt, 3.2)
		"potion":
			draw_circle(c + Vector2(0.0, r * 0.22), r * 0.62, Color(0.84, 0.90, 0.96, 0.55))
			draw_circle(c + Vector2(0.0, r * 0.28), r * 0.50, Color(0.88, 0.18, 0.24))
			draw_rect(Rect2(c + Vector2(-r * 0.20, -r * 0.68), Vector2(r * 0.40, r * 0.44)), Color(0.82, 0.88, 0.94, 0.75), true)
			draw_rect(Rect2(c + Vector2(-r * 0.16, -r * 0.84), Vector2(r * 0.32, r * 0.20)), Color(0.68, 0.46, 0.24), true)
		"book":
			draw_rect(Rect2(c + Vector2(-r * 0.62, -r * 0.76), Vector2(r * 1.24, r * 1.52)), Color(0.46, 0.34, 0.22), true)
			draw_rect(Rect2(c + Vector2(-r * 0.62, -r * 0.76), Vector2(r * 1.24, r * 1.52)), Color(0.86, 0.72, 0.42), false, 1.8)
			draw_rect(Rect2(c + Vector2(-r * 0.28, -r * 0.36), Vector2(r * 0.56, r * 0.72)), Color(0.76, 0.62, 0.36), false, 1.5)
		"sparkle":
			_draw_star4(c, r * 0.86, Color(0.68, 0.92, 1.0))
			_draw_star4(c + Vector2(r * 0.48, -r * 0.48), r * 0.28, Color(0.88, 0.98, 1.0))
		"burst":
			_draw_star5(c + Vector2(-r * 0.30, -r * 0.28), r * 0.42, Color(1.0, 0.90, 0.56), Color(0.6, 0.4, 0.1))
			_draw_star5(c + Vector2(r * 0.36, 0.0), r * 0.34, Color(1.0, 0.94, 0.72), Color(0.6, 0.4, 0.1))
			_draw_star5(c + Vector2(-r * 0.10, r * 0.42), r * 0.30, Color(0.92, 0.86, 0.64), Color(0.6, 0.4, 0.1))
		"hand":
			var hc := Color(0.94, 0.82, 0.56)
			draw_circle(c + Vector2(0.0, r * 0.24), r * 0.46, hc)
			for fi in 4:
				var fx := -r * 0.34 + float(fi) * r * 0.23
				draw_line(c + Vector2(fx, r * 0.12), c + Vector2(fx, -r * 0.62), hc, 2.6)
			draw_line(c + Vector2(-r * 0.38, r * 0.24), c + Vector2(-r * 0.68, -r * 0.12), hc, 2.6)
		"stone":
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-r * 0.72, r * 0.32),
				c + Vector2(-r * 0.54, -r * 0.46),
				c + Vector2(r * 0.12, -r * 0.68),
				c + Vector2(r * 0.74, -r * 0.18),
				c + Vector2(r * 0.58, r * 0.56),
				c + Vector2(-r * 0.22, r * 0.66),
			]), Color(0.74, 0.75, 0.78))
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-r * 0.54, -r * 0.46),
				c + Vector2(r * 0.12, -r * 0.68),
				c + Vector2(r * 0.24, -r * 0.05),
				c + Vector2(-r * 0.28, r * 0.08),
			]), Color(0.86, 0.87, 0.90))

func _draw_star5(c: Vector2, r: float, fill: Color, rim: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI * 0.5 + float(i) * PI / 5.0
		var rad := r if (i % 2 == 0) else (r * 0.44)
		pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, rim, 1.2, true)

func _draw_star4(c: Vector2, r: float, fill: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var ang := -PI * 0.5 + float(i) * PI / 4.0
		var rad := r if (i % 2 == 0) else (r * 0.28)
		pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
	draw_colored_polygon(pts, fill)
