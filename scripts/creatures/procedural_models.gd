class_name ProceduralModels
extends RefCounted
## Original stylized fantasy creatures & material helpers.
## Everything faces +Z to match KayKit / Gobkit character conventions.

static func make_material(
	color: Color,
	roughness: float = 0.85,
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

static func _material(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	return make_material(color, roughness)

static func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, name: String = "Box") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = _material(color)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _sphere(parent: Node3D, radius: float, pos: Vector3, color: Color, name: String = "Sphere") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 8
	mi.mesh = mesh
	mi.material_override = _material(color, 0.55)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _build_slime() -> Node3D:
	var root := Node3D.new()
	root.name = "SlimeVisual"
	var body := _sphere(root, 0.55, Vector3(0.0, 0.42, 0.0), Color(0.32, 0.68, 0.34), "Body")
	body.scale = Vector3(1.0, 0.72, 0.95)
	_sphere(root, 0.075, Vector3(0.19, 0.55, 0.42), Color(0.08, 0.09, 0.1), "EyeL")
	_sphere(root, 0.075, Vector3(-0.19, 0.55, 0.42), Color(0.08, 0.09, 0.1), "EyeR")
	var drip := _sphere(root, 0.22, Vector3(0.0, 0.16, 0.02), Color(0.26, 0.58, 0.28), "Drip")
	drip.scale = Vector3(1.15, 0.45, 1.1)
	return root

static func _build_wolf() -> Node3D:
	var root := Node3D.new()
	root.name = "WolfVisual"
	var fur := Color(0.40, 0.38, 0.36)
	var dark := Color(0.26, 0.25, 0.24)
	_box(root, Vector3(0.46, 0.46, 1.15), Vector3(0.0, 0.72, 0.0), fur, "Body")
	_box(root, Vector3(0.4, 0.4, 0.42), Vector3(0.0, 0.86, 0.66), fur, "Head")
	_box(root, Vector3(0.2, 0.18, 0.28), Vector3(0.0, 0.8, 0.92), dark, "Snout")
	_box(root, Vector3(0.1, 0.16, 0.08), Vector3(0.14, 1.05, 0.6), dark, "EarL")
	_box(root, Vector3(0.1, 0.16, 0.08), Vector3(-0.14, 1.05, 0.6), dark, "EarR")
	for x: float in [0.18, -0.18]:
		for z: float in [0.42, -0.42]:
			_box(root, Vector3(0.13, 0.5, 0.13), Vector3(x, 0.25, z), dark, "Leg")
	var tail := _box(root, Vector3(0.1, 0.1, 0.5), Vector3(0.0, 0.78, -0.72), fur, "Tail")
	tail.rotation.x = -0.4
	return root

static func _build_stag() -> Node3D:
	var root := Node3D.new()
	root.name = "StagVisual"
	var coat := Color(0.56, 0.39, 0.24)
	var cream := Color(0.80, 0.73, 0.62)
	var antler := Color(0.82, 0.76, 0.64)
	_box(root, Vector3(0.48, 0.52, 1.28), Vector3(0.0, 0.96, 0.0), coat, "Body")
	var neck := _box(root, Vector3(0.26, 0.56, 0.28), Vector3(0.0, 1.32, 0.52), coat, "Neck")
	neck.rotation.x = 0.25
	_box(root, Vector3(0.28, 0.28, 0.44), Vector3(0.0, 1.56, 0.74), coat, "Head")
	_box(root, Vector3(0.22, 0.16, 0.18), Vector3(0.0, 1.02, -0.66), cream, "Tail")
	for sx: float in [0.18, -0.18]:
		for sz: float in [0.46, -0.46]:
			_box(root, Vector3(0.11, 0.72, 0.11), Vector3(sx, 0.36, sz), coat.darkened(0.18), "Leg")
		var beam := _box(root, Vector3(0.06, 0.46, 0.06), Vector3(sx * 1.15, 1.86, 0.66), antler, "Antler")
		beam.rotation.z = -sx * 1.35
		var tine := _box(root, Vector3(0.05, 0.26, 0.05), Vector3(sx * 1.65, 1.96, 0.76), antler, "Tine")
		tine.rotation.x = 0.55
	return root

## Smooth procedural animation for static/non-skeletal creature visuals.
static func animate(root: Node3D, visual_type: String, time: float, speed: float, y_offset: float = 0.0) -> void:
	if root == null:
		return
	match visual_type:
		"slime":
			var squash := 1.0 + sin(time * 6.0) * 0.06 + speed * 0.02
			root.scale = Vector3(1.0 / squash, squash, 1.0 / squash)
		"bat", "wraith":
			root.position.y = y_offset + sin(time * 5.2) * 0.14
			root.rotation.z = sin(time * 4.0) * 0.05
		"wolf", "stag", "goblin", "golem", "guardian":
			var freq := 4.5 + speed * 2.2
			var amp := 0.02 + clampf(speed * 0.012, 0.0, 0.06)
			root.position.y = y_offset + absf(sin(time * freq)) * amp
			root.rotation.z = sin(time * freq * 0.5) * (0.02 + clampf(speed * 0.01, 0.0, 0.04))
		_:
			pass
