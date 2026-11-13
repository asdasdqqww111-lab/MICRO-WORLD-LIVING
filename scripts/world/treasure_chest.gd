class_name TreasureChest
extends Interactable

var uid: String = ""
var loot: Array = []
var opened: bool = false
var _visual: Node3D

func setup(container_uid: String, contents: Array) -> void:
	uid = container_uid
	loot = contents

func _ready() -> void:
	super._ready()
	interaction_radius = 2.4
	prompt_text = "Open chest"
	_build_visual()
	if GameManager.world.is_looted(uid):
		opened = true
		prompt_text = "Empty chest"
		_tint(Color(0.45, 0.45, 0.45))

func _build_visual() -> void:
	_visual = AssetLibrary.instantiate(AssetLibrary.DUNGEON_DIR + "chest.glb", 0.9)
	if _visual != null:
		_visual.name = "ChestModel"
		add_child(_visual)
	else:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.2, 0.8, 0.9)
		mi.mesh = box
		add_child(mi)
		_visual = mi

func prompt_for(_player: Node) -> String:
	if Localization.is_arabic():
		return "صندوق فارغ" if opened else "فتح صندوق الكنز"
	return prompt_text

func interact(_player: Node) -> void:
	if opened:
		EventBus.notify.emit("الصندوق فارغ" if Localization.is_arabic() else "The chest is empty")
		return
	opened = true
	prompt_text = "Empty chest"
	GameManager.world.mark_looted(uid)
	for entry: Dictionary in loot:
		GameManager.gain_item(String(entry.get("id", "")), int(entry.get("count", 1)))
	_tint(Color(0.4, 0.4, 0.42))
	if AudioManager != null:
		AudioManager.play_sfx("chest_open")
	EventBus.notify.emit("تم فتح صندوق الكنز!" if Localization.is_arabic() else "Chest opened")

func _tint(color: Color) -> void:
	if _visual == null:
		return
	_tint_recursive(_visual, color)

func _tint_recursive(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var base := mi.get_active_material(0)
		if base is StandardMaterial3D:
			var mat := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
			mat.albedo_color = color
			mi.material_override = mat
	for child: Node in node.get_children():
		_tint_recursive(child, color)
