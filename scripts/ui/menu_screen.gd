class_name MenuScreen
extends Control
## Responsive modal RPG menu base (Inventory, Skill Tree, Guild, Crafting,
## Journal, Character, World Map, Shop, Pause). Supports EN + Arabic RTL.

signal closed()

var content: VBoxContainer
var panel: PanelContainer
var title_label: Label
var close_btn: Button
var _title_text: String = "Menu"
var _title_key: String = ""
var _built: bool = false

func configure(title: String, loc_key: String = "") -> void:
	_title_text = title
	_title_key = loc_key

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIFactory.full_rect(self)
	visible = false
	_build_frame()
	EventBus.language_changed.connect(_on_lang_changed)

func _on_lang_changed(_lang: String) -> void:
	Localization.apply_rtl(self)
	if title_label != null:
		title_label.text = Localization.tr_key(_title_key) if not _title_key.is_empty() else _title_text
	if close_btn != null:
		close_btn.text = Localization.tr_key("close")
	if visible:
		refresh()

func _build_frame() -> void:
	if _built:
		return
	_built = true
	Localization.apply_rtl(self)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	UIFactory.full_rect(dim)
	add_child(dim)

	panel = UIFactory.panel()
	panel.anchor_left = 0.05
	panel.anchor_top = 0.05
	panel.anchor_right = 0.95
	panel.anchor_bottom = 0.95
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0
	add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	outer.add_child(header)
	var disp_title := Localization.tr_key(_title_key) if not _title_key.is_empty() else _title_text
	title_label = UIFactory.label("✦  " + disp_title, 24, UIFactory.GOLD)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	close_btn = UIFactory.button(Localization.tr_key("close"), 42)
	close_btn.custom_minimum_size = Vector2(115, 42)
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	outer.add_child(UIFactory.hsep())

	var scroll := ScrollContainer.new()
	scroll.name = "BodyScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)

func open() -> void:
	if not _built:
		_build_frame()
	Localization.apply_rtl(self)
	if title_label != null:
		var dt := Localization.tr_key(_title_key) if not _title_key.is_empty() else _title_text
		title_label.text = "✦  " + dt
	if close_btn != null:
		close_btn.text = Localization.tr_key("close")
	visible = true
	if AudioManager != null:
		AudioManager.play_sfx("ui_open", -4.0)
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

func refresh() -> void:
	pass
