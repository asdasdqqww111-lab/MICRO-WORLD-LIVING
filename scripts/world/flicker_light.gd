class_name FlickerLight
extends OmniLight3D
## A fire-lit lamp: the energy wanders around its base value like a flame.

var base_energy: float = 1.0
var amount: float = 0.16
var speed: float = 8.0

var _t: float = 0.0

func _ready() -> void:
	_t = float(get_instance_id() % 97) * 0.37
	shadow_enabled = false
	light_energy = base_energy

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta * speed
	light_energy = base_energy * (1.0 + amount * (sin(_t) * 0.55 + sin(_t * 2.31 + 1.7) * 0.30 + sin(_t * 5.3) * 0.15))
