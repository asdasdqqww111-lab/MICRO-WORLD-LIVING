class_name RaidEvent
extends Node
## Dynamic event: every 3rd day at 20:00 three skeletons march on the village.

const RAID_EVERY_DAYS := 3
const RAID_HOUR := 20
const RAID_SIZE := 3

var world: Node
var _raid_ids: Array[String] = []
var _active: bool = false

func setup(world_root: Node) -> void:
	world = world_root
	EventBus.creature_died.connect(_on_creature_died)

func _process(_delta: float) -> void:
	if not GameManager.is_playing or get_tree().paused or world == null:
		return
	var state := GameManager.world
	if not _active and state.hour() >= RAID_HOUR and state.day % RAID_EVERY_DAYS == 0 and state.raid_day != state.day:
		start_raid()

func start_raid() -> void:
	if _active or world == null:
		return
	var state := GameManager.world
	_active = true
	state.raid_active = true
	state.raid_day = state.day
	_raid_ids.clear()
	for i: int in RAID_SIZE:
		var uid := "raid_%d_%d" % [state.day, i]
		var offset := Vector3(randf_range(-4.0, 4.0), 0.0, float(i) * 2.4 - 2.4)
		var spawned: Node = world.call("spawn_creature", "skeleton_forest", uid, Vector3(0.0, 0.5, 34.0) + offset)
		if spawned != null:
			_raid_ids.append(uid)
	EventBus.raid_started.emit(state.day)
	EventBus.notify.emit("Skeletons are attacking the village!")

func _on_creature_died(_creature_id: String, uid: String, _position: Vector3) -> void:
	if not _active:
		return
	_raid_ids.erase(uid)
	if _raid_ids.is_empty():
		_active = false
		GameManager.world.raid_active = false
		EventBus.raid_cleared.emit(GameManager.world.day)
		EventBus.notify.emit("The raid is over. The village is safe.")

func is_active() -> bool:
	return _active
