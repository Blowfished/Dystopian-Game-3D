@tool
class_name KitCanopy
extends Node3D

## Stylized fabric canopy / market stall tent in Market Terraces & Rooftop Gardens.

@export var width: float = 4.8
@export var depth: float = 3.4
@export var height: float = 3.1
@export var color_a: Color = Palette.CANOPY_OCHRE
@export var color_b: Color = Palette.AWNING_STRIPE_B
@export var is_flower_stall: bool = false
@export var add_light: bool = true


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var mat_a := Palette.make_stylized_material(color_a, 0.85, 0.0, Color("#FFE2B0"), 0.25)
	var mat_b := Palette.make_stylized_material(color_b, 0.82, 0.0, Color("#FFF0D4"), 0.25)
	var wood := Palette.make_stylized_material(Palette.WOOD_WARM, 0.74, 0.04, Color("#F2C28B"), 0.25)
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.55, 0.45, Color("#6C8DC9"), 0.22)

	# 4 corner poles
	for px in [-width * 0.46, width * 0.46]:
		for pz in [-depth * 0.46, depth * 0.46]:
			PropUtils.add_cylinder(visual, 0.04, 0.045, height, Vector3(px, height * 0.5, pz), steel, Vector3.ZERO, 8)

	# Striped pitched fabric canopy
	var stripes := 7
	var sw := width / float(stripes)
	for i in range(stripes):
		var sx := -width * 0.5 + sw * (float(i) + 0.5)
		var m := mat_a if i % 2 == 0 else mat_b
		PropUtils.add_box(visual, Vector3(sw - 0.01, 0.07, depth + 0.25), Vector3(sx, height, 0.0), m, Vector3(10.0, 0.0, 0.0))

	# Wooden vendor counter
	PropUtils.add_box(visual, Vector3(width * 0.82, 0.92, 0.85), Vector3(0.0, 0.46, 0.25), wood)
	PropUtils.add_static_box_collider(self, Vector3(width * 0.82, 0.92, 0.85), Vector3(0.0, 0.46, 0.25))

	if is_flower_stall:
		var leaf := Palette.make_stylized_material(Palette.FOLIAGE_MID, 0.78, 0.0, Color("#8BD4C1"), 0.32)
		var f_cols := [Palette.FLOWER_CORAL, Palette.FLOWER_GOLD, Palette.FLOWER_LAVENDER]
		for j in range(5):
			var fx := lerpf(-width * 0.32, width * 0.32, float(j) / 4.0)
			PropUtils.add_sphere(visual, 0.22, Vector3(fx, 1.06, 0.25), leaf, Vector3(1.1, 0.8, 1.1), 8)
			var fmat := Palette.make_stylized_material(f_cols[j % f_cols.size()], 0.7, 0.0, Color("#FFF0CC"), 0.35)
			PropUtils.add_sphere(visual, 0.11, Vector3(fx, 1.24, 0.25), fmat, Vector3.ONE, 6)

	if add_light:
		PropUtils.make_fade_omni(self, Vector3(0.0, height - 0.45, 0.2), Palette.LANTERN_AMBER, 1.8, 8.5, 36.0)
