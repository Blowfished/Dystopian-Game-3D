@tool
class_name BenchProp
extends Node3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var wood := Palette.make_stylized_material(Palette.WOOD_WARM, 0.74, 0.04, Color("#F2C28B"), 0.28)
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.50, 0.50, Color("#6A8CC7"), 0.26)

	# Seat slats
	for sz in [-0.15, 0.0, 0.15]:
		PropUtils.add_box(visual, Vector3(1.85, 0.055, 0.12), Vector3(0.0, 0.46, sz), wood)
	# Backrest slats
	for by in [0.70, 0.86]:
		PropUtils.add_box(visual, Vector3(1.85, 0.11, 0.045), Vector3(0.0, by, -0.24), wood, Vector3(-12.0, 0.0, 0.0))

	# Steel legs & armrests
	for lx in [-0.76, 0.76]:
		PropUtils.add_box(visual, Vector3(0.06, 0.46, 0.46), Vector3(lx, 0.23, 0.0), steel)
		PropUtils.add_box(visual, Vector3(0.06, 0.50, 0.06), Vector3(lx, 0.68, -0.22), steel, Vector3(-12.0, 0.0, 0.0))

	PropUtils.add_static_box_collider(self, Vector3(1.88, 0.52, 0.54), Vector3(0.0, 0.26, 0.0))
