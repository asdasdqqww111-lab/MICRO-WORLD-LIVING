class_name UIRoot
extends CanvasLayer
## Owns every UI screen & HUD and manages modal pause transitions.

var hud: HUD
var touch: TouchControls
var dialog: DialogScreen
var inventory: InventoryScreen
var skills_screen: SkillTreeScreen
var guild_screen: GuildScreen
var crafting_screen: CraftingScreen
var map_screen: WorldMapScreen
var journal: JournalScreen
var character: CharacterScreen
var shop: ShopScreen
var pause_menu: PauseScreen

var player: Player
var world: WorldRoot
var current_screen: MenuScreen = null
var _screens: Dictionary = {}

func setup(p: Player, w: WorldRoot) -> void:
	player = p
	world = w

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_connect()

func _build() -> void:
	hud = HUD.new()
	hud.name = "HUD"
	hud.setup(player)
	add_child(hud)

	touch = TouchControls.new()
	touch.name = "TouchControls"
	add_child(touch)
	if player != null and player.camera_rig != null:
		touch.look_dragged.connect(player.camera_rig.add_look)
		touch.zoom_requested.connect(player.camera_rig.set_zoom_factor)
		player.input.bind_touch_controls(touch)

	inventory = InventoryScreen.new()
	inventory.name = "InventoryScreen"
	inventory.world = world
	inventory.player = player
	add_child(inventory)

	skills_screen = SkillTreeScreen.new()
	skills_screen.name = "SkillTreeScreen"
	add_child(skills_screen)

	guild_screen = GuildScreen.new()
	guild_screen.name = "GuildScreen"
	add_child(guild_screen)

	crafting_screen = CraftingScreen.new()
	crafting_screen.name = "CraftingScreen"
	add_child(crafting_screen)

	map_screen = WorldMapScreen.new()
	map_screen.name = "WorldMapScreen"
	map_screen.player = player
	add_child(map_screen)

	journal = JournalScreen.new()
	journal.name = "JournalScreen"
	add_child(journal)

	character = CharacterScreen.new()
	character.name = "CharacterScreen"
	add_child(character)

	shop = ShopScreen.new()
	shop.name = "ShopScreen"
	add_child(shop)

	pause_menu = PauseScreen.new()
	pause_menu.name = "PauseScreen"
	add_child(pause_menu)

	_screens = {
		"inventory": inventory,
		"skills": skills_screen,
		"guild": guild_screen,
		"crafting": crafting_screen,
		"map": map_screen,
		"journal": journal,
		"character": character,
		"shop": shop,
		"pause": pause_menu,
	}
	for key: String in _screens:
		var screen := _screens[key] as MenuScreen
		screen.closed.connect(_on_screen_closed)

	dialog = DialogScreen.new()
	dialog.name = "DialogScreen"
	add_child(dialog)
	dialog.closed.connect(_refresh_pause_state)

func _connect() -> void:
	hud.quick_menu_pressed.connect(toggle_screen)
	touch.menu_action.connect(_on_menu_action)
	character.open_skill_tree_requested.connect(func() -> void: open_screen("skills"))
	EventBus.dialog_requested.connect(_on_dialog_requested)
	EventBus.shop_requested.connect(_on_shop_requested)
	EventBus.guild_board_opened.connect(func() -> void:
		if dialog.visible:
			dialog.close()
		open_screen("guild"))
	EventBus.crafting_opened.connect(func(station_kind: String) -> void:
		if dialog.visible:
			dialog.close()
		crafting_screen.station_filter = station_kind if not station_kind.is_empty() else "all"
		open_screen("crafting"))
	EventBus.screen_changed.connect(func(scr_name: String) -> void:
		if scr_name == "request_skills":
			if dialog.visible:
				dialog.close()
			open_screen("skills"))
	EventBus.player_died.connect(_on_player_died)
	inventory.item_used.connect(_on_item_used)
	pause_menu.request_main_menu.connect(_on_request_main_menu)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if current_screen != null:
			close_current_screen()
		elif dialog.visible:
			dialog.close()
		else:
			open_screen("pause")
		get_viewport().set_input_as_handled()
		return
	if current_screen == pause_menu:
		return
	if event.is_action_pressed("toggle_inventory"):
		toggle_screen("inventory")
	elif event.is_action_pressed("toggle_skills"):
		toggle_screen("skills")
	elif event.is_action_pressed("toggle_guild"):
		toggle_screen("guild")
	elif event.is_action_pressed("toggle_map"):
		toggle_screen("map")
	elif event.is_action_pressed("toggle_journal"):
		toggle_screen("journal")
	elif event.is_action_pressed("toggle_character"):
		toggle_screen("character")
	elif event.is_action_pressed("toggle_performance"):
		SettingsManager.show_performance_overlay = not SettingsManager.show_performance_overlay
		SettingsManager.save_settings()
		SettingsManager.apply_all()
	elif event.is_action_pressed("quick_save"):
		SaveManager.save_game(SaveManager.DEFAULT_SLOT)
	elif event.is_action_pressed("quick_load"):
		if SaveManager.load_game(SaveManager.DEFAULT_SLOT):
			SceneManager.change_scene(SceneManager.GAME)

func toggle_screen(screen_name: String) -> void:
	if current_screen != null and _screens.get(screen_name) == current_screen:
		close_current_screen()
		return
	open_screen(screen_name)

func open_screen(screen_name: String) -> void:
	var screen := _screens.get(screen_name) as MenuScreen
	if screen == null:
		return
	if current_screen != null and current_screen != screen:
		current_screen.visible = false
	current_screen = screen
	screen.open()
	touch.reset_state()
	_refresh_pause_state()
	EventBus.screen_changed.emit(screen_name)

func close_current_screen() -> void:
	if current_screen == null:
		return
	var screen := current_screen
	current_screen = null
	screen.close()
	_refresh_pause_state()
	EventBus.screen_changed.emit("")

func _on_screen_closed() -> void:
	if current_screen != null and not current_screen.visible:
		current_screen = null
		_refresh_pause_state()
		EventBus.screen_changed.emit("")

func _on_menu_action(action_name: String) -> void:
	toggle_screen(action_name)

func _on_dialog_requested(npc: Node) -> void:
	if current_screen != null:
		return
	dialog.open(npc)
	_refresh_pause_state()

func _on_shop_requested(npc: Node) -> void:
	if dialog.visible:
		dialog.close()
	shop.open_for(npc)
	current_screen = shop
	touch.reset_state()
	_refresh_pause_state()
	EventBus.screen_changed.emit("shop")

func _on_item_used(item_id: String) -> void:
	if player != null:
		player.use_consumable(item_id)

func _on_player_died() -> void:
	if current_screen != null:
		close_current_screen()
	if dialog.visible:
		dialog.close()

func _on_request_main_menu() -> void:
	await SceneManager.go_to_main_menu()

func _refresh_pause_state() -> void:
	var should_pause := current_screen != null or dialog.visible
	get_tree().paused = should_pause
	if hud != null:
		hud.visible = (current_screen == null)
	if touch != null:
		touch.visible = (current_screen == null and not dialog.visible)
	touch.set_controls_visible(not should_pause and SettingsManager.show_touch_controls)
	EventBus.pause_toggled.emit(should_pause)
