class_name PlayerCamera
extends Node3D

## Smooth third-person spring-arm camera with mouse + right-stick orbit,
## wall collision, pitch clamping, and gentle auto-follow alignment.

@export var pivot_offset: Vector3 = Vector3(0.0, 1.48, 0.0)
@export var follow_smoothness: float = 11.0
@export var mouse_sensitivity: float = 0.0028
@export var stick_sensitivity: float = 2.5
@export var min_pitch_deg: float = -48.0
@export var max_pitch_deg: float = 58.0
@export var arm_length: float = 5.4
@export var auto_follow_speed: float = 1.45
@export var auto_follow_delay: float = 1.35

@onready var pitch_pivot: Node3D = $PitchPivot
@onready var spring_arm: SpringArm3D = $PitchPivot/SpringArm3D
@onready var camera: Camera3D = $PitchPivot/SpringArm3D/Camera3D

var _target: CourierController
var _yaw: float = 0.0
var _pitch: float = deg_to_rad(-14.0)
var _manual_orbit_cooldown: float = 0.0


func _ready() -> void:
	top_level = true
	if spring_arm:
		spring_arm.spring_length = arm_length
		spring_arm.collision_mask = 1
		spring_arm.margin = 0.22
	_apply_angles()


func set_target(target_node: CourierController) -> void:
	_target = target_node
	if _target:
		global_position = _target.global_position + pivot_offset
		_yaw = _target.rotation.y
		_apply_angles()


func get_yaw() -> float:
	return _yaw


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and not GameState.is_cursor_captured():
			GameState.set_cursor_captured(true)
	elif event is InputEventMouseMotion and GameState.is_cursor_captured():
		var mm := event as InputEventMouseMotion
		_yaw -= mm.relative.x * mouse_sensitivity
		_pitch = clampf(
			_pitch - mm.relative.y * mouse_sensitivity,
			deg_to_rad(min_pitch_deg),
			deg_to_rad(max_pitch_deg)
		)
		_manual_orbit_cooldown = auto_follow_delay


func _process(delta: float) -> void:
	if _target == null:
		return

	# Gamepad right-stick orbit
	var stick := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if stick.length_squared() > 0.01:
		_yaw -= stick.x * stick_sensitivity * delta
		_pitch = clampf(
			_pitch - stick.y * stick_sensitivity * delta,
			deg_to_rad(min_pitch_deg),
			deg_to_rad(max_pitch_deg)
		)
		_manual_orbit_cooldown = auto_follow_delay
	else:
		_manual_orbit_cooldown = maxf(0.0, _manual_orbit_cooldown - delta)

	# Gentle auto-follow when running sideways/forward without active camera orbit
	if _manual_orbit_cooldown <= 0.0 and _target.is_on_floor():
		var horiz_vel := Vector3(_target.velocity.x, 0.0, _target.velocity.z)
		var move_in := _target.get_move_input_vector()
		# Gently nudge behind the courier when moving mostly sideways (never fight walking toward camera)
		if horiz_vel.length() > 2.2 and move_in.y <= 0.35:
			var desired_yaw := atan2(-horiz_vel.x, -horiz_vel.z)
			var angle_diff := wrapf(desired_yaw - _yaw, -PI, PI)
			if absf(angle_diff) < deg_to_rad(115.0):
				_yaw = lerp_angle(_yaw, desired_yaw, clampf(auto_follow_speed * delta, 0.0, 1.0))

	# Smoothly track the courier's anchor position
	var goal_pos := _target.global_position + pivot_offset
	var weight := 1.0 - exp(-follow_smoothness * delta)
	global_position = global_position.lerp(goal_pos, weight)

	_apply_angles()


func _apply_angles() -> void:
	rotation.y = _yaw
	if pitch_pivot:
		pitch_pivot.rotation.x = _pitch
