class_name MoveState
extends PlayerState


func physics_update(delta: float) -> void:
	var c := courier
	if c.try_start_dash():
		return

	if c.can_consume_jump():
		c.consume_jump()
		state_machine.transition_to(&"Jump")
		return

	c.apply_horizontal_movement(delta)
	c.apply_gravity(delta)
	c.move_and_slide()

	if not c.is_on_floor():
		state_machine.transition_to(&"Fall")
		return

	var horiz_speed := Vector2(c.velocity.x, c.velocity.z).length()
	if c.get_move_input_vector().length_squared() < 0.01 and horiz_speed < 0.15:
		state_machine.transition_to(&"Idle")
