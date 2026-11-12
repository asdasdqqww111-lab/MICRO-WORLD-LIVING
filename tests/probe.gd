extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	# Autoloads are absent in --script mode; the world scene builds itself.
	var packed: PackedScene = load("res://scenes/world/world.tscn")
	var world: Node = packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var multimeshes: Array = []
	var mesh_instances := 0
	var null_meshes := 0
	_collect(world, multimeshes)
	for mm: MultiMeshInstance3D in multimeshes:
		var mesh: Mesh = mm.multimesh.mesh if mm.multimesh != null else null
		print("MM %s count=%d mesh=%s" % [mm.name, mm.multimesh.instance_count if mm.multimesh != null else -1, mesh.resource_path if mesh != null else "NULL"])
	print("multimesh nodes: ", multimeshes.size())
	quit()

func _collect(node: Node, found: Array) -> void:
	if node is MultiMeshInstance3D:
		found.append(node)
	for child: Node in node.get_children():
		_collect(child, found)
