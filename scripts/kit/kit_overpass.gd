@tool
class_name KitOverpass
extends Node3D

## Elevated boulevard overpass deck with heavy structural pillars reaching down
## to the street below, underside neon trim, and overlapping collision deck.

@export var size: Vector3 = Vector3(68.0, 0.75, 11.0):
	set(v):
		size = v
		if is_inside_tree():
			_rebuild()

@export var support_height: float = 7.0
@export var accent_color: Color = Palette.BEACON_MAGENTA
@export var rail_left_side: bool = true
@export var rail_right_side: bool = true


func _ready() -> void:
	add_to_group("walkable_surfaces")
	set_meta("walkable_type", "overpass")
	set_meta("walkable_size", size)
	set_meta("support_type", "street_support_columns")
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
	wet_mat.set_shader_parameter("puddle_amount", 0.52)
	wet_mat.set_shader_parameter("reflect_warmth", 0.45)

	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.56, 0.46, Color("#7A6BB5"), 0.24)
	var concrete := Palette.make_stylized_material(Palette.CONCRETE_DARK, 0.80, 0.08, Color("#6E5CA8"), 0.22)
	var trim := Palette.make_emissive_material(accent_color, 2.35)
	var under_glow := Palette.make_emissive_material(Palette.NEON_CYAN, 1.9)

	# Walkable top deck + thick steel girder belly
	PropUtils.add_box(visual, size, Vector3(0.0, -size.y * 0.5, 0.0), wet_mat)
	PropUtils.add_box(visual, Vector3(size.x - 0.2, 0.55, size.z - 0.6), Vector3(0.0, -size.y - 0.275, 0.0), steel)
	PropUtils.add_box(visual, Vector3(size.x - 0.6, 0.07, 0.07), Vector3(0.0, -size.y * 0.5, size.z * 0.5 + 0.03), trim)
	PropUtils.add_box(visual, Vector3(size.x - 0.6, 0.07, 0.07), Vector3(0.0, -size.y * 0.5, -size.z * 0.5 - 0.03), trim)
	# Under-overpass neon light strip illuminating the boulevard street underneath!
	PropUtils.add_box(visual, Vector3(size.x - 2.0, 0.08, 0.35), Vector3(0.0, -size.y - 0.56, 0.0), under_glow)

	# Side railings (leaving ends open for stairs/ramps/building connectors)
	var sides: Array[float] = []
	if rail_left_side:
		sides.append(-size.z * 0.48)
	if rail_right_side:
		sides.append(size.z * 0.48)
	for cz in sides:
		PropUtils.add_box(visual, Vector3(size.x, 0.07, 0.08), Vector3(0.0, 1.02, cz), steel)
		PropUtils.add_box(visual, Vector3(size.x, 0.045, 0.05), Vector3(0.0, 0.52, cz), steel)
		var posts := maxi(4, int(roundf(size.x / 4.0)) + 1)
		for i in range(posts):
			var px := lerpf(-size.x * 0.48, size.x * 0.48, float(i) / float(posts - 1))
			PropUtils.add_box(visual, Vector3(0.08, 1.02, 0.08), Vector3(px, 0.51, cz), steel)
		PropUtils.add_static_box_collider(self, Vector3(size.x, 1.08, 0.16), Vector3(0.0, 0.54, cz))

	# Heavy support columns reaching cleanly down to street level (y = -support_height)
	var col_rows := maxi(3, int(roundf(size.x / 16.0)) + 1)
	for i in range(col_rows):
		var px := lerpf(-size.x * 0.44, size.x * 0.44, float(i) / float(maxi(1, col_rows - 1)))
		for pz in [-size.z * 0.38, size.z * 0.38]:
			var col_h := support_height + 0.5
			PropUtils.add_box(visual, Vector3(0.85, col_h, 0.85), Vector3(px, -size.y - col_h * 0.5 + 0.25, pz), concrete)
			# Concrete plinth base at street level
			PropUtils.add_box(visual, Vector3(1.15, 0.6, 1.15), Vector3(px, -support_height + 0.3, pz), steel)
			PropUtils.add_static_box_collider(self, Vector3(0.9, col_h, 0.9), Vector3(px, -size.y - col_h * 0.5 + 0.25, pz))
		# Transverse steel header beam under deck
		PropUtils.add_box(visual, Vector3(0.7, 0.65, size.z * 0.88), Vector3(px, -size.y - 0.6, 0.0), steel)

	# Single merged overlapping walkable deck collider
	PropUtils.add_static_box_collider(self, Vector3(size.x + 0.6, size.y + 0.4, size.z + 0.5), Vector3(0.0, -(size.y + 0.4) * 0.5, 0.0))
