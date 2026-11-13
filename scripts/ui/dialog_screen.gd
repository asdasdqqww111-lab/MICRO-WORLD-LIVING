class_name DialogScreen
extends Control
## Fantasy RPG Dialogue Box with wrapping action buttons, quest accept/turn-in,
## Guild registration/promotion, Forge/Shop transitions, and EN/AR RTL layout.

signal closed()

var _panel: PanelContainer
var _name_label: Label
var _lines_box: VBoxContainer
var _actions_box: HFlowContainer
var _status_label: Label
var _npc: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIFactory.full_rect(self)
	visible = false
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.02, 0.04, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	UIFactory.full_rect(dim)
	add_child(dim)

	_panel = UIFactory.panel()
	_panel.anchor_left = 0.08
	_panel.anchor_right = 0.92
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 0
	_panel.offset_right = 0
	_panel.offset_top = -290
	_panel.offset_bottom = -18
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_panel.add_child(box)
	_name_label = UIFactory.label("", 22, UIFactory.GOLD)
	box.add_child(_name_label)
	_lines_box = VBoxContainer.new()
	_lines_box.add_theme_constant_override("separation", 4)
	box.add_child(_lines_box)
	_status_label = UIFactory.wrapped_label("", 15, UIFactory.ACCENT)
	box.add_child(_status_label)
	box.add_child(UIFactory.hsep())
	_actions_box = HFlowContainer.new()
	_actions_box.add_theme_constant_override("h_separation", 8)
	_actions_box.add_theme_constant_override("v_separation", 6)
	box.add_child(_actions_box)

func open(npc: Node) -> void:
	_npc = npc
	Localization.apply_rtl(self)
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
	_name_label.text = "✦  " + String(payload.get("name", "Villager"))
	for child: Node in _lines_box.get_children():
		child.queue_free()
	for line: String in payload.get("lines", []):
		_lines_box.add_child(UIFactory.wrapped_label(line, 16))
	for child: Node in _actions_box.get_children():
		child.queue_free()
	for action: Dictionary in payload.get("actions", []):
		var is_close := String(action.get("type", "")) == "close"
		var button := UIFactory.button(String(action.get("label", "...")), 42)
		button.custom_minimum_size = Vector2(160, 42)
		button.pressed.connect(_on_action.bind(action))
		if is_close:
			button.modulate = Color(1, 1, 1, 0.78)
		_actions_box.add_child(button)

func _on_action(action: Dictionary) -> void:
	if _npc == null:
		close()
		return
	var kind := String(action.get("type", ""))
	if kind == "close":
		close()
		return
	var result: String = String(_npc.call("execute_action", action))
	if kind == "shop" or result == "__close__":
		close()
		return
	_populate()
	_status_label.text = result
