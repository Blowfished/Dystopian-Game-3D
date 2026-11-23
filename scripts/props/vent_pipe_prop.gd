@tool
class_name VentPipeProp
extends Node3D

@export var pipe_height: float = 4.5:
	set(v):
		pipe_height = maxf(v, 1.5)
		if is_inside_tree():
			_rebuild()

@export var emit_steam: bool = true:
	set(v):
		emit_steam = v
		if is_inside_tree():
			_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var pipe_mat := Palette.make_stylized_material(Palette.STEEL_MID, 0.48, 0.55, Color("#7397D6"), 0.30)
	var collar_mat := Palette.make_stylized_material(Palette.STEEL_DARK, 0.56, 0.46, Color("#5774AD"), 0.24)
	var warm_grate := Palette.make_emissive_material(Palette.LANTERN_AMBER, 0.65, 0.5)

	# Twin vertical megastructure pipes + flange collars
	PropUtils.add_cylinder(visual, 0.16, 0.16, pipe_height, Vector3(-0.26, pipe_height * 0.5, 0.0), pipe_mat, Vector3.ZERO, 10)
	PropUtils.add_cylinder(visual, 0.11, 0.11, pipe_height * 0.88, Vector3(0.18, pipe_height * 0.44, 0.06), pipe_mat, Vector3.ZERO, 10)
	for cy in [0.5, pipe_height * 0.48, pipe_height - 0.45]:
		PropUtils.add_cylinder(visual, 0.21, 0.21, 0.12, Vector3(-0.26, cy, 0.0), collar_mat, Vector3.ZERO, 10)

	# Low steam vent exhaust box
	PropUtils.add_box(visual, Vector3(0.92, 0.58, 0.64), Vector3(0.0, 0.29, 0.28), collar_mat)
	PropUtils.add_box(visual, Vector3(0.76, 0.08, 0.48), Vector3(0.0, 0.58, 0.28), warm_grate)
	for gx in [-0.24, -0.08, 0.08, 0.24]:
		PropUtils.add_box(visual, Vector3(0.04, 0.09, 0.50), Vector3(gx, 0.59, 0.28), collar_mat)

	if emit_steam:
		var steam := PropUtils.make_steam_particles(24, 3.0, 1.05, 0.26, Color(0.80, 0.88, 1.0, 0.22))
		steam.position = Vector3(0.0, 0.66, 0.28)
		add_child(steam)

	PropUtils.add_static_box_collider(self, Vector3(0.96, 0.64, 0.68), Vector3(0.0, 0.32, 0.26))
