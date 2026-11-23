@tool
class_name KitBalcony
extends Node3D

## Building-attached cantilevered balcony deck (top at local y = 0.0).
## Always visibly anchored into its backing building facade (-Z) via heavy steel
## cantilever I-beams and diagonal wall brackets, with solid perimeter railings
## on exposed edges and overlapping collision seams.

@export var size: Vector3 = Vector3(12.0, 0.5, 4.2)
@export var accent_color: Color = Palette.LANTERN_AMBER
@export var rail_front: bool = true
@export var rail_left: bool = false
@export var rail_right: bool = false
@export var add_columns: bool = false
@export var column_height: float = 5.0


func _ready() -> void:
	add_to_group("walkable_surfaces")
	set_meta("walkable_type", "balcony")
	set_meta("walkable_size", size)
	set_meta("support_type", "wall_cantilever_brackets")
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	set_meta("walkable_size", size)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var deck := Palette.make_stylized_material(Palette.STEEL_MID, 0.54, 0.38, Color("#8878C4"), 0.26)
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.56, 0.46, Color("#7362AD"), 0.24)
	var trim := Palette.make_emissive_material(accent_color, 1.85)

	# Main balcony deck slab
	PropUtils.add_box(visual, size, Vector3(0.0, -size.y * 0.5, 0.0), deck)
	# Overlapping collider (+0.4m on X and Z so connections to facades, stairs, and bridges never gap!)
	var col_size := Vector3(size.x + 0.45, maxf(size.y, 0.65), size.z + 0.45)
	PropUtils.add_static_box_collider(self, col_size, Vector3(0.0, -col_size.y * 0.5, 0.0))

	# Heavy diagonal cantilever steel brackets anchored straight back into the building wall (-Z)!
	var bracket_count := maxi(3, int(roundf(size.x / 4.2)) + 1)
	for i in range(bracket_count):
		var bx := lerpf(-size.x * 0.44, size.x * 0.44, float(i) / float(maxi(1, bracket_count - 1)))
		# Horizontal underside girder
		PropUtils.add_box(visual, Vector3(0.24, 0.26, size.z + 0.4), Vector3(bx, -size.y - 0.13, -0.2), steel)
		# Diagonal knee brace down into the backing building facade
		PropUtils.add_strut(
			visual,
			Vector3(bx, -size.y - 0.15, size.z * 0.42),
			Vector3(bx, -size.y - 2.35, -size.z * 0.52),
			0.22,
			steel
		)
		# Wall anchor plate bolted to building facade
		PropUtils.add_box(visual, Vector3(0.55, 2.6, 0.24), Vector3(bx, -size.y - 1.25, -size.z * 0.52), steel)

	# Optional ground support columns (when spanning wide terraces or corners)
	if add_columns and column_height > 0.5:
		for cx in [-size.x * 0.44, 0.0, size.x * 0.44]:
			PropUtils.add_box(visual, Vector3(0.55, column_height, 0.55), Vector3(cx, -size.y - column_height * 0.5, size.z * 0.42), steel)
			PropUtils.add_static_box_collider(self, Vector3(0.6, column_height, 0.6), Vector3(cx, -size.y - column_height * 0.5, size.z * 0.42))

	# Edge glow trim
	PropUtils.add_box(visual, Vector3(size.x - 0.2, 0.05, 0.05), Vector3(0.0, -0.18, size.z * 0.5 + 0.03), trim)

	# Front railing (+Z)
	if rail_front:
		_add_rail(visual, Vector3(0.0, 0.0, size.z * 0.48), size.x, false, steel)
	if rail_left:
		_add_rail(visual, Vector3(-size.x * 0.48, 0.0, 0.0), size.z, true, steel)
	if rail_right:
		_add_rail(visual, Vector3(size.x * 0.48, 0.0, 0.0), size.z, true, steel)


func _add_rail(visual: Node3D, center: Vector3, span: float, along_z: bool, mat: Material) -> void:
	var sx := 0.07 if along_z else span
	var sz := span if along_z else 0.07
	PropUtils.add_box(visual, Vector3(sx, 0.065, sz), center + Vector3(0.0, 1.02, 0.0), mat)
	PropUtils.add_box(visual, Vector3(sx, 0.045, sz), center + Vector3(0.0, 0.52, 0.0), mat)
	var posts := maxi(2, int(roundf(span / 2.6)) + 1)
	for p in range(posts):
		var t := lerpf(-span * 0.48, span * 0.48, float(p) / float(posts - 1))
		var offset := Vector3(0.0, 0.51, t) if along_z else Vector3(t, 0.51, 0.0)
		PropUtils.add_box(visual, Vector3(0.07, 1.02, 0.07), center + offset, mat)
	var col_sz := Vector3(0.16, 1.08, span) if along_z else Vector3(span, 1.08, 0.16)
	PropUtils.add_static_box_collider(self, col_sz, center + Vector3(0.0, 0.54, 0.0))
