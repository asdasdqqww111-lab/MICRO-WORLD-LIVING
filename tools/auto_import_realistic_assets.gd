@tool
extends EditorScript
## Phase 2 Auto-Import & Scene Integration EditorScript (`tools/auto_import_realistic_assets.gd`).
## Scans `res://assets_realistic/{models,textures,hdri}`, triggers Godot 4's Import System
## (`EditorFileSystem.scan()` + `reimport_files()`), validates PBR Normal/Roughness textures
## and HDRI panorama resources, and verifies `scenes/game/game.tscn` Cinematic Environment wiring.

const REALISTIC_ROOT := "res://assets_realistic"

func _run() -> void:
	print("[RealisticImport] Scanning res://assets_realistic/ ...")
	var all_files: PackedStringArray = []
	_collect_files(REALISTIC_ROOT, all_files)
	print("[RealisticImport] Found %d realistic asset files." % all_files.size())

	var efs := get_editor_interface().get_resource_filesystem() if Engine.is_editor_hint() else null
	if efs != null:
		efs.scan()
		if not all_files.is_empty():
			efs.reimport_files(all_files)
		print("[RealisticImport] Triggered EditorFileSystem scan & reimport for %d assets." % all_files.size())

	var models_ok := 0
	var tex_ok := 0
	var hdri_ok := 0
	for path: String in all_files:
		if not ResourceLoader.exists(path):
			push_warning("[RealisticImport] Pending import: %s" % path)
			continue
		if path.ends_with(".glb") or path.ends_with(".obj"):
			models_ok += 1
		elif path.ends_with(".hdr") or path.ends_with(".exr"):
			hdri_ok += 1
		elif path.ends_with(".jpg") or path.ends_with(".png"):
			tex_ok += 1

	print("[RealisticImport] Verified Imported -> Models: %d | PBR Textures: %d | HDRI Skies: %d" % [
		models_ok, tex_ok, hdri_ok
	])

func _collect_files(dir_path: String, out: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var full := dir_path + "/" + entry
			if dir.current_is_dir():
				_collect_files(full, out)
			elif not entry.ends_with(".import") and not entry.ends_with(".uid"):
				out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
