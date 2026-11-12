class_name CharacterVisual
extends Node3D
## Animated character wrapper supporting KayKit Human Adventures (Knight, Mage,
## Rogue, Barbarian) + Skeleton rigs, 18-state AnimationNodeStateMachine, and
## dynamic 3D weapon/shield/helmet equipment toggling.

const CLIP_ALIASES := {
	"idle": ["Idle", "Idle_B", "2H_Melee_Idle", "Unarmed_Idle"],
	"walk": ["Walking_A", "Walking_B", "Walking_C"],
	"run": ["Running_A", "Running_B"],
	"sprint": ["Running_B", "Running_A"],
	"jump": ["Jump_Start", "Jump_Full_Short"],
	"fall": ["Jump_Idle", "Jump_Full_Long"],
	"land": ["Jump_Land"],
	"dodge": ["Dodge_Forward", "Dodge_Right", "Dodge_Left", "Jump_Full_Short"],
	"block": ["Block", "Blocking", "Block_Attack", "2H_Melee_Idle"],
	"attack_1": ["1H_Melee_Attack_Slice_Diagonal", "1H_Melee_Attack_Chop", "Unarmed_Melee_Attack_Punch_A"],
	"attack_2": ["1H_Melee_Attack_Slice_Horizontal", "1H_Melee_Attack_Stab", "Unarmed_Melee_Attack_Punch_B"],
	"attack_heavy": ["2H_Melee_Attack_Spin", "2H_Melee_Attack_Chop", "1H_Melee_Attack_Jump_Chop", "1H_Melee_Attack_Chop"],
	"cast": ["Spellcast_Shoot", "Spellcast_Raise", "Spellcast_Long", "Interact"],
	"hit": ["Hit_A", "Hit_B", "Block_Hit"],
	"death": ["Death_A", "Death_B", "Death_C_Skeletons"],
	"interact": ["Interact", "PickUp", "Use_Item"],
	"sit": ["Sit_Chair_Idle", "Sit_Floor_Idle"],
	"lie": ["Lie_Idle"],
	"cheer": ["Cheer", "Taunt"],
}

var model: Node3D
var anim_player: AnimationPlayer
var tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback
var available_states: Dictionary = {}
var current_state: String = ""
var _submeshes: Dictionary = {}

func setup(model_path: String, model_scale: float = 1.0) -> bool:
	var inst := AssetLibrary.instantiate(model_path, model_scale)
	if inst == null:
		push_warning("CharacterVisual: missing model %s" % model_path)
		return false
	model = inst
	model.name = "Model"
	add_child(model)
	_index_meshes_and_shadows(model)
	anim_player = _find_animation_player(model)
	if anim_player != null:
		_build_state_machine()
	play("idle")
	return true

func attach_existing(model_root: Node3D) -> void:
	model = model_root
	add_child(model)
	_index_meshes_and_shadows(model)
	anim_player = _find_animation_player(model)
	if anim_player != null:
		_build_state_machine()
	play("idle")

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child: Node in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _index_meshes_and_shadows(root: Node) -> void:
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		_submeshes[String(mi.name)] = mi
		# Only primary torso/limb silhouettes need shadow casting on mobile
		var sz := mi.get_aabb().size.length()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sz >= 0.75 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child: Node in root.get_children():
		_index_meshes_and_shadows(child)

## Toggle built-in KayKit gear submeshes (e.g. Knight_Helmet, 1H_Sword, Rectangle_Shield).
func configure_gear(visible_substrings: Array, hidden_substrings: Array) -> void:
	for mesh_name: String in _submeshes.keys():
		var mi := _submeshes[mesh_name] as MeshInstance3D
		if mi == null:
			continue
		var low := mesh_name.to_lower()
		for h: Variant in hidden_substrings:
			if low.contains(String(h).to_lower()):
				mi.visible = false
		for v: Variant in visible_substrings:
			if low.contains(String(v).to_lower()):
				mi.visible = true

## Dynamically updates Hero 3D equipment meshes across all 4 playable KayKit rigs!
func sync_player_equipment(inventory: Inventory, hero_class: String = "") -> void:
	if inventory == null or _submeshes.is_empty():
		return
	var cls := hero_class if not hero_class.is_empty() else (GameManager.hero_class if GameManager != null else "knight")
	var weapon_id := inventory.equipped("weapon")
	var shield_id := inventory.equipped("shield")
	var helmet_id := inventory.equipped("helmet")
	var armor_id := inventory.equipped("armor")

	for k: String in _submeshes.keys():
		var low := k.to_lower()
		var mi := _submeshes[k] as MeshInstance3D
		if mi == null:
			continue
		if cls == "mage":
			if k == "2H_Staff":
				mi.visible = not weapon_id.is_empty()
			elif k == "1H_Wand" or k == "Spellbook":
				mi.visible = false
			elif k == "Spellbook_open":
				mi.visible = not shield_id.is_empty() or not inventory.equipped("accessory").is_empty()
			elif k == "Mage_Hat":
				mi.visible = true
			elif k == "Mage_Cape":
				mi.visible = true
			continue
		if cls == "ranger":
			if k == "Knife":
				mi.visible = not weapon_id.is_empty()
			elif k == "Knife_Offhand":
				mi.visible = not weapon_id.is_empty() and shield_id.is_empty()
			elif k == "1H_Crossbow":
				mi.visible = not shield_id.is_empty()
			elif k == "2H_Crossbow" or k == "Throwable":
				mi.visible = false
			elif k == "Rogue_Cape":
				mi.visible = true
			continue
		if cls == "barbarian":
			if k == "2H_Axe":
				mi.visible = (weapon_id == "steel_greatsword")
			elif k == "1H_Axe":
				mi.visible = not weapon_id.is_empty() and weapon_id != "steel_greatsword"
			elif k == "1H_Axe_Offhand":
				mi.visible = not weapon_id.is_empty() and shield_id.is_empty() and weapon_id != "steel_greatsword"
			elif k == "Barbarian_Round_Shield":
				mi.visible = not shield_id.is_empty()
			elif k == "Mug":
				mi.visible = false
			elif k == "Barbarian_Hat":
				mi.visible = not helmet_id.is_empty()
			elif k == "Barbarian_Cape":
				mi.visible = true
			continue
		# Default Knight rig
		if low.contains("offhand"):
			mi.visible = false
		elif low == "1h_sword":
			mi.visible = not weapon_id.is_empty() and weapon_id != "steel_greatsword"
		elif low == "2h_sword":
			mi.visible = (weapon_id == "steel_greatsword")
		elif low.contains("shield"):
			if k == "Round_Shield":
				mi.visible = (shield_id == "oak_shield")
			elif k == "Spike_Shield":
				mi.visible = (shield_id == "iron_shield")
			elif k == "Badge_Shield":
				mi.visible = (shield_id == "guild_aegis")
			else:
				mi.visible = (not shield_id.is_empty() and shield_id != "oak_shield" and shield_id != "iron_shield" and shield_id != "guild_aegis")
		elif low.contains("helmet"):
			mi.visible = not helmet_id.is_empty()
		elif low.contains("cape"):
			mi.visible = not armor_id.is_empty()

func _resolve_clip(aliases: Array) -> String:
	if anim_player == null:
		return ""
	var clips := anim_player.get_animation_list()
	for alias: String in aliases:
		if clips.has(alias):
			return alias
	for alias: String in aliases:
		for clip: String in clips:
			if clip.to_lower().contains(alias.to_lower()):
				return clip
	return ""

func _build_state_machine() -> void:
	var sm := AnimationNodeStateMachine.new()
	available_states.clear()
	for state_name: String in CLIP_ALIASES:
		var clip := _resolve_clip(CLIP_ALIASES[state_name])
		if clip.is_empty():
			continue
		var anim_node := AnimationNodeAnimation.new()
		anim_node.animation = clip
		sm.add_node(state_name, anim_node, Vector2.ZERO)
		available_states[state_name] = clip
		if ["idle", "walk", "run", "sprint", "fall", "block", "sit", "lie"].has(state_name):
			var anim := anim_player.get_animation(clip)
			if anim != null:
				anim.loop_mode = Animation.LOOP_LINEAR
	if available_states.is_empty():
		return
	var names: Array = available_states.keys()
	for from_name: String in names:
		for to_name: String in names:
			if from_name == to_name:
				continue
			var transition := AnimationNodeStateMachineTransition.new()
			var fast := to_name.begins_with("attack") or to_name == "dodge" or to_name == "block" or to_name == "cast"
			transition.xfade_time = 0.08 if fast else 0.16
			transition.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
			sm.add_transition(from_name, to_name, transition)
	tree = AnimationTree.new()
	tree.name = "AnimationTree"
	add_child(tree)
	tree.anim_player = tree.get_path_to(anim_player)
	tree.tree_root = sm
	tree.active = true
	playback = tree.get("parameters/playback") as AnimationNodeStateMachinePlayback

func has_state(state_name: String) -> bool:
	return available_states.has(state_name)

func play(state_name: String, force: bool = false) -> void:
	if state_name == "attack":
		state_name = "attack_1"
	if state_name == current_state and not force:
		return
	if playback == null:
		return
	if not available_states.has(state_name):
		if state_name == "idle":
			return
		state_name = "idle" if available_states.has("idle") else String(available_states.keys()[0])
	current_state = state_name
	playback.travel(state_name)

func play_once(state_name: String) -> void:
	if anim_player == null:
		return
	var clip: String = available_states.get(state_name, "")
	if clip.is_empty():
		return
	if tree != null:
		tree.active = false
	var anim := anim_player.get_animation(clip)
	if anim != null:
		anim.loop_mode = Animation.LOOP_NONE
	anim_player.play(clip)
	current_state = state_name

func resume_tree() -> void:
	if tree != null:
		tree.active = true
	current_state = ""

func tint(color: Color) -> void:
	if model == null:
		return
	_tint_recursive(model, color)

func _tint_recursive(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var base := mi.get_active_material(0)
		if base is StandardMaterial3D:
			var mat := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
			mat.albedo_color = mat.albedo_color * color
			mi.material_override = mat
		else:
			var std := StandardMaterial3D.new()
			std.albedo_color = color
			mi.material_override = std
	for child: Node in node.get_children():
		_tint_recursive(child, color)

func head_position() -> Vector3:
	return global_position + Vector3.UP * 1.85
