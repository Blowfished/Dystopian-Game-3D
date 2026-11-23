@tool
class_name StreetLampProp
extends Node3D

## Warm cozy cyberpunk street lamp with fake volumetric cone, additive wet-ground
## golden glow pool, and distance-faded SpotLight3D (shadows off by default for 60 FPS).

@export var lamp_height: float = 4.8:
	set(v):
		lamp_height = maxf(v, 2.5)
		if is_inside_tree():
			_rebuild()

@export var light_energy: float = 4.4:
	set(v):
		light_energy = v
		if is_inside_tree():
			_rebuild()

@export var cast_shadows: bool = false:
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

	var steel_dark := Palette.make_stylized_material(Palette.STEEL_DARK, 0.50, 0.48, Color("#7D6EC4"), 0.28)
	var steel_mid := Palette.make_stylized_material(Palette.STEEL_MID, 0.45, 0.52, Color("#9B8CE0"), 0.32)
	var lamp_glow := Palette.make_emissive_material(Palette.LAMP_AMBER, 3.8, 0.2)

	# Heavy base pedestal & tall mast
	PropUtils.add_cylinder(visual, 0.16, 0.22, 0.52, Vector3(0.0, 0.26, 0.0), steel_dark, Vector3.ZERO, 10)
	PropUtils.add_cylinder(visual, 0.055, 0.085, lamp_height, Vector3(0.0, lamp_height * 0.5, 0.0), steel_mid, Vector3.ZERO, 10)

	# Angled arm reaching along +Z
	var arm_y := lamp_height - 0.15
	PropUtils.add_strut(visual, Vector3(0.0, arm_y - 0.28, 0.0), Vector3(0.0, arm_y + 0.12, 1.15), 0.065, steel_dark)
	PropUtils.add_strut(visual, Vector3(0.0, arm_y - 0.72, 0.0), Vector3(0.0, arm_y - 0.05, 0.62), 0.04, steel_dark)

	# Cozy lantern hood, glowing bulb & billboard halo
	var head_pos := Vector3(0.0, arm_y + 0.05, 1.18)
	PropUtils.add_cylinder(visual, 0.12, 0.34, 0.22, head_pos + Vector3(0.0, 0.08, 0.0), steel_dark, Vector3.ZERO, 10)
	PropUtils.add_sphere(visual, 0.16, head_pos - Vector3(0.0, 0.07, 0.0), lamp_glow, Vector3(1.0, 1.12, 1.0), 10)
	PropUtils.add_glow_card(visual, head_pos - Vector3(0.0, 0.10, 0.0), Vector2(1.4, 1.4), Palette.LAMP_AMBER, 0.32, 115.0)

	# Cheap volumetric-feel light cone + wet-ground golden light pool!
	PropUtils.add_light_cone(visual, head_pos - Vector3(0.0, 0.08, 0.0), lamp_height * 0.88, 0.22, 2.4, Palette.LAMP_AMBER, 0.16, Vector3(180.0, 0.0, 0.0), 110.0)
	PropUtils.add_ground_glow_pool(visual, Vector3(0.0, 0.0, 1.18), Vector2(6.2, 6.2), Palette.LAMP_AMBER, 0.28, 110.0)

	# Distance-faded downward SpotLight3D casting golden pool onto the wet street
	var spot := SpotLight3D.new()
	spot.position = head_pos - Vector3(0.0, 0.14, 0.0)
	spot.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	spot.light_color = Palette.LAMP_AMBER
	spot.light_energy = light_energy
	spot.light_volumetric_fog_energy = 1.6
	spot.spot_range = lamp_height + 6.5
	spot.spot_angle = 56.0
	spot.spot_angle_attenuation = 1.6
	spot.shadow_enabled = cast_shadows
	spot.distance_fade_enabled = true
	spot.distance_fade_begin = 38.0
	spot.distance_fade_length = 14.0
	spot.add_to_group("secondary_lights")
	add_child(spot)

	PropUtils.add_static_box_collider(self, Vector3(0.28, lamp_height, 0.28), Vector3(0.0, lamp_height * 0.5, 0.0))
