class_name UIFactory
extends RefCounted
## Small procedural UI kit: one theme + helpers so every screen looks the same
## and stays readable on a 5" phone screen.

const BG := Color(0.09, 0.11, 0.14, 0.94)
const BG_SOFT := Color(0.14, 0.17, 0.21, 0.95)
const ACCENT := Color(0.55, 0.78, 0.45)
const ACCENT_DARK := Color(0.28, 0.45, 0.24)
const TEXT := Color(0.94, 0.95, 0.92)
const TEXT_DIM := Color(0.68, 0.72, 0.75)
const GOLD := Color(0.95, 0.78, 0.32)
const DANGER := Color(0.85, 0.3, 0.28)

static var _theme: Theme

static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 18

	var panel := StyleBoxFlat.new()
	panel.bg_color = BG
	panel.border_color = Color(0.3, 0.36, 0.32, 1.0)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(10)
	panel.set_content_margin_all(14)
	t.set_stylebox("panel", "PanelContainer", panel)

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = BG_SOFT
	btn_normal.border_color = ACCENT_DARK
	btn_normal.set_border_width_all(2)
	btn_normal.set_corner_radius_all(8)
	btn_normal.set_content_margin_all(10)
	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.2, 0.26, 0.22, 0.98)
	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = ACCENT_DARK
	var btn_disabled := btn_normal.duplicate() as StyleBoxFlat
	btn_disabled.bg_color = Color(0.12, 0.13, 0.14, 0.8)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var style: StyleBoxFlat = {"normal": btn_normal, "hover": btn_hover,
			"pressed": btn_pressed, "disabled": btn_disabled}[state]
		t.set_stylebox(state, "Button", style)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color(1, 1, 1))
	t.set_color("font_disabled_color", "Button", Color(0.45, 0.47, 0.48))
	t.set_font_size("font_size", "Button", 19)

	t.set_color("font_color", "Label", TEXT)
	t.set_font_size("font_size", "Label", 18)
	t.set_font_size("font_size", "RichTextLabel", 17)
	t.set_color("default_color", "RichTextLabel", TEXT)

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.06, 0.07, 0.08, 0.9)
	bar_bg.set_corner_radius_all(4)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = ACCENT
	bar_fill.set_corner_radius_all(4)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)
	_theme = t
	return t

static func panel(alpha: float = 1.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme = theme()
	if alpha < 1.0:
		p.modulate.a = alpha
	return p

static func label(text: String, size: int = 18, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func wrapped_label(text: String, size: int = 17, color: Color = TEXT) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(320, 0)
	return l

static func button(text: String, min_height: int = 46) -> Button:
	var b := Button.new()
	b.text = text
	b.theme = theme()
	b.custom_minimum_size = Vector2(0, min_height)
	b.focus_mode = Control.FOCUS_NONE
	return b

static func icon_button(text: String, size: int = 56) -> Button:
	var b := button(text, size)
	b.custom_minimum_size = Vector2(size, size)
	b.add_theme_font_size_override("font_size", 20)
	return b

static func spacer(height: int = 8) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c

static func hsep(height: int = 2) -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0.3, 0.36, 0.32, 0.8)
	c.custom_minimum_size = Vector2(0, height)
	return c

static func progress_bar(color: Color, height: int = 16) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.theme = theme()
	bar.custom_minimum_size = Vector2(0, height)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

static func full_rect(control: Control) -> Control:
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0
	return control
