class_name ResourceNode
extends Interactable
## Harvestable overworld resource node (Iron Ore vein, Timber log, Redcap / Moonpetal herb).
## Extends Interactable for unified proximity interaction & headless testability.

var node_uid: String = ""
var resource_kind: String = "ore"   # "ore", "wood", "herb", "moonpetal"
var item_id: String = "iron_ore"
var base_yield: int = 2
var _visual_root: Node3D
var _depleted: bool = false

func setup(uid: String, kind: String, reward_item: String, label: String, amount: int = 2) -> void:
	node_uid = uid
	resource_kind = kind
	item_id = reward_item
	prompt_text = label
	base_yield = amount

func _ready() -> void:
	super._ready()
	add_to_group("resource_node")
	interaction_radius = 2.6
	_build_visual()
	refresh_state()

func _build_visual() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "Visual"
	add_child(_visual_root)

	match resource_kind:
		"ore":
			var rock := AssetLibrary.instantiate_gltfs([
				"res://assets/environments/mountains/rock-largeb.glb",
				"res://assets/environments/mountains/rock-talla.glb",
			], 1.15)
			if rock != null:
				_visual_root.add_child(rock)
			var crystal := MeshInstance3D.new()
			var prism := PrismMesh.new()
			prism.size = Vector3(0.38, 0.62, 0.34)
			crystal.mesh = prism
			crystal.position = Vector3(0.18, 0.45, 0.12)
			crystal.rotation_degrees = Vector3(14.0, 28.0, -18.0)
			crystal.material_override = ProceduralModels.make_material(
				Color(0.68, 0.76, 0.88), 0.32, 0.65, Color(0.24, 0.38, 0.56), 0.35)
			_visual_root.add_child(crystal)
		"wood":
			var stump := AssetLibrary.instantiate_gltfs([
				"res://assets/environments/forests/log-large.glb",
				"res://assets/environments/forests/stump-old.glb",
			], 1.45)
			if stump != null:
				_visual_root.add_child(stump)
		"moonpetal":
			var fl := AssetLibrary.instantiate_gltfs([
				"res://assets/environments/forests/flower-purplea.glb",
			], 1.75)
			if fl != null:
				_visual_root.add_child(fl)
		_:
			var shroom := AssetLibrary.instantiate_gltfs([
				"res://assets/environments/forests/mushroom-redgroup.glb",
				"res://assets/environments/forests/flower-reda.glb",
			], 1.75)
			if shroom != null:
				_visual_root.add_child(shroom)

func refresh_state() -> void:
	_depleted = not node_uid.is_empty() and GameManager.world.is_harvested_today(node_uid)
	enabled = not _depleted
	if _visual_root != null:
		_visual_root.visible = not _depleted

func can_interact(_player: Node) -> bool:
	return not _depleted

func prompt_for(_player: Node) -> String:
	match resource_kind:
		"ore": return "Mine %s" % prompt_text
		"wood": return "Chop %s" % prompt_text
		_: return "Harvest %s" % prompt_text

func interact(_player: Node) -> void:
	if _depleted:
		return
	var bonus := GameManager.skills.gather_extra_yield()
	var amount := maxi(1, base_yield + bonus)
	if GameManager.inventory.is_full() and GameManager.inventory.count_item(item_id) == 0:
		EventBus.notify.emit("Inventory full!")
		return
	GameManager.world.mark_harvested(node_uid)
	GameManager.gain_item(item_id, amount)
	GameManager.gain_xp(10)
	if AudioManager != null:
		match resource_kind:
			"ore": AudioManager.play_sfx("gather_mine")
			"wood": AudioManager.play_sfx("gather_chop")
			_: AudioManager.play_sfx("gather_herb")
	refresh_state()
