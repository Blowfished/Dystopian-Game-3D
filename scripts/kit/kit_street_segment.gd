@tool
class_name KitStreetSegment
extends Node3D

## Solid urban street segment with deep architectural substructure (never floating!),
## wet reflective paving with colored light shimmer, optional curbs, and a single
## slightly overlapping merged collision shape so adjacent segments have zero gaps.

@export var size: Vector3 = Vector3(24.0, 0.5, 10.0):
	set(v):
		size = v
		if is_inside_tree():
			_rebuild()

@export var puddle_amount: float = 0.62:
	set(v):
		puddle_amount = v
		if is_inside_tree():
			_rebuild()

@export var edge_trim_color: Color = Color.BLACK:
	set(v):
		edge_trim_color = v
		if is_inside_tree():
			_rebuild()

@export var reflect_warmth: float = 0.68
@export var foundation_depth: float = 26.0
@export var has_curbs: bool = false
@export var collider_overlap: float = 0.45


func _ready() -> void:
	add_to_group("walkable_surfaces")
	set_meta("walkable_type", "street")
	set_meta("walkable_size", size)
	set_meta("support_type", "solid_foundation")
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	set_meta("walkable_size", size)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var wet_mat := ShaderMaterial.new()
	wet_mat.shader = load("res://shaders/wet_walkway.gdshader")
	wet_mat.set_shader_parameter("tile_size", 1.8)
	wet_mat.set_shader_parameter("puddle_amount", puddle_amount)
	wet_mat.set_shader_parameter("reflect_warmth", reflect_warmth)
	wet_mat.set_shader_parameter("rain_intensity", 1.0)

	var concrete := Palette.make_stylized_material(Palette.CONCRETE_DARK, 0.84, 0.06, Color("#6E5CA8"), 0.22)
	var sub_wall := Palette.make_stylized_material(Color("#1A162E"), 0.88, 0.08, Color("#57468C"), 0.18)
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.55, 0.45, Color("#7362AD"), 0.22)

	# Walkable top paving slab (top at local y = 0.0)
	var top_mesh := PropUtils.add_box(visual, size, Vector3(0.0, -size.y * 0.5, 0.0), wet_mat)
	top_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Concrete apron + deep solid foundation substructure extending down into the lower city strata
	var apron := PropUtils.add_box(visual, Vector3(size.x + 0.35, 1.1, size.z + 0.35), Vector3(0.0, -size.y - 0.55, 0.0), concrete)
	apron.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	if foundation_depth > 1.0:
		var f_depth := foundation_depth
		var f_box := PropUtils.add_box(
			visual,
			Vector3(maxf(size.x - 0.4, 2.0), f_depth, maxf(size.z - 0.4, 2.0)),
			Vector3(0.0, -size.y - 1.1 - f_depth * 0.5, 0.0),
			sub_wall
		)
		f_box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		f_box.visibility_range_end = 260.0

		# Structural underside ribs / girders along street length
		var rib_count := clampi(int(roundf(size.x / 12.0)), 2, 7)
		for i in range(rib_count):
			var rx := lerpf(-size.x * 0.44, size.x * 0.44, float(i) / float(maxi(1, rib_count - 1)))
			var rib := PropUtils.add_box(visual, Vector3(0.9, f_depth, size.z + 0.2), Vector3(rx, -size.y - 1.1 - f_depth * 0.5, 0.0), steel)
			rib.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			rib.visibility_range_end = 220.0

	if has_curbs:
		PropUtils.add_box(visual, Vector3(size.x, 0.14, 0.32), Vector3(0.0, 0.07, size.z * 0.5 - 0.16), steel)
		PropUtils.add_box(visual, Vector3(size.x, 0.14, 0.32), Vector3(0.0, 0.07, -size.z * 0.5 + 0.16), steel)

	if edge_trim_color.a > 0.01 and edge_trim_color != Color.BLACK:
		var trim := Palette.make_emissive_material(edge_trim_color, 1.9)
		var t1 := PropUtils.add_box(visual, Vector3(size.x - 0.4, 0.06, 0.06), Vector3(0.0, -0.18, size.z * 0.5 + 0.03), trim)
		var t2 := PropUtils.add_box(visual, Vector3(size.x - 0.4, 0.06, 0.06), Vector3(0.0, -0.18, -size.z * 0.5 - 0.03), trim)
		t1.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		t2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Single merged overlapping box collider to prevent any seam gaps between adjacent segments
	var col_size := Vector3(size.x + collider_overlap, maxf(size.y, 0.8), size.z + collider_overlap)
	PropUtils.add_static_box_collider(self, col_size, Vector3(0.0, -col_size.y * 0.5, 0.0))
