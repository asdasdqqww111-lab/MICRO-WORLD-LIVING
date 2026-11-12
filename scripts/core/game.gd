class_name Game
extends Node3D
## Game scene root: builds world + player + UI and applies pending save state.

var world: WorldRoot
var player: Player
var ui: UIRoot

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

	player = Player.new()
	player.name = "Player"
	add_child(player)

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
	player.camera_rig.yaw = player.rotation.y
	ui.hud.refresh_all()

func _connect() -> void:
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.player_level_up.connect(_on_level_up)
	EventBus.day_started.connect(_on_day_started)

func _process(delta: float) -> void:
	if not get_tree().paused:
		GameManager.play_time += delta

func _intro() -> void:
	var zone := player.zone
	match zone:
		"dungeon":
			EventBus.notify.emit("The cellar is cold and quiet...")
		"house":
			EventBus.notify.emit("Your house. Finally some quiet.")
		_:
			if GameManager.quest_log.entries.is_empty():
				EventBus.notify.emit("Talk to Mira the Farmer near the market")
				EventBus.notify.emit("Move: joystick / WASD   Look: drag   Attack: F / ATK")

func _on_quest_completed(quest_id: String) -> void:
	if SettingsManager.autosave_enabled:
		SaveManager.save_game(SaveManager.AUTOSAVE_SLOT)

func _on_level_up(level: int) -> void:
	EventBus.notify.emit("Level %d — open STAT to spend a skill point" % level)
	if SettingsManager.autosave_enabled:
		SaveManager.save_game(SaveManager.AUTOSAVE_SLOT)

func _on_day_started(day: int) -> void:
	EventBus.notify.emit("Day %d begins" % day)
	if SettingsManager.autosave_enabled:
		SaveManager.save_game(SaveManager.AUTOSAVE_SLOT)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if ui != null:
			ui.open_screen("pause")
