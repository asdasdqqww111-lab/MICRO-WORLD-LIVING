class_name CraftingStation
extends Interactable
## Interactive Blacksmith Anvil Forge or Alchemy Bench.

var station_type: String = "forge"

func setup(kind: String, title: String) -> void:
	station_type = kind
	prompt_text = "Use %s" % title

func _ready() -> void:
	super._ready()
	interaction_radius = 2.6
	_build_visual()

func _build_visual() -> void:
	var root := Node3D.new()
	add_child(root)
	if station_type == "alchemy":
		var table := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.5, 0.85, 0.85)
		table.mesh = box
		table.position = Vector3(0.0, 0.425, 0.0)
		table.material_override = ProceduralModels.make_material(Color(0.36, 0.24, 0.15), 0.88)
		root.add_child(table)
		var bottle := AssetLibrary.instantiate("res://assets/weapons/mug_full.gltf", 1.1)
		if bottle != null:
			bottle.position = Vector3(-0.25, 0.86, 0.0)
			root.add_child(bottle)
		var candle := AssetLibrary.instantiate("res://assets/models/dungeon/candle_lit.glb", 1.0)
		if candle != null:
			candle.position = Vector3(0.32, 0.86, 0.1)
			root.add_child(candle)
	else:
		var base := MeshInstance3D.new()
		var bmesh := BoxMesh.new()
		bmesh.size = Vector3(1.4, 0.55, 1.0)
		base.mesh = bmesh
		base.position = Vector3(0.0, 0.275, 0.0)
		base.material_override = ProceduralModels.make_material(Color(0.34, 0.33, 0.35), 0.92)
		root.add_child(base)

		var anvil := MeshInstance3D.new()
		var amesh := BoxMesh.new()
		amesh.size = Vector3(0.75, 0.42, 0.36)
		anvil.mesh = amesh
		anvil.position = Vector3(0.0, 0.72, 0.0)
		anvil.material_override = ProceduralModels.make_material(Color(0.24, 0.26, 0.30), 0.45, 0.75)
		root.add_child(anvil)

		var glow := OmniLight3D.new()
		glow.light_color = Color(1.0, 0.48, 0.16)
		glow.light_energy = 1.15
		glow.omni_range = 4.2
		glow.shadow_enabled = false
		glow.position = Vector3(0.0, 1.05, 0.0)
		root.add_child(glow)

func interact(_player: Node) -> void:
	EventBus.crafting_opened.emit(station_type)
