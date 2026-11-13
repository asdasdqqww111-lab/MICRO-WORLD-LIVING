extends SceneTree
## Headless CLI verifier for Phase 2 Auto-Import (`godot --headless --path . -s res://tools/verify_realistic_import.gd`).
## Confirms Godot's Import System imported all realistic GLB models, PBR Normal/Roughness maps, and HDRI skies.

func _initialize() -> void:
	var ed_script := ResourceLoader.load("res://tools/auto_import_realistic_assets.gd")
	var files: PackedStringArray = []
	_walk("res://assets_realistic", files)
	var loaded := 0
	var failed := 0 if ed_script != null else 1
	for f: String in files:
		if ResourceLoader.exists(f):
			var res := ResourceLoader.load(f)
			if res != null:
				loaded += 1
			else:
				push_error("[VerifyImport] Null resource: " + f)
				failed += 1
		else:
			push_error("[VerifyImport] Missing from ResourceLoader: " + f)
			failed += 1
	print("[VerifyImport] Imported %d / %d assets from res://assets_realistic/ (failed=%d)" % [loaded, files.size(), failed])
	quit(0 if failed == 0 and loaded > 0 else 1)

func _walk(dir_path: String, out: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var full := dir_path + "/" + entry
			if dir.current_is_dir():
				_walk(full, out)
			elif not entry.ends_with(".import") and not entry.ends_with(".uid"):
				out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
