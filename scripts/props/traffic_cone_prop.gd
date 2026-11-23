@tool
class_name TrafficConeProp
extends Node3D

@export var glowing_tip: bool = false:
	set(v):
		glowing_tip = v
		if is_inside_tree():
			_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var base_mat := Palette.make_stylized_material(Palette.STEEL_DARK, 0.72, 0.1, Color("#607DB3"), 0.22)
	var cone_mat := Palette.make_stylized_material(Palette.CONE_ORANGE, 0.60, 0.02, Color("#FFBB85"), 0.36)
	var stripe_mat := Palette.make_emissive_material(Palette.CONE_STRIPE, 0.45, 0.35)

	PropUtils.add_box(visual, Vector3(0.42, 0.055, 0.42), Vector3(0.0, 0.028, 0.0), base_mat)
	PropUtils.add_cylinder(visual, 0.045, 0.165, 0.62, Vector3(0.0, 0.34, 0.0), cone_mat, Vector3.ZERO, 12)
	PropUtils.add_cylinder(visual, 0.082, 0.115, 0.14, Vector3(0.0, 0.42, 0.0), stripe_mat, Vector3.ZERO, 12)

	if glowing_tip:
		var tip := Palette.make_emissive_material(Palette.LANTERN_AMBER, 2.4)
		PropUtils.add_sphere(visual, 0.055, Vector3(0.0, 0.68, 0.0), tip, Vector3.ONE, 8)

	PropUtils.add_static_box_collider(self, Vector3(0.38, 0.66, 0.38), Vector3(0.0, 0.33, 0.0))
