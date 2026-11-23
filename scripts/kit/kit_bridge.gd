@tool
class_name KitBridge
extends Node3D

## Architectural pedestrian skybridge / street bridge spanning along X (top at y=0).
## Includes visible heavy end abutments, underside trusses, support piers reaching
## down to lower structure/ground, optional covered roof, and overlapping collider.

@export var length: float = 22.0:
	set(v):
		length = maxf(v, 4.0)
		if is_inside_tree():
			_rebuild()

@export var width: float = 5.5:
	set(v):
		width = maxf(v, 2.4)
		if is_inside_tree():
			_rebuild()

@export var accent_color: Color = Palette.LANTERN_AMBER
@export var support_height: float = 16.0
@export var covered: bool = true
@export var has_mid_piers: bool = true


func _ready() -> void:
	add_to_group("walkable_surfaces")
	set_meta("walkable_type", "bridge")
	set_meta("walkable_size", Vector3(length, 0.8, width))
	set_meta("support_type", "abutments_and_piers")
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	set_meta("walkable_size", Vector3(length, 0.8, width))
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var wet_mat := ShaderMaterial.new()
	wet_mat.shader = load("res://shaders/wet_walkway.gdshader")
	wet_mat.set_shader_parameter("tile_size", 1.8)
	wet_mat.set_shader_parameter("puddle_amount", 0.48)
	wet_mat.set_shader_parameter("reflect_warmth", 0.65)

	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.54, 0.46, Color("#7362AD"), 0.24)
	var concrete := Palette.make_stylized_material(Palette.CONCRETE_DARK, 0.82, 0.08, Color("#6E5CA8"), 0.22)
	var trim := Palette.make_emissive_material(accent_color, 1.9)
	var roof_glow := Palette.make_emissive_material(Palette.STALL_WARM, 1.8)

	# Walkable top deck + deep structural box girder beneath
	PropUtils.add_box(visual, Vector3(length + 0.4, 0.36, width), Vector3(0.0, -0.18, 0.0), wet_mat)
	PropUtils.add_box(visual, Vector3(length + 0.6, 0.95, width - 0.2), Vector3(0.0, -0.82, 0.0), steel)

	# Heavy end abutments / anchors at BOTH ends reaching down into supporting walls/ground!
	var pier_h := maxf(support_height, 5.0)
	for ex in [-length * 0.46, length * 0.46]:
		var abut := PropUtils.add_box(visual, Vector3(1.8, pier_h, width + 0.4), Vector3(ex, -1.25 - pier_h * 0.5, 0.0), concrete)
		abut.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		abut.visibility_range_end = 260.0
		# Diagonal arch braces rising from abutments into bridge deck
		var inward := -signf(ex) * minf(length * 0.16, 4.2)
		for pz in [-width * 0.38, width * 0.38]:
			PropUtils.add_strut(visual, Vector3(ex, -4.5, pz), Vector3(ex + inward, -0.9, pz), 0.34, steel)

	# Mid-span support piers for longer bridges
	if has_mid_piers and length >= 20.0:
		var pier_count := maxi(1, int(floorf(length / 18.0)))
		for i in range(pier_count):
			var px := lerpf(-length * 0.28, length * 0.28, float(i) / float(maxi(1, pier_count - 1))) if pier_count > 1 else 0.0
			for pz in [-width * 0.38, width * 0.38]:
				var pcol := PropUtils.add_box(visual, Vector3(0.95, pier_h, 0.95), Vector3(px, -1.25 - pier_h * 0.5, pz), concrete)
				pcol.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				pcol.visibility_range_end = 250.0
			# Cross-beam tying twin piers
			PropUtils.add_box(visual, Vector3(0.85, 0.7, width), Vector3(px, -3.2, 0.0), steel)

	# Side railings with sturdy colliders
	var hz := width * 0.5 - 0.08
	for cz in [-hz, hz]:
		PropUtils.add_box(visual, Vector3(length, 0.07, 0.08), Vector3(0.0, 1.02, cz), steel)
		PropUtils.add_box(visual, Vector3(length, 0.045, 0.05), Vector3(0.0, 0.52, cz), steel)
		PropUtils.add_box(visual, Vector3(length - 0.4, 0.06, 0.06), Vector3(0.0, -0.22, cz + (0.14 if cz > 0 else -0.14)), trim)
		var posts := maxi(3, int(roundf(length / 3.5)) + 1)
		for p in range(posts):
			var px := lerpf(-length * 0.48, length * 0.48, float(p) / float(posts - 1))
			PropUtils.add_box(visual, Vector3(0.09, 1.05, 0.09), Vector3(px, 0.52, cz), steel)
		PropUtils.add_static_box_collider(self, Vector3(length, 1.1, 0.16), Vector3(0.0, 0.55, cz))

	# Optional covered skybridge canopy with warm interior light strip
	if covered:
		var arch_count := maxi(3, int(roundf(length / 5.5)) + 1)
		for a in range(arch_count):
			var ax := lerpf(-length * 0.46, length * 0.46, float(a) / float(arch_count - 1))
			PropUtils.add_box(visual, Vector3(0.18, 3.6, 0.18), Vector3(ax, 1.8, -hz), steel)
			PropUtils.add_box(visual, Vector3(0.18, 3.6, 0.18), Vector3(ax, 1.8, hz), steel)
			PropUtils.add_box(visual, Vector3(0.18, 0.18, width + 0.2), Vector3(ax, 3.6, 0.0), steel)
		PropUtils.add_box(visual, Vector3(length + 0.4, 0.20, width + 0.5), Vector3(0.0, 3.74, 0.0), steel)
		var strip := PropUtils.add_box(visual, Vector3(length - 1.0, 0.08, 0.35), Vector3(0.0, 3.60, 0.0), roof_glow)
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		PropUtils.add_ground_glow_pool(visual, Vector3(0.0, 0.0, 0.0), Vector2(length * 0.88, width * 0.82), Palette.LANTERN_AMBER, 0.22, 90.0)

	# Single overlapping walkable deck collider (+0.8m on length to merge cleanly with both ends!)
	PropUtils.add_static_box_collider(self, Vector3(length + 0.8, 1.2, width + 0.3), Vector3(0.0, -0.6, 0.0))
