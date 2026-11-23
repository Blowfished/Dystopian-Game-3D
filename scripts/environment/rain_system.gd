class_name RainSystem
extends Node3D

## Follows the player horizontally and emits stylized night rain streaks
## plus subtle ground splash droplets. Automatically adapts density to GameState quality.

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
			_rain_particles.amount = 420
			_splash_particles.amount = 75
		GameState.QualityLevel.MEDIUM:
			_rain_particles.amount = 1050
			_splash_particles.amount = 180
		GameState.QualityLevel.HIGH:
			_rain_particles.amount = 1850
			_splash_particles.amount = 300


func _build_particles() -> void:
	# 1. Stylized falling rain streaks
	_rain_particles = GPUParticles3D.new()
	_rain_particles.name = "RainDrops"
	_rain_particles.position = Vector3(0.0, emitter_height, 0.0)
	_rain_particles.amount = 1050
	_rain_particles.lifetime = 1.15
	_rain_particles.preprocess = 1.0
	_rain_particles.visibility_aabb = AABB(Vector3(-24.0, -24.0, -24.0), Vector3(48.0, 32.0, 48.0))
	_rain_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var rproc := ParticleProcessMaterial.new()
	rproc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rproc.emission_box_extents = Vector3(19.0, 2.5, 19.0)
	rproc.direction = Vector3(0.08, -1.0, 0.04)
	rproc.spread = 2.0
	rproc.initial_velocity_min = 16.5
	rproc.initial_velocity_max = 21.0
	rproc.gravity = Vector3(0.4, -4.0, 0.2)
	_rain_particles.process_material = rproc

	var streak := QuadMesh.new()
	streak.size = Vector2(0.022, 0.72)
	var smat := StandardMaterial3D.new()
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	smat.albedo_color = Color(0.68, 0.80, 1.0, 0.28)
	smat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	streak.material = smat
	_rain_particles.draw_pass_1 = streak
	add_child(_rain_particles)

	# 2. Delicate ground/airborne mist splash pips near feet height
	_splash_particles = GPUParticles3D.new()
	_splash_particles.name = "RainSplashes"
	_splash_particles.position = Vector3(0.0, 0.08, 0.0)
	_splash_particles.amount = 180
	_splash_particles.lifetime = 0.28
	_splash_particles.visibility_aabb = AABB(Vector3(-16.0, -4.0, -16.0), Vector3(32.0, 8.0, 32.0))
	_splash_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var sproc := ParticleProcessMaterial.new()
	sproc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	sproc.emission_box_extents = Vector3(12.0, 0.04, 12.0)
	sproc.direction = Vector3(0.0, 1.0, 0.0)
	sproc.spread = 38.0
	sproc.initial_velocity_min = 0.8
	sproc.initial_velocity_max = 1.8
	sproc.gravity = Vector3(0.0, -9.8, 0.0)
	sproc.scale_min = 0.6
	sproc.scale_max = 1.2
	_splash_particles.process_material = sproc

	var dot := QuadMesh.new()
	dot.size = Vector2(0.055, 0.055)
	var dmat := StandardMaterial3D.new()
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	dmat.albedo_color = Color(0.75, 0.86, 1.0, 0.34)
	dmat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	dot.material = dmat
	_splash_particles.draw_pass_1 = dot
	add_child(_splash_particles)
