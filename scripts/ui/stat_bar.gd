class_name StatBar
extends VBoxContainer

var _label: Label
var _bar: ProgressBar
var _value: float = 1.0
var _maximum: float = 1.0
var _title: String = "HP"

func setup(title: String, color: Color) -> void:
	_title = title
	_label = UIFactory.label("%s 0/0" % title, 15, UIFactory.TEXT_DIM)
	add_child(_label)
	_bar = UIFactory.progress_bar(color, 14)
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.value = 1.0
	add_child(_bar)
	add_theme_constant_override("separation", 2)

func set_values(current: float, maximum: float) -> void:
	_value = current
	_maximum = maxf(0.001, maximum)
	if _bar != null:
		_bar.value = clampf(current / _maximum, 0.0, 1.0)
	if _label != null:
		_label.text = "%s %d/%d" % [_title, int(round(current)), int(round(maximum))]

func flash(color: Color) -> void:
	if _bar == null:
		return
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	_bar.add_theme_stylebox_override("fill", fill)
