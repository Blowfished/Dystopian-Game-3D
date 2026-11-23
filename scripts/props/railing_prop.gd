@tool
class_name RailingProp
extends Node3D

@export var length: float = 4.0:
	set(v):
		length = maxf(v, 0.8)
		if is_inside_tree():
			_rebuild()

@export var height: float = 1.05:
	set(v):
		height = maxf(v, 0.5)
		if is_inside_tree():
			_rebuild()

@export var accent_markers: bool = true:
	set(v):
		accent_markers = v
		if is_inside_tree():
			_rebuild()

@export var add_collision: bool = true


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var steel_dark := Palette.make_stylized_material(Palette.STEEL_DARK, 0.52, 0.45, Color("#6C8ECC"), 0.28)
	var steel_top := Palette.make_stylized_material(Palette.STEEL_LIGHT, 0.42, 0.55, Color("#8BB0EE"), 0.36)
	var marker_mat := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 1.8)

	# Top handrail & lower horizontal bar
	PropUtils.add_box(visual, Vector3(length + 0.06, 0.065, 0.08), Vector3(0.0, height, 0.0), steel_top)
	PropUtils.add_box(visual, Vector3(length, 0.04, 0.05), Vector3(0.0, height * 0.52, 0.0), steel_dark)
	PropUtils.add_box(visual, Vector3(length, 0.05, 0.06), Vector3(0.0, 0.12, 0.0), steel_dark)

	# Main end posts & intermediate posts
	var post_count := maxi(2, int(roundf(length / 2.0)) + 1)
	for i in range(post_count):
		var t := float(i) / float(post_count - 1)
		var x := lerpf(-length * 0.5, length * 0.5, t)
		PropUtils.add_box(visual, Vector3(0.075, height, 0.075), Vector3(x, height * 0.5, 0.0), steel_dark)
		PropUtils.add_box(visual, Vector3(0.14, 0.05, 0.14), Vector3(x, 0.025, 0.0), steel_dark)
		if accent_markers and (i == 0 or i == post_count - 1):
			PropUtils.add_box(visual, Vector3(0.04, 0.10, 0.085), Vector3(x, height - 0.16, 0.0), marker_mat)

	# Vertical balusters
	var baluster_count := maxi(3, int(floorf(length / 0.36)))
	for j in range(1, baluster_count):
		var x := lerpf(-length * 0.5, length * 0.5, float(j) / float(baluster_count))
		PropUtils.add_box(visual, Vector3(0.028, height - 0.16, 0.028), Vector3(x, height * 0.5 + 0.04, 0.0), steel_dark)

	if add_collision:
		PropUtils.add_static_box_collider(self, Vector3(length + 0.08, height + 0.06, 0.14), Vector3(0.0, height * 0.5, 0.0))
