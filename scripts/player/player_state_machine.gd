class_name PlayerStateMachine
extends RefCounted
## Clean Finite State Machine (FSM) governing the Hero's gameplay & animation state:
##   IDLE -> RUNNING -> SPRINTING -> AIRBORNE -> DODGING -> BLOCKING -> ATTACKING -> CASTING -> DEAD

enum State {
	IDLE,
	RUNNING,
	SPRINTING,
	AIRBORNE,
	DODGING,
	BLOCKING,
	ATTACKING,
	CASTING,
	DEAD,
}

signal state_changed(previous: int, current: int)

var current: int = State.IDLE
var time_in_state: float = 0.0

func state_name(st: int = -1) -> String:
	var target := current if st < 0 else st
	match target:
		State.IDLE: return "IDLE"
		State.RUNNING: return "RUNNING"
		State.SPRINTING: return "SPRINTING"
		State.AIRBORNE: return "AIRBORNE"
		State.DODGING: return "DODGING"
		State.BLOCKING: return "BLOCKING"
		State.ATTACKING: return "ATTACKING"
		State.CASTING: return "CASTING"
		State.DEAD: return "DEAD"
		_: return "IDLE"

func transition_to(next_state: int) -> void:
	if next_state == current:
		return
	var prev := current
	current = next_state
	time_in_state = 0.0
	state_changed.emit(prev, current)

func evaluate(delta: float, is_dead: bool, dodge_t: float, attack_t: float, spell_t: float,
		blocking: bool, on_floor: bool, sprinting: bool, planar_speed: float) -> int:
	time_in_state += delta
	var desired := State.IDLE
	if is_dead:
		desired = State.DEAD
	elif dodge_t > 0.0:
		desired = State.DODGING
	elif attack_t > 0.0:
		desired = State.ATTACKING
	elif spell_t > 0.25:
		desired = State.CASTING
	elif blocking:
		desired = State.BLOCKING
	elif not on_floor:
		desired = State.AIRBORNE
	elif planar_speed > 0.12:
		desired = State.SPRINTING if sprinting else State.RUNNING
	else:
		desired = State.IDLE
	transition_to(desired)
	return current
