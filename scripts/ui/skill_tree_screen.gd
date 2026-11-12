class_name SkillTreeScreen
extends MenuScreen
## Interactive 4-Branch 24-Node Skill Tree UI:
##   - 4 Branches: Warrior, Mage, Ranger, Survival (6 tiered nodes each = 24 nodes)
##   - Custom _draw() prerequisite connector lines (gold=unlocked, emerald=ready, dim=locked)
##   - Zoom In / Out (75% - 135%) & Smooth Scrollable Canvas
##   - Detailed Right-Side Node Inspector + Unlock Button + Confirmed Reset Dialog

const BRANCH_META := {
	"warrior": {"key": "branch_warrior", "icon": "⚔", "color": Color(0.95, 0.45, 0.35), "col_x": 0},
	"mage": {"key": "branch_mage", "icon": "✦", "color": Color(0.42, 0.68, 1.0), "col_x": 1},
	"ranger": {"key": "branch_ranger", "icon": "🏹", "color": Color(0.92, 0.78, 0.38), "col_x": 2},
	"survival": {"key": "branch_survival", "icon": "🌿", "color": Color(0.38, 0.88, 0.56), "col_x": 3},
}

class TreeCanvas extends Control:
	var screen_ref: SkillTreeScreen

	func _draw() -> void:
		if screen_ref == null:
			return
		var z := screen_ref.zoom_scale
		for skill_id: String in screen_ref.node_buttons.keys():
			var skill := SkillDB.get_skill(skill_id)
			var to_btn := screen_ref.node_buttons[skill_id] as Control
			if skill == null or to_btn == null:
				continue
			var to_center := to_btn.position + to_btn.size * 0.5
			var rank := GameManager.skills.rank_of(skill_id)
			var can := GameManager.skills.can_upgrade(skill_id)
			for req_id: String in skill.prerequisites:
				if not screen_ref.node_buttons.has(req_id):
					continue
				var from_btn := screen_ref.node_buttons[req_id] as Control
				var from_center := from_btn.position + from_btn.size * 0.5
				var req_rank := GameManager.skills.rank_of(req_id)
				var line_col := Color(0.28, 0.34, 0.42, 0.65)
				var width := 2.5 * z
				if rank > 0 and req_rank > 0:
					line_col = UIFactory.GOLD
					width = 4.0 * z
				elif can and req_rank > 0:
					line_col = UIFactory.ACCENT
					width = 3.2 * z
				draw_line(from_center, to_center, Color(0, 0, 0, 0.55), width + 2.5)
				draw_line(from_center, to_center, line_col, width, true)

var zoom_scale: float = 1.0
var selected_skill_id: String = "mighty_blow"
var node_buttons: Dictionary = {}
var _canvas: TreeCanvas
var _inspector_box: VBoxContainer
var _points_label: Label
var _confirm_reset_box: HBoxContainer

func _ready() -> void:
	configure("Skill Tree", "skills")
	super._ready()
	EventBus.skill_tree_changed.connect(func() -> void:
		if visible:
			refresh())

func refresh() -> void:
	clear_content()
	node_buttons.clear()

	# Top Bar: Available Points, Spent Points, Zoom Controls, Reset Button
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	content.add_child(top)

	_points_label = UIFactory.label("%s: %d   (Lv %d · Spent: %d)" % [
		Localization.tr_key("skill_points"), GameManager.skills.points,
		GameManager.progression.level, GameManager.skills.total_spent_points()
	], 18, UIFactory.GOLD)
	_points_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_points_label)

	var zoom_out := UIFactory.button("−", 38)
	zoom_out.custom_minimum_size = Vector2(44, 38)
	zoom_out.pressed.connect(func() -> void:
		zoom_scale = clampf(zoom_scale - 0.15, 0.75, 1.35)
		refresh())
	top.add_child(zoom_out)

	top.add_child(UIFactory.label("%d%%" % int(round(zoom_scale * 100.0)), 15, UIFactory.TEXT_DIM))

	var zoom_in := UIFactory.button("+", 38)
	zoom_in.custom_minimum_size = Vector2(44, 38)
	zoom_in.pressed.connect(func() -> void:
		zoom_scale = clampf(zoom_scale + 0.15, 0.75, 1.35)
		refresh())
	top.add_child(zoom_in)

	var reset_btn := UIFactory.button(Localization.tr_key("reset_skills"), 38)
	reset_btn.disabled = GameManager.skills.total_spent_points() == 0
	reset_btn.pressed.connect(func() -> void:
		if _confirm_reset_box != null:
			_confirm_reset_box.visible = not _confirm_reset_box.visible)
	top.add_child(reset_btn)

	# Confirmation Banner for Skill Reset
	_confirm_reset_box = HBoxContainer.new()
	_confirm_reset_box.visible = false
	_confirm_reset_box.add_theme_constant_override("separation", 10)
	_confirm_reset_box.add_child(UIFactory.label("Refund all %d spent skill points?" % GameManager.skills.total_spent_points(), 15, UIFactory.GOLD))
	var yes_btn := UIFactory.button(Localization.tr_key("reset_confirm"), 36)
	yes_btn.pressed.connect(func() -> void:
		var refunded := GameManager.skills.reset_all()
		GameManager.recalc_stats()
		EventBus.skill_tree_changed.emit()
		EventBus.notify.emit("Refunded %d Skill Points!" % refunded)
		refresh())
	_confirm_reset_box.add_child(yes_btn)
	content.add_child(_confirm_reset_box)

	# Split: Left = Scrollable 4-Branch Tree Canvas | Right = Node Inspector Card
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 14)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(split)

	var tree_scroll := ScrollContainer.new()
	tree_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree_scroll.custom_minimum_size = Vector2(680, 430)
	split.add_child(tree_scroll)

	_canvas = TreeCanvas.new()
	_canvas.screen_ref = self
	var col_w := 196.0 * zoom_scale
	var row_h := 94.0 * zoom_scale
	_canvas.custom_minimum_size = Vector2(col_w * 4.0 + 36.0, row_h * 4.6 + 64.0)
	tree_scroll.add_child(_canvas)

	# Branch Column Headers & 24 Skill Nodes
	for b_key: String in ["warrior", "mage", "ranger", "survival"]:
		var meta: Dictionary = BRANCH_META[b_key]
		var col_idx := int(meta["col_x"])
		var base_x := 16.0 + float(col_idx) * col_w

		var hdr := UIFactory.label("%s %s" % [String(meta["icon"]), Localization.tr_key(String(meta["key"]))],
			int(17.0 * zoom_scale), meta["color"] as Color)
		hdr.position = Vector2(base_x, 8.0)
		hdr.size = Vector2(col_w - 14.0, 30.0)
		hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_canvas.add_child(hdr)

		var branch_skills := SkillDB.skills_for_branch(b_key)
		var tier_buckets: Dictionary = {}
		for s: SkillData in branch_skills:
			if not tier_buckets.has(s.tier):
				tier_buckets[s.tier] = []
			(tier_buckets[s.tier] as Array).append(s)

		for tier_key: int in tier_buckets.keys():
			var row_list: Array = tier_buckets[tier_key]
			for sub_idx: int in row_list.size():
				var s: SkillData = row_list[sub_idx]
				var btn := _make_node_button(s, meta["color"] as Color)
				var node_w := (col_w - 22.0) if row_list.size() == 1 else (col_w * 0.47)
				var node_h := 64.0 * zoom_scale
				var nx := base_x + (0.0 if row_list.size() == 1 else float(sub_idx) * (node_w + 8.0))
				var ny := 48.0 + float(tier_key) * row_h
				btn.position = Vector2(nx, ny)
				btn.size = Vector2(node_w, node_h)
				btn.custom_minimum_size = Vector2(node_w, node_h)
				_canvas.add_child(btn)
				node_buttons[s.id] = btn

	_canvas.queue_redraw()

	# Right Inspector Card
	var inspector_card := UIFactory.card_panel()
	inspector_card.custom_minimum_size = Vector2(290, 420)
	split.add_child(inspector_card)
	_inspector_box = VBoxContainer.new()
	_inspector_box.add_theme_constant_override("separation", 8)
	inspector_card.add_child(_inspector_box)
	_populate_inspector()

func _make_node_button(skill: SkillData, branch_col: Color) -> Button:
	var rank := GameManager.skills.rank_of(skill.id)
	var can := GameManager.skills.can_upgrade(skill.id)
	var disp := skill.title_ar if (Localization.is_arabic() and not skill.title_ar.is_empty()) else skill.title
	var label_txt := "%s %s\n[%d/%d]" % [skill.icon_glyph, disp, rank, skill.max_rank]
	var b := UIFactory.button(label_txt, int(58.0 * zoom_scale))
	b.add_theme_font_size_override("font_size", maxi(11, int(13.0 * zoom_scale)))
	b.clip_text = true

	var fill := Color(0.11, 0.14, 0.19, 0.94)
	var border := Color(0.32, 0.36, 0.44, 0.85)
	if rank >= skill.max_rank:
		fill = branch_col.darkened(0.55)
		border = UIFactory.GOLD
	elif rank > 0:
		fill = branch_col.darkened(0.65)
		border = branch_col.lightened(0.25)
	elif can:
		fill = Color(0.14, 0.24, 0.20, 0.96)
		border = UIFactory.ACCENT
	if selected_skill_id == skill.id:
		border = Color(1.0, 0.96, 0.76)

	var sb := UIFactory.make_panel_style(fill, border, 2, 8, 4)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", UIFactory.make_panel_style(fill.lightened(0.10), UIFactory.GOLD, 2, 8, 4))
	b.pressed.connect(func() -> void:
		selected_skill_id = skill.id
		refresh())
	return b

func _populate_inspector() -> void:
	for c: Node in _inspector_box.get_children():
		c.queue_free()
	var skill := SkillDB.get_skill(selected_skill_id)
	if skill == null:
		_inspector_box.add_child(UIFactory.label("Select a skill node", 16, UIFactory.TEXT_DIM))
		return

	var meta: Dictionary = BRANCH_META.get(skill.branch, BRANCH_META["warrior"])
	var ar := Localization.is_arabic()
	var disp := Localization.skill_title(skill)
	_inspector_box.add_child(UIFactory.label("%s  %s" % [skill.icon_glyph, disp], 20, meta["color"] as Color))
	var rank := GameManager.skills.rank_of(skill.id)
	_inspector_box.add_child(UIFactory.label(
		("المستوى %d · الرتبة %d / %d · التكلفة %d ن.م" if ar else "Tier %d · Rank %d / %d · Cost %d SP") % [
		skill.tier + 1, rank, skill.max_rank, skill.point_cost], 14, UIFactory.GOLD))
	_inspector_box.add_child(UIFactory.hsep())
	_inspector_box.add_child(UIFactory.wrapped_label(Localization.skill_desc(skill), 15, UIFactory.TEXT))

	if skill.required_level > 1:
		var lv_ok := GameManager.progression.level >= skill.required_level
		_inspector_box.add_child(UIFactory.label(("يتطلب مستوى البطل %d" if ar else "Requires Hero Level %d") % skill.required_level, 14,
			UIFactory.ACCENT if lv_ok else UIFactory.DANGER))

	if not skill.prerequisites.is_empty():
		var req_names: PackedStringArray = []
		for req_id: String in skill.prerequisites:
			var rs := SkillDB.get_skill(req_id)
			req_names.append(Localization.skill_title(rs) if rs != null else req_id)
		var req_met := GameManager.skills.prerequisites_met(skill.id)
		_inspector_box.add_child(UIFactory.wrapped_label(("المتطلب السابق: " if ar else "Prerequisite: ") + "، ".join(req_names), 14,
			UIFactory.ACCENT if req_met else UIFactory.DANGER))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_inspector_box.add_child(spacer)

	var can := GameManager.skills.can_upgrade(skill.id)
	var unlock_btn := UIFactory.button(
		"MAXED" if rank >= skill.max_rank else "%s (%d SP)" % [Localization.tr_key("unlock"), skill.point_cost], 48)
	unlock_btn.disabled = not can
	unlock_btn.pressed.connect(func() -> void:
		if GameManager.skills.upgrade(skill.id):
			GameManager.recalc_stats()
			EventBus.skill_tree_changed.emit()
			if AudioManager != null:
				AudioManager.play_sfx("level_up")
			EventBus.notify.emit("Unlocked %s (Rank %d)!" % [skill.title, GameManager.skills.rank_of(skill.id)])
			refresh())
	_inspector_box.add_child(unlock_btn)
