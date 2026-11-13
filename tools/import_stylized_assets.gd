@tool
extends EditorScript
## Scans and verifies the cloned CC0 Stylized/Chibi PBR Mobile asset packs:
##   - KayKit Character Pack: Adventures 1.0 (`res://assets/kaykit_adventurers/`)
##   - Quaternius Stylized Nature Pack (`res://assets/stylized_nature/`)

const REQUIRED_STYLIZED_ASSETS := [
	"res://assets/kaykit_adventurers/Knight.glb",
	"res://assets/kaykit_adventurers/knight_texture.png",
	"res://assets/stylized_nature/trees/PineTree_1.glb",
	"res://assets/stylized_nature/trees/PineTree_2.glb",
	"res://assets/stylized_nature/trees/PineTree_3.glb",
	"res://assets/stylized_nature/trees/PineTree_4.glb",
	"res://assets/stylized_nature/rocks/Rock_1.glb",
	"res://assets/stylized_nature/rocks/Rock_2.glb",
	"res://assets/stylized_nature/rocks/Rock_3.glb",
	"res://assets/stylized_nature/rocks/Rock_4.glb",
	"res://assets/stylized_nature/foliage/Flowers.glb",
	"res://assets/stylized_nature/foliage/Grass.glb",
	"res://assets/stylized_nature/stylized_meadow_sky_1k.hdr",
]

func _run() -> void:
	var fs := get_editor_interface().get_resource_filesystem() if Engine.is_editor_hint() else null
	if fs != null:
		fs.scan()
	var ok_count := 0
	for path: String in REQUIRED_STYLIZED_ASSETS:
		if ResourceLoader.exists(path):
			ok_count += 1
			print("[StylizedImport] Verified: ", path)
		else:
			push_warning("[StylizedImport] Missing: " + path)
	print("[StylizedImport] Verified %d / %d stylized PBR assets." % [ok_count, REQUIRED_STYLIZED_ASSETS.size()])
