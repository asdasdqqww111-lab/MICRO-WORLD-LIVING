class_name Combat
extends RefCounted
## Stateless melee maths shared by the player, creatures and traps.

const DAMAGEABLE_GROUP := "damageable"

## Returns every damageable node inside a sphere in front of `attacker`.
## `arc_degrees` = 360 behaves as a full circle (used by traps / spin attacks).
static func melee_targets(attacker: Node3D, reach: float, arc_degrees: float,
		exclude: Array[RID] = [], mask: int = 0) -> Array[Node]:
	var targets: Array[Node] = []
	if attacker == null or not attacker.is_inside_tree():
		return targets
	var world := attacker.get_world_3d()
	if world == null:
		return targets
	var shape := SphereShape3D.new()
	shape.radius = maxf(0.2, reach)
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis.IDENTITY, attacker.global_position + Vector3.UP * 0.9)
	params.collision_mask = mask if mask != 0 else (1 | 4)
	params.exclude = exclude
	params.collide_with_areas = false
	params.collide_with_bodies = true
	var hits := world.direct_space_state.intersect_shape(params, 32)
	var forward := -attacker.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.001 else Vector3.FORWARD
	var half_arc := deg_to_rad(clampf(arc_degrees, 1.0, 360.0) * 0.5)
	var cos_limit := cos(half_arc)
	for hit: Dictionary in hits:
		var collider: Variant = hit.get("collider")
		if not (collider is Node3D):
			continue
		var node: Node = collider
		var node_3d := collider as Node3D
		if node_3d == null:
			continue
		if not node.is_in_group(DAMAGEABLE_GROUP):
			continue
		if node == attacker:
			continue
		var to_target: Vector3 = node_3d.global_position - attacker.global_position
		to_target.y = 0.0
		if to_target.length() > 0.001 and arc_degrees < 359.0:
			if forward.dot(to_target.normalized()) < cos_limit:
				continue
		if not targets.has(node):
			targets.append(node)
	return targets

## Applies damage to a node exposing `take_hit(amount, source, is_crit)`.
static func apply_hit(target: Node, amount: float, source: Node, is_crit: bool = false) -> bool:
	if target == null or not target.has_method("take_hit"):
		return false
	target.call("take_hit", amount, source, is_crit)
	return true
