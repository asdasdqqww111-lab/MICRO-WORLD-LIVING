class_name ZoneDoor
extends Interactable
## Door / cave mouth / gate that moves the player between zones.

var target_position: Vector3 = Vector3.ZERO
var target_zone: String = ""
var transition_text: String = "Travel"

func setup(destination: Vector3, zone_id: String, label: String) -> void:
	target_position = destination
	target_zone = zone_id
	prompt_text = label

func interact(player: Node) -> void:
	if player == null or not player.has_method("teleport"):
		return
	player.call("teleport", target_position, target_zone)
	EventBus.notify.emit(transition_text)
