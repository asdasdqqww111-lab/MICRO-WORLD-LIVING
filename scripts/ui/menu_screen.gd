class_name MenuScreen
extends Control
## Base for the full-screen menus (inventory, journal, character, shop, pause).

signal closed()

var content: VBoxContainer
var panel: PanelContainer
var _title_text: String = "Menu"
var _built: bool = false

func configure(title: String) -> void:
	_title_text = title

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIFactory.full_rect(self)
	visible = false
	_build_frame()

func _build_frame() -> void:
	if _built:
		return
	_built = true
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.02, 0.03, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	UIFactory.full_rect(dim)
	add_child(dim)

	panel = UIFactory.panel()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(820, 540)
	add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	var header := HBoxContainer.new()
	outer.add_child(header)
	var title := UIFactory.label(_title_text, 26, UIFactory.TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_button := UIFactory.button("Close")
	close_button.custom_minimum_size = Vector2(120, 44)
	close_button.pressed.connect(close)
	header.add_child(close_button)

	outer.add_child(UIFactory.hsep())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)

func open() -> void:
	if not _built:
		_build_frame()
	visible = true
	refresh()

func close() -> void:
	visible = false
	closed.emit()

func is_open() -> bool:
	return visible

func clear_content() -> void:
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()

## Subclasses override.
func refresh() -> void:
	pass
