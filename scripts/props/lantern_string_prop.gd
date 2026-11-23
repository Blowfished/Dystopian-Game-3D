@tool
class_name LanternStringProp
extends Node3D

## Catenary string of glowing warm paper lanterns suspended between canyon walls,
## gently swaying in the rainy night breeze with cheap billboard glow halos and
## distance-faded warm ambient fill lights.

@export var end_offset: Vector3 = Vector3(8.5, 0.0, 0.0):
	set(v):
		end_offset = v
		if is_inside_tree():
			_rebuild()

@export var sag: float = 0.85:
	set(v):
		sag = maxf(v, 0.05)
		if is_inside_tree():
			_rebuild()

@export var lantern_count: int = 6:
	set(v):
		lantern_count = clampi(v, 2, 16)
		if is_inside_tree():
			_rebuild()

@export var emit_light_pools: bool = true:
	set(v):
		emit_light_pools = v
		if is_inside_tree():
			_rebuild()

var _lantern_nodes: Array[Node3D] = []
var _time: float = 0.0


func _ready() -> void:
	_rebuild()


func _process(delta: float) -> void:
	_time += delta
	for i in range(_lantern_nodes.size()):
		var n := _lantern_nodes[i]
		if is_instance_valid(n):
			n.rotation.z = sin(_time * 1.35 + float(i) * 0.95) * 0.085
			n.rotation.x = cos(_time * 1.05 + float(i) * 1.4) * 0.055


func _curve_point(t: float) -> Vector3:
	var p := Vector3.ZERO.lerp(end_offset, t)
	p.y -= 4.0 * sag * t * (1.0 - t)
	return p


func _rebuild() -> void:
	PropUtils.clear_children(self)
	_lantern_nodes.clear()

	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var wire_mat := Palette.make_stylized_material(Palette.STEEL_DARK, 0.7, 0.3, Color("#605294"), 0.15)
	var cap_mat := Palette.make_stylized_material(Palette.WOOD_DARK, 0.78, 0.05, Color("#8F6748"), 0.2)
	var lantern_warm := Palette.make_emissive_material(Palette.LANTERN_AMBER, 3.0, 0.25)
	var lantern_coral := Palette.make_emissive_material(Color("#FF8854"), 2.8, 0.25)

	# Segmented sagging cable
	var segs := maxi(8, lantern_count + 2)
	for s in range(segs):
		var p0 := _curve_point(float(s) / float(segs))
		var p1 := _curve_point(float(s + 1) / float(segs))
		var seg := PropUtils.add_strut(visual, p0, p1, 0.026, wire_mat)
		if seg:
			seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Glowing paper lanterns + cheap billboard glow halos along the span
	for i in range(lantern_count):
		var t := float(i + 1) / float(lantern_count + 1)
		var anchor := _curve_point(t)
		var pivot := Node3D.new()
		pivot.position = anchor
		visual.add_child(pivot)

		var is_coral := (i % 3 == 1)
		var lmat := lantern_coral if is_coral else lantern_warm
		var gcol := Color("#FF8854") if is_coral else Palette.LANTERN_AMBER
		PropUtils.add_cylinder(pivot, 0.009, 0.009, 0.18, Vector3(0.0, -0.09, 0.0), wire_mat, Vector3.ZERO, 6)
		PropUtils.add_cylinder(pivot, 0.085, 0.085, 0.035, Vector3(0.0, -0.18, 0.0), cap_mat, Vector3.ZERO, 6)
		var sph := PropUtils.add_sphere(pivot, 0.16, Vector3(0.0, -0.35, 0.0), lmat, Vector3(0.95, 1.26, 0.95), 8)
		sph.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		PropUtils.add_glow_card(pivot, Vector3(0.0, -0.35, 0.0), Vector2(1.15, 1.15), gcol, 0.26, 105.0)
		_lantern_nodes.append(pivot)

	# 1–2 distance-faded warm local lights along the span
	if emit_light_pools:
		var mid_pt := _curve_point(0.5) - Vector3(0.0, 0.45, 0.0)
		PropUtils.make_fade_omni(self, mid_pt, Palette.LANTERN_AMBER, 2.35, 11.5, 36.0)
