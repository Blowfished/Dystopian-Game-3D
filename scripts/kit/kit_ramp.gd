@tool
class_name KitRamp
extends Node3D

## Solid architectural accessible ramp rising along -Z from y=0 to y=height over run_length.
## Supported by solid concrete/steel piers reaching down below y=0 (never floating!)
## and overlapping landing aprons at both ends so there are zero collision gaps.

@export var width: float = 4.5:
	set(v):
		width = maxf(v, 1.8)
		if is_inside_tree():
			_rebuild()

@export var height: float = 5.0:
	set(v):
		height = v
		if is_inside_tree():
			_rebuild()

@export var run_length: float = 16.0:
	set(v):
		run_length = maxf(v, 3.0)
		if is_inside_tree():
			_rebuild()

@export var accent_color: Color = Palette.LANDMARK_TEAL
@export var foundation_depth: float = 16.0


func _ready() -> void:
	add_to_group("walkable_surfaces")
	set_meta("walkable_type", "ramp")
	set_meta("walkable_size", Vector3(width, height, run_length))
	set_meta("support_type", "solid_ramp_piers")
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	set_meta("walkable_size", Vector3(width, height, run_length))
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var deck_mat := Palette.make_stylized_material(Palette.STEEL_MID, 0.56, 0.35, Color("#8878C4"), 0.26)
	var concrete := Palette.make_stylized_material(Palette.CONCRETE_DARK, 0.84, 0.06, Color("#6E5CA8"), 0.20)
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.54, 0.45, Color("#7362AD"), 0.24)
	var trim := Palette.make_emissive_material(accent_color, 1.85)

	var slope_len := sqrt(run_length * run_length + height * height)
	var angle_deg := rad_to_deg(atan2(height, run_length))
	var mid := Vector3(0.0, height * 0.5, -run_length * 0.5)

	# Main ramp deck + thick under-girder
	PropUtils.add_box(visual, Vector3(width, 0.42, slope_len + 0.3), mid - Vector3(0.0, 0.21, 0.0), deck_mat, Vector3(angle_deg, 0.0, 0.0))
	PropUtils.add_box(visual, Vector3(width - 0.3, 0.55, slope_len), mid - Vector3(0.0, 0.65, 0.0), steel, Vector3(angle_deg, 0.0, 0.0))

	# Solid architectural support wall/piers underneath the ramp down to ground / foundation_depth
	var segs := maxi(4, int(roundf(run_length / 3.5)))
	var seg_d := run_length / float(segs)
	for i in range(segs):
		var t := (float(i) + 0.5) / float(segs)
		var sy := height * t
		var sz := -run_length * t
		var total_h := sy + foundation_depth
		var pier := PropUtils.add_box(visual, Vector3(width - 0.35, total_h, seg_d + 0.12), Vector3(0.0, sy - 0.45 - total_h * 0.5, sz), concrete)
		pier.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pier.visibility_range_end = 240.0

	# Side handrails & glow strips
	for sx in [-width * 0.5 - 0.08, width * 0.5 + 0.08]:
		PropUtils.add_box(visual, Vector3(0.09, 0.08, slope_len + 0.2), mid + Vector3(sx, 1.0, 0.0), steel, Vector3(angle_deg, 0.0, 0.0))
		PropUtils.add_box(visual, Vector3(0.06, 0.05, slope_len + 0.2), mid + Vector3(sx, 0.52, 0.0), steel, Vector3(angle_deg, 0.0, 0.0))
		PropUtils.add_box(visual, Vector3(0.05, 0.05, slope_len), mid + Vector3(sx, 0.14, 0.0), trim, Vector3(angle_deg, 0.0, 0.0))
		PropUtils.add_static_box_collider(self, Vector3(0.20, 1.12, slope_len + 0.2), mid + Vector3(sx, 0.55, 0.0), Vector3(angle_deg, 0.0, 0.0))

	# Smooth sloped collider + overlapping bottom & top landing aprons
	PropUtils.add_static_box_collider(self, Vector3(width + 0.3, 0.5, slope_len + 0.7), mid - Vector3(0.0, 0.25, 0.0), Vector3(angle_deg, 0.0, 0.0))
	PropUtils.add_static_box_collider(self, Vector3(width + 0.3, 0.5, 1.0), Vector3(0.0, -0.25, 0.3))
	PropUtils.add_static_box_collider(self, Vector3(width + 0.3, 0.5, 1.2), Vector3(0.0, height - 0.25, -run_length - 0.4))
