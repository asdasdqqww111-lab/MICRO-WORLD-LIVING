extends Node
## Lightweight offline SFX, Ambience & Music controller (autoload: AudioManager).
## Uses shipped original CC0 16-bit PCM WAV assets and connects to EventBus.

const SFX_PATHS := {
	"sword_swing": "res://assets/sounds/sword_swing.wav",
	"sword_swing_1": "res://assets/sounds/sword_swing.wav",
	"sword_swing_2": "res://assets/sounds/sword_swing.wav",
	"heavy_swing": "res://assets/sounds/heavy_swing.wav",
	"heavy_slash": "res://assets/sounds/heavy_swing.wav",
	"hit_impact": "res://assets/sounds/hit_impact.wav",
	"hit_flesh": "res://assets/sounds/hit_impact.wav",
	"hit_armor": "res://assets/sounds/shield_block.wav",
	"shield_block": "res://assets/sounds/shield_block.wav",
	"dodge_whoosh": "res://assets/sounds/dodge_whoosh.wav",
	"dodge_roll": "res://assets/sounds/dodge_whoosh.wav",
	"spell_cast": "res://assets/sounds/spell_fire.wav",
	"spell_fire": "res://assets/sounds/spell_fire.wav",
	"spell_ice": "res://assets/sounds/spell_ice.wav",
	"spell_lightning": "res://assets/sounds/spell_lightning.wav",
	"footstep_grass": "res://assets/sounds/footstep_grass.wav",
	"footstep_stone": "res://assets/sounds/footstep_stone.wav",
	"pickup_item": "res://assets/sounds/pickup_item.wav",
	"coin_pickup": "res://assets/sounds/pickup_item.wav",
	"equip_gear": "res://assets/sounds/craft_anvil.wav",
	"chest_open": "res://assets/sounds/chest_open.wav",
	"quest_complete": "res://assets/sounds/quest_complete.wav",
	"level_up": "res://assets/sounds/level_up.wav",
	"craft_anvil": "res://assets/sounds/craft_anvil.wav",
	"gather_mine": "res://assets/sounds/craft_anvil.wav",
	"gather_chop": "res://assets/sounds/heavy_swing.wav",
	"gather_herb": "res://assets/sounds/pickup_item.wav",
	"npc_greet": "res://assets/sounds/ui_click.wav",
	"ui_click": "res://assets/sounds/ui_click.wav",
}

const MUSIC_PATHS := {
	"village": "res://assets/music/music_eldoria_village.wav",
	"guild": "res://assets/music/music_eldoria_village.wav",
	"house": "res://assets/music/music_eldoria_village.wav",
	"menu": "res://assets/music/music_eldoria_village.wav",
	"dungeon": "res://assets/music/music_dungeon_crypt.wav",
}
const AMBIENCE_PATH := "res://assets/music/ambient_wind_river.wav"

const POOL_SIZE := 8

var _streams: Dictionary = {}
var _sfx_pool: Array[AudioStreamPlayer] = []
var _pool_idx: int = 0
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _current_music: String = ""

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
	_music_player.volume_db = -8.0
	add_child(_music_player)
	_music_player.finished.connect(func() -> void:
		if not _current_music.is_empty():
			_music_player.play())

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = "SFX"
	_ambience_player.volume_db = -14.0
	add_child(_ambience_player)
	_ambience_player.finished.connect(func() -> void:
		if GameManager.is_playing:
			_ambience_player.play())

func _connect_events() -> void:
	EventBus.damage_dealt.connect(func(_t: Node, _a: float, _c: bool) -> void: play_sfx("hit_impact", -2.0))
	EventBus.item_picked_up.connect(func(_id: String, _n: int) -> void: play_sfx("pickup_item", -3.0))
	EventBus.quest_completed.connect(func(_id: String) -> void: play_sfx("quest_complete", 0.0))
	EventBus.player_level_up.connect(func(_lv: int) -> void: play_sfx("level_up", 0.0))

func _load_stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path] as AudioStream
	if not ResourceLoader.exists(path):
		return null
	var s := ResourceLoader.load(path) as AudioStream
	_streams[path] = s
	return s

func play_sfx(sfx_id: String, volume_db: float = 0.0, pitch_variance: float = 0.06) -> void:
	var path: String = SFX_PATHS.get(sfx_id, "")
	if path.is_empty() or _sfx_pool.is_empty():
		return
	var stream := _load_stream(path)
	if stream == null:
		return
	var player := _sfx_pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % _sfx_pool.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	player.play()

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
	var key := "dungeon" if zone_id == "dungeon" else ("menu" if zone_id == "menu" else "village")
	play_music(key)
	set_ambience_active(zone_id == "" or zone_id == "village")

func set_ambience_active(active: bool) -> void:
	if _ambience_player == null:
		return
	if active:
		if not _ambience_player.playing:
			var s := _load_stream(AMBIENCE_PATH)
			if s != null:
				_ambience_player.stream = s
				_ambience_player.play()
	else:
		_ambience_player.stop()
