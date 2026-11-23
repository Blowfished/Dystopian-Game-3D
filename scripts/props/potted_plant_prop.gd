@tool
class_name PottedPlantProp
extends Node3D

@export_enum("Round Planter", "Long Planter") var planter_style: int = 0:
	set(v):
		planter_style = v
		if is_inside_tree():
			_rebuild()

@export var seed_offset: int = 1:
	set(v):
		seed_offset = v
		if is_inside_tree():
			_rebuild()

var _foliage_root: Node3D
var _time: float = 0.0


func _ready() -> void:
	_rebuild()


func _process(delta: float) -> void:
	_time += delta
	if is_instance_valid(_foliage_root):
		_foliage_root.rotation.z = sin(_time * 1.4 + float(seed_offset) * 1.7) * 0.035
		_foliage_root.rotation.x = cos(_time * 1.1 + float(seed_offset) * 0.8) * 0.025


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var pot_mat := Palette.make_stylized_material(Palette.CONCRETE_WARM, 0.82, 0.02, Color("#7A94C7"), 0.24)
	var pot_rim := Palette.make_stylized_material(Palette.AWNING_STRIPE_A.darkened(0.25), 0.78, 0.02, Color("#D69E7A"), 0.28)
	var soil_mat := Palette.make_stylized_material(Palette.WOOD_DARK, 0.94, 0.0, Color("#4D5B80"), 0.1)
	var leaf_dark := Palette.make_stylized_material(Palette.FOLIAGE_DARK, 0.80, 0.0, Color("#70BAAB"), 0.32)
	var leaf_mid := Palette.make_stylized_material(Palette.FOLIAGE_MID, 0.76, 0.0, Color("#8BD4C1"), 0.36)
	var leaf_light := Palette.make_stylized_material(Palette.FOLIAGE_LIGHT, 0.72, 0.0, Color("#B2EDD9"), 0.42)

	_foliage_root = Node3D.new()
	_foliage_root.position = Vector3(0.0, 0.56, 0.0)
	visual.add_child(_foliage_root)

	if planter_style == 0:
		PropUtils.add_cylinder(visual, 0.42, 0.32, 0.56, Vector3(0.0, 0.28, 0.0), pot_mat, Vector3.ZERO, 10)
		PropUtils.add_cylinder(visual, 0.46, 0.45, 0.09, Vector3(0.0, 0.54, 0.0), pot_rim, Vector3.ZERO, 10)
		PropUtils.add_cylinder(visual, 0.38, 0.38, 0.05, Vector3(0.0, 0.54, 0.0), soil_mat, Vector3.ZERO, 10)

		# Stylized lush layered bush clusters
		PropUtils.add_sphere(_foliage_root, 0.36, Vector3(0.0, 0.28, 0.0), leaf_dark, Vector3(1.15, 0.92, 1.1), 10)
		PropUtils.add_sphere(_foliage_root, 0.29, Vector3(-0.22, 0.42, 0.12), leaf_mid, Vector3(1.05, 0.95, 1.0), 10)
		PropUtils.add_sphere(_foliage_root, 0.27, Vector3(0.24, 0.38, -0.10), leaf_mid, Vector3(1.0, 0.9, 1.05), 10)
		PropUtils.add_sphere(_foliage_root, 0.24, Vector3(0.04, 0.62, 0.02), leaf_light, Vector3(1.1, 0.95, 1.0), 10)
		PropUtils.add_sphere(_foliage_root, 0.18, Vector3(-0.14, 0.66, -0.14), leaf_light, Vector3(1.0, 0.85, 1.0), 8)
		PropUtils.add_static_box_collider(self, Vector3(0.84, 0.60, 0.84), Vector3(0.0, 0.30, 0.0))
	else:
		PropUtils.add_box(visual, Vector3(1.55, 0.54, 0.64), Vector3(0.0, 0.27, 0.0), pot_mat)
		PropUtils.add_box(visual, Vector3(1.63, 0.08, 0.72), Vector3(0.0, 0.54, 0.0), pot_rim)
		PropUtils.add_box(visual, Vector3(1.42, 0.05, 0.52), Vector3(0.0, 0.55, 0.0), soil_mat)

		for cx in [-0.46, 0.0, 0.46]:
			PropUtils.add_sphere(_foliage_root, 0.30, Vector3(cx, 0.24, 0.0), leaf_dark, Vector3(1.1, 0.86, 0.95), 9)
			PropUtils.add_sphere(_foliage_root, 0.24, Vector3(cx + 0.08, 0.42, 0.06), leaf_mid, Vector3(1.0, 0.92, 0.9), 9)
			PropUtils.add_sphere(_foliage_root, 0.18, Vector3(cx - 0.06, 0.56, -0.04), leaf_light, Vector3(1.0, 0.85, 0.9), 8)
		PropUtils.add_static_box_collider(self, Vector3(1.60, 0.58, 0.70), Vector3(0.0, 0.29, 0.0))
