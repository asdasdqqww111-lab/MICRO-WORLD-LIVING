class_name QuestBoardProp
extends Interactable
## Interactive Adventurers Guild Quest & Bounty Board.

func setup(label: String = "Inspect Guild Quest Board") -> void:
	prompt_text = label

func _ready() -> void:
	super._ready()
	if prompt_text == "Interact":
		prompt_text = "Inspect Guild Quest Board"
	interaction_radius = 2.8
	_build_visual()

func _build_visual() -> void:
	var wood_mat := ProceduralModels.make_material(Color(0.35, 0.23, 0.14), 0.88)
	var paper_mat := ProceduralModels.make_material(Color(0.90, 0.84, 0.68), 0.82)
	var gold_mat := ProceduralModels.make_material(Color(0.84, 0.66, 0.24), 0.42, 0.55)

	for sx: float in [-0.85, 0.85]:
		var post := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.09
		cyl.height = 2.1
		post.mesh = cyl
		post.position = Vector3(sx, 1.05, 0.0)
		post.material_override = wood_mat
		add_child(post)

	var board := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.85, 1.15, 0.12)
	board.mesh = box
	board.position = Vector3(0.0, 1.38, 0.0)
	board.material_override = wood_mat
	add_child(board)

	var roof := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(2.15, 0.36, 0.55)
	roof.mesh = prism
	roof.position = Vector3(0.0, 2.12, 0.0)
	roof.material_override = wood_mat
	add_child(roof)

	for p: Vector3 in [Vector3(-0.52, 1.45, 0.07), Vector3(0.0, 1.32, 0.07), Vector3(0.52, 1.46, 0.07), Vector3(-0.26, 1.12, 0.07), Vector3(0.32, 1.10, 0.07)]:
		var sheet := MeshInstance3D.new()
		var sbox := BoxMesh.new()
		sbox.size = Vector3(0.32, 0.38, 0.02)
		sheet.mesh = sbox
		sheet.position = p
		sheet.material_override = paper_mat
		add_child(sheet)

	var crest := MeshInstance3D.new()
	var cmesh := TorusMesh.new()
	cmesh.inner_radius = 0.10
	cmesh.outer_radius = 0.18
	crest.mesh = cmesh
	crest.rotation_degrees.x = 90.0
	crest.position = Vector3(0.0, 1.82, 0.08)
	crest.material_override = gold_mat
	add_child(crest)

func interact(_player: Node) -> void:
	EventBus.guild_board_opened.emit()
