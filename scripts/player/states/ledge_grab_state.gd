class_name LedgeGrabState
extends PlayerState

var _start_pos: Vector3
var _target_pos: Vector3
var _elapsed: float = 0.0
var _wall_normal: Vector3 = Vector3.FORWARD


func enter(data: Dictionary = {}) -> void:
	var c := courier
	_start_pos = c.global_position
	_target_pos = data.get("stand_position", _start_pos + Vector3(0.0, 1.1, 0.0))
	_wall_normal = data.get("wall_normal", -c.facing_direction)
	_elapsed = 0.0
	c.velocity = Vector3.ZERO
	c.air_dash_available = true
	c.rotate_visual_toward(-_wall_normal, 1.0)
	AudioManager.play_ledge_grab()


func physics_update(delta: float) -> void:
	var c := courier
	_elapsed += delta
	var t := clampf(_elapsed / maxf(c.ledge_mantle_duration, 0.05), 0.0, 1.0)

	# Smooth two-arc mantle: rise up cleanly, then glide forward onto the platform deck.
	var eased := t * t * (3.0 - 2.0 * t)
	var mid_pos := Vector3(_start_pos.x, _target_pos.y + 0.12, _start_pos.z)
	var pos := _start_pos.lerp(mid_pos, clampf(eased * 1.65, 0.0, 1.0)).lerp(_target_pos, clampf((eased - 0.35) / 0.65, 0.0, 1.0))
	c.global_position = pos

	if t >= 1.0:
		c.global_position = _target_pos
		c.velocity = Vector3.ZERO
		if c.visual:
			c.visual.trigger_land(0.32)
		state_machine.transition_to(&"Move" if c.get_move_input_vector().length_squared() > 0.01 else &"Idle")
