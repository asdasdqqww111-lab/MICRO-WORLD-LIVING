class_name PlayerInput
extends RefCounted
## Merges keyboard/mouse with the on-screen touch controls into one clean API.

var _touch: Node

func bind_touch_controls(node: Node) -> void:
	_touch = node

func move_vector() -> Vector2:
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if is_instance_valid(_touch) and _touch.has_method("get_move_vector"):
		v += _touch.call("get_move_vector") as Vector2
	return v.limit_length(1.0)

func is_sprinting() -> bool:
	if Input.is_action_pressed("sprint"):
		return true
	if is_instance_valid(_touch) and _touch.has_method("is_sprinting"):
		return bool(_touch.call("is_sprinting"))
	return false

func is_blocking() -> bool:
	if Input.is_action_pressed("block"):
		return true
	if is_instance_valid(_touch) and _touch.has_method("is_blocking"):
		return bool(_touch.call("is_blocking"))
	return false

func jump_pressed() -> bool:
	return Input.is_action_just_pressed("jump") or _touch_pressed("jump")

func dodge_pressed() -> bool:
	return Input.is_action_just_pressed("dodge") or _touch_pressed("dodge")

func attack_pressed() -> bool:
	return Input.is_action_just_pressed("attack") or _touch_pressed("attack")

func heavy_attack_pressed() -> bool:
	return Input.is_action_just_pressed("attack_heavy") or _touch_pressed("attack_heavy")

func spell_pressed() -> bool:
	return Input.is_action_just_pressed("cast_spell") or _touch_pressed("cast_spell")

func potion_pressed() -> bool:
	return Input.is_action_just_pressed("quick_potion") or _touch_pressed("quick_potion")

func interact_pressed() -> bool:
	return Input.is_action_just_pressed("interact") or _touch_pressed("interact")

func _touch_pressed(action: String) -> bool:
	if not is_instance_valid(_touch) or not _touch.has_method("consume_pressed"):
		return false
	return bool(_touch.call("consume_pressed", action))
