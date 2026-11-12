class_name Interactable
extends Node3D
## Anything the player can walk up to and use (NPCs, chests, doors, loot).
## Proximity based: cheap, deterministic and headless-testable.

@export var prompt_text: String = "Interact"
@export var interaction_radius: float = 2.6
@export var interaction_id: String = ""

var enabled: bool = true

func _ready() -> void:
	add_to_group("interactable")

func can_interact(_player: Node) -> bool:
	return enabled

func prompt_for(_player: Node) -> String:
	return prompt_text

func interact(_player: Node) -> void:
	pass

func is_in_range(node: Node3D) -> bool:
	return global_position.distance_to(node.global_position) <= interaction_radius
