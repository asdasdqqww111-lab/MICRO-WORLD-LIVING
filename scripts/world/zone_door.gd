class_name ZoneDoor
extends Interactable
## Door / cave mouth / gate that moves the player between zones.

var target_position: Vector3 = Vector3.ZERO
var target_zone: String = ""
var transition_text: String = "Travel"
var prompt_ar: String = ""
var transition_ar: String = ""

func setup(destination: Vector3, zone_id: String, label: String, label_ar: String = "", trans_ar: String = "") -> void:
	target_position = destination
	target_zone = zone_id
	prompt_text = label
	prompt_ar = label_ar
	transition_ar = trans_ar

func prompt_for(_player: Node) -> String:
	if Localization.is_arabic():
		if not prompt_ar.is_empty():
			return prompt_ar
		match target_zone:
			"house": return "دخول منزلك في إلدوريا"
			"guild": return "دخول القاعة الكبرى لنقابة المغامرين"
			"dungeon": return "النزول إلى السرداب الغارق"
			"village": return "الخروج إلى مدينة إلدوريا الملكية"
	return prompt_text

func interact(player: Node) -> void:
	if player == null or not player.has_method("teleport"):
		return
	player.call("teleport", target_position, target_zone)
	if Localization.is_arabic() and not transition_ar.is_empty():
		EventBus.notify.emit(transition_ar)
	elif Localization.is_arabic():
		match target_zone:
			"house": EventBus.notify.emit("دخلت منزلك الدافئ في إلدوريا")
			"guild": EventBus.notify.emit("مرحباً بك في القاعة الكبرى لنقابة مغامري إلدوريا")
			"dungeon": EventBus.notify.emit("هواء قديم بارد يتصاعد من أعماق السرداب الغارق...")
			_: EventBus.notify.emit("عدت إلى رحاب مدينة إلدوريا الملكية")
	else:
		EventBus.notify.emit(transition_text)
