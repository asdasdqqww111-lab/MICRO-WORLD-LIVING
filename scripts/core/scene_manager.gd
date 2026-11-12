extends Node
## Scene transitions with a small fade (autoload: SceneManager).

const MAIN_MENU := "res://scenes/main_menu/main_menu.tscn"
const GAME := "res://scenes/game/game.tscn"

var _busy: bool = false
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade()

func _build_fade() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 128
	_fade_layer.name = "FadeLayer"
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.02, 0.02, 0.03, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)

func is_busy() -> bool:
	return _busy

func change_scene(path: String, fade_time: float = 0.25) -> void:
	if _busy:
		return
	get_tree().paused = false
	_busy = true
	await _fade_to(1.0, fade_time)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneManager: failed to load %s (error %d)" % [path, err])
	_busy = false
	await get_tree().process_frame
	await _fade_to(0.0, fade_time)

func new_game() -> void:
	GameManager.start_new_game()
	await change_scene(GAME)

func continue_game() -> bool:
	if not SaveManager.load_game(SaveManager.DEFAULT_SLOT):
		return false
	await change_scene(GAME)
	return true

func go_to_main_menu() -> void:
	GameManager.is_playing = false
	await change_scene(MAIN_MENU)

func _fade_to(alpha: float, duration: float) -> void:
	if _fade_rect == null:
		return
	_fade_rect.visible = true
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", alpha, duration)
	await tween.finished
	_fade_rect.visible = alpha > 0.001

func quit_game() -> void:
	if SaveManager.has_save(SaveManager.DEFAULT_SLOT) and GameManager.is_playing:
		SaveManager.save_game(SaveManager.AUTOSAVE_SLOT)
	get_tree().quit()
