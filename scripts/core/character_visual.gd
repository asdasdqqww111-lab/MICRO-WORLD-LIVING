class_name CharacterVisual
extends Node3D
## Wraps an imported KayKit character: model instance + AnimationTree state
## machine built from whatever clips the pack actually ships.

const CLIP_ALIASES := {
	"idle": ["Idle", "Idle_B", "Unarmed_Idle"],
	"walk": ["Walking_A", "Walking_B", "Walking_C", "Walking_Backwards"],
	"run": ["Running_A", "Running_B", "Running_C"],
	"jump": ["Jump_Start", "Jump_Full_Short"],
	"fall": ["Jump_Idle", "Jump_Full_Long"],
	"land": ["Jump_Land"],
	"attack_1": ["1H_Melee_Attack_Slice_Diagonal", "1H_Melee_Attack_Chop", "Unarmed_Melee_Attack_Punch_A"],
	"attack_2": ["1H_Melee_Attack_Slice_Horizontal", "1H_Melee_Attack_Stab", "Unarmed_Melee_Attack_Punch_B"],
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
var available_states: Dictionary = {}   # state -> clip name
var current_state: String = ""

func setup(model_path: String, model_scale: float = 1.0) -> bool:
	if not ResourceLoader.exists(model_path):
		push_warning("CharacterVisual: missing model %s" % model_path)
		return false
	var packed := load(model_path) as PackedScene
	if packed == null:
		push_warning("CharacterVisual: %s is not a PackedScene" % model_path)
		return false
	model = packed.instantiate() as Node3D
	if model == null:
		return false
	model.name = "Model"
	model.scale = Vector3.ONE * model_scale
	add_child(model)
	_setup_shadows(model)
	anim_player = _find_animation_player(model)
	if anim_player != null:
		_build_state_machine()
	play("idle")
	set_process(anim_player != null)
	return true

func attach_existing(model_root: Node3D) -> void:
	model = model_root
	add_child(model)
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

func _setup_shadows(root: Node) -> void:
	if root is GeometryInstance3D:
		(root as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child: Node in root.get_children():
		_setup_shadows(child)

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
		if ["idle", "walk", "run", "fall", "sit", "lie"].has(state_name):
			var anim := anim_player.get_animation(clip)
			if anim != null:
				anim.loop_mode = Animation.LOOP_LINEAR
	if available_states.is_empty():
		return
	# Fully connected graph: travel() can reach any state with a crossfade.
	var names: Array = available_states.keys()
	for from_name: String in names:
		for to_name: String in names:
			if from_name == to_name:
				continue
			var transition := AnimationNodeStateMachineTransition.new()
			transition.xfade_time = 0.18 if not to_name.begins_with("attack") else 0.08
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
	if model == null:
		return global_position + Vector3.UP * 1.9
	return global_position + Vector3.UP * 1.85
