class_name CollisionLayers
extends RefCounted
## Strict 3D Physics Collision Layer & Mask Architecture for Eldoria:
##   Bit 0 (1):  Solid World Environment (Terrain, Walls, Floors, Bridges, Boulders, Boundaries)
##   Bit 1 (2):  Player CharacterBody3D
##   Bit 2 (4):  Creatures, Wildlife & Bosses
##   Bit 3 (8):  Village & Guild NPCs
##   Bit 4 (16): Non-solid Trigger Areas / Interactables / Sensors (never block movement!)

const ENVIRONMENT := 1 << 0   # 1
const PLAYER      := 1 << 1   # 2
const CREATURE    := 1 << 2   # 4
const NPC         := 1 << 3   # 8
const TRIGGER     := 1 << 4   # 16

## The player is stopped by the solid world, by villagers and by monsters, and
## never by Area3D triggers or sensors.
const MASK_PLAYER_SOLID := ENVIRONMENT | NPC | CREATURE
const MASK_CREATURE_SOLID := ENVIRONMENT | PLAYER | NPC | CREATURE
const MASK_CAMERA_OCCLUSION := ENVIRONMENT

static func configure_player_body(body: CharacterBody3D) -> void:
	if body == null:
		return
	body.collision_layer = PLAYER
	body.collision_mask = MASK_PLAYER_SOLID
	body.safe_margin = 0.05
	body.floor_stop_on_slope = true
	body.floor_block_on_wall = true
	body.floor_max_angle = deg_to_rad(48.0)
	body.floor_snap_length = 0.36
	body.wall_min_slide_angle = deg_to_rad(12.0)
	body.max_slides = 6
