class_name JumpState
extends PlayerState


func enter(data: Dictionary = {}) -> void:
	var c := courier
	if data.has("wall_normal"):
		var wn: Vector3 = data["wall_normal"]
		c.velocity.y = c.wall_jump_up_velocity
		c.velocity.x = wn.x * c.wall_jump_push_velocity
		c.velocity.z = wn.z * c.wall_jump_push_velocity
		c.wall_jump_lock_timer = 0.16
		c.rotate_visual_toward(wn, 1.0)
	else:
		c.velocity.y = c.jump_velocity

	if c.visual:
		c.visual.trigger_jump()
	AudioManager.play_jump()


func physics_update(delta: float) -> void:
	var c := courier
	if c.try_start_dash():
		return

	# Variable jump height: gently cut upward velocity when releasing jump early.
	if Input.is_action_just_released("jump") and c.velocity.y > 0.0:
		c.velocity.y *= c.jump_cut_multiplier

	c.apply_horizontal_movement(delta, 0.92)
	c.apply_gravity(delta)
	c.move_and_slide()

	var ledge := c.detect_ledge()
	if not ledge.is_empty():
		state_machine.transition_to(&"LedgeGrab", ledge)
		return

	if c.velocity.y <= 0.0:
		state_machine.transition_to(&"Fall")
		return

	if c.is_on_floor():
		state_machine.transition_to(&"Move" if c.get_move_input_vector().length_squared() > 0.01 else &"Idle")
