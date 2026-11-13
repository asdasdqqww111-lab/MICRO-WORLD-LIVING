class_name CreatureData
extends Resource
## Data-driven creature, wildlife, elite & boss template (resources/creatures/*.tres).

@export var id: String = ""
@export var display_name: String = ""
@export_file("*.glb") var model_path: String = ""
@export var max_health: float = 40.0
@export var damage: float = 6.0
@export var defense: float = 1.0
@export var move_speed: float = 2.6
@export var attack_range: float = 1.8
@export var attack_cooldown: float = 1.6
@export var aggro_radius: float = 12.0
@export var leash_radius: float = 26.0
@export var xp_reward: int = 20
@export var gold_reward: int = 3
@export var hostile: bool = true
@export var flee_when_hurt: bool = false
@export var is_elite: bool = false
@export var is_boss: bool = false
@export var body_scale: float = 1.0
@export var model_y_offset: float = 0.0
@export var tint_color: Color = Color.WHITE
@export var visual_type: String = "skeleton"
@export var loot: Array = []

func roll_loot(rng: RandomNumberGenerator) -> Array:
	var drops: Array = []
	for entry: Dictionary in loot:
		var chance := float(entry.get("chance", 0.0))
		if rng.randf() <= chance:
			var lo := int(entry.get("min", 1))
			var hi := int(entry.get("max", lo))
			drops.append({
				"id": String(entry.get("id", "")),
				"count": rng.randi_range(lo, maxi(lo, hi)),
			})
	return drops
