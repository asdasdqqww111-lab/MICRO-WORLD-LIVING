## AdvancedCinematicFog — cinematic volumetric fog with zone-based transitions.
##
## Sits as a direct child of the World node. It reuses the scene-level
## WorldEnvironment (a child of Game, i.e. the World node's parent) and tweens
## the fog colour / density / volumetric properties when the player crosses
## into a new biome. Dense zone fog also defines the effective render distance:
## distant prop clusters are already LOD-culled, and the fog hides the cull
## boundaries so the world reads as one continuous atmosphere instead of popping.
##
## Zone mapping:
##   OVERWORLD  — village / city / open fields
##   FOREST     — western woodland
##   TOWER      — the tower approach & floors
##   DUNGEON    — the Sunken Crypt
##   BOSS_ARENA — the crypt boss sanctum
extends Node3D

class_name AdvancedCinematicFog

enum ZoneType { OVERWORLD, FOREST, TOWER, DUNGEON, BOSS_ARENA }

@export_group("Fog Settings")

@export var current_zone: ZoneType = ZoneType.OVERWORLD
@export var transition_duration: float = 1.5

@export_subgroup("Volumetric Fog (Godot 4)")
@export var enable_volumetric: bool = true
@export var volumetric_length: float = 150.0
@export var volumetric_detail_spread: float = 2.0

@export_subgroup("Zone Configurations")
@export var zone_densities: Dictionary = {
	ZoneType.OVERWORLD: 0.015,
	ZoneType.FOREST: 0.045,
	ZoneType.TOWER: 0.07,
	ZoneType.DUNGEON: 0.09,
	ZoneType.BOSS_ARENA: 0.11,
}

@export var zone_colors: Dictionary = {
	ZoneType.OVERWORLD: Color(0.14, 0.18, 0.25),
	ZoneType.FOREST: Color(0.09, 0.19, 0.14),
	ZoneType.TOWER: Color(0.08, 0.07, 0.12),
	ZoneType.DUNGEON: Color(0.05, 0.05, 0.08),
	ZoneType.BOSS_ARENA: Color(0.20, 0.06, 0.06),
}

## How far the depth fog reaches per zone — denser fog = shorter visible range,
## which is what lets the engine cull distant geometry without it being obvious.
@export var zone_fog_depth_end: Dictionary = {
	ZoneType.OVERWORLD: 150.0,
	ZoneType.FOREST: 90.0,
	ZoneType.TOWER: 70.0,
	ZoneType.DUNGEON: 55.0,
	ZoneType.BOSS_ARENA: 48.0,
}

var world_environment: WorldEnvironment
var tween: Tween

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_setup_environment_node()
	# Apply immediately (no tween) on first ready so there is never a black
	# frame before the first zone's fog is in place.
	apply_fog_settings(current_zone, 0.0)
	# React to the existing zone system for dungeon / tower transitions.
	EventBus.zone_entered.connect(_on_zone_entered)

func _setup_environment_node() -> void:
	# The WorldEnvironment lives on the Game node (this node's grandparent via
	# the World node's parent). Reuse it so we drive the same environment the
	# day/night cycle and world builder already configured.
	world_environment = get_node_or_null("../WorldEnvironment")
	if not world_environment:
		world_environment = WorldEnvironment.new()
		world_environment.name = "WorldEnvironment"
		var p := get_parent()
		if p != null:
			p.add_child(world_environment)
		else:
			add_child(world_environment)

	if not world_environment.environment:
		world_environment.environment = Environment.new()

## Central zone switch — updates the zone and tweens the fog to match.
func _set_zone(new_zone: ZoneType) -> void:
	if current_zone == new_zone:
		return
	current_zone = new_zone
	if is_inside_tree() and not Engine.is_editor_hint():
		apply_fog_settings(current_zone, transition_duration)

## Maps the game's string zone ids (from player.set_zone / EventBus) onto the
## fog ZoneType enum. House / guild interiors keep the current fog rather than
## snapping back to overworld, so interior transitions stay smooth.
func _on_zone_entered(zone_id: String) -> void:
	match zone_id:
		"dungeon":
			_set_zone(ZoneType.DUNGEON)
		"tower":
			_set_zone(ZoneType.TOWER)
		"village", "city", "":
			_set_zone(ZoneType.OVERWORLD)
		_:
			pass  # house / guild — leave the fog as-is for a seamless interior

## Called by Area3D triggers when the player crosses a biome boundary.
func trigger_zone_transition(zone_name: String) -> void:
	match zone_name.to_lower():
		"forest":
			_set_zone(ZoneType.FOREST)
		"tower":
			_set_zone(ZoneType.TOWER)
		"dungeon":
			_set_zone(ZoneType.DUNGEON)
		"boss":
			_set_zone(ZoneType.BOSS_ARENA)
		_:
			_set_zone(ZoneType.OVERWORLD)

func apply_fog_settings(zone: ZoneType, duration: float) -> void:
	if not world_environment or not world_environment.environment:
		return

	var env: Environment = world_environment.environment
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL

	var target_density: float = zone_densities.get(zone, 0.02)
	var target_color: Color = zone_colors.get(zone, Color(0.1, 0.1, 0.15))
	var target_depth_end: float = zone_fog_depth_end.get(zone, 150.0)

	if enable_volumetric:
		env.volumetric_fog_enabled = true
		env.volumetric_fog_length = volumetric_length
		env.volumetric_fog_detail_spread = volumetric_detail_spread

	if duration > 0.0:
		if tween and tween.is_valid():
			tween.kill()
		tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(env, "fog_density", target_density, duration)
		tween.tween_property(env, "fog_light_color", target_color, duration)
		tween.tween_property(env, "fog_depth_end", target_depth_end, duration)
		if enable_volumetric:
			tween.tween_property(env, "volumetric_fog_density", target_density * 0.8, duration)
			tween.tween_property(env, "volumetric_fog_albedo", target_color, duration)
	else:
		env.fog_density = target_density
		env.fog_light_color = target_color
		env.fog_depth_end = target_depth_end
		if enable_volumetric:
			env.volumetric_fog_density = target_density * 0.8
			env.volumetric_fog_albedo = target_color
