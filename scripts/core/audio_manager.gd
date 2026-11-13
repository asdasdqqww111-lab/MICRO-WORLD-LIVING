extends Node
## Enhanced Offline SFX, Surface Footstep Foley & Dynamic Biome Ambience Controller (autoload: AudioManager).
## Combines shipped 16-bit PCM WAV tracks with Kenney's CC0 RPG Audio foley (.ogg) from GitHub.

const SFX_PATHS := {
	"sword_swing": "res://assets/sounds/sword_swing.wav",
	"sword_swing_1": "res://assets/sounds/rpg/knife_slice.ogg",
	"sword_swing_2": "res://assets/sounds/rpg/knife_slice_2.ogg",
	"sword_finisher": "res://assets/sounds/combo_finisher.wav",
	"sword_hit": "res://assets/sounds/hit_impact.wav",
	"sword_heavy": "res://assets/sounds/heavy_swing.wav",
	"heavy_swing": "res://assets/sounds/heavy_swing.wav",
	"heavy_slash": "res://assets/sounds/rpg/chop.ogg",
	"bow_shoot": "res://assets/sounds/bow_shoot.wav",
	"crit_hit": "res://assets/sounds/crit_hit.wav",
	"hit_impact": "res://assets/sounds/hit_impact.wav",
	"hit_flesh": "res://assets/sounds/hit_impact.wav",
	"player_hurt": "res://assets/sounds/hit_impact.wav",
	"hit_armor": "res://assets/sounds/shield_block.wav",
	"shield_block": "res://assets/sounds/shield_block.wav",
	"dodge_whoosh": "res://assets/sounds/dodge_whoosh.wav",
	"dodge_roll": "res://assets/sounds/rpg/cloth_1.ogg",
	"jump_land": "res://assets/sounds/rpg/footstep_4.ogg",
	"magic_cast": "res://assets/sounds/spell_fire.wav",
	"spell_cast": "res://assets/sounds/spell_fire.wav",
	"spell_fire": "res://assets/sounds/spell_fire.wav",
	"spell_ice": "res://assets/sounds/spell_ice.wav",
	"spell_lightning": "res://assets/sounds/spell_lightning.wav",
	"footstep_grass": "res://assets/sounds/footstep_grass.wav",
	"footstep_stone": "res://assets/sounds/rpg/footstep_0.ogg",
	"footstep_wood": "res://assets/sounds/rpg/footstep_8.ogg",
	"pickup_item": "res://assets/sounds/pickup_item.wav",
	"coin_pickup": "res://assets/sounds/rpg/handle_coins.ogg",
	"potion_drink": "res://assets/sounds/rpg/metal_pot_1.ogg",
	"equip_gear": "res://assets/sounds/rpg/belt_handle_1.ogg",
	"draw_weapon": "res://assets/sounds/rpg/draw_knife_1.ogg",
	"door_open": "res://assets/sounds/rpg/door_open_1.ogg",
	"door_close": "res://assets/sounds/rpg/door_close_1.ogg",
	"book_open": "res://assets/sounds/rpg/book_open.ogg",
	"book_flip": "res://assets/sounds/rpg/book_flip_1.ogg",
	"chest_open": "res://assets/sounds/chest_open.wav",
	"quest_complete": "res://assets/sounds/quest_complete.wav",
	"level_up": "res://assets/sounds/level_up.wav",
	"craft_anvil": "res://assets/sounds/craft_anvil.wav",
	"gather_mine": "res://assets/sounds/craft_anvil.wav",
	"gather_chop": "res://assets/sounds/rpg/chop.ogg",
	"gather_herb": "res://assets/sounds/rpg/cloth_2.ogg",
	"npc_greet": "res://assets/sounds/rpg/cloth_belt.ogg",
	"ui_click": "res://assets/sounds/rpg/metal_click.ogg",
}

const SFX_VARIANTS := {
	"footstep_stone": [
		"res://assets/sounds/rpg/footstep_0.ogg",
		"res://assets/sounds/rpg/footstep_1.ogg",
		"res://assets/sounds/rpg/footstep_2.ogg",
		"res://assets/sounds/rpg/footstep_3.ogg",
		"res://assets/sounds/footstep_stone.wav",
	],
	"footstep_grass": [
		"res://assets/sounds/footstep_grass.wav",
		"res://assets/sounds/rpg/footstep_5.ogg",
		"res://assets/sounds/rpg/footstep_6.ogg",
		"res://assets/sounds/rpg/footstep_7.ogg",
	],
	"footstep_wood": [
		"res://assets/sounds/rpg/footstep_8.ogg",
		"res://assets/sounds/rpg/footstep_9.ogg",
		"res://assets/sounds/rpg/creak_1.ogg",
	],
	"sword_swing": [
		"res://assets/sounds/sword_swing.wav",
		"res://assets/sounds/rpg/knife_slice.ogg",
		"res://assets/sounds/rpg/knife_slice_2.ogg",
	],
	"coin_pickup": [
		"res://assets/sounds/rpg/handle_coins.ogg",
		"res://assets/sounds/rpg/handle_coins_2.ogg",
	],
	"dodge_roll": [
		"res://assets/sounds/dodge_whoosh.wav",
		"res://assets/sounds/rpg/cloth_1.ogg",
		"res://assets/sounds/rpg/cloth_3.ogg",
	],
	"door_open": [
		"res://assets/sounds/rpg/door_open_1.ogg",
		"res://assets/sounds/rpg/door_open_2.ogg",
	],
	"book_flip": [
		"res://assets/sounds/rpg/book_flip_1.ogg",
		"res://assets/sounds/rpg/book_flip_2.ogg",
		"res://assets/sounds/rpg/book_flip_3.ogg",
	],
}

const MUSIC_PATHS := {
	"village": "res://assets/music/music_eldoria_village.wav",
	"guild": "res://assets/music/music_eldoria_village.wav",
	"house": "res://assets/music/music_eldoria_village.wav",
	"menu": "res://assets/music/music_eldoria_village.wav",
	"dungeon": "res://assets/music/music_dungeon_crypt.wav",
	"tower": "res://assets/music/music_dungeon_crypt.wav",
}

const AMBIENCE_PATHS := {
	"city": "res://assets/music/ambient_royal_city.wav",
	"forest": "res://assets/music/ambient_forest_birds.wav",
	"river": "res://assets/music/ambient_wind_river.wav",
}

const POOL_SIZE := 10

var _streams: Dictionary = {}
var _sfx_pool: Array[AudioStreamPlayer] = []
var _pool_idx: int = 0
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _current_music: String = ""
var _current_ambience: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_build_players()
	_connect_events()

func _ensure_buses() -> void:
	for bus_name in ["SFX", "Music"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")
	if SettingsManager != null:
		SettingsManager.apply_audio()

func _build_players() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "SFX_%d" % i
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	_music_player.volume_db = -8.5
	add_child(_music_player)
	_music_player.finished.connect(func() -> void:
		if not _current_music.is_empty():
			_music_player.play())

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = "SFX"
	_ambience_player.volume_db = -12.5
	add_child(_ambience_player)
	_ambience_player.finished.connect(func() -> void:
		if GameManager.is_playing and not _current_ambience.is_empty():
			_ambience_player.play())

func _connect_events() -> void:
	EventBus.damage_dealt.connect(func(_t: Node, _a: float, is_crit: bool) -> void:
		play_sfx("crit_hit" if is_crit else "hit_impact", -1.5 if is_crit else -2.5))
	EventBus.item_picked_up.connect(func(id: String, _n: int) -> void:
		play_sfx("coin_pickup" if id.contains("ring") or id.contains("crown") else "pickup_item", -3.0))
	EventBus.quest_completed.connect(func(_id: String) -> void: play_sfx("quest_complete", 0.0))
	EventBus.player_level_up.connect(func(_lv: int) -> void: play_sfx("level_up", 0.0))
	EventBus.equipment_changed.connect(func() -> void: play_sfx("equip_gear", -3.0))
	EventBus.zone_entered.connect(func(_z: String) -> void: play_sfx("door_open", -3.5))

func _load_stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path] as AudioStream
	if not ResourceLoader.exists(path):
		return null
	var s := ResourceLoader.load(path) as AudioStream
	_streams[path] = s
	return s

func play_sfx(sfx_id: String, volume_db: float = 0.0, pitch_variance: float = 0.08) -> void:
	if _sfx_pool.is_empty():
		return
	var path: String = ""
	if SFX_VARIANTS.has(sfx_id):
		var arr: Array = SFX_VARIANTS[sfx_id]
		if not arr.is_empty():
			path = String(arr[randi() % arr.size()])
	if path.is_empty():
		path = SFX_PATHS.get(sfx_id, "")
	if path.is_empty():
		return
	var stream := _load_stream(path)
	if stream == null and SFX_PATHS.has(sfx_id):
		stream = _load_stream(String(SFX_PATHS[sfx_id]))
	if stream == null:
		return
	var player := _sfx_pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % _sfx_pool.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = randf_range(maxf(0.55, 1.0 - pitch_variance), 1.0 + pitch_variance)
	player.play()

func play_footstep(surface: String, sprinting: bool = false) -> void:
	var pitch_var := 0.12
	match surface:
		"stone":
			play_sfx("footstep_stone", -5.0 if sprinting else -7.0, pitch_var)
		"wood":
			play_sfx("footstep_wood", -5.5 if sprinting else -7.5, pitch_var)
		"water":
			play_sfx("footstep_grass", -4.5, 0.22)
		_:
			play_sfx("footstep_grass", -5.5 if sprinting else -7.5, pitch_var)

func play_music(track_key: String) -> void:
	if _current_music == track_key and _music_player.playing:
		return
	var path: String = MUSIC_PATHS.get(track_key, "")
	if path.is_empty():
		return
	var stream := _load_stream(path)
	if stream == null:
		return
	_current_music = track_key
	_music_player.stream = stream
	_music_player.play()

func play_music_for_zone(zone_id: String) -> void:
	var key := "village"
	if zone_id == "dungeon" or zone_id == "tower":
		key = "dungeon"
	elif zone_id == "menu":
		key = "menu"
	play_music(key)
	if zone_id == "village" or zone_id == "":
		update_biome_ambience("village", "village")
	else:
		set_ambience_active(false)

func update_biome_ambience(zone_id: String, biome: String) -> void:
	if _ambience_player == null:
		return
	if zone_id != "village":
		set_ambience_active(false)
		return
	var target_key := "river"
	if biome == "village":
		target_key = "city"
	elif biome == "dense_woodland" or biome == "ancient_grove" or biome == "pine_highlands":
		target_key = "forest"
	if _current_ambience == target_key and _ambience_player.playing:
		return
	var path: String = AMBIENCE_PATHS.get(target_key, AMBIENCE_PATHS["river"])
	var s := _load_stream(path)
	if s != null:
		_current_ambience = target_key
		_ambience_player.stream = s
		_ambience_player.play()

func set_ambience_active(active: bool) -> void:
	if _ambience_player == null:
		return
	if active:
		if not _ambience_player.playing:
			update_biome_ambience("village", "village")
	else:
		_current_ambience = ""
		_ambience_player.stop()
