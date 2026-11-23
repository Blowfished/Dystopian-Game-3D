@tool
class_name CrateStackProp
extends Node3D

@export_enum("Step Stack (Climbable)", "Low Cluster") var layout: int = 0:
	set(v):
		layout = v
		if is_inside_tree():
			_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var crate_teal := Palette.make_stylized_material(Palette.CRATE_TEAL, 0.68, 0.14, Color("#6FC7D1"), 0.28)
	var crate_ochre := Palette.make_stylized_material(Palette.CRATE_OCHRE, 0.72, 0.08, Color("#E8B982"), 0.28)
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.52, 0.45, Color("#6A8AC4"), 0.24)
	var tag := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 1.8)

	if layout == 0:
		# Lower large crate (y: 0 -> 1.1)
		_build_crate(visual, Vector3(1.25, 1.10, 1.15), Vector3(-0.55, 0.55, 0.0), crate_teal, steel, tag)
		PropUtils.add_static_box_collider(self, Vector3(1.25, 1.10, 1.15), Vector3(-0.55, 0.55, 0.0))

		# Adjacent taller stacked pair (y: 0 -> 2.05) — natural step up to Tier 2 trusses!
		_build_crate(visual, Vector3(1.18, 1.15, 1.18), Vector3(0.70, 0.575, -0.06), crate_ochre, steel, null)
		_build_crate(visual, Vector3(0.98, 0.90, 0.98), Vector3(0.66, 1.60, -0.02), crate_teal, steel, tag, Vector3(0.0, 9.0, 0.0))
		PropUtils.add_static_box_collider(self, Vector3(1.18, 2.05, 1.18), Vector3(0.68, 1.025, -0.04))
	else:
		_build_crate(visual, Vector3(1.05, 0.85, 0.95), Vector3(-0.42, 0.425, 0.05), crate_ochre, steel, null)
		_build_crate(visual, Vector3(0.84, 0.72, 0.82), Vector3(0.56, 0.36, -0.10), crate_teal, steel, tag, Vector3(0.0, -14.0, 0.0))
		PropUtils.add_static_box_collider(self, Vector3(1.95, 0.85, 1.05), Vector3(0.05, 0.425, 0.0))


func _build_crate(
	parent: Node3D,
	size: Vector3,
	pos: Vector3,
	body_mat: Material,
	trim_mat: Material,
	tag_mat: Material,
	rot_deg: Vector3 = Vector3.ZERO
) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation_degrees = rot_deg
	parent.add_child(g)

	PropUtils.add_box(g, size, Vector3.ZERO, body_mat)
	# Top & bottom steel bands
	PropUtils.add_box(g, Vector3(size.x + 0.04, 0.08, size.z + 0.04), Vector3(0.0, size.y * 0.44, 0.0), trim_mat)
	PropUtils.add_box(g, Vector3(size.x + 0.04, 0.08, size.z + 0.04), Vector3(0.0, -size.y * 0.44, 0.0), trim_mat)
	if tag_mat:
		PropUtils.add_box(g, Vector3(0.24, 0.07, 0.03), Vector3(size.x * 0.2, 0.08, size.z * 0.5 + 0.012), tag_mat)
