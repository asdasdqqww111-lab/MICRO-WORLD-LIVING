class_name UIFactory
extends RefCounted
## Unified Fantasy RPG UI Theme & Widget Kit (EN + Arabic RTL + Noto Font).

const BG := Color(0.07, 0.09, 0.13, 0.94)
const BG_SOFT := Color(0.13, 0.16, 0.22, 0.96)
const BORDER_GOLD := Color(0.68, 0.55, 0.28, 0.92)
const ACCENT := Color(0.46, 0.80, 0.52)
const ACCENT_DARK := Color(0.22, 0.42, 0.30)
const MANA_BLUE := Color(0.32, 0.62, 0.96)
const STAMINA_TEAL := Color(0.32, 0.78, 0.72)
const TEXT := Color(0.95, 0.94, 0.90)
const TEXT_DIM := Color(0.68, 0.72, 0.78)
const GOLD := Color(0.96, 0.80, 0.34)
const GOLD_DIM := Color(0.68, 0.56, 0.28)
const DANGER := Color(0.88, 0.30, 0.30)

static var _theme: Theme

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
	panel_sb.set_border_width_all(2)
	panel_sb.set_corner_radius_all(10)
	panel_sb.set_content_margin_all(12)
	panel_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	panel_sb.shadow_size = 6
	t.set_stylebox("panel", "PanelContainer", panel_sb)

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = BG_SOFT
	btn_normal.border_color = Color(0.46, 0.42, 0.30, 0.92)
	btn_normal.set_border_width_all(2)
	btn_normal.set_corner_radius_all(8)
	btn_normal.set_content_margin_all(8)
	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.19, 0.24, 0.32, 0.98)
	btn_hover.border_color = GOLD
	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color(0.24, 0.34, 0.44, 0.98)
	btn_pressed.border_color = GOLD
	var btn_disabled := btn_normal.duplicate() as StyleBoxFlat
	btn_disabled.bg_color = Color(0.10, 0.11, 0.14, 0.72)
	btn_disabled.border_color = Color(0.24, 0.26, 0.30, 0.65)
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
