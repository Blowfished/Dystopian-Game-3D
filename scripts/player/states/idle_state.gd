class_name IdleState
extends PlayerState


func physics_update(delta: float) -> void:
	var c := courier
	if c.try_start_dash():
		return

	if c.can_consume_jump():
		c.consume_jump()
		state_machine.transition_to(&"Jump")
		return

	if not c.is_on_floor():
		state_machine.transition_to(&"Fall")
		return

	if c.get_move_input_vector().length_squared() > 0.01:
		state_machine.transition_to(&"Move")
		return

	c.apply_horizontal_movement(delta)
	c.apply_gravity(delta)
	c.move_and_slide()
