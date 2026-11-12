class_name ProceduralModels
extends RefCounted
## Original low-poly creatures built from primitives (no external downloads
## needed for Quaternius' creature pack, which is unreachable from CI).
## Everything faces +Z to match the KayKit models.

static func build(visual_type: String) -> Node3D:
	match visual_type:
		"slime":
			return _build_slime()
		"wolf":
			return _build_wolf()
		_:
			var empty := Node3D.new()
			empty.name = "EmptyVisual"
			return empty

static func _material(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat

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
	var body := _sphere(root, 0.55, Vector3(0.0, 0.42, 0.0), Color(0.36, 0.78, 0.32), "Body")
	body.scale = Vector3(1.0, 0.72, 0.95)
	# Eyes on +Z (forward).
	_sphere(root, 0.075, Vector3(0.19, 0.55, 0.42), Color(0.08, 0.09, 0.1), "EyeL")
	_sphere(root, 0.075, Vector3(-0.19, 0.55, 0.42), Color(0.08, 0.09, 0.1), "EyeR")
	var drip := _sphere(root, 0.22, Vector3(0.0, 0.16, 0.02), Color(0.3, 0.68, 0.27), "Drip")
	drip.scale = Vector3(1.15, 0.45, 1.1)
	return root

static func _build_wolf() -> Node3D:
	var root := Node3D.new()
	root.name = "WolfVisual"
	var fur := Color(0.42, 0.4, 0.38)
	var dark := Color(0.28, 0.27, 0.26)
	var body := _box(root, Vector3(0.46, 0.46, 1.15), Vector3(0.0, 0.72, 0.0), fur, "Body")
	body.rotation.x = 0.0
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

## Cheap procedural idle animation (used because these meshes have no skeleton).
static func animate(root: Node3D, visual_type: String, time: float, speed: float) -> void:
	if root == null:
		return
	match visual_type:
		"slime":
			var squash := 1.0 + sin(time * 6.0) * 0.06 + speed * 0.02
			root.scale = Vector3(1.0 / squash, squash, 1.0 / squash)
		"wolf":
			var bob := sin(time * (6.0 + speed * 2.0)) * 0.035
			root.position.y = absf(bob)
			root.rotation.z = sin(time * 7.0) * 0.02
		_:
			pass
