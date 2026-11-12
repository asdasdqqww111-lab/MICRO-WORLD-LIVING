class_name SkillData
extends Resource
## One node of the small skill tree (resources/skills/*.tres).

enum Effect { ATTACK_FLAT, DEFENSE_FLAT, SPEED_PCT, MAX_HEALTH_FLAT }

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var effect: Effect = Effect.ATTACK_FLAT
@export var per_rank: float = 2.0
@export var max_rank: int = 3
@export var point_cost: int = 1
