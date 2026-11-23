class_name CourierController
extends CharacterBody3D

## Third-person exploration platformer controller for the Lattice Courier.
## All feel & tuning values are exposed as @export variables.

@export_group("Movement")
@export var move_speed: float = 6.6
@export var ground_acceleration: float = 38.0
@export var ground_deceleration: float = 42.0
@export var air_acceleration: float = 22.0
@export var air_deceleration: float = 8.0
@export var turn_speed: float = 12.5

@export_group("Jumping")
@export var jump_velocity: float = 9.4
@export var jump_cut_multiplier: float = 0.48
@export var gravity: float = 24.0
@export var fall_gravity_multiplier: float = 1.32
@export var max_fall_speed: float = 24.0
@export var coyote_time: float = 0.14
@export var jump_buffer_time: float = 0.14

@export_group("Dash")
@export var dash_speed: float = 15.2
@export var dash_duration: float = 0.19
@export var dash_cooldown: float = 0.55

@export_group("Wall Slide & Ledge Grab")
@export var wall_slide_max_speed: float = 3.2
@export var wall_jump_up_velocity: float = 9.0
@export var wall_jump_push_velocity: float = 7.4
@export var ledge_mantle_duration: float = 0.24

@export_group("Respawn")
@export var chasm_kill_y: float = -12.0

@onready var state_machine: StateMachine = $StateMachine
@onready var visual_anchor: Node3D = $VisualAnchor
@onready var visual: CourierVisual = $VisualAnchor/CourierVisual
@onready var camera_rig: PlayerCamera = $CameraRig
@onready var dash_particles: GPUParticles3D = $DashParticles

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var air_dash_available: bool = true
var facing_direction: Vector3 = Vector3.FORWARD
var last_wall_normal: Vector3 = Vector3.ZERO
var wall_jump_lock_timer: float = 0.0

var _footstep_timer: float = 0.0
var _respawning: bool = false
var _last_vertical_speed: float = 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	facing_direction = -global_transform.basis.z
	facing_direction.y = 0.0
	if facing_direction.length_squared() < 0.001:
		facing_direction = Vector3.FORWARD
	facing_direction = facing_direction.normalized()

	GameState.last_safe_position = global_position
	state_machine.init(self)
	if camera_rig:
		camera_rig.set_target(self)


func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)


func _process(delta: float) -> void:
	state_machine.process_frame(delta)
	if visual:
		var horiz_speed := Vector2(velocity.x, velocity.z).length()
		visual.set_motion_state(
			state_machine.get_current_state_name(),
			horiz_speed,
			velocity.y,
			is_on_floor()
		)


func _physics_process(delta: float) -> void:
	if _respawning:
		return

	# Timers
	if is_on_floor():
		coyote_timer = coyote_time
		air_dash_available = true
		# Record safe checkpoint when steadily grounded away from edges.
		if global_position.y > -1.0:
			GameState.last_safe_position = global_position + Vector3(0.0, 0.12, 0.0)
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)

	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)
	wall_jump_lock_timer = maxf(0.0, wall_jump_lock_timer - delta)

	var was_on_floor := is_on_floor()
	_last_vertical_speed = velocity.y

	state_machine.process_physics(delta)

	# Landing impact feedback
	if not was_on_floor and is_on_floor() and _last_vertical_speed < -2.5:
		var strength := clampf(absf(_last_vertical_speed) / 14.0, 0.2, 1.0)
		if visual:
			visual.trigger_land(strength)
		AudioManager.play_land(absf(_last_vertical_speed))

	# Footstep cadence while moving on floor
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horiz_speed > 1.2 and state_machine.get_current_state_name() == &"Move":
		_footstep_timer -= delta * clampf(horiz_speed / move_speed, 0.6, 1.35)
		if _footstep_timer <= 0.0:
			_footstep_timer = 0.34
			AudioManager.play_footstep(_is_on_metal_surface())
	else:
		_footstep_timer = minf(_footstep_timer, 0.08)

	# Chasm safety net
	if global_position.y < chasm_kill_y:
		_respawn_at_safe_position()


func get_move_input_vector() -> Vector2:
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()
	return input_vec


func get_world_move_direction() -> Vector3:
	var input_vec := get_move_input_vector()
	if input_vec.length_squared() < 0.001:
		return Vector3.ZERO
	var cam_yaw := camera_rig.get_yaw() if camera_rig else 0.0
	var basis_yaw := Basis(Vector3.UP, cam_yaw)
	var forward := -basis_yaw.z
	var right := basis_yaw.x
	var dir := (right * input_vec.x + forward * (-input_vec.y))
	dir.y = 0.0
	return dir.normalized() if dir.length_squared() > 0.0001 else Vector3.ZERO


func apply_horizontal_movement(delta: float, control_scale: float = 1.0) -> void:
	var move_dir := get_world_move_direction()
	var grounded := is_on_floor()
	var accel := (ground_acceleration if grounded else air_acceleration) * control_scale
	var decel := (ground_deceleration if grounded else air_deceleration) * control_scale

	if wall_jump_lock_timer > 0.0:
		accel *= 0.25

	var horiz := Vector3(velocity.x, 0.0, velocity.z)
	if move_dir.length_squared() > 0.001:
		var target := move_dir * move_speed
		horiz = horiz.move_toward(target, accel * delta)
		rotate_visual_toward(move_dir, delta)
	else:
		horiz = horiz.move_toward(Vector3.ZERO, decel * delta)

	velocity.x = horiz.x
	velocity.z = horiz.z


func rotate_visual_toward(direction: Vector3, delta: float) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	facing_direction = flat.normalized()
	var target_yaw := atan2(-facing_direction.x, -facing_direction.z)
	visual_anchor.rotation.y = lerp_angle(visual_anchor.rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))


func apply_gravity(delta: float) -> void:
	var g := gravity * (fall_gravity_multiplier if velocity.y < 0.0 else 1.0)
	velocity.y = maxf(velocity.y - g * delta, -max_fall_speed)


func can_consume_jump() -> bool:
	return jump_buffer_timer > 0.0 and coyote_timer > 0.0


func consume_jump() -> void:
	jump_buffer_timer = 0.0
	coyote_timer = 0.0


func can_dash() -> bool:
	if dash_cooldown_timer > 0.0:
		return false
	return is_on_floor() or air_dash_available


func try_start_dash() -> bool:
	if Input.is_action_just_pressed("dash") and can_dash():
		if not is_on_floor():
			air_dash_available = false
		dash_cooldown_timer = dash_cooldown
		state_machine.transition_to(&"Dash")
		return true
	return false


func check_wall_slide() -> bool:
	if is_on_floor() or velocity.y > 0.4:
		return false
	if not is_on_wall_only():
		return false
	var wall_n := get_wall_normal()
	if absf(wall_n.y) > 0.25:
		return false
	var input_dir := get_world_move_direction()
	if input_dir.length_squared() < 0.04:
		return false
	# Pressing toward the wall engages a smooth wall-slide.
	if input_dir.dot(-wall_n) > 0.35:
		last_wall_normal = wall_n
		return true
	return false


func detect_ledge() -> Dictionary:
	# Forgiving ledge detector using two short direct-space raycasts.
	if is_on_floor() or velocity.y > 2.8:
		return {}
	var space := get_world_3d().direct_space_state
	if space == null:
		return {}

	var fwd := facing_direction.normalized()
	var chest_origin := global_position + Vector3(0.0, 1.05, 0.0)
	var head_origin := global_position + Vector3(0.0, 1.72, 0.0)

	# 1. Must have a wall in front at chest level.
	var q_front := PhysicsRayQueryParameters3D.create(chest_origin, chest_origin + fwd * 0.62, 1)
	var hit_front := space.intersect_ray(q_front)
	if hit_front.is_empty():
		return {}
	var wall_normal: Vector3 = hit_front["normal"]
	if absf(wall_normal.y) > 0.25:
		return {}

	# 2. Must have clear air just above the ledge.
	var q_clear := PhysicsRayQueryParameters3D.create(head_origin, head_origin + fwd * 0.72, 1)
	if not space.intersect_ray(q_clear).is_empty():
		return {}

	# 3. Cast downward slightly beyond the wall face to find the ledge deck surface.
	var inward := -Vector3(wall_normal.x, 0.0, wall_normal.z).normalized()
	var down_start: Vector3 = Vector3(hit_front["position"].x, head_origin.y, hit_front["position"].z) + inward * 0.28
	var down_end := down_start - Vector3(0.0, 0.95, 0.0)
	var q_top := PhysicsRayQueryParameters3D.create(down_start, down_end, 1)
	var hit_top := space.intersect_ray(q_top)
	if hit_top.is_empty():
		return {}
	var top_normal: Vector3 = hit_top["normal"]
	if top_normal.y < 0.75:
		return {}

	var ledge_pos: Vector3 = hit_top["position"]
	var dy := ledge_pos.y - global_position.y
	if dy < 0.78 or dy > 1.65:
		return {}

	return {
		"ledge_position": ledge_pos,
		"wall_normal": wall_normal,
		"stand_position": ledge_pos + inward * 0.24 + Vector3(0.0, 0.08, 0.0),
	}


func _is_on_metal_surface() -> bool:
	# Elevated truss platforms & catwalks sit above y = 1.2m.
	return global_position.y > 1.2


func _respawn_at_safe_position() -> void:
	_respawning = true
	velocity = Vector3.ZERO
	SceneTransition.fade_blink(func() -> void:
		global_position = GameState.last_safe_position
		velocity = Vector3.ZERO
		air_dash_available = true
		state_machine.transition_to(&"Idle")
		_respawning = false
	)
