@tool
class_name CatwalkBridgeProp
extends Node3D

@export var length: float = 7.5:
	set(v):
		length = maxf(v, 2.0)
		if is_inside_tree():
			_rebuild()

@export var width: float = 2.0:
	set(v):
		width = maxf(v, 1.2)
		if is_inside_tree():
			_rebuild()

@export var side_railings: bool = true:
	set(v):
		side_railings = v
		if is_inside_tree():
			_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var deck_mat := Palette.make_stylized_material(Palette.STEEL_MID, 0.48, 0.50, Color("#7A9FDB"), 0.30)
	var truss_mat := Palette.make_stylized_material(Palette.STEEL_DARK, 0.56, 0.46, Color("#5978B0"), 0.25)
	var light_strip := Palette.make_emissive_material(Palette.LANTERN_AMBER, 1.9)

	# Deck sits with top at local y = 0.0
	PropUtils.add_box(visual, Vector3(length, 0.14, width), Vector3(0.0, -0.07, 0.0), deck_mat)

	# Grate ribs
	var ribs := maxi(4, int(roundf(length / 0.7)))
	for i in range(ribs):
		var x := lerpf(-length * 0.48, length * 0.48, float(i) / float(maxi(1, ribs - 1)))
		PropUtils.add_box(visual, Vector3(0.06, 0.02, width - 0.14), Vector3(x, 0.008, 0.0), truss_mat)

	# Underside I-beams & diagonal truss depth
	var depth := 0.52
	var hz := width * 0.46
	PropUtils.add_box(visual, Vector3(length, 0.07, 0.07), Vector3(0.0, -depth, hz), truss_mat)
	PropUtils.add_box(visual, Vector3(length, 0.07, 0.07), Vector3(0.0, -depth, -hz), truss_mat)

	var bays := maxi(3, int(roundf(length / 1.25)))
	for b in range(bays):
		var x0 := lerpf(-length * 0.48, length * 0.48, float(b) / float(bays))
		var x1 := lerpf(-length * 0.48, length * 0.48, float(b + 1) / float(bays))
		for cz in [-hz, hz]:
			PropUtils.add_box(visual, Vector3(0.06, depth, 0.06), Vector3(x0, -depth * 0.5, cz), truss_mat)
			if b % 2 == 0:
				PropUtils.add_strut(visual, Vector3(x0, -0.10, cz), Vector3(x1, -depth, cz), 0.045, truss_mat)
			else:
				PropUtils.add_strut(visual, Vector3(x0, -depth, cz), Vector3(x1, -0.10, cz), 0.045, truss_mat)

	# Subtle warm under-bridge lighting strips
	PropUtils.add_box(visual, Vector3(length - 0.5, 0.03, 0.03), Vector3(0.0, -0.15, hz + 0.02), light_strip)
	PropUtils.add_box(visual, Vector3(length - 0.5, 0.03, 0.03), Vector3(0.0, -0.15, -hz - 0.02), light_strip)

	# Low curb / side rails (leaving ends open so player walks across freely)
	if side_railings:
		var rail_h := 0.96
		for cz in [-hz, hz]:
			PropUtils.add_box(visual, Vector3(length, 0.055, 0.06), Vector3(0.0, rail_h, cz), deck_mat)
			PropUtils.add_box(visual, Vector3(length, 0.035, 0.04), Vector3(0.0, rail_h * 0.48, cz), truss_mat)
			var posts := maxi(3, int(roundf(length / 1.8)) + 1)
			for p in range(posts):
				var x := lerpf(-length * 0.48, length * 0.48, float(p) / float(posts - 1))
				PropUtils.add_box(visual, Vector3(0.055, rail_h, 0.055), Vector3(x, rail_h * 0.5, cz), truss_mat)
			PropUtils.add_static_box_collider(self, Vector3(length, rail_h, 0.12), Vector3(0.0, rail_h * 0.5, cz))

	PropUtils.add_static_box_collider(self, Vector3(length, depth, width), Vector3(0.0, -depth * 0.5, 0.0))
