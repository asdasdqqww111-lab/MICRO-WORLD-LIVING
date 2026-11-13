class_name Game
extends Node3D
## Game scene root: builds Eldoria World + Knight Player + Fantasy UI and applies save state.

var world: WorldRoot
var player: Player
var ui: UIRoot
var vfx: VFXManager
var tower: TowerManager

func _ready() -> void:
	randomize()
	GameManager.is_playing = true
	_build()
	_apply_state()
	_connect()
	_intro()

func _build() -> void:
	world = WorldRoot.new()
	world.name = "World"
	add_child(world)

	tower = TowerManager.new()
	tower.name = "CelestialTower"
	tower.world = world
	add_child(tower)

	player = Player.new()
	player.name = "Player"
	add_child(player)

	vfx = VFXManager.new()
	vfx.setup(player)
	add_child(vfx)

	ui = UIRoot.new()
	ui.name = "UI"
	ui.setup(player, world)
	add_child(ui)

func _apply_state() -> void:
	var pending := SaveManager.consume_pending()
	player.set_spawn_position(world.spawn_point)
	if pending.is_empty():
		player.global_position = world.player_spawn_point()
		player.set_zone(GameManager.pending_zone if not GameManager.pending_zone.is_empty() else "village")
		GameManager.pending_zone = player.zone
	else:
		var player_state: Dictionary = pending.get("player", {})
		if player_state.is_empty():
			player.global_position = world.player_spawn_point()
		else:
			player.apply_save_state(player_state)
	# Restore the tower floor when the save says the player was inside.
	if tower != null and player.zone == "tower":
		tower.restore_after_load(player)
	player.camera_rig.snap_to_parent()
	player.camera_rig.yaw = player.rotation.y
	world._apply_zone_visibility(player.zone)
	ui.hud.refresh_all()

func _connect() -> void:
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.player_level_up.connect(_on_level_up)
	EventBus.day_started.connect(_on_day_started)

func _process(delta: float) -> void:
	if not get_tree().paused:
		GameManager.play_time += delta

func _intro() -> void:
	match player.zone:
		"dungeon":
			EventBus.notify.emit("Cold ancient air rises from the Sunken Crypt...")
		"guild":
			EventBus.notify.emit("Grand Hall of the Eldoria Adventurers Guild")
		"house":
			EventBus.notify.emit("Your Eldoria Cottage")
		"tower":
			if tower != null and tower.active_floor() > 0:
				var ar := Localization.is_arabic()
				EventBus.notify.emit("استأنفت الصعود — الطابق %d" % tower.active_floor() if ar else "The ascent resumes — Floor %d" % tower.active_floor())
		_:
			if GameManager.quest_log.entries.is_empty():
				EventBus.notify.emit(Localization.tr_key("welcome_eldoria"))

func _on_quest_completed(_quest_id: String) -> void:
	if SettingsManager.autosave_enabled:
		SaveManager.save_game(SaveManager.AUTOSAVE_SLOT)

func _on_level_up(level: int) -> void:
	EventBus.notify.emit("Level %d reached — open SKILLS to unlock abilities!" % level)
	if SettingsManager.autosave_enabled:
		SaveManager.save_game(SaveManager.AUTOSAVE_SLOT)

func _on_day_started(day: int) -> void:
	EventBus.notify.emit("Dawn breaks over Eldoria — Day %d" % day)
	if SettingsManager.autosave_enabled:
		SaveManager.save_game(SaveManager.AUTOSAVE_SLOT)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if ui != null:
			ui.open_screen("pause")
