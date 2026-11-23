class_name DashState
extends PlayerState

var _timer: float = 0.0
var _dash_dir: Vector3 = Vector3.FORWARD


func enter(_data: Dictionary = {}) -> void:
	var c := courier
	_timer = c.dash_duration
	var move_dir := c.get_world_move_direction()
	_dash_dir = move_dir if move_dir.length_squared() > 0.01 else c.facing_direction.normalized()
	c.rotate_visual_toward(_dash_dir, 1.0)
	c.velocity = Vector3(_dash_dir.x * c.dash_speed, 0.35, _dash_dir.z * c.dash_speed)

	if c.visual:
		c.visual.trigger_dash()
	if c.dash_particles:
		c.dash_particles.emitting = true
	AudioManager.play_dash()


func exit() -> void:
	var c := courier
	# Smooth momentum carry-out rather than abrupt halt
	var horiz := Vector3(c.velocity.x, 0.0, c.velocity.z)
	if horiz.length() > c.move_speed * 1.05:
		horiz = horiz.normalized() * c.move_speed * 1.05
		c.velocity.x = horiz.x
		c.velocity.z = horiz.z
	if c.dash_particles:
		c.dash_particles.emitting = false


func physics_update(delta: float) -> void:
	var c := courier
	_timer -= delta
	c.velocity.x = _dash_dir.x * c.dash_speed
	c.velocity.z = _dash_dir.z * c.dash_speed
	c.velocity.y = move_toward(c.velocity.y, 0.0, 6.0 * delta)
	c.move_and_slide()

	# Allow jumping out of a grounded dash for snappy platforming feel
	if c.can_consume_jump():
		c.consume_jump()
		state_machine.transition_to(&"Jump")
		return

	if _timer <= 0.0:
		if c.is_on_floor():
			state_machine.transition_to(&"Move" if c.get_move_input_vector().length_squared() > 0.01 else &"Idle")
		else:
			state_machine.transition_to(&"Fall")
