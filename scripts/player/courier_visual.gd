class_name CourierVisual
extends Node3D

## Procedural stylized Courier rig & animator.
## Built from clean composed primitives so a real rigged 3D model can drop in
## as a replacement for scenes/player/courier_visual.tscn with zero controller changes.

@onready var root_squash: Node3D = $SquashRoot
@onready var torso_pivot: Node3D = $SquashRoot/TorsoPivot
@onready var head_pivot: Node3D = $SquashRoot/TorsoPivot/HeadPivot
@onready var bag_pivot: Node3D = $SquashRoot/TorsoPivot/BagPivot
@onready var scarf_tail: Node3D = $SquashRoot/TorsoPivot/ScarfTail
@onready var arm_l: Node3D = $SquashRoot/TorsoPivot/ArmL
@onready var arm_r: Node3D = $SquashRoot/TorsoPivot/ArmR
@onready var leg_l: Node3D = $SquashRoot/LegL
@onready var leg_r: Node3D = $SquashRoot/LegR

var _state_name: StringName = &"Idle"
var _horiz_speed: float = 0.0
var _vert_vel: float = 0.0
var _grounded: bool = true

var _time: float = 0.0
var _stride_phase: float = 0.0
var _squash_vec: Vector3 = Vector3.ONE


func _ready() -> void:
	_apply_palette_materials()


func set_motion_state(state_name: StringName, horizontal_speed: float, vertical_velocity: float, is_grounded: bool) -> void:
	_state_name = state_name
	_horiz_speed = horizontal_speed
	_vert_vel = vertical_velocity
	_grounded = is_grounded


func trigger_jump() -> void:
	_squash_vec = Vector3(0.82, 1.26, 0.82)


func trigger_land(strength: float = 0.6) -> void:
	var s := clampf(strength, 0.25, 1.0)
	_squash_vec = Vector3(1.0 + 0.26 * s, 1.0 - 0.24 * s, 1.0 + 0.26 * s)


func trigger_dash() -> void:
	_squash_vec = Vector3(0.84, 0.92, 1.32)


func _process(delta: float) -> void:
	_time += delta

	# Elastic return of squash & stretch
	var spring := 1.0 - exp(-14.0 * delta)
	_squash_vec = _squash_vec.lerp(Vector3.ONE, spring)
	root_squash.scale = _squash_vec

	var speed_ratio := clampf(_horiz_speed / 6.6, 0.0, 1.25)

	# Target procedural poses
	var torso_bob := 0.0
	var torso_pitch := 0.0
	var torso_roll := 0.0
	var head_pitch := 0.0
	var leg_swing := 0.0
	var arm_swing := 0.0
	var bag_bob := 0.0
	var scarf_pitch := 0.12

	match _state_name:
		&"Idle":
			torso_bob = sin(_time * 2.4) * 0.025
			head_pitch = sin(_time * 1.4) * 0.04
			scarf_pitch = 0.14 + sin(_time * 3.1) * 0.08
			bag_bob = sin(_time * 2.4 - 0.6) * 0.015
		&"Move":
			_stride_phase += delta * (7.2 + speed_ratio * 5.2)
			torso_bob = absf(sin(_stride_phase)) * 0.075 * speed_ratio
			torso_pitch = -0.14 * speed_ratio
			torso_roll = sin(_stride_phase) * 0.06 * speed_ratio
			leg_swing = sin(_stride_phase) * 0.68 * speed_ratio
			arm_swing = -sin(_stride_phase) * 0.56 * speed_ratio
			bag_bob = sin(_stride_phase * 2.0 - 0.8) * 0.045 * speed_ratio
			scarf_pitch = 0.45 * speed_ratio + sin(_time * 10.0) * 0.12
		&"Jump":
			torso_pitch = -0.12
			head_pitch = 0.08
			leg_swing = 0.35
			arm_swing = -0.65
			bag_bob = -0.04
			scarf_pitch = 0.65
		&"Fall":
			torso_pitch = 0.08
			head_pitch = -0.08
			leg_swing = -0.22 + sin(_time * 9.0) * 0.1
			arm_swing = 0.72
			bag_bob = 0.06
			scarf_pitch = 0.88 + sin(_time * 14.0) * 0.16
		&"Dash":
			torso_pitch = -0.42
			head_pitch = 0.26
			leg_swing = 0.55
			arm_swing = 0.95
			bag_bob = 0.04
			scarf_pitch = 1.15
		&"WallSlide":
			torso_pitch = 0.06
			torso_roll = 0.12
			leg_swing = 0.25
			arm_swing = -0.85
			scarf_pitch = 0.55
		&"LedgeGrab":
			torso_pitch = -0.22
			leg_swing = -0.35
			arm_swing = -1.65
			scarf_pitch = 0.35

	var w := 1.0 - exp(-16.0 * delta)
	torso_pivot.position.y = lerpf(torso_pivot.position.y, 0.72 + torso_bob, w)
	torso_pivot.rotation.x = lerpf(torso_pivot.rotation.x, torso_pitch, w)
	torso_pivot.rotation.z = lerpf(torso_pivot.rotation.z, torso_roll, w)
	head_pivot.rotation.x = lerpf(head_pivot.rotation.x, head_pitch, w)

	leg_l.rotation.x = lerpf(leg_l.rotation.x, leg_swing, w)
	leg_r.rotation.x = lerpf(leg_r.rotation.x, -leg_swing, w)
	arm_l.rotation.x = lerpf(arm_l.rotation.x, arm_swing, w)
	arm_r.rotation.x = lerpf(arm_r.rotation.x, -arm_swing * 0.85, w)

	bag_pivot.position.y = lerpf(bag_pivot.position.y, 0.02 + bag_bob, w)
	bag_pivot.rotation.x = lerpf(bag_pivot.rotation.x, -torso_pitch * 0.5 + bag_bob * 2.0, w)
	scarf_tail.rotation.x = lerpf(scarf_tail.rotation.x, scarf_pitch, w)


func _apply_palette_materials() -> void:
	# Strong warm rim light so the small courier stays readable against the dark indigo skyline.
	var jacket_mat := Palette.make_stylized_material(Palette.COURIER_JACKET, 0.76, 0.04, Color("#FFE2A8"), 0.52)
	var scarf_mat := Palette.make_stylized_material(Palette.COURIER_SCARF, 0.85, 0.0, Color("#FFBC94"), 0.42)
	var pants_mat := Palette.make_stylized_material(Palette.COURIER_PANTS, 0.82, 0.04, Color("#7EA3E0"), 0.34)
	var boot_mat := Palette.make_stylized_material(Palette.COURIER_BOOTS, 0.58, 0.1, Color("#9BB8E8"), 0.25)
	var bag_mat := Palette.make_stylized_material(Palette.COURIER_BAG, 0.68, 0.08, Color("#FFD399"), 0.38)
	var skin_mat := Palette.make_stylized_material(Palette.COURIER_SKIN, 0.72, 0.0, Color("#FFE7C4"), 0.35)
	var hat_mat := Palette.make_stylized_material(Palette.COURIER_HAT, 0.82, 0.02, Color("#89B4F2"), 0.48)
	var tag_mat := Palette.make_emissive_material(Palette.COURIER_TAG_TEAL, 3.0, 0.25)
	var buckle_mat := Palette.make_stylized_material(Palette.LANTERN_AMBER, 0.35, 0.65, Palette.LANTERN_GLOW, 0.4)

	_set_mat("SquashRoot/TorsoPivot/JacketMesh", jacket_mat)
	_set_mat("SquashRoot/TorsoPivot/ScarfRing", scarf_mat)
	_set_mat("SquashRoot/TorsoPivot/ScarfTail/ScarfTailMesh", scarf_mat)
	_set_mat("SquashRoot/TorsoPivot/HeadPivot/HeadMesh", skin_mat)
	_set_mat("SquashRoot/TorsoPivot/HeadPivot/BeanieMesh", hat_mat)
	_set_mat("SquashRoot/TorsoPivot/HeadPivot/BeaniePom", scarf_mat)
	_set_mat("SquashRoot/TorsoPivot/ArmL/ArmLMesh", jacket_mat)
	_set_mat("SquashRoot/TorsoPivot/ArmR/ArmRMesh", jacket_mat)
	_set_mat("SquashRoot/TorsoPivot/BagPivot/BagBody", bag_mat)
	_set_mat("SquashRoot/TorsoPivot/BagPivot/BagFlap", bag_mat)
	_set_mat("SquashRoot/TorsoPivot/BagPivot/BagStrap", boot_mat)
	_set_mat("SquashRoot/TorsoPivot/BagPivot/BagBuckle", buckle_mat)
	_set_mat("SquashRoot/TorsoPivot/BagPivot/BagTealTag", tag_mat)
	_set_mat("SquashRoot/LegL/LegLMesh", pants_mat)
	_set_mat("SquashRoot/LegL/BootLMesh", boot_mat)
	_set_mat("SquashRoot/LegR/LegRMesh", pants_mat)
	_set_mat("SquashRoot/LegR/BootRMesh", boot_mat)


func _set_mat(path: String, mat: Material) -> void:
	var node := get_node_or_null(path) as MeshInstance3D
	if node:
		node.material_override = mat
