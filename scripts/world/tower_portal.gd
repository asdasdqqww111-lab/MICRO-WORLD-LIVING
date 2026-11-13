class_name TowerPortal
extends Interactable
## Portal/gate node used by the Celestial Ascent Tower:
##   - "enter": overworld gate -> tower floor (chosen in interact())
##   - "up":    current floor -> next floor (locked until Floor Master dies)
##   - "exit":  current floor -> overworld gate
## The manager passes itself in so can_interact() can query live tower state.

var manager: Node = null            # TowerManager reference (set by manager)
var kind := "up"                     # "enter" | "up" | "exit"
var floor_num := 1
var is_final := false

func setup_portal(p_kind: String, p_floor: int, p_manager: Node, final: bool = false) -> void:
	kind = p_kind
	floor_num = p_floor
	manager = p_manager
	is_final = final
	interaction_id = "tower_%s_%d" % [kind, floor_num]

func _ready() -> void:
	super._ready()
	_build_visual()

func _build_visual() -> void:
	var color := Color(0.95, 0.80, 0.35)
	if kind == "up":
		color = Color(0.55, 0.85, 1.0)
	elif kind == "exit":
		color = Color(0.75, 0.60, 1.0)
	var arch := MeshInstance3D.new()
	arch.name = "PortalArch"
	var torus := TorusMesh.new()
	torus.inner_radius = 1.15
	torus.outer_radius = 1.45
	torus.rings = 14
	torus.ring_segments = 22
	arch.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.7
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.85
	arch.material_override = mat
	arch.position = Vector3(0.0, 1.45, 0.0)
	arch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(arch)

	var beam := MeshInstance3D.new()
	beam.name = "PortalBeam"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 2.6
	beam.mesh = cyl
	var beam_mat := StandardMaterial3D.new()
	beam_mat.albedo_color = Color(color.r, color.g, color.b, 0.22)
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.emission_enabled = true
	beam_mat.emission = color
	beam_mat.emission_energy_multiplier = 0.5
	beam.material_override = beam_mat
	beam.position = Vector3(0.0, 1.35, 0.0)
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beam)

func prompt_for(_player: Node) -> String:
	var ar := Localization.is_arabic()
	match kind:
		"enter":
			return "ادخل برج الصعود السماوي" if ar else "Enter the Celestial Ascent Tower"
		"up":
			if not can_interact(_player):
				return "البوابة مقفلة — اهزم سيد الطابق أولًا" if ar else "Sealed — defeat the Floor Master first"
			if is_final:
				return "الطابق الأخير — لا مزيد من الصعود" if ar else "Final floor — no floor beyond"
			return "اصعد إلى الطابق %d" % (floor_num + 1) if ar else "Ascend to Floor %d" % (floor_num + 1)
		"exit":
			return "اخرج إلى العالم الخارجي" if ar else "Exit to the overworld"
	return prompt_text

func can_interact(_player: Node) -> bool:
	if not enabled:
		return false
	match kind:
		"enter":
			return true
		"up":
			if manager == null or is_final:
				return false
			return manager.call("is_master_defeated", floor_num) as bool
		"exit":
			return true
	return enabled

func interact(player: Node) -> void:
	if not can_interact(player):
		var ar := Localization.is_arabic()
		if AudioManager != null:
			AudioManager.play_sfx("ui_click", -4.0)
		EventBus.notify.emit("البوابة مختومة بقوة سيد الطابق!" if ar else "The gate is sealed by the Floor Master's power!")
		return
	if player == null or not player.has_method("teleport"):
		return
	match kind:
		"enter":
			manager.call("player_entered", player)
		"up":
			manager.call("ascend", player)
		"exit":
			manager.call("player_exited", player)
