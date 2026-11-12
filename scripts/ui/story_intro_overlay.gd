class_name StoryIntroOverlay
extends Control
## Illustrated 3-Chapter Eldoria Prologue Overlay (EN + AR RTL).
## Pauses world simulation cleanly while the player reads or skips the opening lore.

signal finished()

var _slide_index: int = 0
var _slides: Array[Dictionary] = []
var _chapter_lbl: Label
var _title_lbl: Label
var _body_lbl: Label
var _progress_lbl: Label
var _next_btn: Button
var _skip_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIFactory.full_rect(self)
	_build()

func start_prologue() -> void:
	_slides = Localization.prologue_slides()
	_slide_index = 0
	visible = true
	get_tree().paused = true
	_refresh_slide()

func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.03, 0.05, 0.10, 0.92)
	UIFactory.full_rect(backdrop)
	add_child(backdrop)

	var card := UIFactory.panel(0.98)
	card.anchor_left = 0.12
	card.anchor_top = 0.14
	card.anchor_right = 0.88
	card.anchor_bottom = 0.86
	add_child(card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	card.add_child(box)

	_chapter_lbl = UIFactory.label("", 16, UIFactory.ACCENT)
	_chapter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_chapter_lbl)

	_title_lbl = UIFactory.label("", 28, UIFactory.GOLD)
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title_lbl)

	box.add_child(UIFactory.hsep())

	_body_lbl = UIFactory.wrapped_label("", 19, UIFactory.TEXT)
	_body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_body_lbl)

	box.add_child(UIFactory.hsep())

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 14)
	box.add_child(nav)

	_skip_btn = UIFactory.button(Localization.tr_key("skip_intro"), 48)
	_skip_btn.custom_minimum_size = Vector2(180, 48)
	_skip_btn.pressed.connect(_close_prologue)
	nav.add_child(_skip_btn)

	_progress_lbl = UIFactory.label("", 15, UIFactory.TEXT_DIM)
	_progress_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav.add_child(_progress_lbl)

	_next_btn = UIFactory.button(Localization.tr_key("next_page"), 48)
	_next_btn.custom_minimum_size = Vector2(210, 48)
	_next_btn.pressed.connect(_on_next)
	nav.add_child(_next_btn)

func _refresh_slide() -> void:
	Localization.apply_rtl(self)
	if _slides.is_empty():
		_close_prologue()
		return
	var slide: Dictionary = _slides[_slide_index]
	_chapter_lbl.text = "✦  %s  ✦" % String(slide.get("chapter", ""))
	_title_lbl.text = String(slide.get("title", ""))
	_body_lbl.text = String(slide.get("body", ""))
	_body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if Localization.is_arabic() else HORIZONTAL_ALIGNMENT_LEFT
	_progress_lbl.text = "%d / %d" % [_slide_index + 1, _slides.size()]
	_skip_btn.text = Localization.tr_key("skip_intro")
	var is_last := (_slide_index >= _slides.size() - 1)
	_next_btn.text = Localization.tr_key("enter_eldoria") if is_last else Localization.tr_key("next_page")

func _on_next() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("ui_click", -2.0, 1.05)
	if _slide_index + 1 < _slides.size():
		_slide_index += 1
		_refresh_slide()
	else:
		_close_prologue()

func _close_prologue() -> void:
	visible = false
	get_tree().paused = false
	finished.emit()
