@tool
class_name NeonSignProp
extends Node3D

@export var sign_size: Vector2 = Vector2(0.85, 2.3):
	set(v):
		sign_size = Vector2(maxf(v.x, 0.4), maxf(v.y, 0.4))
		if is_inside_tree():
			_rebuild()

@export var primary_color: Color = Palette.LANDMARK_TEAL:
	set(v):
		primary_color = v
		if is_inside_tree():
			_rebuild()

@export var secondary_color: Color = Palette.BEACON_MAGENTA:
	set(v):
		secondary_color = v
		if is_inside_tree():
			_rebuild()

@export var emit_spill_light: bool = true:
	set(v):
		emit_spill_light = v
		if is_inside_tree():
			_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var frame_mat := Palette.make_stylized_material(Palette.STEEL_DARK, 0.55, 0.48, Color("#6080B8"), 0.24)
	var backing_mat := Palette.make_stylized_material(Color("#12182C"), 0.72, 0.1, Color("#405682"), 0.15)
	var prim_mat := Palette.make_emissive_material(primary_color, 2.9, 0.2)
	var sec_mat := Palette.make_emissive_material(secondary_color, 2.6, 0.2)

	var w := sign_size.x
	var h := sign_size.y

	# Metal signboard chassis & mounting brackets
	PropUtils.add_box(visual, Vector3(w, h, 0.16), Vector3.ZERO, frame_mat)
	PropUtils.add_box(visual, Vector3(w - 0.14, h - 0.14, 0.18), Vector3.ZERO, backing_mat)
	PropUtils.add_box(visual, Vector3(0.45, 0.08, 0.08), Vector3(-w * 0.5 - 0.22, h * 0.32, 0.0), frame_mat)
	PropUtils.add_box(visual, Vector3(0.45, 0.08, 0.08), Vector3(-w * 0.5 - 0.22, -h * 0.32, 0.0), frame_mat)

	# Glowing neon border strips on both faces
	for side: float in [-1.0, 1.0]:
		var z: float = side * 0.095
		PropUtils.add_box(visual, Vector3(w - 0.12, 0.045, 0.03), Vector3(0.0, h * 0.46, z), prim_mat)
		PropUtils.add_box(visual, Vector3(w - 0.12, 0.045, 0.03), Vector3(0.0, -h * 0.46, z), prim_mat)
		PropUtils.add_box(visual, Vector3(0.045, h - 0.12, 0.03), Vector3(w * 0.46, 0.0, z), sec_mat)
		PropUtils.add_box(visual, Vector3(0.045, h - 0.12, 0.03), Vector3(-w * 0.46, 0.0, z), sec_mat)

		# Stylized abstract cyberpunk typography / emblem bars
		var rows := maxi(2, int(roundf(h / 0.45)))
		for r in range(rows):
			var ry := lerpf(-h * 0.30, h * 0.30, float(r) / float(maxi(1, rows - 1)))
			var bw := (w * 0.58) if (r % 2 == 0) else (w * 0.38)
			var gmat := prim_mat if (r % 3 != 1) else sec_mat
			PropUtils.add_box(visual, Vector3(bw, 0.09, 0.03), Vector3(0.0, ry, z), gmat)

	if emit_spill_light:
		var omni := OmniLight3D.new()
		omni.position = Vector3(0.0, 0.0, 0.45)
		omni.light_color = primary_color
		omni.light_energy = 1.6
		omni.omni_range = 6.0
		omni.omni_attenuation = 1.6
		omni.add_to_group("secondary_lights")
		add_child(omni)
