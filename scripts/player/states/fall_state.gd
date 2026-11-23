class_name FallState
extends PlayerState


func physics_update(delta: float) -> void:
	var c := courier
	if c.try_start_dash():
		return

	# Coyote-time jump still works shortly after stepping off a ledge!
	if c.can_consume_jump():
		c.consume_jump()
		state_machine.transition_to(&"Jump")
		return

	c.apply_horizontal_movement(delta, 0.88)
	c.apply_gravity(delta)
	c.move_and_slide()

	if c.is_on_floor():
		state_machine.transition_to(&"Move" if c.get_move_input_vector().length_squared() > 0.01 else &"Idle")
		return

	var ledge := c.detect_ledge()
	if not ledge.is_empty():
		state_machine.transition_to(&"LedgeGrab", ledge)
		return

	if c.check_wall_slide():
		state_machine.transition_to(&"WallSlide", {"wall_normal": c.last_wall_normal})
