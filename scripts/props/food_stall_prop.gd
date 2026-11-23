@tool
class_name FoodStallProp
extends Node3D

## Hero cozy cyberpunk night food stall with striped awning, warm glowing counter,
## hanging paper lanterns, steaming broth pot, menu sign, wooden stools, and cheap
## additive ground glow pool (distance-faded lights for steady 60 FPS).

@export var stall_light_energy: float = 4.2
@export var enable_steam: bool = true

var _lanterns: Array[Node3D] = []
var _time: float = 0.0


func _ready() -> void:
	_rebuild()


func _process(delta: float) -> void:
	_time += delta
	for i in range(_lanterns.size()):
		var l := _lanterns[i]
		if is_instance_valid(l):
			l.rotation.z = sin(_time * 1.65 + float(i) * 1.3) * 0.08
			l.rotation.x = cos(_time * 1.2 + float(i) * 0.9) * 0.05


func _rebuild() -> void:
	PropUtils.clear_children(self)
	_lanterns.clear()

	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var wood_dark := Palette.make_stylized_material(Palette.WOOD_DARK, 0.78, 0.04, Color("#D69E6C"), 0.24)
	var wood_warm := Palette.make_stylized_material(Palette.WOOD_WARM, 0.72, 0.04, Color("#FFC985"), 0.30)
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.54, 0.45, Color("#7A6BB5"), 0.26)
	var stripe_a := Palette.make_stylized_material(Palette.AWNING_STRIPE_A, 0.84, 0.0, Color("#FFAA85"), 0.28)
	var stripe_b := Palette.make_stylized_material(Palette.AWNING_STRIPE_B, 0.82, 0.0, Color("#FFE7C2"), 0.30)
	var interior_glow := Palette.make_emissive_material(Palette.STALL_WARM, 1.85, 0.45)
	var lantern_glow := Palette.make_emissive_material(Palette.LANTERN_AMBER, 3.0, 0.3)
	var sign_teal := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 2.7, 0.2)
	var sign_coral := Palette.make_emissive_material(Palette.NEON_CORAL, 2.6, 0.2)
	var pot_metal := Palette.make_stylized_material(Palette.STEEL_LIGHT, 0.34, 0.68, Color("#FFE2B3"), 0.35)
	var bowl_cream := Palette.make_stylized_material(Palette.CREAM_WARM, 0.45, 0.0, Color("#FFE3B3"), 0.25)

	# Booth base & back wall (faces +Z)
	PropUtils.add_box(visual, Vector3(4.4, 1.05, 2.1), Vector3(0.0, 0.525, -0.35), wood_dark)
	PropUtils.add_box(visual, Vector3(4.5, 2.85, 0.22), Vector3(0.0, 1.425, -1.35), steel)
	PropUtils.add_box(visual, Vector3(3.85, 1.45, 0.08), Vector3(0.0, 1.82, -1.21), interior_glow)
	for mx in [-1.45, -0.5, 0.5, 1.45]:
		PropUtils.add_box(visual, Vector3(0.08, 1.48, 0.12), Vector3(mx, 1.82, -1.18), wood_dark)

	PropUtils.add_box(visual, Vector3(0.20, 2.85, 2.1), Vector3(-2.15, 1.425, -0.35), wood_dark)
	PropUtils.add_box(visual, Vector3(0.20, 2.85, 2.1), Vector3(2.15, 1.425, -0.35), wood_dark)
	PropUtils.add_box(visual, Vector3(4.65, 0.12, 0.82), Vector3(0.0, 1.08, 0.55), wood_warm)
	PropUtils.add_box(visual, Vector3(4.6, 0.28, 2.35), Vector3(0.0, 2.95, -0.25), steel)

	# Striped Awning
	var awning_pivot := Node3D.new()
	awning_pivot.position = Vector3(0.0, 2.82, 0.78)
	awning_pivot.rotation_degrees = Vector3(18.0, 0.0, 0.0)
	visual.add_child(awning_pivot)

	var stripe_count := 9
	var total_w := 4.75
	var sw := total_w / float(stripe_count)
	for i in range(stripe_count):
		var x := -total_w * 0.5 + sw * (float(i) + 0.5)
		var mat := stripe_a if (i % 2 == 0) else stripe_b
		PropUtils.add_box(awning_pivot, Vector3(sw - 0.01, 0.075, 1.55), Vector3(x, 0.0, 0.55), mat)
		PropUtils.add_box(awning_pivot, Vector3(sw - 0.01, 0.24, 0.05), Vector3(x, -0.14, 1.31), mat, Vector3(-18.0, 0.0, 0.0))

	PropUtils.add_cylinder(visual, 0.035, 0.035, 2.55, Vector3(-2.15, 1.28, 1.15), steel, Vector3.ZERO, 8)
	PropUtils.add_cylinder(visual, 0.035, 0.035, 2.55, Vector3(2.15, 1.28, 1.15), steel, Vector3.ZERO, 8)

	# Overhead Glowing Menu Signboard
	PropUtils.add_box(visual, Vector3(3.1, 0.62, 0.14), Vector3(0.0, 3.45, 0.65), steel)
	PropUtils.add_box(visual, Vector3(2.92, 0.46, 0.06), Vector3(0.0, 3.45, 0.72), interior_glow)
	PropUtils.add_box(visual, Vector3(2.98, 0.04, 0.09), Vector3(0.0, 3.74, 0.71), sign_coral)
	PropUtils.add_box(visual, Vector3(2.98, 0.04, 0.09), Vector3(0.0, 3.16, 0.71), sign_teal)
	for gx in [-1.0, -0.45, 0.1, 0.65, 1.05]:
		PropUtils.add_box(visual, Vector3(0.24, 0.26, 0.08), Vector3(gx, 3.45, 0.73), wood_dark)

	# Steaming soup pot & bowls
	PropUtils.add_cylinder(visual, 0.26, 0.24, 0.34, Vector3(-1.15, 1.31, 0.32), pot_metal, Vector3.ZERO, 10)
	PropUtils.add_cylinder(visual, 0.14, 0.09, 0.11, Vector3(0.25, 1.19, 0.58), bowl_cream, Vector3.ZERO, 8)
	PropUtils.add_cylinder(visual, 0.14, 0.09, 0.11, Vector3(0.72, 1.19, 0.52), bowl_cream, Vector3.ZERO, 8)
	PropUtils.add_box(visual, Vector3(0.32, 0.26, 0.22), Vector3(1.45, 1.26, 0.38), wood_dark)

	# 3 cozy hanging paper lanterns + billboard glow halos
	for lx in [-1.35, 0.0, 1.35]:
		var lp := Node3D.new()
		lp.position = Vector3(lx, 2.38, 1.38)
		visual.add_child(lp)
		PropUtils.add_cylinder(lp, 0.012, 0.012, 0.22, Vector3(0.0, -0.11, 0.0), steel, Vector3.ZERO, 6)
		PropUtils.add_sphere(lp, 0.15, Vector3(0.0, -0.34, 0.0), lantern_glow, Vector3(0.95, 1.25, 0.95), 8)
		PropUtils.add_glow_card(lp, Vector3(0.0, -0.34, 0.0), Vector2(0.95, 0.95), Palette.LANTERN_AMBER, 0.28, 95.0)
		_lanterns.append(lp)

	# 3 wooden bar stools
	for sx in [-1.15, 0.0, 1.15]:
		PropUtils.add_cylinder(visual, 0.21, 0.21, 0.06, Vector3(sx, 0.66, 1.32), wood_warm, Vector3.ZERO, 8)
		PropUtils.add_cylinder(visual, 0.03, 0.04, 0.64, Vector3(sx, 0.32, 1.32), steel, Vector3.ZERO, 6)
		PropUtils.add_cylinder(visual, 0.19, 0.21, 0.04, Vector3(sx, 0.02, 1.32), steel, Vector3.ZERO, 8)

	# Lush warm ground glow pool + distance-faded non-shadow hero omni light
	PropUtils.add_ground_glow_pool(visual, Vector3(0.0, 0.0, 2.2), Vector2(7.5, 5.6), Palette.STALL_WARM, 0.36, 110.0)
	PropUtils.make_fade_omni(self, Vector3(0.0, 2.25, 1.25), Palette.STALL_WARM, stall_light_energy, 13.5, 42.0)

	if enable_steam:
		var steam := PropUtils.make_steam_particles(18, 2.4, 0.85, 0.18, Color(0.98, 0.92, 0.84, 0.24))
		steam.position = Vector3(-1.15, 1.54, 0.32)
		add_child(steam)

	PropUtils.add_static_box_collider(self, Vector3(4.5, 2.9, 2.35), Vector3(0.0, 1.45, -0.25))
	PropUtils.add_static_box_collider(self, Vector3(4.65, 1.12, 0.82), Vector3(0.0, 0.56, 0.55))
