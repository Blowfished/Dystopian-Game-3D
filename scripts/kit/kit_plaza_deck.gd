@tool
class_name KitPlazaDeck
extends Node3D

## Solid urban plaza / stepped building rooftop deck.
## Always backed by a solid architectural podium building mass extending down
## to lower levels / lower city strata (NEVER a floating slab!).

@export var size: Vector3 = Vector3(36.0, 0.8, 30.0):
	set(v):
		size = v
		if is_inside_tree():
			_rebuild()

@export var puddle_amount: float = 0.52
@export var accent_color: Color = Palette.LANTERN_AMBER
@export var reflect_warmth: float = 0.68
@export var foundation_depth: float = 28.0
@export var collider_overlap: float = 0.5
@export var lit_podium_windows: bool = true


func _ready() -> void:
	add_to_group("walkable_surfaces")
	set_meta("walkable_type", "plaza")
	set_meta("walkable_size", size)
	set_meta("support_type", "solid_building_podium")
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	set_meta("walkable_size", size)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var wet_mat := ShaderMaterial.new()
	wet_mat.shader = load("res://shaders/wet_walkway.gdshader")
	wet_mat.set_shader_parameter("tile_size", 2.0)
	wet_mat.set_shader_parameter("puddle_amount", puddle_amount)
	wet_mat.set_shader_parameter("reflect_warmth", reflect_warmth)
	wet_mat.set_shader_parameter("rain_intensity", 1.0)

	var concrete := Palette.make_stylized_material(Palette.CONCRETE_DARK, 0.84, 0.06, Color("#6E5CA8"), 0.22)
	var podium_mat := Palette.make_stylized_material(Color("#1C1732"), 0.86, 0.08, Color("#63529E"), 0.20)
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.55, 0.45, Color("#7362AD"), 0.22)
	var trim := Palette.make_emissive_material(accent_color, 1.7)

	# Walkable top deck (top at local y = 0.0)
	var top_box := PropUtils.add_box(visual, size, Vector3(0.0, -size.y * 0.5, 0.0), wet_mat)
	top_box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Molded cornice lip
	var lip := PropUtils.add_box(visual, Vector3(size.x + 0.5, 0.9, size.z + 0.5), Vector3(0.0, -size.y - 0.45, 0.0), concrete)
	lip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Glowing perimeter trim on all 4 edges
	var t_n := PropUtils.add_box(visual, Vector3(size.x, 0.06, 0.06), Vector3(0.0, -0.22, -size.z * 0.5 - 0.05), trim)
	var t_s := PropUtils.add_box(visual, Vector3(size.x, 0.06, 0.06), Vector3(0.0, -0.22, size.z * 0.5 + 0.05), trim)
	var t_w := PropUtils.add_box(visual, Vector3(0.06, 0.06, size.z), Vector3(-size.x * 0.5 - 0.05, -0.22, 0.0), trim)
	var t_e := PropUtils.add_box(visual, Vector3(0.06, 0.06, size.z), Vector3(size.x * 0.5 + 0.05, -0.22, 0.0), trim)
	for t in [t_n, t_s, t_w, t_e]:
		t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Solid architectural podium building block underneath (extending down to lower level / lower city!)
	var pd := maxf(foundation_depth, 4.0)
	var podium_size := Vector3(maxf(size.x - 0.5, 2.0), pd, maxf(size.z - 0.5, 2.0))
	var podium_y := -size.y - 0.9 - pd * 0.5
	var podium := PropUtils.add_box(visual, podium_size, Vector3(0.0, podium_y, 0.0), podium_mat)
	podium.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	podium.visibility_range_end = 300.0

	# Solid podium collider below the top surface so the retaining wall / building base is solid!
	PropUtils.add_static_box_collider(self, podium_size, Vector3(0.0, podium_y, 0.0))

	# Structural corner buttress piers & mid pilasters along the podium walls
	var pier_xs := [-size.x * 0.48, 0.0, size.x * 0.48]
	var pier_zs := [-size.z * 0.48, 0.0, size.z * 0.48]
	for cx in pier_xs:
		for cz in pier_zs:
			if absf(cx) < 0.1 and absf(cz) < 0.1:
				continue
			var col := PropUtils.add_box(visual, Vector3(1.1, pd + 0.8, 1.1), Vector3(cx, podium_y + 0.4, cz), steel)
			col.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			col.visibility_range_end = 240.0

	# Warm glowing recessed service windows along the podium faces (batched via MultiMesh!)
	if lit_podium_windows and pd >= 4.5:
		_add_podium_windows(visual, podium_size, pd, -size.y - 0.9)

	# Single merged overlapping top walkable collider
	var col_size := Vector3(size.x + collider_overlap, maxf(size.y, 0.9), size.z + collider_overlap)
	PropUtils.add_static_box_collider(self, col_size, Vector3(0.0, -col_size.y * 0.5, 0.0))


func _add_podium_windows(parent: Node3D, psize: Vector3, depth: float, top_y: float) -> void:
	var mmi := MultiMeshInstance3D.new()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 220.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var wbox := BoxMesh.new()
	wbox.size = Vector3(1.8, 1.4, 0.12)
	wbox.material = Palette.make_emissive_material(Palette.WINDOW_WARM_A, 1.5)
	mm.mesh = wbox

	var transforms: Array[Transform3D] = []
	var rows := clampi(int(floorf(depth / 4.8)), 1, 5)
	var cols_x := clampi(int(floorf(psize.x / 5.5)), 2, 12)
	var cols_z := clampi(int(floorf(psize.z / 5.5)), 2, 10)

	for r in range(rows):
		var wy := top_y - 2.2 - float(r) * 4.6
		for c in range(cols_x):
			if (r * 5 + c * 7) % 4 == 0:
				continue
			var wx := lerpf(-psize.x * 0.42, psize.x * 0.42, float(c) / float(maxi(1, cols_x - 1)))
			transforms.append(Transform3D(Basis.IDENTITY, Vector3(wx, wy, psize.z * 0.5 + 0.05)))
			transforms.append(Transform3D(Basis.IDENTITY, Vector3(wx, wy, -psize.z * 0.5 - 0.05)))
		for c in range(cols_z):
			if (r * 3 + c * 11) % 4 == 0:
				continue
			var wz := lerpf(-psize.z * 0.42, psize.z * 0.42, float(c) / float(maxi(1, cols_z - 1)))
			var rot_b := Basis(Vector3.UP, PI * 0.5)
			transforms.append(Transform3D(rot_b, Vector3(psize.x * 0.5 + 0.05, wy, wz)))
			transforms.append(Transform3D(rot_b, Vector3(-psize.x * 0.5 - 0.05, wy, wz)))

	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
	mmi.multimesh = mm
	parent.add_child(mmi)
