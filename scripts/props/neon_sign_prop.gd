@tool
class_name NeonSignProp
extends Node3D

## Layered neon sign blade mounted to building facades with glowing neon tubes,
## cheap additive glow halo, and optional distance-faded colored spill light.

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

	var frame_mat := Palette.make_stylized_material(Palette.STEEL_DARK, 0.55, 0.48, Color("#7A6BB5"), 0.24)
	var backing_mat := Palette.make_stylized_material(Color("#18132E"), 0.72, 0.1, Color("#57468C"), 0.15)
	var prim_mat := Palette.make_emissive_material(primary_color, 3.2, 0.2)
	var sec_mat := Palette.make_emissive_material(secondary_color, 2.9, 0.2)

	var w := sign_size.x
	var h := sign_size.y

	PropUtils.add_box(visual, Vector3(w, h, 0.16), Vector3.ZERO, frame_mat)
	PropUtils.add_box(visual, Vector3(w - 0.14, h - 0.14, 0.18), Vector3.ZERO, backing_mat)
	PropUtils.add_box(visual, Vector3(0.55, 0.08, 0.08), Vector3(-w * 0.5 - 0.26, h * 0.32, 0.0), frame_mat)
	PropUtils.add_box(visual, Vector3(0.55, 0.08, 0.08), Vector3(-w * 0.5 - 0.26, -h * 0.32, 0.0), frame_mat)

	for side: float in [-1.0, 1.0]:
		var z: float = side * 0.095
		PropUtils.add_box(visual, Vector3(w - 0.12, 0.05, 0.03), Vector3(0.0, h * 0.46, z), prim_mat)
		PropUtils.add_box(visual, Vector3(w - 0.12, 0.05, 0.03), Vector3(0.0, -h * 0.46, z), prim_mat)
		PropUtils.add_box(visual, Vector3(0.05, h - 0.12, 0.03), Vector3(w * 0.46, 0.0, z), sec_mat)
		PropUtils.add_box(visual, Vector3(0.05, h - 0.12, 0.03), Vector3(-w * 0.46, 0.0, z), sec_mat)

		var rows := maxi(2, int(roundf(h / 0.48)))
		for r in range(rows):
			var ry := lerpf(-h * 0.30, h * 0.30, float(r) / float(maxi(1, rows - 1)))
			var bw := (w * 0.60) if (r % 2 == 0) else (w * 0.40)
			var gmat := prim_mat if (r % 3 != 1) else sec_mat
			var bar := PropUtils.add_box(visual, Vector3(bw, 0.10, 0.03), Vector3(0.0, ry, z), gmat)
			bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Cheap additive billboard glow halo around the sign!
	PropUtils.add_glow_card(visual, Vector3.ZERO, Vector2(maxf(w, h) * 1.45, maxf(w, h) * 1.45), primary_color, 0.22, 140.0)

	if emit_spill_light:
		PropUtils.make_fade_omni(self, Vector3(0.0, 0.0, 0.65), primary_color, 2.0, 8.5, 32.0)
