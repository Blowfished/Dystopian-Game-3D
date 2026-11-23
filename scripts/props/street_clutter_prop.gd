@tool
class_name StreetClutterProp
extends Node3D

## Modular cozy-cyberpunk street-level prop & atmospheric detail kit:
## - "vending_machine": glowing drink/ramen machine + wet ground glow pool
## - "bike_rack": steel rack with stylized parked bicycles
## - "trash_can": urban waste & recycling bin with glowing status strip
## - "utility_box": street electrical cabinet with wall conduits & LEDs
## - "cable_span": overhead sagging bundle of dark power/data cables
## - "light_shaft": soft diagonal volumetric canyon light shaft
## - "glow_pool": cheap additive colored light pool on wet street puddles

@export_enum("vending_machine", "bike_rack", "trash_can", "utility_box", "cable_span", "light_shaft", "glow_pool") var prop_kind: String = "vending_machine":
	set(v):
		prop_kind = v
		if is_inside_tree():
			_rebuild()

@export var accent_color: Color = Palette.LANTERN_AMBER
@export var end_offset: Vector3 = Vector3(14.0, 0.0, 0.0)
@export var pool_size: Vector2 = Vector2(6.0, 6.0)
@export var shaft_height: float = 34.0
@export var shaft_tilt_deg: Vector3 = Vector3(18.0, 0.0, 12.0)


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	match prop_kind:
		"vending_machine":
			_build_vending_machine(visual)
		"bike_rack":
			_build_bike_rack(visual)
		"trash_can":
			_build_trash_can(visual)
		"utility_box":
			_build_utility_box(visual)
		"cable_span":
			_build_cable_span(visual)
		"light_shaft":
			_build_light_shaft(visual)
		"glow_pool":
			_build_glow_pool(visual)


func _build_vending_machine(visual: Node3D) -> void:
	var body_col := Color("#2B2645") if accent_color != Palette.NEON_CORAL else Color("#4F263B")
	var body_mat := Palette.make_stylized_material(body_col, 0.48, 0.35, Color("#9B8CE0"), 0.28)
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.55, 0.45, Color("#7362AD"), 0.22)
	var screen_mat := Palette.make_emissive_material(accent_color, 2.5, 0.25)
	var warm_disp := Palette.make_emissive_material(Palette.CREAM_WARM, 2.1, 0.25)

	PropUtils.add_box(visual, Vector3(1.18, 2.08, 0.82), Vector3(0.0, 1.04, 0.0), body_mat)
	# Illuminated front beverage display window (faces +Z)
	PropUtils.add_box(visual, Vector3(0.96, 1.02, 0.08), Vector3(0.0, 1.34, 0.40), warm_disp)
	# Colored header banner & drink rows
	PropUtils.add_box(visual, Vector3(0.96, 0.24, 0.09), Vector3(0.0, 1.92, 0.40), screen_mat)
	for ry in [1.02, 1.28, 1.54]:
		PropUtils.add_box(visual, Vector3(0.92, 0.04, 0.10), Vector3(0.0, ry, 0.41), steel)
	# Dispensing slot & keypad
	PropUtils.add_box(visual, Vector3(0.76, 0.28, 0.10), Vector3(0.0, 0.36, 0.39), steel)
	PropUtils.add_box(visual, Vector3(0.16, 0.24, 0.08), Vector3(0.36, 0.72, 0.41), screen_mat)

	# Cheap wet-ground glow spill + billboard glow halo (zero real light cost!)
	PropUtils.add_ground_glow_pool(visual, Vector3(0.0, 0.0, 1.05), Vector2(3.8, 3.6), accent_color, 0.34, 85.0)
	PropUtils.add_glow_card(visual, Vector3(0.0, 1.35, 0.55), Vector2(1.8, 1.8), accent_color, 0.24, 90.0)
	PropUtils.add_static_box_collider(self, Vector3(1.22, 2.1, 0.88), Vector3(0.0, 1.05, 0.0))


func _build_bike_rack(visual: Node3D) -> void:
	var steel := Palette.make_stylized_material(Palette.STEEL_LIGHT, 0.45, 0.55, Color("#9688D9"), 0.28)
	var wheel_mat := Palette.make_stylized_material(Color("#161424"), 0.82, 0.05, Color("#57468C"), 0.15)
	var bike_cols := [Palette.SCOOTER_BODY, Palette.AWNING_STRIPE_A, Palette.CANOPY_OCHRE]

	# Rack base rails + 4 hoops
	PropUtils.add_box(visual, Vector3(2.8, 0.06, 0.72), Vector3(0.0, 0.03, 0.0), steel)
	for i in range(4):
		var hx := lerpf(-1.1, 1.1, float(i) / 3.0)
		PropUtils.add_box(visual, Vector3(0.05, 0.68, 0.05), Vector3(hx, 0.34, -0.28), steel)
		PropUtils.add_box(visual, Vector3(0.05, 0.68, 0.05), Vector3(hx, 0.34, 0.28), steel)
		PropUtils.add_box(visual, Vector3(0.05, 0.05, 0.60), Vector3(hx, 0.68, 0.0), steel)

	# 3 stylized parked bicycles tucked into the rack
	for b in range(3):
		var bx := lerpf(-0.75, 0.75, float(b) / 2.0)
		var fmat := Palette.make_stylized_material(bike_cols[b % bike_cols.size()], 0.55, 0.35, Color("#FFE2B0"), 0.25)
		# Front & rear wheels
		PropUtils.add_cylinder(visual, 0.32, 0.32, 0.06, Vector3(bx, 0.34, -0.45), wheel_mat, Vector3(0.0, 0.0, 90.0), 10)
		PropUtils.add_cylinder(visual, 0.32, 0.32, 0.06, Vector3(bx, 0.34, 0.52), wheel_mat, Vector3(0.0, 0.0, 90.0), 10)
		# Frame triangle + handlebars + seat
		PropUtils.add_strut(visual, Vector3(bx, 0.34, -0.45), Vector3(bx, 0.82, -0.20), 0.045, fmat)
		PropUtils.add_strut(visual, Vector3(bx, 0.82, -0.20), Vector3(bx, 0.76, 0.35), 0.045, fmat)
		PropUtils.add_strut(visual, Vector3(bx, 0.34, 0.52), Vector3(bx, 0.76, 0.35), 0.045, fmat)
		PropUtils.add_box(visual, Vector3(0.46, 0.04, 0.04), Vector3(bx, 0.88, -0.22), steel)
		PropUtils.add_box(visual, Vector3(0.14, 0.06, 0.24), Vector3(bx, 0.84, 0.36), wheel_mat)

	PropUtils.add_static_box_collider(self, Vector3(2.85, 0.92, 1.55), Vector3(0.0, 0.46, 0.05))


func _build_trash_can(visual: Node3D) -> void:
	var bin_mat := Palette.make_stylized_material(Palette.STEEL_MID, 0.58, 0.38, Color("#8878C4"), 0.24)
	var lid_mat := Palette.make_stylized_material(Palette.STEEL_DARK, 0.50, 0.45, Color("#7362AD"), 0.22)
	var strip := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 1.9)

	# Dual waste + recycling street bin
	PropUtils.add_box(visual, Vector3(1.15, 0.96, 0.58), Vector3(0.0, 0.48, 0.0), bin_mat)
	PropUtils.add_box(visual, Vector3(1.22, 0.12, 0.64), Vector3(0.0, 0.98, 0.0), lid_mat)
	PropUtils.add_box(visual, Vector3(0.42, 0.14, 0.06), Vector3(-0.28, 0.76, 0.30), lid_mat)
	PropUtils.add_box(visual, Vector3(0.42, 0.14, 0.06), Vector3(0.28, 0.76, 0.30), lid_mat)
	PropUtils.add_box(visual, Vector3(1.06, 0.04, 0.05), Vector3(0.0, 0.56, 0.30), strip)
	PropUtils.add_static_box_collider(self, Vector3(1.22, 1.05, 0.65), Vector3(0.0, 0.52, 0.0))


func _build_utility_box(visual: Node3D) -> void:
	var box_mat := Palette.make_stylized_material(Color("#2D2A44"), 0.68, 0.32, Color("#8878C4"), 0.24)
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.52, 0.48, Color("#7362AD"), 0.22)
	var led_a := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 2.4)
	var led_b := Palette.make_emissive_material(Palette.LANTERN_AMBER, 2.4)

	PropUtils.add_box(visual, Vector3(1.35, 1.55, 0.72), Vector3(0.0, 0.775, 0.0), box_mat)
	PropUtils.add_box(visual, Vector3(1.42, 0.12, 0.78), Vector3(0.0, 1.58, 0.0), steel)
	# Vertical wall conduits climbing behind the box
	for cx in [-0.42, -0.18, 0.34]:
		PropUtils.add_cylinder(visual, 0.055, 0.055, 4.6, Vector3(cx, 2.3, -0.32), steel, Vector3.ZERO, 8)
	# Status LEDs & hazard trim
	PropUtils.add_box(visual, Vector3(0.08, 0.08, 0.04), Vector3(-0.42, 1.32, 0.37), led_a)
	PropUtils.add_box(visual, Vector3(0.08, 0.08, 0.04), Vector3(-0.28, 1.32, 0.37), led_b)
	PropUtils.add_box(visual, Vector3(1.18, 0.08, 0.04), Vector3(0.0, 0.26, 0.37), led_b)
	PropUtils.add_static_box_collider(self, Vector3(1.4, 1.62, 0.78), Vector3(0.0, 0.81, 0.0))


func _build_cable_span(visual: Node3D) -> void:
	var wire_mat := Palette.make_stylized_material(Color("#121022"), 0.72, 0.35, Color("#57468C"), 0.16)
	var segs := 8
	for strand in range(3):
		var y_off := float(strand) * 0.35
		var z_off := (float(strand) - 1.0) * 0.42
		var sag := 1.15 + float(strand) * 0.35
		for s in range(segs):
			var t0 := float(s) / float(segs)
			var t1 := float(s + 1) / float(segs)
			var p0 := Vector3.ZERO.lerp(end_offset, t0) + Vector3(0.0, y_off - 4.0 * sag * t0 * (1.0 - t0), z_off)
			var p1 := Vector3.ZERO.lerp(end_offset, t1) + Vector3(0.0, y_off - 4.0 * sag * t1 * (1.0 - t1), z_off)
			var seg := PropUtils.add_strut(visual, p0, p1, 0.055 if strand == 1 else 0.035, wire_mat)
			if seg:
				seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				seg.visibility_range_end = 170.0


func _build_light_shaft(visual: Node3D) -> void:
	var pivot := Node3D.new()
	pivot.rotation_degrees = shaft_tilt_deg
	visual.add_child(pivot)
	PropUtils.add_light_cone(
		pivot,
		Vector3(0.0, shaft_height, 0.0),
		shaft_height,
		1.4,
		6.2,
		accent_color,
		0.11,
		Vector3(180.0, 0.0, 0.0),
		180.0
	)


func _build_glow_pool(visual: Node3D) -> void:
	PropUtils.add_ground_glow_pool(visual, Vector3.ZERO, pool_size, accent_color, 0.28, 120.0)
