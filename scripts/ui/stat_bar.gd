class_name StatBar
extends HBoxContainer
## Compact HUD vital bar: a coloured fill on a dark track. No text of its own
## (every glyph is a separate draw call on the Mobile renderer in Godot 4.3);
## the HUD prints the one number that matters, HP, in the panel header.

var _bar: ProgressBar
var _fill: StyleBoxFlat
var _value: float = 1.0
var _maximum: float = 1.0
var _title: String = "HP"
var _base_color: Color = Color(0.88, 0.24, 0.28)

func setup(title: String, color: Color, _icon_kind: String = "", bar_height: int = 9) -> void:
	_title = title
	_base_color = color
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, bar_height)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.value = 1.0
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var radius := int(bar_height / 2.0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.06, 0.09, 0.82)
	bg.set_corner_radius_all(radius)
	_bar.add_theme_stylebox_override("background", bg)

	_fill = StyleBoxFlat.new()
	_fill.bg_color = color
	_fill.set_corner_radius_all(radius)
	_bar.add_theme_stylebox_override("fill", _fill)
	add_child(_bar)

func set_title(title: String) -> void:
	_title = title

func title() -> String:
	return _title

func set_values(current: float, maximum: float) -> void:
	_value = current
	_maximum = maxf(0.001, maximum)
	if _bar != null:
		_bar.value = clampf(current / _maximum, 0.0, 1.0)

func value_text() -> String:
	return "%d/%d" % [int(round(_value)), int(round(_maximum))]

func flash(color: Color) -> void:
	if _fill == null:
		return
	_fill.bg_color = color
	var tween := create_tween()
	tween.tween_property(_fill, "bg_color", _base_color, 0.35)
