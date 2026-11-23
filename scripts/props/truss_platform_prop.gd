@tool
class_name TrussPlatformProp
extends Node3D

@export var platform_size: Vector3 = Vector3(4.2, 0.62, 2.8):
	set(v):
		platform_size = Vector3(maxf(v.x, 1.2), maxf(v.y, 0.3), maxf(v.z, 1.2))
		if is_inside_tree():
			_rebuild()

@export var accent_amber: bool = true:
	set(v):
		accent_amber = v
		if is_inside_tree():
			_rebuild()

@export var add_under_light: bool = false:
	set(v):
		add_under_light = v
		if is_inside_tree():
			_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var deck_mat := Palette.make_stylized_material(Palette.STEEL_MID, 0.52, 0.45, Color("#7397D6"), 0.30)
	var truss_mat := Palette.make_stylized_material(Palette.STEEL_DARK, 0.58, 0.48, Color("#5674AD"), 0.24)
	var trim_color := Palette.LANTERN_AMBER if accent_amber else Palette.LANDMARK_TEAL
	var trim_mat := Palette.make_emissive_material(trim_color, 1.65)

	var sx := platform_size.x
	var sy := platform_size.y
	var sz := platform_size.z
	var deck_h := 0.14

	# Top walking deck (top sits cleanly at local y = 0.0 for easy level placement!)
	PropUtils.add_box(visual, Vector3(sx, deck_h, sz), Vector3(0.0, -deck_h * 0.5, 0.0), deck_mat)

	# Stylized floor rib plates for visual crispness
	var rib_count := maxi(3, int(roundf(sx / 0.85)))
	for i in range(rib_count):
		var x := lerpf(-sx * 0.46, sx * 0.46, float(i) / float(maxi(1, rib_count - 1)))
		PropUtils.add_box(visual, Vector3(0.07, 0.02, sz - 0.14), Vector3(x, 0.008, 0.0), truss_mat)

	# Subtle glowing edge safety strips on front/back edges
	PropUtils.add_box(visual, Vector3(sx - 0.24, 0.035, 0.035), Vector3(0.0, -0.055, sz * 0.5 + 0.008), trim_mat)
	PropUtils.add_box(visual, Vector3(sx - 0.24, 0.035, 0.035), Vector3(0.0, -0.055, -sz * 0.5 - 0.008), trim_mat)

	# Lower truss chord frame & diagonal bracing
	var bottom_y := -sy
	var top_y := -deck_h
	var hx := sx * 0.48
	var hz := sz * 0.46
	var beam_t := 0.07

	# Bottom perimeter chords
	PropUtils.add_box(visual, Vector3(sx - 0.08, beam_t, beam_t), Vector3(0.0, bottom_y, hz), truss_mat)
	PropUtils.add_box(visual, Vector3(sx - 0.08, beam_t, beam_t), Vector3(0.0, bottom_y, -hz), truss_mat)
	PropUtils.add_box(visual, Vector3(beam_t, beam_t, sz - 0.08), Vector3(-hx, bottom_y, 0.0), truss_mat)
	PropUtils.add_box(visual, Vector3(beam_t, beam_t, sz - 0.08), Vector3(hx, bottom_y, 0.0), truss_mat)

	# Vertical corner posts
	for cx in [-hx, hx]:
		for cz in [-hz, hz]:
			PropUtils.add_box(visual, Vector3(0.085, sy, 0.085), Vector3(cx, -sy * 0.5, cz), truss_mat)

	# Diagonal steel truss lattice along X sides
	var bays := maxi(2, int(roundf(sx / 1.15)))
	for b in range(bays):
		var x0 := lerpf(-hx, hx, float(b) / float(bays))
		var x1 := lerpf(-hx, hx, float(b + 1) / float(bays))
		for cz in [-hz, hz]:
			if b % 2 == 0:
				PropUtils.add_strut(visual, Vector3(x0, top_y, cz), Vector3(x1, bottom_y, cz), 0.05, truss_mat)
			else:
				PropUtils.add_strut(visual, Vector3(x0, bottom_y, cz), Vector3(x1, top_y, cz), 0.05, truss_mat)

	# Side end diagonals
	for cx in [-hx, hx]:
		PropUtils.add_strut(visual, Vector3(cx, top_y, -hz), Vector3(cx, bottom_y, hz), 0.05, truss_mat)
		PropUtils.add_strut(visual, Vector3(cx, bottom_y, -hz), Vector3(cx, top_y, hz), 0.05, truss_mat)

	if add_under_light:
		var light := OmniLight3D.new()
		light.position = Vector3(0.0, bottom_y - 0.25, 0.0)
		light.light_color = trim_color
		light.light_energy = 1.25
		light.omni_range = 6.5
		light.add_to_group("secondary_lights")
		add_child(light)

	PropUtils.add_static_box_collider(self, Vector3(sx, sy, sz), Vector3(0.0, -sy * 0.5, 0.0))
