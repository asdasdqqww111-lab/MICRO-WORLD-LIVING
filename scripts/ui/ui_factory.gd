class_name UIFactory
extends RefCounted
## Unified Glassmorphism Fantasy RPG UI Theme & Widget Kit (Cairo EN + Arabic RTL).

const BG := Color(0.05, 0.08, 0.13, 0.62)
const BG_SOFT := Color(0.09, 0.14, 0.21, 0.54)
const BG_GLASS_HUD := Color(0.04, 0.07, 0.12, 0.44)
const BORDER_GOLD := Color(0.86, 0.76, 0.48, 0.48)
const ACCENT := Color(0.46, 0.84, 0.56)
const ACCENT_DARK := Color(0.20, 0.40, 0.28)
const MANA_BLUE := Color(0.36, 0.68, 1.0)
const STAMINA_TEAL := Color(0.32, 0.82, 0.76)
const TEXT := Color(0.96, 0.95, 0.92)
const TEXT_DIM := Color(0.74, 0.78, 0.84)
const GOLD := Color(0.98, 0.82, 0.36)
const GOLD_DIM := Color(0.70, 0.58, 0.32, 0.65)
const DANGER := Color(0.92, 0.32, 0.34)

static var _theme: Theme

static func invalidate_theme() -> void:
	_theme = null

static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	var f := Localization.ui_font()
	if f != null:
		t.default_font = f
	t.default_font_size = 17

	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = BG
	panel_sb.border_color = BORDER_GOLD
	panel_sb.set_border_width_all(1)
	panel_sb.set_corner_radius_all(14)
	panel_sb.set_content_margin_all(11)
	panel_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	panel_sb.shadow_size = 8
	t.set_stylebox("panel", "PanelContainer", panel_sb)

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = BG_SOFT
	btn_normal.border_color = Color(0.78, 0.72, 0.54, 0.38)
	btn_normal.set_border_width_all(1)
	btn_normal.set_corner_radius_all(12)
	btn_normal.set_content_margin_all(8)
	btn_normal.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	btn_normal.shadow_size = 4
	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.16, 0.24, 0.34, 0.76)
	btn_hover.border_color = GOLD
	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color(0.22, 0.34, 0.48, 0.84)
	btn_pressed.border_color = GOLD
	var btn_disabled := btn_normal.duplicate() as StyleBoxFlat
	btn_disabled.bg_color = Color(0.08, 0.10, 0.14, 0.36)
	btn_disabled.border_color = Color(0.28, 0.32, 0.38, 0.28)
	for state_name: String in ["normal", "hover", "pressed", "disabled"]:
		var style: StyleBoxFlat = {
			"normal": btn_normal,
			"hover": btn_hover,
			"pressed": btn_pressed,
			"disabled": btn_disabled,
		}[state_name]
		t.set_stylebox(state_name, "Button", style)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color(1, 1, 1))
	t.set_color("font_disabled_color", "Button", Color(0.45, 0.47, 0.50))
	t.set_font_size("font_size", "Button", 17)

	t.set_color("font_color", "Label", TEXT)
	t.set_font_size("font_size", "Label", 17)
	t.set_font_size("font_size", "RichTextLabel", 16)
	t.set_color("default_color", "RichTextLabel", TEXT)

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.05, 0.06, 0.09, 0.92)
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
	Localization.apply_rtl(p)
	if alpha < 1.0:
		p.modulate.a = alpha
	return p

static func make_panel_style(bg: Color, border: Color, border_w: int = 2, corner: int = 8, pad: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(corner)
	sb.set_content_margin_all(pad)
	return sb

static func card_panel(border_col: Color = BORDER_GOLD, bg_col: Color = BG_SOFT) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme = theme()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", sb)
	Localization.apply_rtl(p)
	return p

static func label(text: String, size: int = 17, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.theme = theme()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func wrapped_label(text: String, size: int = 16, color: Color = TEXT) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(240, 0)
	return l

static func button(text: String, min_height: int = 44) -> Button:
	var b := Button.new()
	b.text = text
	b.theme = theme()
	b.custom_minimum_size = Vector2(0, min_height)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void:
		if AudioManager != null:
			AudioManager.play_sfx("ui_click", -5.0))
	return b

static func icon_button(text: String, size: int = 54) -> Button:
	var b := button(text, size)
	b.custom_minimum_size = Vector2(size, size)
	b.add_theme_font_size_override("font_size", 16)
	return b

static func glass_circle_button(text: String, diameter: int = 64, tint: Color = GOLD) -> Button:
	var b := Button.new()
	b.text = text
	b.theme = theme()
	b.custom_minimum_size = Vector2(diameter, diameter)
	b.focus_mode = Control.FOCUS_NONE
	var rad := int(ceil(float(diameter) * 0.5))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.10, 0.16, 0.38).lerp(Color(tint.r, tint.g, tint.b, 0.26), 0.28)
	normal.border_color = Color(tint.r, tint.g, tint.b, 0.62)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(rad)
	normal.set_content_margin_all(2)
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	normal.shadow_size = 5
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(tint.r, tint.g, tint.b, 0.36)
	hover.border_color = tint.lightened(0.28)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(tint.r, tint.g, tint.b, 0.54)
	pressed.border_color = Color(1.0, 0.96, 0.82, 0.95)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_color_override("font_color", tint.lerp(Color.WHITE, 0.45))
	return b

static func glass_pill_button(text: String, min_w: int = 58, height: int = 30) -> Button:
	var b := button(text, height)
	b.custom_minimum_size = Vector2(min_w, height)
	var rad := int(ceil(float(height) * 0.5))
	var normal := StyleBoxFlat.new()
	normal.bg_color = BG_GLASS_HUD
	normal.border_color = Color(0.86, 0.78, 0.52, 0.32)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(rad)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 2
	normal.content_margin_bottom = 2
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.14, 0.22, 0.32, 0.68)
	hover.border_color = GOLD
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_font_size_override("font_size", 13)
	return b

static func spacer(height: int = 8) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c

static func hsep(height: int = 2) -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0.55, 0.45, 0.25, 0.55)
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
