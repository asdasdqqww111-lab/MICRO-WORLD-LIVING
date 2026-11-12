class_name ProceduralModels
extends RefCounted
## Articulated, multi-part stylized 3D fantasy creatures & material helpers.
## All creatures face +Z to match KayKit / Gobkit character conventions and animate
## limbs, tails, and cores procedurally with zero extra shadow-pass draw calls.

static func make_material(
	color: Color,
	roughness: float = 0.82,
	metallic: float = 0.0,
	emission: Color = Color.BLACK,
	emission_energy: float = 0.0
) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat

static func build(visual_type: String) -> Node3D:
	match visual_type:
		"slime":
			return _build_slime()
		"wolf":
			return _build_wolf()
		"stag":
			return _build_stag()
		_:
			var empty := Node3D.new()
			empty.name = "EmptyVisual"
			return empty

static func _material(color: Color, roughness: float = 0.82) -> StandardMaterial3D:
	return make_material(color, roughness)

static func _part_mesh(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

static func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, node_name: String = "Box") -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _part_mesh(parent, mesh, pos, _material(color), node_name)

static func _capsule(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, node_name: String) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 4
	return _part_mesh(parent, mesh, pos, mat, node_name)

static func _sphere(parent: Node3D, radius: float, pos: Vector3, color: Color, node_name: String = "Sphere") -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 8
	return _part_mesh(parent, mesh, pos, _material(color, 0.45), node_name)

static func _build_slime() -> Node3D:
	var root := Node3D.new()
	root.name = "SlimeVisual"

	# Translucent emerald outer jelly dome
	var outer_mat := StandardMaterial3D.new()
	outer_mat.albedo_color = Color(0.24, 0.78, 0.42, 0.78)
	outer_mat.roughness = 0.22
	outer_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var dome_mesh := SphereMesh.new()
	dome_mesh.radius = 0.56
	dome_mesh.height = 1.04
	dome_mesh.radial_segments = 14
	dome_mesh.rings = 8
	var body := _part_mesh(root, dome_mesh, Vector3(0.0, 0.44, 0.0), outer_mat, "Body")
	body.scale = Vector3(1.04, 0.80, 1.0)

	# Glowing inner arcane nucleus
	var core_mat := make_material(Color(0.55, 1.0, 0.66), 0.3, 0.0, Color(0.30, 0.95, 0.52), 1.35)
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.22
	core_mesh.height = 0.44
	_part_mesh(root, core_mesh, Vector3(0.0, 0.42, 0.02), core_mat, "Core")

	# Expressive dark eyes + white specular highlights
	_sphere(root, 0.075, Vector3(0.19, 0.54, 0.44), Color(0.07, 0.09, 0.11), "EyeL")
	_sphere(root, 0.075, Vector3(-0.19, 0.54, 0.44), Color(0.07, 0.09, 0.11), "EyeR")
	_sphere(root, 0.026, Vector3(0.21, 0.57, 0.50), Color(0.95, 0.98, 1.0), "ShineL")
	_sphere(root, 0.026, Vector3(-0.17, 0.57, 0.50), Color(0.95, 0.98, 1.0), "ShineR")

	var base := _sphere(root, 0.34, Vector3(0.0, 0.12, 0.0), Color(0.20, 0.62, 0.34), "BaseRipple")
	base.scale = Vector3(1.55, 0.28, 1.48)
	return root

static func _build_articulated_leg(parent: Node3D, pivot_name: String, hip_pos: Vector3,
		upper_r: float, len_y: float, upper_mat: Material, paw_mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = pivot_name
	pivot.position = hip_pos
	parent.add_child(pivot)
	_capsule(pivot, upper_r, len_y, Vector3(0.0, -len_y * 0.48, 0.0), upper_mat, "Limb")
	var paw := _box(pivot, Vector3(upper_r * 2.1, 0.10, upper_r * 2.6), Vector3(0.0, -len_y + 0.05, 0.04), Color.WHITE, "Paw")
	paw.material_override = paw_mat
	return pivot

static func _build_wolf() -> Node3D:
	var root := Node3D.new()
	root.name = "WolfVisual"
	var fur_mat := _material(Color(0.36, 0.36, 0.39), 0.84)
	var ruff_mat := _material(Color(0.54, 0.53, 0.55), 0.86)
	var dark_mat := _material(Color(0.22, 0.22, 0.25), 0.88)
	var eye_mat := make_material(Color(1.0, 0.72, 0.18), 0.3, 0.0, Color(1.0, 0.62, 0.12), 1.4)

	# Muscular chest + tapered hindquarters + thick shoulder ruff
	var chest := _capsule(root, 0.27, 0.86, Vector3(0.0, 0.72, 0.22), fur_mat, "Chest")
	chest.rotation.x = PI * 0.5
	var hindquarters := _capsule(root, 0.22, 0.78, Vector3(0.0, 0.68, -0.30), fur_mat, "Haunches")
	hindquarters.rotation.x = PI * 0.5
	var ruff := _capsule(root, 0.30, 0.56, Vector3(0.0, 0.80, 0.44), ruff_mat, "NeckRuff")
	ruff.rotation.x = 0.95

	# Head, snout, fangs, glowing amber eyes & pointed ears
	var head_pivot := Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0.0, 0.92, 0.68)
	root.add_child(head_pivot)
	_sphere(head_pivot, 0.22, Vector3.ZERO, Color(0.38, 0.38, 0.41), "Skull")
	var snout := _capsule(head_pivot, 0.11, 0.38, Vector3(0.0, -0.05, 0.22), dark_mat, "Snout")
	snout.rotation.x = PI * 0.5
	_sphere(head_pivot, 0.045, Vector3(0.0, -0.02, 0.40), Color(0.08, 0.08, 0.09), "Nose")
	_part_mesh(head_pivot, SphereMesh.new(), Vector3(0.11, 0.05, 0.17), eye_mat, "EyeL").scale = Vector3.ONE * 0.08
	_part_mesh(head_pivot, SphereMesh.new(), Vector3(-0.11, 0.05, 0.17), eye_mat, "EyeR").scale = Vector3.ONE * 0.08

	for sx: float in [1.0, -1.0]:
		var ear := _box(head_pivot, Vector3(0.09, 0.20, 0.08), Vector3(sx * 0.13, 0.21, -0.02), Color(0.24, 0.24, 0.27), "Ear")
		ear.rotation = Vector3(0.18, 0.0, -sx * 0.22)

	# 4 Articulated Galloping Legs
	_build_articulated_leg(root, "LegFL", Vector3(0.17, 0.58, 0.40), 0.075, 0.58, fur_mat, dark_mat)
	_build_articulated_leg(root, "LegFR", Vector3(-0.17, 0.58, 0.40), 0.075, 0.58, fur_mat, dark_mat)
	_build_articulated_leg(root, "LegBL", Vector3(0.17, 0.58, -0.38), 0.080, 0.58, fur_mat, dark_mat)
	_build_articulated_leg(root, "LegBR", Vector3(-0.17, 0.58, -0.38), 0.080, 0.58, fur_mat, dark_mat)

	# Bushy Articulated Tail
	var tail_pivot := Node3D.new()
	tail_pivot.name = "TailPivot"
	tail_pivot.position = Vector3(0.0, 0.74, -0.62)
	root.add_child(tail_pivot)
	var tail := _capsule(tail_pivot, 0.085, 0.56, Vector3(0.0, -0.10, -0.22), ruff_mat, "Tail")
	tail.rotation.x = -1.05
	return root

static func _build_stag() -> Node3D:
	var root := Node3D.new()
	root.name = "StagVisual"
	var coat_mat := _material(Color(0.58, 0.39, 0.23), 0.82)
	var cream_mat := _material(Color(0.85, 0.78, 0.66), 0.85)
	var hoof_mat := _material(Color(0.22, 0.17, 0.14), 0.88)
	var antler_mat := _material(Color(0.88, 0.82, 0.70), 0.72)

	# Sculpted torso + cream chest/underbelly
	var torso := _capsule(root, 0.27, 1.24, Vector3(0.0, 0.96, 0.0), coat_mat, "Torso")
	torso.rotation.x = PI * 0.5
	var belly := _capsule(root, 0.21, 1.02, Vector3(0.0, 0.84, 0.06), cream_mat, "Belly")
	belly.rotation.x = PI * 0.5

	# Graceful arched neck + head + royal branching antlers
	var neck_pivot := Node3D.new()
	neck_pivot.name = "HeadPivot"
	neck_pivot.position = Vector3(0.0, 1.12, 0.48)
	root.add_child(neck_pivot)
	var neck := _capsule(neck_pivot, 0.14, 0.58, Vector3(0.0, 0.22, 0.10), coat_mat, "Neck")
	neck.rotation.x = 0.32
	var head := _capsule(neck_pivot, 0.13, 0.44, Vector3(0.0, 0.46, 0.28), coat_mat, "Head")
	head.rotation.x = PI * 0.48
	_sphere(neck_pivot, 0.042, Vector3(0.0, 0.44, 0.50), Color(0.14, 0.11, 0.10), "Nose")
	_sphere(neck_pivot, 0.038, Vector3(0.11, 0.50, 0.28), Color(0.10, 0.09, 0.09), "EyeL")
	_sphere(neck_pivot, 0.038, Vector3(-0.11, 0.50, 0.28), Color(0.10, 0.09, 0.09), "EyeR")

	for sx: float in [1.0, -1.0]:
		var ear := _box(neck_pivot, Vector3(0.16, 0.07, 0.06), Vector3(sx * 0.18, 0.54, 0.16), Color(0.52, 0.34, 0.20), "Ear")
		ear.rotation.z = -sx * 0.35
		var beam := _capsule(neck_pivot, 0.030, 0.54, Vector3(sx * 0.18, 0.76, 0.14), antler_mat, "AntlerBeam")
		beam.rotation = Vector3(-0.18, 0.0, -sx * 0.52)
		var tine1 := _capsule(neck_pivot, 0.022, 0.30, Vector3(sx * 0.26, 0.80, 0.26), antler_mat, "TineFront")
		tine1.rotation = Vector3(0.65, 0.0, -sx * 0.25)
		var tine2 := _capsule(neck_pivot, 0.022, 0.28, Vector3(sx * 0.32, 0.94, 0.10), antler_mat, "TineCrown")
		tine2.rotation = Vector3(-0.15, 0.0, -sx * 0.18)

	# 4 Slender Articulated Legs
	_build_articulated_leg(root, "LegFL", Vector3(0.17, 0.78, 0.44), 0.062, 0.78, coat_mat, hoof_mat)
	_build_articulated_leg(root, "LegFR", Vector3(-0.17, 0.78, 0.44), 0.062, 0.78, coat_mat, hoof_mat)
	_build_articulated_leg(root, "LegBL", Vector3(0.17, 0.78, -0.44), 0.068, 0.78, coat_mat, hoof_mat)
	_build_articulated_leg(root, "LegBR", Vector3(-0.17, 0.78, -0.44), 0.068, 0.78, coat_mat, hoof_mat)

	var tail_pivot := Node3D.new()
	tail_pivot.name = "TailPivot"
	tail_pivot.position = Vector3(0.0, 1.04, -0.60)
	root.add_child(tail_pivot)
	_capsule(tail_pivot, 0.065, 0.24, Vector3(0.0, 0.02, -0.08), cream_mat, "TailTuft")
	return root

## Smooth articulated animation for quadrupeds, slimes, flyers, and non-skeletal monsters.
static func animate(root: Node3D, visual_type: String, time: float, speed: float, y_offset: float = 0.0) -> void:
	if root == null:
		return
	match visual_type:
		"slime":
			var squash := 1.0 + sin(time * 6.2) * 0.08 + clampf(speed * 0.03, 0.0, 0.14)
			root.scale = Vector3(1.0 / sqrt(squash), squash, 1.0 / sqrt(squash))
			var core := root.get_node_or_null("Core") as Node3D
			if core != null:
				core.position.y = 0.42 + sin(time * 4.5) * 0.05
		"wolf", "stag":
			var moving := clampf(speed / 3.6, 0.0, 1.35)
			var freq := 8.5 if visual_type == "wolf" else 7.8
			var stride := sin(time * freq) * 0.62 * moving
			var fl := root.get_node_or_null("LegFL") as Node3D
			var fr := root.get_node_or_null("LegFR") as Node3D
			var bl := root.get_node_or_null("LegBL") as Node3D
			var br := root.get_node_or_null("LegBR") as Node3D
			if fl != null: fl.rotation.x = stride
			if br != null: br.rotation.x = stride
			if fr != null: fr.rotation.x = -stride
			if bl != null: bl.rotation.x = -stride
			var tail := root.get_node_or_null("TailPivot") as Node3D
			if tail != null:
				tail.rotation.y = sin(time * 5.2) * (0.18 + moving * 0.16)
			var head := root.get_node_or_null("HeadPivot") as Node3D
			if head != null:
				head.rotation.x = sin(time * 2.4) * 0.06 - moving * 0.08
			root.position.y = y_offset + absf(sin(time * freq)) * (0.045 * moving)
		"bat", "wraith":
			root.position.y = y_offset + sin(time * 5.6) * 0.16
			root.rotation.z = sin(time * 4.2) * 0.06
		"goblin", "golem", "guardian":
			var freq := 4.8 + speed * 2.2
			var amp := 0.02 + clampf(speed * 0.014, 0.0, 0.07)
			root.position.y = y_offset + absf(sin(time * freq)) * amp
			root.rotation.z = sin(time * freq * 0.5) * (0.02 + clampf(speed * 0.012, 0.0, 0.05))
		_:
			pass
