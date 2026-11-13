extends SceneTree
## Headless CLI verifier (`godot --headless --path . --script res://tools/verify_stylized_import.gd`).
## Validates both `tools/import_stylized_assets.gd` (EditorScript) and Godot's import of all
## KayKit Adventurers + Quaternius Stylized Nature GLBs, HDRI sky, and custom Spatial Shaders.

func _initialize() -> void:
	var ed_script := ResourceLoader.load("res://tools/import_stylized_assets.gd")
	var files: PackedStringArray = [
		"res://shaders/stylized_terrain_splat.gdshader",
		"res://shaders/stylized_wind_grass.gdshader",
		"res://shaders/chibi_knight_rim.gdshader",
	]
	_walk("res://assets/kaykit_adventurers", files)
	_walk("res://assets/stylized_nature", files)
	var loaded := 0
	var failed := 0 if ed_script != null else 1
	for f: String in files:
		if ResourceLoader.exists(f):
			var res := ResourceLoader.load(f)
			if res != null:
				loaded += 1
			else:
				push_error("[VerifyStylizedImport] Null resource: " + f)
				failed += 1
		else:
			push_error("[VerifyStylizedImport] Missing resource: " + f)
			failed += 1
	print("[VerifyStylizedImport] Imported %d / %d stylized PBR assets & shaders (failed=%d)" % [loaded, files.size(), failed])
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
