class_name HealthComponent
extends Node
## Hit points for any node.  The owning node decides how to visualise/react.

signal damaged(amount: float, current: float, maximum: float)
signal healed(amount: float, current: float, maximum: float)
signal died()

@export var max_health: float = 100.0
@export var start_full: bool = true

var current_health: float = 0.0
var invulnerable: bool = false
var dead: bool = false

func _ready() -> void:
	if start_full:
		current_health = max_health
	current_health = clampf(current_health, 0.0, max_health)

func setup(maximum: float, current: float = -1.0) -> void:
	max_health = maxf(1.0, maximum)
	current_health = max_health if current < 0.0 else clampf(current, 0.0, max_health)
	dead = current_health <= 0.0

func take_damage(amount: float) -> float:
	if dead or invulnerable or amount <= 0.0:
		return 0.0
	var before := current_health
	current_health = maxf(0.0, current_health - amount)
	var applied := before - current_health
	damaged.emit(applied, current_health, max_health)
	if current_health <= 0.0 and not dead:
		dead = true
		died.emit()
	return applied

func heal(amount: float) -> float:
	if dead or amount <= 0.0:
		return 0.0
	var before := current_health
	current_health = minf(max_health, current_health + amount)
	var applied := current_health - before
	if applied > 0.0:
		healed.emit(applied, current_health, max_health)
	return applied

func revive(ratio: float = 1.0) -> void:
	dead = false
	current_health = clampf(max_health * ratio, 1.0, max_health)

func set_max_health(value: float, keep_ratio: bool = false) -> void:
	var ratio := current_health / max_health if max_health > 0.0 else 1.0
	max_health = maxf(1.0, value)
	current_health = clampf(max_health * ratio if keep_ratio else minf(current_health, max_health), 0.0, max_health)

func ratio() -> float:
	return 0.0 if max_health <= 0.0 else clampf(current_health / max_health, 0.0, 1.0)

func is_dead() -> bool:
	return dead
