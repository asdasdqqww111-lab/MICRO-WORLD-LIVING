class_name DungeonTrap
extends Node3D
## Modular timed Spike Trap for the Sunken Crypt dungeon.
## Cycles: dormant -> warning telegraph (amber) -> active spikes -> retract.

@export var trap_damage: float = 14.0
@export var cycle_period: float = 3.6
@export var phase_offset: float = 0.0

var _timer: float = 0.0
var _spikes_node: Node3D
var _telegraph: MeshInstance3D
var _damage_cooldown: float = 0.0

func _ready() -> void:
	_timer = phase_offset
	_build_visual()

func _build_visual() -> void:
	var grate := AssetLibrary.instantiate("res://assets/models/dungeon/floor_tile_big_spikes.glb", 0.5)
	if grate != null:
		add_child(grate)

	_telegraph = MeshInstance3D.new()
	var quad := BoxMesh.new()
	quad.size = Vector3(1.75, 0.03, 1.75)
	_telegraph.mesh = quad
	_telegraph.position = Vector3(0.0, 0.03, 0.0)
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(1.0, 0.45, 0.12, 0.55)
	tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_telegraph.material_override = tmat
	_telegraph.visible = false
	add_child(_telegraph)

	_spikes_node = Node3D.new()
	_spikes_node.position = Vector3(0.0, -0.45, 0.0)
	add_child(_spikes_node)
	var spike_mat := ProceduralModels.make_material(Color(0.72, 0.75, 0.80), 0.35, 0.75)
	for sx: float in [-0.45, 0.0, 0.45]:
		for sz: float in [-0.45, 0.0, 0.45]:
			var cone := MeshInstance3D.new()
			var cmesh := CylinderMesh.new()
			cmesh.top_radius = 0.01
			cmesh.bottom_radius = 0.08
			cmesh.height = 0.55
			cone.mesh = cmesh
			cone.position = Vector3(sx, 0.28, sz)
			cone.material_override = spike_mat
			_spikes_node.add_child(cone)

func _physics_process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_timer = fmod(_timer + delta, cycle_period)
	_damage_cooldown = maxf(0.0, _damage_cooldown - delta)

	var phase := _timer / cycle_period
	var warning := phase >= 0.48 and phase < 0.68
	var active := phase >= 0.68 and phase < 0.88
	_telegraph.visible = warning or active
	var target_y := 0.02 if active else -0.48
	_spikes_node.position.y = lerpf(_spikes_node.position.y, target_y, clampf(delta * 14.0, 0.0, 1.0))

	if active and _damage_cooldown <= 0.0:
		var player := get_tree().get_first_node_in_group("player") as Player
		if player != null and not player.dead and player.global_position.distance_to(global_position) < 1.15:
			Combat.apply_hit(player, trap_damage, self, false)
			_damage_cooldown = 0.9
