class_name RainSystem
extends Node3D

## Follows the player horizontally and emits stylized night rain streaks
## plus subtle ground splash ripples. Automatically adapts density to GameState quality.

@export var follow_target_path: NodePath
@export var emitter_height: float = 14.0

var _target: Node3D
var _rain_particles: GPUParticles3D
var _splash_particles: GPUParticles3D


func _ready() -> void:
	_build_particles()
	if not follow_target_path.is_empty():
		_target = get_node_or_null(follow_target_path) as Node3D
	GameState.quality_changed.connect(_on_quality_changed)
	_on_quality_changed(GameState.quality_level)


func _process(_delta: float) -> void:
	if _target != null and is_instance_valid(_target):
		global_position = Vector3(_target.global_position.x, _target.global_position.y, _target.global_position.z)


func _on_quality_changed(level: GameState.QualityLevel) -> void:
	if _rain_particles == null or _splash_particles == null:
		return
	match level:
		GameState.QualityLevel.LOW:
			_rain_particles.amount = 550
			_splash_particles.amount = 90
		GameState.QualityLevel.MEDIUM:
			_rain_particles.amount = 1400
			_splash_particles.amount = 220
		GameState.QualityLevel.HIGH:
			_rain_particles.amount = 2300
			_splash_particles.amount = 360


func _build_particles() -> void:
	# 1. Stylized falling rain streaks (velocity-aligned, soft gradient texture)
	_rain_particles = GPUParticles3D.new()
	_rain_particles.name = "RainDrops"
	_rain_particles.position = Vector3(0.0, emitter_height, 0.0)
	_rain_particles.amount = 1400
	_rain_particles.lifetime = 1.15
	_rain_particles.preprocess = 1.0
	_rain_particles.visibility_aabb = AABB(Vector3(-24.0, -24.0, -24.0), Vector3(48.0, 32.0, 48.0))
	_rain_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var rproc := ParticleProcessMaterial.new()
	rproc.particle_flag_align_y = true
	rproc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rproc.emission_box_extents = Vector3(19.0, 2.5, 19.0)
	rproc.direction = Vector3(0.08, -1.0, 0.04)
	rproc.spread = 2.5
	rproc.initial_velocity_min = 17.0
	rproc.initial_velocity_max = 22.0
	rproc.gravity = Vector3(0.4, -4.0, 0.2)
	rproc.scale_min = 0.8
	rproc.scale_max = 1.25
	_rain_particles.process_material = rproc

	var streak := QuadMesh.new()
	streak.size = Vector2(0.028, 0.94)
	var smat := StandardMaterial3D.new()
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	smat.albedo_color = Color(0.58, 0.76, 1.0, 0.26)
	smat.albedo_texture = _make_rain_streak_texture()
	smat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	streak.material = smat
	_rain_particles.draw_pass_1 = streak
	add_child(_rain_particles)

	# 2. Subtle expanding splash ripples on the wet ground
	_splash_particles = GPUParticles3D.new()
	_splash_particles.name = "RainSplashes"
	_splash_particles.position = Vector3(0.0, 0.03, 0.0)
	_splash_particles.amount = 220
	_splash_particles.lifetime = 0.36
	_splash_particles.preprocess = 0.5
	_splash_particles.visibility_aabb = AABB(Vector3(-16.0, -2.0, -16.0), Vector3(32.0, 4.0, 32.0))
	_splash_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var sproc := ParticleProcessMaterial.new()
	sproc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	sproc.emission_box_extents = Vector3(13.0, 0.01, 13.0)
	sproc.direction = Vector3(0.0, 1.0, 0.0)
	sproc.spread = 0.0
	sproc.initial_velocity_min = 0.0
	sproc.initial_velocity_max = 0.0
	sproc.gravity = Vector3.ZERO
	sproc.scale_min = 0.75
	sproc.scale_max = 1.35

	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.25))
	scale_curve.add_point(Vector2(1.0, 1.0))
	var scale_tex := CurveTexture.new()
	scale_tex.curve = scale_curve
	sproc.scale_curve = scale_tex

	var alpha_grad := Gradient.new()
	alpha_grad.set_color(0, Color(0.66, 0.83, 1.0, 0.0))
	alpha_grad.add_point(0.22, Color(0.66, 0.83, 1.0, 0.42))
	alpha_grad.set_color(alpha_grad.get_point_count() - 1, Color(0.66, 0.83, 1.0, 0.0))
	var alpha_tex := GradientTexture1D.new()
	alpha_tex.gradient = alpha_grad
	sproc.color_ramp = alpha_tex
	_splash_particles.process_material = sproc

	var ripple := PlaneMesh.new()
	ripple.size = Vector2(0.28, 0.28)
	var rmat := StandardMaterial3D.new()
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.vertex_color_use_as_albedo = true
	rmat.albedo_texture = _make_ripple_ring_texture()
	rmat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	ripple.material = rmat
	_splash_particles.draw_pass_1 = ripple
	add_child(_splash_particles)


func _make_rain_streak_texture() -> ImageTexture:
	var w := 16
	var h := 64
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var v := float(y) / float(h - 1)
		# Soft tail at top (v=0), brightest near leading droplet tip (v=0.82), smooth tip fade
		var vert := smoothstep(0.0, 0.78, v) * (1.0 - smoothstep(0.84, 1.0, v))
		for x in range(w):
			var u := absf(float(x) / float(w - 1) * 2.0 - 1.0)
			var horiz := pow(clampf(1.0 - u, 0.0, 1.0), 2.2)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, horiz * vert))
	return ImageTexture.create_from_image(img)


func _make_ripple_ring_texture() -> ImageTexture:
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var max_r := size * 0.5
	for y in range(size):
		for x in range(size):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center) / max_r
			var ring := exp(-pow((d - 0.68) * 6.5, 2.0))
			var edge_fade := 1.0 - smoothstep(0.75, 1.0, d)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, ring * edge_fade))
	return ImageTexture.create_from_image(img)
