@tool
class_name FoodStallProp
extends Node3D

## Hero cozy cyberpunk night food stall with striped awning, warm glowing counter,
## hanging paper lanterns, steaming broth pot, menu sign, and wooden stools.

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
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.54, 0.45, Color("#6C8DC9"), 0.26)
	var stripe_a := Palette.make_stylized_material(Palette.AWNING_STRIPE_A, 0.84, 0.0, Color("#FFAA85"), 0.28)
	var stripe_b := Palette.make_stylized_material(Palette.AWNING_STRIPE_B, 0.82, 0.0, Color("#FFE7C2"), 0.30)
	var interior_glow := Palette.make_emissive_material(Palette.STALL_WARM, 1.45, 0.5)
	var lantern_glow := Palette.make_emissive_material(Palette.LANTERN_AMBER, 2.8, 0.3)
	var sign_teal := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 2.6, 0.2)
	var sign_coral := Palette.make_emissive_material(Palette.NEON_CORAL, 2.5, 0.2)
	var pot_metal := Palette.make_stylized_material(Palette.STEEL_LIGHT, 0.34, 0.68, Color("#FFE2B3"), 0.35)
	var bowl_cream := Palette.make_stylized_material(Palette.CREAM_WARM, 0.45, 0.0, Color("#FFE3B3"), 0.25)

	# Booth base & back wall (faces +Z toward the promenade)
	PropUtils.add_box(visual, Vector3(4.4, 1.05, 2.1), Vector3(0.0, 0.525, -0.35), wood_dark)
	PropUtils.add_box(visual, Vector3(4.5, 2.85, 0.22), Vector3(0.0, 1.425, -1.35), steel)
	# Warm glowing rear kitchen wall window
	PropUtils.add_box(visual, Vector3(3.85, 1.45, 0.08), Vector3(0.0, 1.82, -1.21), interior_glow)
	# Vertical wooden mullion slats across rear glow panel for cozy depth
	for mx in [-1.45, -0.5, 0.5, 1.45]:
		PropUtils.add_box(visual, Vector3(0.08, 1.48, 0.12), Vector3(mx, 1.82, -1.18), wood_dark)

	# Side walls
	PropUtils.add_box(visual, Vector3(0.20, 2.85, 2.1), Vector3(-2.15, 1.425, -0.35), wood_dark)
	PropUtils.add_box(visual, Vector3(0.20, 2.85, 2.1), Vector3(2.15, 1.425, -0.35), wood_dark)

	# Serving counter slab protruding slightly forward
	PropUtils.add_box(visual, Vector3(4.65, 0.12, 0.82), Vector3(0.0, 1.08, 0.55), wood_warm)
	# Roof box
	PropUtils.add_box(visual, Vector3(4.6, 0.28, 2.35), Vector3(0.0, 2.95, -0.25), steel)

	# Striped Awning (9 crisp alternating terracotta & cream panels angled outward!)
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
		# Scalloped front valance flap hanging vertically
		PropUtils.add_box(awning_pivot, Vector3(sw - 0.01, 0.24, 0.05), Vector3(x, -0.14, 1.31), mat, Vector3(-18.0, 0.0, 0.0))

	# Awning support poles on corners
	PropUtils.add_cylinder(visual, 0.035, 0.035, 2.55, Vector3(-2.15, 1.28, 1.15), steel)
	PropUtils.add_cylinder(visual, 0.035, 0.035, 2.55, Vector3(2.15, 1.28, 1.15), steel)

	# Overhead Glowing Menu Signboard mounted on roof edge
	PropUtils.add_box(visual, Vector3(3.1, 0.62, 0.14), Vector3(0.0, 3.45, 0.65), steel)
	PropUtils.add_box(visual, Vector3(2.92, 0.46, 0.06), Vector3(0.0, 3.45, 0.72), interior_glow)
	# Stylized neon glyph bars + teal/coral accents on sign
	PropUtils.add_box(visual, Vector3(2.98, 0.04, 0.09), Vector3(0.0, 3.74, 0.71), sign_coral)
	PropUtils.add_box(visual, Vector3(2.98, 0.04, 0.09), Vector3(0.0, 3.16, 0.71), sign_teal)
	for gx in [-1.0, -0.45, 0.1, 0.65, 1.05]:
		PropUtils.add_box(visual, Vector3(0.24, 0.26, 0.08), Vector3(gx, 3.45, 0.73), wood_dark)

	# Steaming soup pot & counter bowls
	PropUtils.add_cylinder(visual, 0.26, 0.24, 0.34, Vector3(-1.15, 1.31, 0.32), pot_metal)
	PropUtils.add_cylinder(visual, 0.14, 0.09, 0.11, Vector3(0.25, 1.19, 0.58), bowl_cream)
	PropUtils.add_cylinder(visual, 0.14, 0.09, 0.11, Vector3(0.72, 1.19, 0.52), bowl_cream)
	PropUtils.add_box(visual, Vector3(0.32, 0.26, 0.22), Vector3(1.45, 1.26, 0.38), wood_dark)

	# 3 cozy hanging paper lanterns beneath the awning edge
	for lx in [-1.35, 0.0, 1.35]:
		var lp := Node3D.new()
		lp.position = Vector3(lx, 2.38, 1.38)
		visual.add_child(lp)
		PropUtils.add_cylinder(lp, 0.012, 0.012, 0.22, Vector3(0.0, -0.11, 0.0), steel, Vector3.ZERO, 6)
		PropUtils.add_sphere(lp, 0.15, Vector3(0.0, -0.34, 0.0), lantern_glow, Vector3(0.95, 1.25, 0.95), 10)
		PropUtils.add_cylinder(lp, 0.08, 0.08, 0.04, Vector3(0.0, -0.16, 0.0), wood_dark, Vector3.ZERO, 8)
		PropUtils.add_cylinder(lp, 0.08, 0.08, 0.04, Vector3(0.0, -0.51, 0.0), wood_dark, Vector3.ZERO, 8)
		_lanterns.append(lp)

	# 3 wooden bar stools in front of the counter
	for sx in [-1.15, 0.0, 1.15]:
		PropUtils.add_cylinder(visual, 0.21, 0.21, 0.06, Vector3(sx, 0.66, 1.32), wood_warm)
		PropUtils.add_cylinder(visual, 0.03, 0.04, 0.64, Vector3(sx, 0.32, 1.32), steel)
		PropUtils.add_cylinder(visual, 0.19, 0.21, 0.04, Vector3(sx, 0.02, 1.32), steel)

	# Warm golden stall lights (primary hero light pool!)
	var omni := OmniLight3D.new()
	omni.position = Vector3(0.0, 2.15, 0.95)
	omni.light_color = Palette.STALL_WARM
	omni.light_energy = stall_light_energy
	omni.omni_range = 11.5
	omni.omni_attenuation = 1.35
	omni.shadow_enabled = true
	omni.shadow_blur = 2.0
	add_child(omni)

	var spill := SpotLight3D.new()
	spill.position = Vector3(0.0, 2.6, 1.35)
	spill.rotation_degrees = Vector3(-72.0, 0.0, 0.0)
	spill.light_color = Palette.LANTERN_AMBER
	spill.light_energy = 3.2
	spill.spot_range = 10.0
	spill.spot_angle = 58.0
	spill.spot_angle_attenuation = 1.6
	spill.add_to_group("secondary_lights")
	add_child(spill)

	if enable_steam:
		var steam := PropUtils.make_steam_particles(22, 2.4, 0.85, 0.18, Color(0.96, 0.92, 0.84, 0.24))
		steam.position = Vector3(-1.15, 1.54, 0.32)
		add_child(steam)

	# Colliders: booth body + jumpable roof/awning canopy!
	PropUtils.add_static_box_collider(self, Vector3(4.5, 2.9, 2.35), Vector3(0.0, 1.45, -0.25))
	PropUtils.add_static_box_collider(self, Vector3(4.75, 0.16, 1.6), Vector3(0.0, 2.66, 1.25), Vector3(16.0, 0.0, 0.0))
	PropUtils.add_static_box_collider(self, Vector3(4.65, 1.12, 0.82), Vector3(0.0, 0.56, 0.55))
