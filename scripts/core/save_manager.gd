extends Node
## Versioned JSON persistence (autoload: SaveManager).
##
## Layout of a save file:
##   { "schema_version": 3, "saved_at": "...", "game": {...GameManager...},
##     "player": {"position": [x,y,z], "rotation_y": r, "health": h, "stamina": s},
##     "meta": {"zone": "...", "version_name": "0.1"} }
##
## Migration rules live in `_migrate()`; unknown/newer versions are rejected
## instead of guessed at.

const DEFAULT_SLOT := "save_1"
const AUTOSAVE_SLOT := "autosave"
const SCHEMA_VERSION := 3
const SAVE_DIR := "user://saves"
const AUTOSAVE_INTERVAL := 120.0

var pending_state: Dictionary = {}
var _autosave_timer: float = 0.0
var last_save_error: String = ""

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	set_process(true)

func _process(delta: float) -> void:
	if not GameManager.is_playing or not SettingsManager.autosave_enabled:
		return
	if get_tree().paused:
		return
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_game(AUTOSAVE_SLOT)

func path_for(slot: String = DEFAULT_SLOT) -> String:
	return "%s/%s.json" % [SAVE_DIR, slot]

func has_save(slot: String = DEFAULT_SLOT) -> bool:
	return FileAccess.file_exists(path_for(slot))

func save_game(slot: String = DEFAULT_SLOT) -> bool:
	last_save_error = ""
	var payload := _gather_state()
	var json := JSON.stringify(payload, "\t")
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var final_path := path_for(slot)
	var tmp_path := final_path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		last_save_error = "cannot open %s (%s)" % [tmp_path, error_string(FileAccess.get_open_error())]
		push_error("SaveManager: " + last_save_error)
		return false
	file.store_string(json)
	file.close()
	# Atomic-ish replace so a crash mid-write cannot corrupt the previous save.
	var dir := DirAccess.open(SAVE_DIR)
	if dir != null and dir.file_exists(final_path.get_file()):
		dir.remove(final_path.get_file())
	var err := DirAccess.rename_absolute(tmp_path, final_path)
	if err != OK:
		last_save_error = "rename failed (%s)" % error_string(err)
		push_error("SaveManager: " + last_save_error)
		return false
	EventBus.game_saved.emit(slot)
	return true

func load_game(slot: String = DEFAULT_SLOT) -> bool:
	last_save_error = ""
	var path := path_for(slot)
	if not FileAccess.file_exists(path):
		last_save_error = "no save in slot '%s'" % slot
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_save_error = "cannot read %s" % path
		return false
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		last_save_error = "corrupt save (invalid JSON)"
		push_error("SaveManager: " + last_save_error)
		return false
	var data: Dictionary = parsed
	var version := int(data.get("schema_version", 1))
	if version > SCHEMA_VERSION:
		last_save_error = "save version %d is newer than supported %d" % [version, SCHEMA_VERSION]
		push_error("SaveManager: " + last_save_error)
		return false
	data = _migrate(data, version)
	var game: Dictionary = data.get("game", {})
	if game.is_empty():
		last_save_error = "save has no game payload"
		return false
	GameManager.apply_dict(game)
	pending_state = data
	EventBus.game_loaded.emit(slot)
	return true

## Called by the game scene once nodes exist.
func consume_pending() -> Dictionary:
	var state := pending_state
	pending_state = {}
	return state

func has_pending() -> bool:
	return not pending_state.is_empty()

func delete_save(slot: String = DEFAULT_SLOT) -> bool:
	var path := path_for(slot)
	if not FileAccess.file_exists(path):
		return false
	return DirAccess.remove_absolute(path) == OK

func save_slots() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return out
	for file_name: String in dir.get_files():
		if file_name.ends_with(".json"):
			out.append(file_name.get_basename())
	out.sort()
	return out

func _gather_state() -> Dictionary:
	var player_state: Dictionary = {}
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("to_save_dict"):
		player_state = player.call("to_save_dict") as Dictionary
	return {
		"schema_version": SCHEMA_VERSION,
		"saved_at": Time.get_datetime_string_from_system(true),
		"meta": {
			"zone": String(player_state.get("zone", "village")),
			"version_name": "0.1",
			"engine": Engine.get_version_info().get("string", ""),
		},
		"game": GameManager.to_dict(),
		"player": player_state,
	}

## v1 -> v2: added the skill tree payload.
## v2 -> v3: world clock/weather/raid state moved into game.world.
func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	var game: Dictionary = data.get("game", {})
	if from_version < 2:
		if not game.has("skills"):
			game["skills"] = {"ranks": {}, "points": 0}
	if from_version < 3:
		if not game.has("world"):
			game["world"] = WorldState.new().to_dict()
		if not data.has("meta"):
			data["meta"] = {"zone": "village", "version_name": "0.1"}
	data["game"] = game
	data["schema_version"] = SCHEMA_VERSION
	return data
