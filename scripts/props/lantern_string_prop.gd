@tool
class_name LanternStringProp
extends Node3D

## Catenary string of glowing warm paper lanterns suspended between local origin
## and end_offset, gently swaying in the rainy night breeze.

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
	# Parabolic catenary approximation
	p.y -= 4.0 * sag * t * (1.0 - t)
	return p


func _rebuild() -> void:
	PropUtils.clear_children(self)
	_lantern_nodes.clear()

	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var wire_mat := Palette.make_stylized_material(Palette.STEEL_DARK, 0.7, 0.3, Color("#4D6594"), 0.15)
	var cap_mat := Palette.make_stylized_material(Palette.WOOD_DARK, 0.78, 0.05, Color("#8F6748"), 0.2)
	var lantern_warm := Palette.make_emissive_material(Palette.LANTERN_AMBER, 2.75, 0.28)
	var lantern_coral := Palette.make_emissive_material(Color("#FF8854"), 2.55, 0.28)

	# Segmented sagging cable
	var segs := maxi(10, lantern_count * 2 + 2)
	for s in range(segs):
		var p0 := _curve_point(float(s) / float(segs))
		var p1 := _curve_point(float(s + 1) / float(segs))
		PropUtils.add_strut(visual, p0, p1, 0.024, wire_mat)

	# Glowing paper lanterns along the span
	for i in range(lantern_count):
		var t := float(i + 1) / float(lantern_count + 1)
		var anchor := _curve_point(t)
		var pivot := Node3D.new()
		pivot.position = anchor
		visual.add_child(pivot)

		var lmat := lantern_coral if (i % 3 == 1) else lantern_warm
		PropUtils.add_cylinder(pivot, 0.009, 0.009, 0.18, Vector3(0.0, -0.09, 0.0), wire_mat, Vector3.ZERO, 6)
		PropUtils.add_cylinder(pivot, 0.085, 0.085, 0.035, Vector3(0.0, -0.18, 0.0), cap_mat, Vector3.ZERO, 8)
		PropUtils.add_sphere(pivot, 0.155, Vector3(0.0, -0.35, 0.0), lmat, Vector3(0.92, 1.24, 0.92), 10)
		PropUtils.add_cylinder(pivot, 0.08, 0.08, 0.035, Vector3(0.0, -0.52, 0.0), cap_mat, Vector3.ZERO, 8)
		_lantern_nodes.append(pivot)

	# Place 2 soft warm light pools along the string (grouped so Low quality can toggle them)
	if emit_light_pools:
		for lt in [0.33, 0.67]:
			var lp := _curve_point(lt) - Vector3(0.0, 0.42, 0.0)
			var omni := OmniLight3D.new()
			omni.position = lp
			omni.light_color = Palette.LANTERN_AMBER
			omni.light_energy = 1.95
			omni.light_volumetric_fog_energy = 1.35
			omni.omni_range = 8.5
			omni.omni_attenuation = 1.45
			omni.add_to_group("secondary_lights")
			add_child(omni)
