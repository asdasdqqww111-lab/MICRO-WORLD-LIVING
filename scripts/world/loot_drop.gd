class_name LootDrop
extends Interactable

var items: Array = []
var _visual: MeshInstance3D
var _time: float = 0.0

func setup(drop_items: Array) -> void:
	items = drop_items

func _ready() -> void:
	super._ready()
	prompt_text = "Pick up"
	interaction_radius = 2.2
	_build_visual()

func _build_visual() -> void:
	_visual = MeshInstance3D.new()
	_visual.name = "LootCube"
	var box := BoxMesh.new()
	box.size = Vector3(0.34, 0.34, 0.34)
	_visual.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.98, 0.82, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.45, 0.1)
	mat.emission_energy_multiplier = 0.8
	_visual.material_override = mat
	_visual.position = Vector3(0.0, 0.45, 0.0)
	_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_visual)

func _process(delta: float) -> void:
	_time += delta
	if _visual != null:
		_visual.rotation.y += delta * 2.2
		_visual.position.y = 0.45 + sin(_time * 2.4) * 0.08

func interact(_player: Node) -> void:
	for drop: Dictionary in items:
		GameManager.gain_item(String(drop.get("id", "")), int(drop.get("count", 1)))
	if items.is_empty():
		EventBus.notify.emit("Nothing here")
	queue_free()

func summary() -> String:
	var parts: PackedStringArray = []
	for drop: Dictionary in items:
		var data := ItemDB.get_item(String(drop.get("id", "")))
		parts.append("%s x%d" % [data.display_name if data != null else "?", int(drop.get("count", 1))])
	return ", ".join(parts)
