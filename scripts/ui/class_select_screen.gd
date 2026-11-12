class_name ClassSelectScreen
extends Control
## Hero Creation & Class Selection Modal (Knight, Mage, Ranger, Barbarian).
## Bilingual (EN + AR RTL) with live attribute, starting equipment & skill preview.

signal confirmed(class_id: String, hero_name: String)
signal cancelled()

var selected_class: String = "knight"
var _name_input: LineEdit
var _cards_row: HBoxContainer
var _preview_box: VBoxContainer
var _title_lbl: Label
var _confirm_btn: Button
var _cancel_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIFactory.full_rect(self)
	_build()
	refresh()

func open_modal() -> void:
	visible = true
	if _name_input != null and _name_input.text.strip_edges().is_empty():
		_name_input.text = Localization.tr_key("hero_default_name")
	refresh()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.08, 0.84)
	UIFactory.full_rect(dim)
	add_child(dim)

	var panel := UIFactory.panel(0.97)
	panel.anchor_left = 0.05
	panel.anchor_top = 0.05
	panel.anchor_right = 0.95
	panel.anchor_bottom = 0.95
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	_title_lbl = UIFactory.label("✦  " + Localization.tr_key("choose_hero"), 26, UIFactory.GOLD)
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_lbl)

	_cancel_btn = UIFactory.button(Localization.tr_key("close"), 42)
	_cancel_btn.custom_minimum_size = Vector2(115, 42)
	_cancel_btn.pressed.connect(func() -> void:
		visible = false
		cancelled.emit())
	header.add_child(_cancel_btn)

	root.add_child(UIFactory.hsep())

	# Hero Name Input Row
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 12)
	root.add_child(name_row)
	name_row.add_child(UIFactory.label(Localization.tr_key("hero_name"), 18, UIFactory.ACCENT))

	_name_input = LineEdit.new()
	_name_input.text = Localization.tr_key("hero_default_name")
	_name_input.max_length = 22
	_name_input.custom_minimum_size = Vector2(260, 42)
	var f := Localization.ui_font()
	if f != null:
		_name_input.add_theme_font_override("font", f)
	_name_input.add_theme_font_size_override("font_size", 18)
	name_row.add_child(_name_input)

	# 4 Class Cards Row
	_cards_row = HBoxContainer.new()
	_cards_row.add_theme_constant_override("separation", 10)
	root.add_child(_cards_row)

	# Selected Class Detailed Preview Card
	var prev_panel := UIFactory.card_panel(UIFactory.GOLD)
	prev_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(prev_panel)
	_preview_box = VBoxContainer.new()
	_preview_box.add_theme_constant_override("separation", 6)
	prev_panel.add_child(_preview_box)

	# Confirm Adventure Button
	_confirm_btn = UIFactory.button("⚔  " + Localization.tr_key("begin_journey"), 54)
	_confirm_btn.pressed.connect(func() -> void:
		var hname := _name_input.text.strip_edges() if _name_input != null else ""
		if hname.is_empty():
			hname = Localization.tr_key("hero_default_name")
		visible = false
		confirmed.emit(selected_class, hname))
	root.add_child(_confirm_btn)

func select_class(class_id: String) -> void:
	if HeroClassDB.has_class(class_id):
		selected_class = class_id
		if AudioManager != null:
			AudioManager.play_sfx("ui_click", -2.0, 1.08)
		refresh()

func refresh() -> void:
	Localization.apply_rtl(self)
	if _title_lbl != null:
		_title_lbl.text = "✦  " + Localization.tr_key("choose_hero")
	if _cancel_btn != null:
		_cancel_btn.text = Localization.tr_key("close")
	if _confirm_btn != null:
		_confirm_btn.text = "⚔  " + Localization.tr_key("begin_journey")

	if _cards_row != null:
		for c: Node in _cards_row.get_children():
			c.queue_free()
		for cid: String in HeroClassDB.all_class_ids():
			var def := HeroClassDB.get_class_def(cid)
			var is_sel := (cid == selected_class)
			var accent: Color = def.get("accent", UIFactory.GOLD) as Color
			var btn := UIFactory.button("%s  %s" % [String(def.get("glyph", "⚔")), Localization.class_title(cid)], 62)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.toggle_mode = true
			btn.button_pressed = is_sel
			btn.modulate = Color(1.12, 1.08, 0.96) if is_sel else Color(0.84, 0.86, 0.90)
			btn.add_theme_color_override("font_color", accent if is_sel else UIFactory.TEXT)
			btn.pressed.connect(func() -> void: select_class(cid))
			_cards_row.add_child(btn)

	if _preview_box != null:
		for c: Node in _preview_box.get_children():
			c.queue_free()
		var def := HeroClassDB.get_class_def(selected_class)
		var ar := Localization.is_arabic()
		var accent: Color = def.get("accent", UIFactory.GOLD) as Color
		_preview_box.add_child(UIFactory.label("%s  %s" % [String(def.get("glyph", "⚔")), Localization.class_title(selected_class)], 22, accent))
		_preview_box.add_child(UIFactory.wrapped_label(Localization.class_desc(selected_class), 15, UIFactory.TEXT))
		_preview_box.add_child(UIFactory.hsep())

		var hp := 100.0 + float(def.get("hp_bonus", 0.0))
		var mp := 60.0 + float(def.get("mp_bonus", 0.0))
		var sp := 100.0 + float(def.get("sp_bonus", 0.0))
		var atk := 10.0 + float(def.get("atk_bonus", 0.0))
		var df := 5.0 + float(def.get("def_bonus", 0.0))
		var mag := 8.0 + float(def.get("mag_bonus", 0.0))
		var crit := int(round((0.05 + float(def.get("crit_bonus", 0.0))) * 100.0))

		var stats_line := (
			"الصحة: %.0f  ·  المانا: %.0f  ·  النشاط: %.0f  ·  الهجوم: %.1f  ·  الدفاع: %.1f  ·  السحر: %.1f  ·  الحرجة: %d%%"
			% [hp, mp, sp, atk, df, mag, crit]
		) if ar else (
			"HP: %.0f  ·  MP: %.0f  ·  SP: %.0f  ·  ATK: %.1f  ·  DEF: %.1f  ·  MAG: %.1f  ·  CRIT: %d%%"
			% [hp, mp, sp, atk, df, mag, crit]
		)
		_preview_box.add_child(UIFactory.wrapped_label(stats_line, 15, UIFactory.GOLD))

		# Starting Gear & Signature Skill
		var gear_names: PackedStringArray = []
		for entry: Dictionary in def.get("items", []):
			var it := ItemDB.get_item(String(entry.get("id", "")))
			if it != null:
				var cnt := int(entry.get("count", 1))
				var nm := Localization.item_name(it)
				gear_names.append(("%s ×%d" % [nm, cnt]) if cnt > 1 else nm)
		var gear_prefix := "العتاد الابتدائي: " if ar else "Starting Loadout: "
		_preview_box.add_child(UIFactory.wrapped_label(gear_prefix + " · ".join(gear_names), 14, UIFactory.ACCENT))

		var s_id := String(def.get("starting_skill", ""))
		if not s_id.is_empty():
			var sk := SkillDB.get_skill(s_id)
			if sk != null:
				var sk_txt := ("المهارة الفطرية المفتوحة: %s (%s)" % [Localization.skill_title(sk), Localization.skill_desc(sk)]) if ar else ("Signature Starting Skill: %s (%s)" % [Localization.skill_title(sk), Localization.skill_desc(sk)])
				_preview_box.add_child(UIFactory.wrapped_label("★ " + sk_txt, 14, Color(0.68, 0.88, 1.0)))
		else:
			var free_txt := "★ يبدأ بنقطة مهارة حرة وترس البلوط المستدير للصد المتقن." if ar else "★ Starts with Oak Round Shield equipped + 1 Free Skill Point."
			_preview_box.add_child(UIFactory.wrapped_label(free_txt, 14, Color(0.68, 0.88, 1.0)))
