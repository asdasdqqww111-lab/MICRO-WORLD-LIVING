extends Node
class_name CityStreamPlayerTracker
## Feeds the live player position into a CityChunkStream on a fixed interval
## instead of every physics frame (mobile-friendly: no per-frame allocations).

const UPDATE_INTERVAL: float = 0.25

var stream: Node3D
var _timer: float = 0.0

func setup(city_stream: Node3D) -> void:
	stream = city_stream

func _process(delta: float) -> void:
	if stream == null or not is_instance_valid(stream):
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = UPDATE_INTERVAL
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null:
		stream.set_player_position(player.global_position)
