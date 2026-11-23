class_name WallSlideState
extends PlayerState

var _wall_normal: Vector3 = Vector3.FORWARD


func enter(data: Dictionary = {}) -> void:
	_wall_normal = data.get("wall_normal", courier.last_wall_normal)
	if _wall_normal.length_squared() < 0.01:
		_wall_normal = Vector3.FORWARD
	_wall_normal = _wall_normal.normalized()
	courier.velocity.y = maxf(courier.velocity.y, -courier.wall_slide_max_speed)


func physics_update(delta: float) -> void:
	var c := courier
	if c.try_start_dash():
		return

	# Forgiving wall jump!
	if c.jump_buffer_timer > 0.0:
		c.consume_jump()
		c.air_dash_available = true
		state_machine.transition_to(&"Jump", {"wall_normal": _wall_normal})
		return

	c.velocity.y = maxf(c.velocity.y - c.gravity * 0.35 * delta, -c.wall_slide_max_speed)
	c.velocity.x = -_wall_normal.x * 1.4
	c.velocity.z = -_wall_normal.z * 1.4
	c.rotate_visual_toward(-_wall_normal, delta * 1.2)
	c.move_and_slide()

	if c.is_on_floor():
		state_machine.transition_to(&"Idle")
		return

	var ledge := c.detect_ledge()
	if not ledge.is_empty():
		state_machine.transition_to(&"LedgeGrab", ledge)
		return

	var input_dir := c.get_world_move_direction()
	if not c.is_on_wall() or input_dir.length_squared() < 0.02 or input_dir.dot(-_wall_normal) < 0.15:
		state_machine.transition_to(&"Fall")
