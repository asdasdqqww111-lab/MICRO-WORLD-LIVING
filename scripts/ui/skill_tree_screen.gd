class_name SkillTreeScreen
extends MenuScreen
## Interactive 24-Node 4-Branch RPG Skill Tree (Section 17):
##   - Branches: Warrior, Mage, Ranger, Survival (6 skills each = 24 skills)
##   - Zoomable (0.75x..1.30x) & scrollable node graph with custom _draw()
##     prerequisite connection lines (Gold = unlocked, Cyan = available, Grey = locked)
##   - Node inspector with prerequisites, level gate, rank, cost & Upgrade button
##   - Confirmed Skill Reset modal (refunds all spent skill points)

class SkillGraphCanvas extends Control:
	var edges: Array = []   # [{"from": Vector2, "to": Vector2, "color": Color, "width": float}]

	func _draw() -> void:
		for e: Dictionary in edges:
			var a := e["from"] as Vector2
			var b := e["to"] as Vector2
			var col := e["color"] as Color
			var w := float(e["width"])
			var mid_y := (a.y + b.y) * 0.5
			draw_line(a, Vector2(a.x, mid_y), col, w, true)
			draw_line(Vector2(a.x, mid_y), Vector2(b.x, mid_y), col, w, true)
			draw_line(Vector2(b.x, mid_y), b, col, w, true)
			draw_circle(b, w * 1.4, col)

const BRANCH_META := {
	"warrior": {"label": "⚔ Warrior", "color": Color(0.92, 0.42, 0.34)},
	"mage": {"label": "🔥 Mage", "color": Color(0.42, 0.70, 1.0)},
	"ranger": {"label": "🏹 Ranger", "color": Color(0.46, 0.84, 0.50)},
	"survival": {"label": "🌿 Survival", "color": Color(0.92, 0.76, 0.34)},
}

var _branch_filter: String = "all"
var _zoom: float = 1.0
var _selected_skill_id: String = "mighty_blow"
var _confirming_reset: bool = false

func _ready() -> void:
	configure("Skill Tree", "skills")
	super._ready()
	EventBus.skill_tree_changed.connect(func() -> void:
		if visible:
			refresh())

func refresh() -> void:
	clear_content()
	SkillDB.ensure_loaded()

	# Top Control Bar: Available Skill Points, Branch Filter Tabs, Zoom Controls & Reset
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 8)
	content.add_child(top_bar)

	var pts_lbl := UIFactory.label("%s: %d   |   %s %d" % [
		Localization.tr_key("skill_points"), GameManager.skills.points,
		Localization.tr_key("level"), GameManager.progression.level], 18, UIFactory.GOLD)
	top_bar.add_child(pts_lbl)

	var spacer_ctrl := Control.new()
	spacer_ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer_ctrl)

	for bf: String in ["all", "warrior", "mage", "ranger", "survival"]:
		var b_title := "All (24)" if bf == "all" else Localization.tr_key("branch_" + bf)
		var tab := UIFactory.button(b_title, 38)
		tab.toggle_mode = true
		tab.button_pressed = (_branch_filter == bf)
		tab.pressed.connect(func() -> void:
			_branch_filter = bf
			_confirming_reset = false
			refresh())
		top_bar.add_child(tab)

	var zoom_out := UIFactory.button("−", 38)
	zoom_out.custom_minimum_size = Vector2(40, 38)
	zoom_out.pressed.connect(func() -> void:
		_zoom = clampf(_zoom - 0.15, 0.75, 1.30)
		refresh())
	top_bar.add_child(zoom_out)

	var zoom_in := UIFactory.button("+", 38)
	zoom_in.custom_minimum_size = Vector2(40, 38)
	zoom_in.pressed.connect(func() -> void:
		_zoom = clampf(_zoom + 0.15, 0.75, 1.30)
		refresh())
	top_bar.add_child(zoom_in)

	content.add_child(UIFactory.hsep())

	# Split Body: Scrollable/Zoomable Interactive Graph (Left) + Skill Inspector (Right)
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.custom_minimum_size = Vector2(0, 430)
	split.add_theme_constant_override("separation", 12)
	content.add_child(split)

	var graph_scroll := ScrollContainer.new()
	graph_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	graph_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	split.add_child(graph_scroll)

	var canvas := _build_graph_canvas()
	graph_scroll.add_child(canvas)

	var inspector := UIFactory.card_panel()
	inspector.custom_minimum_size = Vector2(290, 0)
	split.add_child(inspector)
	_populate_inspector(inspector)

func _build_graph_canvas() -> SkillGraphCanvas:
	var canvas := SkillGraphCanvas.new()
	var branches_to_show: Array[String] = []
	if _branch_filter == "all":
		branches_to_show.assign(SkillDB.BRANCHES)
	else:
		branches_to_show.append(_branch_filter)

	var col_w := 315.0 * _zoom
	var tier_h := 118.0 * _zoom
	var node_w := 136.0 * _zoom
	var node_h := 74.0 * _zoom
	canvas.custom_minimum_size = Vector2(maxf(580.0, float(branches_to_show.size()) * col_w + 40.0), 4.0 * tier_h + 70.0)

	var centers: Dictionary = {}   # skill_id -> Vector2

	for b_idx: int in branches_to_show.size():
		var b_name := branches_to_show[b_idx]
		var meta: Dictionary = BRANCH_META[b_name]
		var base_x := 20.0 + float(b_idx) * col_w

		var hdr := UIFactory.label(Localization.tr_key("branch_" + b_name), int(18.0 * _zoom), meta["color"] as Color)
		hdr.position = Vector2(base_x, 8.0)
		hdr.custom_minimum_size = Vector2(col_w - 20.0, 28.0)
		hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		canvas.add_child(hdr)

		var branch_skills := SkillDB.skills_for_branch(b_name)
		for skill: SkillData in branch_skills:
			var nx := base_x + float(skill.column) * (node_w + 16.0 * _zoom)
			if skill.tier >= 2 and _has_single_node_in_tier(branch_skills, skill.tier):
				nx = base_x + (node_w + 16.0 * _zoom) * 0.5
			var ny := 46.0 + float(skill.tier) * tier_h
			centers[skill.id] = Vector2(nx + node_w * 0.5, ny + node_h * 0.5)

			var btn := _create_skill_node_button(skill, Vector2(nx, ny), Vector2(node_w, node_h), meta["color"] as Color)
			canvas.add_child(btn)

	# Build prerequisite connection lines
	var edges: Array = []
	for b_name: String in branches_to_show:
		for skill: SkillData in SkillDB.skills_for_branch(b_name):
			if not centers.has(skill.id):
				continue
			var dst := centers[skill.id] as Vector2
			for pre_id: String in skill.prerequisites:
				if not centers.has(pre_id):
					continue
				var src := centers[pre_id] as Vector2
				var unlocked := GameManager.skills.rank_of(skill.id) > 0
				var avail := GameManager.skills.rank_of(pre_id) > 0
				var line_col := UIFactory.GOLD if unlocked else (Color(0.40, 0.80, 1.0, 0.9) if avail else Color(0.32, 0.36, 0.42, 0.75))
				edges.append({
					"from": src + Vector2(0.0, node_h * 0.48),
					"to": dst - Vector2(0.0, node_h * 0.48),
					"color": line_col,
					"width": 3.2 if unlocked else 2.2,
				})
	canvas.edges = edges
	canvas.queue_redraw()
	return canvas

func _has_single_node_in_tier(list: Array[SkillData], tier: int) -> bool:
	var c := 0
	for s: SkillData in list:
		if s.tier == tier:
			c += 1
	return c == 1

func _create_skill_node_button(skill: SkillData, pos: Vector2, sz: Vector2, branch_col: Color) -> Button:
	var rank := GameManager.skills.rank_of(skill.id)
	var maxed := rank >= skill.max_rank
	var can_up := GameManager.skills.can_upgrade(skill.id, GameManager.progression.level)
	var title_txt := skill.title_ar if (Localization.is_arabic() and not skill.title_ar.is_empty()) else skill.title

	var btn := Button.new()
	btn.theme = UIFactory.theme()
	btn.position = pos
	btn.custom_minimum_size = sz
	btn.size = sz
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = "%s %s\n[%d/%d]" % [skill.icon_glyph, title_txt, rank, skill.max_rank]
	btn.add_theme_font_size_override("font_size", maxi(12, int(13.0 * _zoom)))

	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(3 if _selected_skill_id == skill.id else 2)
	if maxed:
		sb.bg_color = Color(0.24, 0.20, 0.08, 0.96)
		sb.border_color = UIFactory.GOLD
	elif rank > 0:
		sb.bg_color = branch_col.darkened(0.68)
		sb.border_color = branch_col.lightened(0.18)
	elif can_up:
		sb.bg_color = Color(0.14, 0.22, 0.30, 0.96)
		sb.border_color = Color(0.45, 0.85, 1.0)
	else:
		sb.bg_color = Color(0.09, 0.10, 0.13, 0.88)
		sb.border_color = Color(0.28, 0.30, 0.35)
	if _selected_skill_id == skill.id:
		sb.border_color = Color.WHITE
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

	btn.pressed.connect(func() -> void:
		_selected_skill_id = skill.id
		_confirming_reset = false
		if AudioManager != null:
			AudioManager.play_sfx("ui_click", -5.0)
		refresh())
	return btn

func _populate_inspector(panel_box: PanelContainer) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel_box.add_child(box)

	var skill := SkillDB.get_skill(_selected_skill_id)
	if skill == null:
		box.add_child(UIFactory.label("Select a skill node", 16, UIFactory.TEXT_DIM))
		return

	var rank := GameManager.skills.rank_of(skill.id)
	var title_txt := skill.title_ar if (Localization.is_arabic() and not skill.title_ar.is_empty()) else skill.title
	box.add_child(UIFactory.label("%s  %s" % [skill.icon_glyph, title_txt], 20, UIFactory.GOLD))
	box.add_child(UIFactory.label("%s · Rank %d / %d" % [
		Localization.tr_key("branch_" + skill.branch), rank, skill.max_rank], 14, UIFactory.ACCENT))
	box.add_child(UIFactory.hsep())

	box.add_child(UIFactory.wrapped_label(skill.description, 15, UIFactory.TEXT))
	box.add_child(UIFactory.label("Required Level: %d   |   Cost: %d pt" % [skill.required_level, skill.point_cost],
		14, UIFactory.TEXT_DIM))

	if not skill.prerequisites.is_empty():
		var pre_names: PackedStringArray = []
		for pid: String in skill.prerequisites:
			var ps := SkillDB.get_skill(pid)
			var met := GameManager.skills.rank_of(pid) > 0
			pre_names.append(("%s " % ("✔" if met else "✖")) + (ps.title if ps != null else pid))
		box.add_child(UIFactory.wrapped_label("Requires: " + ", ".join(pre_names), 14,
			UIFactory.ACCENT if GameManager.skills.prerequisites_met(skill.id) else UIFactory.DANGER))

	var upgrade_btn := UIFactory.button(
		"Max Rank Reached" if rank >= skill.max_rank else ("%s (%d pt)" % [Localization.tr_key("unlock_skill"), skill.point_cost]), 46)
	upgrade_btn.disabled = not GameManager.skills.can_upgrade(skill.id, GameManager.progression.level)
	upgrade_btn.pressed.connect(func() -> void:
		if GameManager.upgrade_skill(skill.id):
			refresh())
	box.add_child(upgrade_btn)

	box.add_child(UIFactory.spacer(8))
	box.add_child(UIFactory.hsep())

	# Confirmed Skill Reset Section
	var spent := GameManager.skills.total_spent_points()
	if not _confirming_reset:
		var reset_btn := UIFactory.button("%s (%dg)" % [Localization.tr_key("reset_skills"), GameManager.SKILL_RESET_COST], 40)
		reset_btn.disabled = spent <= 0
		reset_btn.pressed.connect(func() -> void:
			_confirming_reset = true
			refresh())
		box.add_child(reset_btn)
	else:
		box.add_child(UIFactory.wrapped_label("Refund all %d spent skill points for %d Gold?" % [spent, GameManager.SKILL_RESET_COST], 14, UIFactory.GOLD))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var yes_btn := UIFactory.button("Confirm Reset", 40)
		yes_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		yes_btn.pressed.connect(func() -> void:
			_confirming_reset = false
			GameManager.reset_skill_tree(true)
			refresh())
		var no_btn := UIFactory.button("Cancel", 40)
		no_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		no_btn.pressed.connect(func() -> void:
			_confirming_reset = false
			refresh())
		row.add_child(yes_btn)
		row.add_child(no_btn)
		box.add_child(row)
