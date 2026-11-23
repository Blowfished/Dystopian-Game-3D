@tool
class_name ScooterProp
extends Node3D

@export var body_color: Color = Palette.SCOOTER_BODY:
	set(v):
		body_color = v
		if is_inside_tree():
			_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	# Slight relaxed kickstand lean
	visual.rotation_degrees = Vector3(0.0, 0.0, -7.0)
	add_child(visual)

	var body_mat := Palette.make_stylized_material(body_color, 0.42, 0.18, Color("#8FE0DC"), 0.36)
	var trim_mat := Palette.make_stylized_material(Palette.SCOOTER_ACCENT, 0.52, 0.12, Color("#FFD699"), 0.30)
	var tire_mat := Palette.make_stylized_material(Color("#151926"), 0.88, 0.02, Color("#5670A3"), 0.20)
	var metal_mat := Palette.make_stylized_material(Palette.STEEL_LIGHT, 0.38, 0.65, Color("#A4C2F0"), 0.35)
	var seat_mat := Palette.make_stylized_material(Palette.COURIER_BAG, 0.72, 0.04, Color("#D6A578"), 0.25)
	var head_glow := Palette.make_emissive_material(Palette.CREAM_WARM, 3.2)
	var tail_glow := Palette.make_emissive_material(Palette.NEON_CORAL, 2.6)

	# Wheels (scooter points along +Z)
	PropUtils.add_cylinder(visual, 0.28, 0.28, 0.14, Vector3(0.0, 0.28, 0.68), tire_mat, Vector3(0.0, 0.0, 90.0), 14)
	PropUtils.add_cylinder(visual, 0.15, 0.15, 0.16, Vector3(0.0, 0.28, 0.68), metal_mat, Vector3(0.0, 0.0, 90.0), 10)
	PropUtils.add_cylinder(visual, 0.28, 0.28, 0.15, Vector3(0.0, 0.28, -0.64), tire_mat, Vector3(0.0, 0.0, 90.0), 14)
	PropUtils.add_cylinder(visual, 0.15, 0.15, 0.17, Vector3(0.0, 0.28, -0.64), metal_mat, Vector3(0.0, 0.0, 90.0), 10)

	# Floorboard & rear fairing
	PropUtils.add_box(visual, Vector3(0.42, 0.10, 0.88), Vector3(0.0, 0.28, 0.02), body_mat)
	PropUtils.add_box(visual, Vector3(0.48, 0.42, 0.86), Vector3(0.0, 0.56, -0.52), body_mat)
	PropUtils.add_box(visual, Vector3(0.50, 0.08, 0.78), Vector3(0.0, 0.62, -0.52), trim_mat)

	# Front leg shield & fender
	PropUtils.add_box(visual, Vector3(0.44, 0.72, 0.20), Vector3(0.0, 0.66, 0.46), body_mat, Vector3(-16.0, 0.0, 0.0))
	PropUtils.add_box(visual, Vector3(0.24, 0.16, 0.38), Vector3(0.0, 0.48, 0.72), body_mat, Vector3(12.0, 0.0, 0.0))

	# Seat & rear courier rack box
	PropUtils.add_box(visual, Vector3(0.36, 0.14, 0.64), Vector3(0.0, 0.82, -0.34), seat_mat)
	PropUtils.add_box(visual, Vector3(0.36, 0.28, 0.34), Vector3(0.0, 0.94, -0.84), trim_mat)

	# Steering column, handlebars, headlight & taillight
	PropUtils.add_cylinder(visual, 0.045, 0.055, 0.52, Vector3(0.0, 0.95, 0.42), metal_mat, Vector3(-15.0, 0.0, 0.0), 8)
	PropUtils.add_cylinder(visual, 0.025, 0.025, 0.68, Vector3(0.0, 1.14, 0.36), metal_mat, Vector3(0.0, 0.0, 90.0), 8)
	PropUtils.add_cylinder(visual, 0.085, 0.085, 0.10, Vector3(0.0, 1.10, 0.49), head_glow, Vector3(90.0, 0.0, 0.0), 10)
	PropUtils.add_box(visual, Vector3(0.18, 0.09, 0.06), Vector3(0.0, 0.66, -0.96), tail_glow)

	# Kickstand
	PropUtils.add_strut(visual, Vector3(-0.18, 0.26, -0.10), Vector3(-0.32, 0.0, -0.22), 0.035, metal_mat)

	PropUtils.add_static_box_collider(self, Vector3(0.66, 1.18, 1.88), Vector3(0.0, 0.59, -0.05))
