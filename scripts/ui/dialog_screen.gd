class_name DialogScreen
extends Control
## Bottom dialog panel used by the village NPCs.

signal closed()

var _panel: PanelContainer
var _name_label: Label
var _lines_box: VBoxContainer
var _actions_box: HBoxContainer
var _status_label: Label
var _npc: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIFactory.full_rect(self)
	visible = false
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.02, 0.03, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	UIFactory.full_rect(dim)
	add_child(dim)

	_panel = UIFactory.panel()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -430
	_panel.offset_right = 430
	_panel.offset_top = -320
	_panel.offset_bottom = -24
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)
	_name_label = UIFactory.label("", 24, UIFactory.GOLD)
	box.add_child(_name_label)
	_lines_box = VBoxContainer.new()
	_lines_box.add_theme_constant_override("separation", 4)
	box.add_child(_lines_box)
	_status_label = UIFactory.wrapped_label("", 16, UIFactory.ACCENT)
	box.add_child(_status_label)
	box.add_child(UIFactory.hsep())
	_actions_box = HBoxContainer.new()
	_actions_box.add_theme_constant_override("separation", 8)
	box.add_child(_actions_box)

func open(npc: Node) -> void:
	_npc = npc
	visible = true
	_status_label.text = ""
	_populate()

func close() -> void:
	visible = false
	_npc = null
	closed.emit()

func _populate() -> void:
	if _npc == null or not _npc.has_method("dialog_payload"):
		close()
		return
	var payload: Dictionary = _npc.call("dialog_payload") as Dictionary
	_name_label.text = String(payload.get("name", "Villager"))
	for child: Node in _lines_box.get_children():
		child.queue_free()
	for line: String in payload.get("lines", []):
		_lines_box.add_child(UIFactory.wrapped_label(line, 17))
	for child: Node in _actions_box.get_children():
		child.queue_free()
	for action: Dictionary in payload.get("actions", []):
		var is_close := String(action.get("type", "")) == "close"
		var button := UIFactory.button(String(action.get("label", "...")), 46)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_action.bind(action))
		if is_close:
			button.modulate = Color(1, 1, 1, 0.75)
		_actions_box.add_child(button)

func _on_action(action: Dictionary) -> void:
	if _npc == null:
		close()
		return
	var result: String = String(_npc.call("execute_action", action))
	var kind := String(action.get("type", ""))
	if kind == "close":
		close()
		return
	if kind == "shop":
		close()
		return
	if not result.is_empty():
		_status_label.text = result
	_populate()
	_status_label.text = result
