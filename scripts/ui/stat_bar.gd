class_name StatBar
extends HBoxContainer
## Stylized Glassmorphism RPG Vital Row matching reference HUD:
##   [Left RpgIcon]  [Right-aligned Arabic/EN Label + Glossy Rounded ProgressBar]

var _icon: RpgIcon
var _label: Label
var _bar: ProgressBar
var _value: float = 1.0
var _maximum: float = 1.0
var _title: String = "نقاط الصحة (HP)"
var _base_color: Color = Color(0.88, 0.24, 0.28)

func setup(title: String, color: Color, icon_kind: String = "heart_red") -> void:
	_title = title
	_base_color = color
	add_theme_constant_override("separation", 8)
	alignment = BoxContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_wrap := CenterContainer.new()
	icon_wrap.custom_minimum_size = Vector2(22, 26)
	icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_wrap)

	_icon = RpgIcon.new().setup(icon_kind, Vector2(20, 20), color)
	icon_wrap.add_child(_icon)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)

	_label = UIFactory.label("%s: 0/0" % title, 12, Color(0.96, 0.96, 0.95))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(_label)

	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 10)
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.value = 1.0
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.11, 0.14, 0.85)
	bg.border_color = Color(0.75, 0.78, 0.82, 0.22)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(5)
	_bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(5)
	_bar.add_theme_stylebox_override("fill", fill)
	col.add_child(_bar)

func set_title(title: String) -> void:
	_title = title
	set_values(_value, _maximum)

func set_values(current: float, maximum: float) -> void:
	_value = current
	_maximum = maxf(0.001, maximum)
	if _bar != null:
		_bar.value = clampf(current / _maximum, 0.0, 1.0)
	if _label != null:
		_label.text = "%s: %d/%d" % [_title, int(round(current)), int(round(maximum))]

func flash(color: Color) -> void:
	if _bar == null:
		return
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(5)
	_bar.add_theme_stylebox_override("fill", fill)
