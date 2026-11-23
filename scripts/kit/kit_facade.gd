@tool
class_name KitFacade
extends Node3D

## High-density 10–40 story cyberpunk building facade (35m–140m tall) with
## OccluderInstance3D and MultiMeshInstance3D batched architectural details:
## warm & cool windows, upper balconies, AC condenser units, laundry lines,
## rooftop/ledge satellite dishes, vertical utility pipes, and stacked jutting neon blade signs!

@export var size: Vector3 = Vector3(24.0, 68.0, 12.0):
	set(v):
		size = v
		if is_inside_tree():
			_rebuild()

@export_enum("noodle", "market", "neon", "garden") var district_theme: String = "noodle":
	set(v):
		district_theme = v
		if is_inside_tree():
			_rebuild()

@export var detail_faces: String = "both"  # "both", "front", "back", "all"
@export var seed_offset: int = 0


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(position.x * 73.0 + position.z * 131.0 + size.x * 19.0)) + seed_offset + 101

	var wall_col := Palette.FACADE_WALL
	var trim_col := Palette.FACADE_TRIM
	var win_warm := Palette.WINDOW_WARM_A
	var win_alt := Palette.WINDOW_WARM_B
	var accent_a := Palette.LANTERN_AMBER
	var accent_b := Palette.LANDMARK_TEAL

	match district_theme:
		"market":
			wall_col = Color("#292342")
			trim_col = Color("#423A66")
			win_warm = Palette.WINDOW_WARM_B
			win_alt = Palette.LANTERN_AMBER
			accent_a = Palette.CANOPY_OCHRE
			accent_b = Palette.LANDMARK_TEAL
		"neon":
			wall_col = Color("#1B1733")
			trim_col = Color("#302A57")
			win_warm = Palette.WINDOW_WARM_A
			win_alt = Palette.NEON_CYAN
			accent_a = Palette.BEACON_MAGENTA
			accent_b = Palette.NEON_CYAN
		"garden":
			wall_col = Color("#20243D")
			trim_col = Color("#36455E")
			win_warm = Palette.WINDOW_WARM_B
			win_alt = Palette.GREENHOUSE_GLOW
			accent_a = Palette.LANDMARK_TEAL
			accent_b = Palette.LANTERN_AMBER

	var wall_mat := Palette.make_stylized_material(wall_col, 0.84, 0.06, Color("#7D6EC4"), 0.22)
	var trim_mat := Palette.make_stylized_material(trim_col, 0.65, 0.26, Color("#9688D9"), 0.24)
	var steel_mat := Palette.make_stylized_material(Palette.STEEL_DARK, 0.56, 0.44, Color("#7362AD"), 0.22)
	var ac_mat := Palette.make_stylized_material(Color("#474263"), 0.72, 0.22, Color("#887CC2"), 0.20)
	var plant_mat := Palette.make_stylized_material(Palette.FOLIAGE_MID, 0.78, 0.0, Color("#8BD4C1"), 0.28)
	var accent_a_mat := Palette.make_emissive_material(accent_a, 2.3)
	var accent_b_mat := Palette.make_emissive_material(accent_b, 2.4)
	var accent_c_mat := Palette.make_emissive_material(Palette.LANTERN_AMBER, 2.4)

	# Building core (base sits at local y = 0.0, extends below y=0 by 24m into lower city!)
	var sub_extend := 24.0
	var core_h := size.y + sub_extend
	var core_y := size.y * 0.5 - sub_extend * 0.5
	var core_mesh := PropUtils.add_box(visual, Vector3(size.x, core_h, size.z), Vector3(0.0, core_y, 0.0), wall_mat)
	core_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	PropUtils.add_static_box_collider(self, Vector3(size.x, core_h, size.z), Vector3(0.0, core_y, 0.0))
	PropUtils.add_occluder_box(self, Vector3(size.x * 0.96, size.y * 0.96, size.z * 0.96), Vector3(0.0, size.y * 0.5, 0.0))

	# Stepped upper crown / mechanical penthouse for authentic megastructure silhouette
	var crown_w := size.x * 0.68
	var crown_d := size.z * 0.68
	var crown_h := clampf(size.y * 0.14, 4.5, 14.0)
	var crown := PropUtils.add_box(visual, Vector3(crown_w, crown_h, crown_d), Vector3(0.0, size.y + crown_h * 0.5, 0.0), trim_mat)
	crown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var roof_beacon := PropUtils.add_box(visual, Vector3(size.x + 0.3, 0.14, size.z + 0.3), Vector3(0.0, size.y - 0.55, 0.0), accent_a_mat)
	roof_beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Architectural floor ledges (every 2 stories) & corner pilasters (batched in MultiMesh!)
	var floor_h := 3.6
	var total_floors := maxi(4, int(floorf(size.y / floor_h)))
	var ledge_transforms: Array[Transform3D] = []
	for f in range(1, total_floors + 1, 2):
		var cy := float(f) * floor_h
		if cy > size.y - 0.5:
			break
		var b := Basis.IDENTITY.scaled(Vector3(size.x + 0.45, 0.28, size.z + 0.45))
		ledge_transforms.append(Transform3D(b, Vector3(0.0, cy - 0.14, 0.0)))
	_add_box_multimesh(visual, ledge_transforms, trim_mat, 260.0)

	# Determine which faces get rich street-level/upper-floor detail
	var faces: Array[Dictionary] = []
	# Each face: normal dir, center offset, tangent width, yaw_rad
	if detail_faces in ["both", "front", "all"]:
		faces.append({"z_sign": 1.0, "axis": "z", "span": size.x, "half_depth": size.z * 0.5, "yaw": 0.0})
	if detail_faces in ["both", "back", "all"]:
		faces.append({"z_sign": -1.0, "axis": "z", "span": size.x, "half_depth": size.z * 0.5, "yaw": PI})
	if detail_faces == "all" or size.z >= 14.0:
		faces.append({"z_sign": 1.0, "axis": "x", "span": size.z, "half_depth": size.x * 0.5, "yaw": PI * 0.5})
		faces.append({"z_sign": -1.0, "axis": "x", "span": size.z, "half_depth": size.x * 0.5, "yaw": -PI * 0.5})

	var win_warm_xforms: Array[Transform3D] = []
	var win_alt_xforms: Array[Transform3D] = []
	var balcony_xforms: Array[Transform3D] = []
	var ac_xforms: Array[Transform3D] = []
	var pipe_xforms: Array[Transform3D] = []
	var laundry_xforms: Array[Transform3D] = []
	var plant_xforms: Array[Transform3D] = []
	var sign_a_xforms: Array[Transform3D] = []
	var sign_b_xforms: Array[Transform3D] = []
	var sign_c_xforms: Array[Transform3D] = []
	var sign_frame_xforms: Array[Transform3D] = []

	for face in faces:
		var span: float = face["span"]
		var half_d: float = face["half_depth"]
		var yaw: float = face["yaw"]
		var rot_b := Basis(Vector3.UP, yaw)
		var cols := maxi(2, int(floorf((span - 2.0) / 2.8)))

		# Vertical drainage / utility pipes running up the facade edges
		for px_side in [-span * 0.44, span * 0.44]:
			var p_h := minf(size.y * 0.9, 55.0)
			var lp := rot_b * Vector3(px_side, p_h * 0.5 + 1.0, half_d + 0.14)
			pipe_xforms.append(Transform3D(rot_b.scaled(Vector3(0.22, p_h, 0.22)), lp))

		# Windows + Upper-floor balconies, AC units, laundry lines, potted plants (start at floor 1 = y=4.2m above shopfronts!)
		var max_detail_floor := mini(total_floors, 26)
		for f in range(1, max_detail_floor):
			var wy := float(f) * floor_h + 1.8
			if wy > size.y - 1.5:
				break
			for c in range(cols):
				var wx := lerpf(-span * 0.42, span * 0.42, float(c) / float(maxi(1, cols - 1)))
				var r_val := rng.randf()

				# Windows (~78% lit with warm amber/gold dominance + occasional cool cyan/teal)
				if r_val > 0.22:
					var w_pos := rot_b * Vector3(wx, wy, half_d + 0.05)
					var w_scale := Vector3(rng.randf_range(1.15, 1.55), rng.randf_range(1.4, 1.75), 0.10)
					var xf := Transform3D(rot_b.scaled(w_scale), w_pos)
					if r_val > 0.84:
						win_alt_xforms.append(xf)
					else:
						win_warm_xforms.append(xf)

				# Upper-floor architectural clutter (concentrated on stories 2–12 where player sees clearly!)
				if f >= 1 and f <= 11:
					var clutter_roll := rng.randf()
					if clutter_roll < 0.24:
						# Protruding mini balcony slab + rail + optional plant or laundry line
						var by := float(f) * floor_h + 0.12
						var b_pos := rot_b * Vector3(wx, by, half_d + 0.55)
						balcony_xforms.append(Transform3D(rot_b.scaled(Vector3(2.2, 0.22, 1.1)), b_pos))
						# Railing bar
						var r_pos := rot_b * Vector3(wx, by + 0.88, half_d + 1.02)
						pipe_xforms.append(Transform3D(rot_b.scaled(Vector3(2.2, 0.08, 0.08)), r_pos))
						if rng.randf() < 0.55:
							var pl_pos := rot_b * Vector3(wx + 0.55, by + 0.42, half_d + 0.65)
							plant_xforms.append(Transform3D(rot_b.scaled(Vector3(0.55, 0.58, 0.55)), pl_pos))
						if rng.randf() < 0.42:
							# Laundry line / hanging cloth strips
							var l_pos := rot_b * Vector3(wx - 0.35, by + 1.15, half_d + 0.85)
							laundry_xforms.append(Transform3D(rot_b.scaled(Vector3(1.1, 0.45, 0.06)), l_pos))
					elif clutter_roll < 0.52:
						# AC condenser unit bolted beside window
						var ac_pos := rot_b * Vector3(wx + 0.88, wy - 0.45, half_d + 0.34)
						ac_xforms.append(Transform3D(rot_b.scaled(Vector3(0.72, 0.52, 0.48)), ac_pos))

		# Satellite dishes on upper ledges
		if span >= 10.0:
			var dish_count := mini(3, maxi(1, int(span / 10.0)))
			for d_idx in range(dish_count):
				var dx := rng.randf_range(-span * 0.38, span * 0.38)
				var dy := rng.randf_range(minf(14.0, size.y * 0.5), minf(34.0, size.y - 3.0))
				var dish_pos := rot_b * Vector3(dx, dy, half_d + 0.55)
				var dish_rot := rot_b * Basis(Vector3.RIGHT, deg_to_rad(-28.0)) * Basis(Vector3.UP, rng.randf_range(-0.4, 0.4))
				ac_xforms.append(Transform3D(dish_rot.scaled(Vector3(0.95, 0.95, 0.16)), dish_pos))

		# Stacked layered jutting neon sign blades at varied heights & slight angles!
		if span >= 8.0 and (face["axis"] == "z" or district_theme == "neon"):
			var sign_count := clampi(int(span / 4.8), 2, 7)
			if district_theme == "neon":
				sign_count = clampi(int(span / 3.4), 3, 10)
			for s_idx in range(sign_count):
				var sx := lerpf(-span * 0.40, span * 0.40, float(s_idx) / float(maxi(1, sign_count - 1))) + rng.randf_range(-0.8, 0.8)
				var sy := rng.randf_range(5.8, minf(32.0, size.y - 4.0))
				var is_vertical := rng.randf() < 0.72
				var sw := rng.randf_range(0.95, 1.85) if is_vertical else rng.randf_range(2.6, 5.2)
				var sh := rng.randf_range(3.0, 6.4) if is_vertical else rng.randf_range(1.1, 2.2)
				var jut := rng.randf_range(1.1, 2.35)
				var tilt := deg_to_rad(rng.randf_range(-10.0, 10.0))

				var s_basis := rot_b * Basis(Vector3.UP, (PI * 0.5 if is_vertical else 0.0) + tilt)
				var s_pos := rot_b * Vector3(sx, sy, half_d + jut)
				# Bracket arm anchoring sign cleanly into the wall
				var brk_pos := rot_b * Vector3(sx, sy, half_d + jut * 0.5)
				sign_frame_xforms.append(Transform3D(rot_b.scaled(Vector3(0.14, 0.14, jut)), brk_pos))
				# Backing frame
				sign_frame_xforms.append(Transform3D(s_basis.scaled(Vector3(sw + 0.16, sh + 0.16, 0.18)), s_pos))
				# Glowing neon face
				var face_xf := Transform3D(s_basis.scaled(Vector3(sw, sh, 0.24)), s_pos)
				var pick := (s_idx + seed_offset) % 3
				if pick == 0:
					sign_a_xforms.append(face_xf)
				elif pick == 1:
					sign_b_xforms.append(face_xf)
				else:
					sign_c_xforms.append(face_xf)

	# Commit all batched MultiMeshInstance3Ds (ultra low draw calls!)
	_add_box_multimesh(visual, win_warm_xforms, Palette.make_emissive_material(win_warm, 1.85), 290.0)
	_add_box_multimesh(visual, win_alt_xforms, Palette.make_emissive_material(win_alt, 1.95), 290.0)
	_add_box_multimesh(visual, balcony_xforms, trim_mat, 165.0)
	_add_box_multimesh(visual, ac_xforms, ac_mat, 130.0)
	_add_box_multimesh(visual, pipe_xforms, steel_mat, 145.0)
	_add_box_multimesh(visual, laundry_xforms, Palette.make_stylized_material(Palette.CREAM_WARM, 0.85, 0.0, Color("#FFE2B0"), 0.22), 105.0)
	_add_box_multimesh(visual, plant_xforms, plant_mat, 115.0)
	_add_box_multimesh(visual, sign_frame_xforms, steel_mat, 190.0)
	_add_box_multimesh(visual, sign_a_xforms, accent_a_mat, 240.0)
	_add_box_multimesh(visual, sign_b_xforms, accent_b_mat, 240.0)
	_add_box_multimesh(visual, sign_c_xforms, accent_c_mat, 240.0)


func _add_box_multimesh(parent: Node3D, xforms: Array[Transform3D], mat: Material, vis_end: float) -> void:
	if xforms.is_empty():
		return
	var mmi := MultiMeshInstance3D.new()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = vis_end
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	box.material = mat
	mm.mesh = box
	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])
	mmi.multimesh = mm
	parent.add_child(mmi)
