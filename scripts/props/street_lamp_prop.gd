@tool
class_name StreetLampProp
extends Node3D

@export var lamp_height: float = 4.6:
	set(v):
		lamp_height = maxf(v, 2.5)
		if is_inside_tree():
			_rebuild()

@export var light_energy: float = 4.6:
	set(v):
		light_energy = v
		if is_inside_tree():
			_rebuild()

@export var cast_shadows: bool = true:
	set(v):
		cast_shadows = v
		if is_inside_tree():
			_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var steel_dark := Palette.make_stylized_material(Palette.STEEL_DARK, 0.50, 0.48, Color("#6D8EC9"), 0.28)
	var steel_mid := Palette.make_stylized_material(Palette.STEEL_MID, 0.45, 0.52, Color("#89ACEB"), 0.32)
	var lamp_glow := Palette.make_emissive_material(Palette.LAMP_AMBER, 3.6, 0.2)

	# Heavy base pedestal & tall mast
	PropUtils.add_cylinder(visual, 0.16, 0.22, 0.52, Vector3(0.0, 0.26, 0.0), steel_dark, Vector3.ZERO, 10)
	PropUtils.add_cylinder(visual, 0.055, 0.085, lamp_height, Vector3(0.0, lamp_height * 0.5, 0.0), steel_mid, Vector3.ZERO, 10)

	# Stylized angled arm reaching along +Z
	var arm_y := lamp_height - 0.15
	PropUtils.add_strut(visual, Vector3(0.0, arm_y - 0.28, 0.0), Vector3(0.0, arm_y + 0.12, 1.05), 0.065, steel_dark)
	PropUtils.add_strut(visual, Vector3(0.0, arm_y - 0.72, 0.0), Vector3(0.0, arm_y - 0.05, 0.58), 0.04, steel_dark)

	# Cozy lantern hood & glowing bulb
	var head_pos := Vector3(0.0, arm_y + 0.05, 1.08)
	PropUtils.add_cylinder(visual, 0.12, 0.34, 0.22, head_pos + Vector3(0.0, 0.08, 0.0), steel_dark, Vector3.ZERO, 12)
	PropUtils.add_sphere(visual, 0.15, head_pos - Vector3(0.0, 0.07, 0.0), lamp_glow, Vector3(1.0, 1.12, 1.0), 10)

	# Soft volumetric-feel light cone mesh (works nicely even on Low quality when Volumetric Fog is off!)
	var cone_h := lamp_height * 0.85
	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 0.22
	cone_mesh.bottom_radius = 2.05
	cone_mesh.height = cone_h
	cone_mesh.radial_segments = 18
	cone_mesh.cap_top = false
	cone_mesh.cap_bottom = false

	var cone_mat := ShaderMaterial.new()
	cone_mat.shader = load("res://shaders/searchlight_beam.gdshader")
	cone_mat.set_shader_parameter("beam_color", Palette.LAMP_AMBER)
	cone_mat.set_shader_parameter("intensity", 0.14)
	cone_mat.set_shader_parameter("edge_softness", 2.0)
	cone_mat.set_shader_parameter("beam_height", cone_h)

	var cone := MeshInstance3D.new()
	cone.mesh = cone_mesh
	cone.material_override = cone_mat
	# Flip upside down so v_height = 0 is at the lamp bulb (bright) and fades out toward the ground
	cone.position = head_pos - Vector3(0.0, cone_h * 0.5 + 0.08, 0.0)
	cone.rotation_degrees = Vector3(180.0, 0.0, 0.0)
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.add_child(cone)

	# Warm downward SpotLight3D casting golden pool onto the wet promenade
	var spot := SpotLight3D.new()
	spot.position = head_pos - Vector3(0.0, 0.14, 0.0)
	spot.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	spot.light_color = Palette.LAMP_AMBER
	spot.light_energy = light_energy
	spot.light_volumetric_fog_energy = 1.65
	spot.spot_range = lamp_height + 6.0
	spot.spot_angle = 52.0
	spot.spot_angle_attenuation = 1.7
	spot.shadow_enabled = cast_shadows
	spot.shadow_blur = 2.2
	add_child(spot)

	# Subtle warm halo omni around the lantern hood
	var halo := OmniLight3D.new()
	halo.position = head_pos - Vector3(0.0, 0.12, 0.0)
	halo.light_color = Palette.LANTERN_GLOW
	halo.light_energy = 1.3
	halo.omni_range = 4.2
	halo.add_to_group("secondary_lights")
	add_child(halo)

	PropUtils.add_static_box_collider(self, Vector3(0.28, lamp_height, 0.28), Vector3(0.0, lamp_height * 0.5, 0.0))
