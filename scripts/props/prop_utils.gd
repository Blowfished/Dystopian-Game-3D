class_name PropUtils
extends RefCounted

## Helper constructors for clean stylized kitbashed modular props,
## cheap fake glow pools/cones, and cached particle textures.

static var _puff_tex: ImageTexture = null
static var _glow_mat_cache: Dictionary = {}
static var _beam_shader: Shader = null


static func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


static func add_box(
	parent: Node3D,
	size: Vector3,
	pos: Vector3,
	mat: Material,
	rot_deg: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


static func add_cylinder(
	parent: Node3D,
	top_r: float,
	bottom_r: float,
	height: float,
	pos: Vector3,
	mat: Material,
	rot_deg: Vector3 = Vector3.ZERO,
	segments: int = 12
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height
	mesh.radial_segments = segments
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


static func add_sphere(
	parent: Node3D,
	radius: float,
	pos: Vector3,
	mat: Material,
	scale_vec: Vector3 = Vector3.ONE,
	segments: int = 12
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = maxi(segments / 2, 5)
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scale_vec
	parent.add_child(mi)
	return mi


static func add_strut(
	parent: Node3D,
	from_pos: Vector3,
	to_pos: Vector3,
	thickness: float,
	mat: Material
) -> MeshInstance3D:
	var delta := to_pos - from_pos
	var length := delta.length()
	if length < 0.001:
		return null
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(thickness, thickness, length)
	mi.mesh = mesh
	mi.material_override = mat
	var mid := (from_pos + to_pos) * 0.5
	var dir := delta / length
	var up := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	mi.transform = Transform3D(Basis.looking_at(dir, up), mid)
	parent.add_child(mi)
	return mi


static func add_ground_glow_pool(
	parent: Node3D,
	pos: Vector3,
	size_xz: Vector2,
	color: Color,
	alpha: float = 0.32,
	vis_range: float = 95.0
) -> MeshInstance3D:
	## Cheap additive emissive light-pool card lying flush above wet street puddles.
	var key := "%s|%.2f" % [color.to_html(), alpha]
	var mat: StandardMaterial3D
	if _glow_mat_cache.has(key):
		mat = _glow_mat_cache[key]
	else:
		mat = Palette.make_additive_glow_material(color, alpha)
		_glow_mat_cache[key] = mat

	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size_xz
	qm.orientation = PlaneMesh.FACE_Y
	mi.mesh = qm
	mi.material_override = mat
	mi.position = Vector3(pos.x, pos.y + 0.035, pos.z)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = vis_range
	parent.add_child(mi)
	return mi


static func add_glow_card(
	parent: Node3D,
	pos: Vector3,
	size_xy: Vector2,
	color: Color,
	alpha: float = 0.28,
	vis_range: float = 110.0
) -> MeshInstance3D:
	## Billboarded cheap additive halo card for lanterns, lamps, and neon signs.
	var key := "bb|%s|%.2f" % [color.to_html(), alpha]
	var mat: StandardMaterial3D
	if _glow_mat_cache.has(key):
		mat = _glow_mat_cache[key]
	else:
		mat = Palette.make_additive_glow_material(color, alpha)
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_glow_mat_cache[key] = mat

	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size_xy
	mi.mesh = qm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = vis_range
	parent.add_child(mi)
	return mi


static func add_light_cone(
	parent: Node3D,
	top_pos: Vector3,
	cone_height: float,
	top_r: float,
	bottom_r: float,
	color: Color,
	intensity: float = 0.16,
	rot_deg: Vector3 = Vector3(180.0, 0.0, 0.0),
	vis_range: float = 105.0
) -> MeshInstance3D:
	if _beam_shader == null:
		_beam_shader = load("res://shaders/searchlight_beam.gdshader")
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bottom_r
	cyl.height = cone_height
	cyl.radial_segments = 14
	cyl.cap_top = false
	cyl.cap_bottom = false

	var mat := ShaderMaterial.new()
	mat.shader = _beam_shader
	mat.set_shader_parameter("beam_color", color)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("edge_softness", 2.0)
	mat.set_shader_parameter("beam_height", cone_height)

	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.material_override = mat
	mi.position = top_pos - Vector3(0.0, cone_height * 0.5, 0.0)
	mi.rotation_degrees = rot_deg
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = vis_range
	parent.add_child(mi)
	return mi


static func add_static_box_collider(
	parent: Node3D,
	size: Vector3,
	pos: Vector3,
	rot_deg: Vector3 = Vector3.ZERO
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	body.rotation_degrees = rot_deg
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	parent.add_child(body)
	return body


static func add_occluder_box(parent: Node3D, size: Vector3, pos: Vector3) -> OccluderInstance3D:
	var occ := OccluderInstance3D.new()
	var box := BoxOccluder3D.new()
	box.size = size
	occ.occluder = box
	occ.position = pos
	parent.add_child(occ)
	return occ


static func make_fade_omni(
	parent: Node3D,
	pos: Vector3,
	color: Color,
	energy: float = 2.0,
	omni_range: float = 9.0,
	fade_begin: float = 34.0
) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.light_volumetric_fog_energy = 1.25
	light.omni_range = omni_range
	light.omni_attenuation = 1.4
	light.shadow_enabled = false
	light.distance_fade_enabled = true
	light.distance_fade_begin = fade_begin
	light.distance_fade_length = 14.0
	light.add_to_group("secondary_lights")
	parent.add_child(light)
	return light


static func make_steam_particles(
	amount: int = 18,
	lifetime: float = 2.6,
	rise_speed: float = 1.15,
	spread_radius: float = 0.25,
	tint: Color = Color(0.92, 0.88, 0.98, 0.22)
) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = 1.0
	p.visibility_range_end = 75.0

	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc.emission_sphere_radius = spread_radius
	proc.direction = Vector3(0.15, 1.0, 0.0)
	proc.spread = 22.0
	proc.initial_velocity_min = rise_speed * 0.7
	proc.initial_velocity_max = rise_speed * 1.25
	proc.gravity = Vector3(0.18, 0.22, 0.05)
	proc.scale_min = 0.35
	proc.scale_max = 1.15

	var grad := Gradient.new()
	grad.set_color(0, Color(tint.r, tint.g, tint.b, 0.0))
	grad.add_point(0.25, tint)
	grad.add_point(0.75, Color(tint.r, tint.g, tint.b, tint.a * 0.55))
	grad.set_color(grad.get_point_count() - 1, Color(tint.r, tint.g, tint.b, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	proc.color_ramp = grad_tex
	p.process_material = proc

	var quad := QuadMesh.new()
	quad.size = Vector2(0.72, 0.72)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.albedo_texture = _make_soft_puff_texture()
	quad.material = mat
	p.draw_pass_1 = quad
	return p


static func _make_soft_puff_texture() -> ImageTexture:
	if _puff_tex != null:
		return _puff_tex
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	for y in range(size):
		for x in range(size):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center) / (size * 0.5)
			var a := pow(clampf(1.0 - d, 0.0, 1.0), 2.1)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_puff_tex = ImageTexture.create_from_image(img)
	return _puff_tex
