class_name CharacterVisual
extends Node3D
## Realistic Human-Proportioned Animated Character Controller.
## Supports Realistic Medieval Knight (HumanArmature), Quaternius Realistic RPG Cast
## (CharacterArmature — 24 clips), and Skeleton Monster rigs, plus real 3D BoneAttachment3D
## weapon & shield sockets with PBR metallic/normal materials.

const CLIP_ALIASES := {
	"idle": ["HumanArmature|Idle_swordRight", "HumanArmature|Idle", "Idle_Sword", "Idle_Neutral", "Idle", "Idle_B", "2H_Melee_Idle", "Unarmed_Idle", "idle", "movement", "clip"],
	"idle_combat": ["HumanArmature|Idle_swordRight", "Idle_Sword", "Idle_Combat", "2H_Melee_Idle", "Idle", "holding-right"],
	"walk": ["HumanArmature|Walking", "Walk", "Walking_A", "Walking_B", "Walking_C", "Walking_D_Skeletons", "walk", "movement", "clip"],
	"walk_back": ["Run_Back", "Walking_Backwards", "HumanArmature|Walking", "Walk", "Walking_A", "walk"],
	"run": ["HumanArmature|Run_swordRight", "HumanArmature|Run", "Run", "Running_A", "Running_B", "Running_C", "sprint", "movement", "clip"],
	"sprint": ["HumanArmature|Run", "Run", "Running_B", "Running_A", "sprint", "movement", "clip"],
	"strafe_left": ["Run_Left", "Running_Strafe_Left", "HumanArmature|Walking", "Walk", "Walking_A"],
	"strafe_right": ["Run_Right", "Running_Strafe_Right", "HumanArmature|Walking", "Walk", "Walking_B"],
	"jump": ["HumanArmature|Jump", "Jump_Start", "Jump_Full_Short", "Roll", "jump"],
	"fall": ["HumanArmature|Jump", "Jump_Idle", "Jump_Full_Long", "Idle", "fall"],
	"land": ["Jump_Land", "HumanArmature|Idle_swordRight", "Idle"],
	"dodge": ["HumanArmature|Roll_sword", "HumanArmature|Roll", "Roll", "Dodge_Forward", "Jump_Full_Short"],
	"dodge_back": ["HumanArmature|Roll", "Roll", "Dodge_Backward", "Dodge_Forward"],
	"dodge_left": ["HumanArmature|Roll", "Roll", "Dodge_Left", "Dodge_Forward"],
	"dodge_right": ["HumanArmature|Roll", "Roll", "Dodge_Right", "Dodge_Forward"],
	"block": ["HumanArmature|Idle_swordLeft", "Idle_Sword", "Blocking", "Block", "2H_Melee_Idle"],
	"block_hit": ["HitRecieve", "Block_Hit", "Block_Attack", "Block", "HumanArmature|Idle_swordLeft"],
	"attack_1": ["HumanArmature|Run_swordAttack", "Sword_Slash", "1H_Melee_Attack_Slice_Diagonal", "Punch_Right", "attack-melee-right"],
	"attack_2": ["Sword_Slash", "Punch_Left", "HumanArmature|Run_swordAttack", "1H_Melee_Attack_Slice_Horizontal", "1H_Melee_Attack_Stab"],
	"attack_3": ["HumanArmature|swordAttackJump", "Kick_Right", "Sword_Slash", "1H_Melee_Attack_Jump_Chop", "1H_Melee_Attack_Chop"],
	"attack_dual_1": ["Sword_Slash", "Dualwield_Melee_Attack_Slice", "HumanArmature|Run_swordAttack", "1H_Melee_Attack_Slice_Diagonal"],
	"attack_dual_2": ["Punch_Left", "Dualwield_Melee_Attack_Stab", "Sword_Slash"],
	"attack_2h_1": ["HumanArmature|swordAttackJump", "Sword_Slash", "2H_Melee_Attack_Slice", "1H_Melee_Attack_Slice_Diagonal"],
	"attack_2h_2": ["HumanArmature|Run_swordAttack", "Kick_Left", "2H_Melee_Attack_Chop", "1H_Melee_Attack_Chop"],
	"attack_ranged": ["Gun_Shoot", "Run_Shoot", "1H_Ranged_Shoot", "2H_Ranged_Shoot", "Sword_Slash"],
	"attack_heavy": ["HumanArmature|swordAttackJump", "Kick_Right", "Sword_Slash", "2H_Melee_Attack_Spin", "2H_Melee_Attack_Chop"],
	"cast": ["Wave", "Interact", "Spellcast_Shoot", "Spellcast_Raise", "Spellcast_Long", "HumanArmature|Run_swordAttack"],
	"cast_summon": ["Wave", "Spellcast_Summon", "Spellcast_Raise", "Interact"],
	"hit": ["HitRecieve", "HitRecieve_2", "Hit_A", "Hit_B", "HumanArmature|Idle_swordLeft"],
	"death": ["HumanArmature|Death", "Death", "Death_A", "Death_B", "Death_C_Skeletons", "die"],
	"interact": ["Interact", "Wave", "PickUp", "Use_Item", "HumanArmature|Idle", "interact-right"],
	"pickup": ["Interact", "PickUp", "HumanArmature|Idle"],
	"use_item": ["Interact", "Use_Item", "Wave"],
	"sit": ["Idle_Neutral", "Sit_Chair_Idle", "Sit_Floor_Idle", "HumanArmature|Idle", "sit"],
	"lie": ["Death", "Lie_Idle", "HumanArmature|Death"],
	"cheer": ["Wave", "Cheer", "HumanArmature|Jump", "emote-yes"],
	"taunt": ["Wave", "Taunt", "Taunt_Longer", "Cheer"],
	"spawn": ["Skeletons_Awaken_Floor", "Spawn_Ground", "Idle", "HumanArmature|Idle"],
	"work_hammer": ["Sword_Slash", "Punch_Right", "1H_Melee_Attack_Chop", "Interact"],
	"work_pray": ["Wave", "Interact", "Spellcast_Long", "Idle"],
}

var model: Node3D
var anim_player: AnimationPlayer
var tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback
var available_states: Dictionary = {}
var current_state: String = ""
var _submeshes: Dictionary = {}
var _skeleton: Skeleton3D
var _weapon_socket: BoneAttachment3D
var _shield_socket: BoneAttachment3D
var _equipped_weapon_node: Node3D
var _equipped_shield_node: Node3D
var _model_path: String = ""

func setup(model_path: String, model_scale: float = 1.0) -> bool:
	_model_path = model_path
	var norm_scale := model_scale * AssetLibrary.character_base_scale(model_path)
	var inst := AssetLibrary.instantiate(model_path, norm_scale)
	if inst == null:
		push_warning("CharacterVisual: missing model %s" % model_path)
		return false
	model = inst
	model.name = "Model"
	add_child(model)
	_skeleton = _find_skeleton(model)
	_merge_skinned_submeshes(model)
	_index_meshes_and_shadows(model)
	_hide_default_accessory_submeshes()
	_apply_chibi_hero_shader_if_kaykit(model_path)
	_setup_hand_sockets()
	anim_player = _find_animation_player(model)
	if anim_player != null:
		_build_state_machine()
	play("idle")
	return true

## Collapse multi-part skinned body submeshes (Body, Head, Arms, Legs) sharing the same Skeleton3D
## into ONE single-surface skinned MeshInstance3D (~6x fewer skinned draw calls per character!).
func _merge_skinned_submeshes(root: Node) -> void:
	if _skeleton == null:
		return
	var skinned: Array[MeshInstance3D] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c: Node in n.get_children():
			stack.append(c)
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.skin != null and mi.mesh != null and mi.visible:
				skinned.append(mi)
	if skinned.size() <= 1:
		return
	var primary := skinned[0]
	var base_mat: Material = primary.get_surface_override_material(0)
	if base_mat == null and primary.mesh.get_surface_count() > 0:
		base_mat = primary.mesh.surface_get_material(0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var appended := 0
	for mi: MeshInstance3D in skinned:
		for s: int in mi.mesh.get_surface_count():
			st.append_from(mi.mesh, s, Transform3D.IDENTITY)
			appended += 1
	if appended == 0:
		return
	var combined := st.commit()
	if base_mat != null and combined.get_surface_count() > 0:
		combined.surface_set_material(0, base_mat)
	primary.name = "CombinedBodySkin"
	primary.mesh = combined
	for i in range(1, skinned.size()):
		var extra := skinned[i]
		if extra.get_parent() != null:
			extra.get_parent().remove_child(extra)
		extra.free()

## Hide non-skinned optional KayKit equipment/props by default until explicitly enabled.
func _hide_default_accessory_submeshes() -> void:
	var gear_tokens := [
		"sword", "shield", "helmet", "cape", "axe", "dagger", "crossbow",
		"bow", "wand", "staff", "spellbook", "mug", "hood", "hat", "quiver",
	]
	for mesh_name: String in _submeshes.keys():
		var mi := _submeshes[mesh_name] as MeshInstance3D
		if mi == null or mi.skin != null:
			continue
		var low := mesh_name.to_lower()
		for tok: String in gear_tokens:
			if low.contains(tok):
				mi.visible = false
				break

func _apply_chibi_hero_shader_if_kaykit(model_path: String) -> void:
	if not model_path.contains("Knight.glb"):
		return
	for hidden_part: String in ["Knight_Helmet", "Knight_Cape", "1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield", "1H_Sword", "2H_Sword"]:
		if _submeshes.has(hidden_part):
			(_submeshes[hidden_part] as MeshInstance3D).visible = false
	var rim_mat := ArtDirection.chibi_knight_rim_material()
	for mesh_name: String in _submeshes.keys():
		var mi := _submeshes[mesh_name] as MeshInstance3D
		if mi != null:
			mi.material_override = rim_mat

func attach_existing(model_root: Node3D) -> void:
	model = model_root
	add_child(model)
	_skeleton = _find_skeleton(model)
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

func _find_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child: Node in root.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _setup_hand_sockets() -> void:
	if _skeleton == null:
		return
	var r_bone := _find_bone_name(["Palm.R", "Wrist.R", "Hand.R", "handslot.r"])
	if not r_bone.is_empty():
		_weapon_socket = BoneAttachment3D.new()
		_weapon_socket.name = "WeaponSocket"
		_weapon_socket.bone_name = r_bone
		_skeleton.add_child(_weapon_socket)
	var l_bone := _find_bone_name(["Palm.L", "Wrist.L", "Hand.L", "handslot.l"])
	if not l_bone.is_empty():
		_shield_socket = BoneAttachment3D.new()
		_shield_socket.name = "ShieldSocket"
		_shield_socket.bone_name = l_bone
		_skeleton.add_child(_shield_socket)

func _find_bone_name(candidates: Array) -> String:
	if _skeleton == null:
		return ""
	for c: String in candidates:
		if _skeleton.find_bone(c) >= 0:
			return c
	return ""

func _skeleton_world_scale() -> float:
	if _skeleton == null or model == null:
		return 1.0
	var s := model.scale.x
	var p: Node = _skeleton
	while p != null and p != model:
		if p is Node3D:
			s *= maxf(0.001, absf((p as Node3D).scale.x))
		p = p.get_parent()
	return maxf(0.01, s)

func _attach_socket_model(socket: BoneAttachment3D, path: String, desired_meters: float, raw_meters: float, rot_deg: Vector3) -> Node3D:
	if socket == null or not AssetLibrary.has_model(path):
		return null
	var local_s := desired_meters / maxf(0.01, raw_meters * _skeleton_world_scale())
	var n := AssetLibrary.instantiate(path, local_s)
	if n == null:
		return null
	n.rotation_degrees = rot_deg
	for child: Node in n.find_children("*", "GeometryInstance3D", true, false):
		(child as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	socket.add_child(n)
	return n

func _index_meshes_and_shadows(root: Node) -> void:
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		_submeshes[String(mi.name)] = mi
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child: Node in root.get_children():
		_index_meshes_and_shadows(child)

## Toggle built-in submeshes OR attach realistic hand gear for NPCs.
func configure_gear(visible_substrings: Array, hidden_substrings: Array) -> void:
	var matched_builtin := false
	for mesh_name: String in _submeshes.keys():
		var mi := _submeshes[mesh_name] as MeshInstance3D
		if mi == null or mi.skin != null:
			continue
		var low := mesh_name.to_lower()
		for h: Variant in hidden_substrings:
			if low.contains(String(h).to_lower()):
				mi.visible = false
		for v: Variant in visible_substrings:
			if low.contains(String(v).to_lower()):
				mi.visible = true
				matched_builtin = true
	if not matched_builtin and _weapon_socket != null and _equipped_weapon_node == null:
		for v: Variant in visible_substrings:
			var vs := String(v).to_lower()
			if vs.contains("sword") or vs.contains("axe"):
				_equipped_weapon_node = _attach_socket_model(_weapon_socket,
					AssetLibrary.REALISTIC_WEAPONS_DIR + "knight_longsword.glb", 1.05, 4.35, Vector3(0.0, 0.0, 90.0))
				break
			elif vs.contains("crossbow") or vs.contains("bow"):
				_equipped_weapon_node = _attach_socket_model(_weapon_socket,
					AssetLibrary.REALISTIC_WEAPONS_DIR + "war_bow.glb", 1.10, 5.44, Vector3(0.0, 0.0, 90.0))
				break

## Dynamically updates Hero 3D stylized weapons & shields on KayKit / BoneAttachment3D rigs.
func sync_player_equipment(inventory: Inventory, hero_class: String = "") -> void:
	if inventory == null:
		return
	var cls := hero_class if not hero_class.is_empty() else (GameManager.hero_class if GameManager != null else "knight")
	var weapon_id := inventory.equipped("weapon")
	var shield_id := inventory.equipped("shield")

	if _equipped_weapon_node != null and is_instance_valid(_equipped_weapon_node):
		_equipped_weapon_node.queue_free()
		_equipped_weapon_node = null
	if _equipped_shield_node != null and is_instance_valid(_equipped_shield_node):
		_equipped_shield_node.queue_free()
		_equipped_shield_node = null

	if _model_path.contains("Knight.glb"):
		# Keep Knight_Helmet & Knight_Cape hidden so sculpted brown hair & X-strap steel backplate show!
		if _submeshes.has("Knight_Helmet"):
			(_submeshes["Knight_Helmet"] as MeshInstance3D).visible = false
		if _submeshes.has("Knight_Cape"):
			(_submeshes["Knight_Cape"] as MeshInstance3D).visible = false
		# Keep starter weapon/shield sheathed when idle for the clean Chibi silhouette; show upgraded blades
		var show_2h := weapon_id == "steel_greatsword" or weapon_id == "eldoria_mythic_blade"
		var show_1h := not weapon_id.is_empty() and weapon_id != "rusty_sword" and not show_2h
		var show_sh := not shield_id.is_empty() and shield_id != "oak_shield"
		if _submeshes.has("1H_Sword"):
			(_submeshes["1H_Sword"] as MeshInstance3D).visible = show_1h
		if _submeshes.has("2H_Sword"):
			(_submeshes["2H_Sword"] as MeshInstance3D).visible = show_2h
		if _submeshes.has("Badge_Shield"):
			(_submeshes["Badge_Shield"] as MeshInstance3D).visible = show_sh
		return

	if not weapon_id.is_empty() and _weapon_socket != null:
		var w_path := AssetLibrary.REALISTIC_WEAPONS_DIR + "knight_longsword.glb"
		var w_desired := 1.12
		var w_raw := 4.35
		var w_rot := Vector3(0.0, 0.0, 90.0)
		if weapon_id == "steel_greatsword" or weapon_id == "eldoria_mythic_blade" or cls == "barbarian":
			w_path = AssetLibrary.REALISTIC_WEAPONS_DIR + "claymore_greatsword.glb"
			w_desired = 1.38
			w_raw = 6.59
		elif cls == "ranger" and weapon_id.contains("bow"):
			w_path = AssetLibrary.REALISTIC_WEAPONS_DIR + "war_bow.glb"
			w_desired = 1.15
			w_raw = 5.44
			w_rot = Vector3(0.0, 0.0, 90.0)
		_equipped_weapon_node = _attach_socket_model(_weapon_socket, w_path, w_desired, w_raw, w_rot)

	if not shield_id.is_empty() and _shield_socket != null and cls != "mage":
		_equipped_shield_node = _attach_socket_model(_shield_socket,
			AssetLibrary.REALISTIC_WEAPONS_DIR + "heater_shield.glb", 0.72, 2.56, Vector3(0.0, 0.0, 180.0))

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
		if ["idle", "idle_combat", "walk", "walk_back", "run", "sprint", "strafe_left", "strafe_right", "fall", "block", "sit", "lie", "work_hammer", "work_pray"].has(state_name):
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
	if _model_path.contains("Knight.glb") and _submeshes.has("1H_Sword"):
		var in_combat_pose := state_name.begins_with("attack") or state_name == "block" or state_name == "idle_combat"
		if in_combat_pose:
			(_submeshes["1H_Sword"] as MeshInstance3D).visible = true
		if state_name == "block" and _submeshes.has("Badge_Shield"):
			(_submeshes["Badge_Shield"] as MeshInstance3D).visible = true
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
	return global_position + Vector3.UP * 1.88
