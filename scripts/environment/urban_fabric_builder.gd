@tool
class_name UrbanFabricBuilder
extends Node3D

## Builds the continuous surrounding dense city fabric using MultiMeshInstance3D:
## 1. Lower City Strata (Y = -16m to -52m) directly below overlooks, railings, & bridges
##    with lower street decks, lower rooftops, glowing billboards, and lit windows (NEVER void!).
## 2. Close-in Canyon Backdrop Towers (45m–140m tall) filling every gap behind walkable
##    districts and across the Maglev rail canyon so the sky is a narrow ribbon overhead.
## 3. High Overhead Canyon Cross-Bridges (Y = 18m–52m) spanning across streets & the rail trench.
## 4. Deep Indigo-Violet Atmospheric Fog Floor planes below the lower city strata.

@export var fabric_seed: int = 202611

const WINDOW_SHADER := preload("res://shaders/skyline_windows.gdshader")


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var rng := RandomNumberGenerator.new()
	rng.seed = fabric_seed

	_build_lower_city_strata(rng)
	_build_canyon_infill_towers(rng)
	_build_overhead_canyon_bridges()
	_build_hazy_fog_floor()


func _build_lower_city_strata(rng: RandomNumberGenerator) -> void:
	## Dense lower city tier directly visible below railings, stations, and bridges (-18m..-52m).
	var lower_root := Node3D.new()
	lower_root.name = "LowerCityStrata"
	add_child(lower_root)

	# 1. Lower city street grid decks (Y = -20m and Y = -32m) with warm & cyan glowing lane strips
	var deck_mat := Palette.make_stylized_material(Color("#151126"), 0.88, 0.08, Color("#4D3E80"), 0.16)
	var lane_amber := Palette.make_emissive_material(Palette.LANTERN_AMBER, 1.9)
	var lane_cyan := Palette.make_emissive_material(Palette.NEON_CYAN, 2.0)
	var lane_mag := Palette.make_emissive_material(Palette.BEACON_MAGENTA, 2.0)

	var deck_xforms: Array[Transform3D] = []
	var amber_xforms: Array[Transform3D] = []
	var cyan_xforms: Array[Transform3D] = []
	var mag_xforms: Array[Transform3D] = []

	# Continuous lower boulevard directly below the Maglev rail canyon (Z = -22 to -60, X = -190 to +190)
	deck_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(420.0, 1.2, 46.0)), Vector3(15.0, -21.0, -40.0)))
	# Lower cross-avenues running North-South under the city fabric
	for lx in [-135.0, -68.0, 0.0, 66.0, 145.0]:
		deck_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(22.0, 1.2, 240.0)), Vector3(lx, -22.0, -10.0)))
		amber_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.45, 0.14, 220.0)), Vector3(lx - 6.0, -21.2, -10.0)))
		cyan_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.45, 0.14, 220.0)), Vector3(lx + 6.0, -21.2, -10.0)))

	# Lower East-West transit ribbons & glowing signage along the rail trench floor
	for lz in [-28.0, -42.0, -56.0]:
		amber_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(380.0, 0.14, 0.55)), Vector3(10.0, -20.2, lz)))
	# Lower billboards facing South (+Z) toward players peering over the promenade railings!
	for i in range(18):
		var bx := lerpf(-145.0, 145.0, float(i) / 17.0)
		var bz := rng.randf_range(-44.0, -29.0)
		var by := rng.randf_range(-16.0, -6.5)
		var bw := rng.randf_range(5.5, 11.5)
		var bh := rng.randf_range(2.8, 5.4)
		var xf := Transform3D(Basis.IDENTITY.scaled(Vector3(bw, bh, 0.35)), Vector3(bx, by, bz))
		var pick := i % 3
		if pick == 0:
			amber_xforms.append(xf)
		elif pick == 1:
			mag_xforms.append(xf)
		else:
			cyan_xforms.append(xf)

	# Lower sub-strata buildings rising from Y = -58m up to Y = -8m..-22m (NEVER poking above walkable decks!)
	var lower_towers := MultiMeshInstance3D.new()
	lower_towers.name = "LowerStrataBuildings"
	lower_towers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	mm.mesh = box

	var mat := ShaderMaterial.new()
	mat.shader = WINDOW_SHADER
	mat.set_shader_parameter("tower_dark", Color("#110D24"))
	mat.set_shader_parameter("tower_mid", Color("#1C1538"))
	mat.set_shader_parameter("haze_color", Color("#1D1638"))
	mat.set_shader_parameter("emission_boost", 1.95)
	mat.set_shader_parameter("window_density", 0.62)
	mat.set_shader_parameter("window_scale", 0.85)
	mat.set_shader_parameter("layer_haze", 0.24)
	lower_towers.material_override = mat

	var t_xforms: Array[Transform3D] = []
	var t_customs: Array[Color] = []
	for i in range(130):
		var tx := rng.randf_range(-210.0, 235.0)
		var tz := rng.randf_range(-135.0, 125.0)
		var tw := rng.randf_range(10.0, 24.0)
		var td := rng.randf_range(10.0, 22.0)
		var top_y := rng.randf_range(-20.0, -7.5)
		var base_y := -66.0
		var th := top_y - base_y
		t_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(tw, th, td)), Vector3(tx, base_y + th * 0.5, tz)))
		t_customs.append(Color(rng.randf(), tw, th, rng.randf()))

	mm.instance_count = t_xforms.size()
	for i in range(t_xforms.size()):
		mm.set_instance_transform(i, t_xforms[i])
		mm.set_instance_custom_data(i, t_customs[i])
	lower_towers.multimesh = mm
	lower_root.add_child(lower_towers)

	_commit_box_mmi(lower_root, "LowerDecks", deck_xforms, deck_mat, 320.0)
	_commit_box_mmi(lower_root, "LowerGlowAmber", amber_xforms, lane_amber, 280.0)
	_commit_box_mmi(lower_root, "LowerGlowCyan", cyan_xforms, lane_cyan, 280.0)
	_commit_box_mmi(lower_root, "LowerGlowMag", mag_xforms, lane_mag, 280.0)


func _build_canyon_infill_towers(rng: RandomNumberGenerator) -> void:
	## Dense 12–42 story canyon skyscrapers (45m–145m tall) right across the Maglev rail canyon
	## and packed tightly around all 4 walkable districts so there are ZERO void gaps anywhere!
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "CanyonInfillTowers"
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	mm.mesh = box

	var mat := ShaderMaterial.new()
	mat.shader = WINDOW_SHADER
	mat.set_shader_parameter("tower_dark", Color("#15112B"))
	mat.set_shader_parameter("tower_mid", Color("#221C42"))
	mat.set_shader_parameter("haze_color", Color("#1F173B"))
	mat.set_shader_parameter("emission_boost", 2.15)
	mat.set_shader_parameter("window_density", 0.60)
	mat.set_shader_parameter("window_scale", 0.92)
	mat.set_shader_parameter("layer_haze", 0.10)
	mmi.material_override = mat

	var transforms: Array[Transform3D] = []
	var customs: Array[Color] = []

	# A. North Maglev Canyon Wall (Z = -42 to -118, West of Neon Boulevard X = -195 to +70)
	# Gives the exact dense skyscraper wall across the rail trench from Noodle Alley & Market Terraces!
	var x_cursor := -185.0
	while x_cursor < 66.0:
		var tw := rng.randf_range(16.0, 26.0)
		var td := rng.randf_range(16.0, 24.0)
		var th := rng.randf_range(75.0, 145.0)
		var tz := -46.0 - rng.randf_range(0.0, 12.0)
		var base_y := -48.0
		# Leave a subtle skyline frame gap right near X=14..26 so Hero Landmark Tower peeks dramatically between towers!
		if absf(x_cursor - 18.0) > 12.0:
			transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(tw, th, td)), Vector3(x_cursor, base_y + th * 0.5, tz)))
			customs.append(Color(rng.randf(), tw, th, rng.randf()))
		# Second deeper row behind the first
		var th2 := rng.randf_range(95.0, 175.0)
		transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(tw * 1.15, th2, td * 1.1)), Vector3(x_cursor + 6.0, base_y + th2 * 0.5, tz - 32.0)))
		customs.append(Color(rng.randf(), tw * 1.15, th2, rng.randf()))
		x_cursor += tw * 0.88

	# B. Dense perimeter infill blocks wrapping behind South, West, East, and North-East of all 4 districts
	var infill_zones := [
		# West behind Noodle Alley
		{"x0": -205.0, "x1": -146.0, "z0": -40.0, "z1": 95.0, "count": 28},
		# South behind Noodle Alley & Market Terraces
		{"x0": -155.0, "x1": 92.0, "z0": 88.0, "z1": 158.0, "count": 36},
		# South-West pocket between Noodle Alley South & Market Terraces West
		{"x0": -90.0, "x1": -48.0, "z0": 48.0, "z1": 96.0, "count": 14},
		# Pocket between Market East, Neon South, & Rooftop Gardens North
		{"x0": 48.0, "x1": 90.0, "z0": 24.0, "z1": 52.0, "count": 10},
		# East behind Neon Boulevard & Rooftop Gardens
		{"x0": 176.0, "x1": 240.0, "z0": -125.0, "z1": 135.0, "count": 38},
		# North behind Neon Boulevard
		{"x0": 92.0, "x1": 195.0, "z0": -185.0, "z1": -138.0, "count": 24},
		# South behind Rooftop Gardens
		{"x0": 90.0, "x1": 215.0, "z0": 106.0, "z1": 168.0, "count": 24},
	]
	for zone in infill_zones:
		var count: int = zone["count"]
		for i in range(count):
			var tx := rng.randf_range(zone["x0"], zone["x1"])
			var tz := rng.randf_range(zone["z0"], zone["z1"])
			var tw := rng.randf_range(14.0, 28.0)
			var td := rng.randf_range(14.0, 26.0)
			var th := rng.randf_range(70.0, 165.0)
			var base_y := -48.0
			transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(tw, th, td)), Vector3(tx, base_y + th * 0.5, tz)))
			customs.append(Color(rng.randf(), tw, th, rng.randf()))

	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_custom_data(i, customs[i])
	mmi.multimesh = mm
	add_child(mmi)


func _build_overhead_canyon_bridges() -> void:
	## Dramatic high-altitude architectural sky-bridges crossing the narrow canyon sky strips
	## above Noodle Alley, Market Terraces, Neon Boulevard, and the Maglev rail canyon!
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.58, 0.44, Color("#7A6BB5"), 0.24)
	var strip_amber := Palette.make_emissive_material(Palette.LANTERN_AMBER, 2.1)
	var strip_cyan := Palette.make_emissive_material(Palette.NEON_CYAN, 2.2)
	var strip_mag := Palette.make_emissive_material(Palette.BEACON_MAGENTA, 2.2)

	var body_xforms: Array[Transform3D] = []
	var amber_xforms: Array[Transform3D] = []
	var cyan_xforms: Array[Transform3D] = []
	var mag_xforms: Array[Transform3D] = []

	var bridge_specs := [
		# High sky-bridges over Noodle Alley Main Street (both ends anchored deep inside North & South canyon towers!)
		{"pos": Vector3(-76.0, 20.0, 3.0), "size": Vector3(4.6, 2.6, 26.0), "col": 0},
		{"pos": Vector3(-54.0, 28.0, 3.0), "size": Vector3(4.8, 2.8, 26.0), "col": 1},
		{"pos": Vector3(-108.0, 24.0, 28.0), "size": Vector3(22.0, 2.4, 4.0), "col": 0},
		# High sky-bridges across the Maglev rail canyon (anchored inside North canyon towers & South flanking towers!)
		{"pos": Vector3(-68.0, 24.0, -30.0), "size": Vector3(5.6, 3.0, 42.0), "col": 1},
		{"pos": Vector3(56.0, 26.0, -30.0), "size": Vector3(5.6, 3.0, 42.0), "col": 2},
		# High sky-bridges over Neon Boulevard Canyon (X=104..140 buried inside West & East skyscrapers!)
		{"pos": Vector3(122.0, 20.0, -40.0), "size": Vector3(36.0, 2.8, 4.4), "col": 2},
		{"pos": Vector3(122.0, 29.0, -68.0), "size": Vector3(36.0, 3.2, 4.8), "col": 1},
		{"pos": Vector3(122.0, 19.0, -90.0), "size": Vector3(36.0, 2.6, 4.2), "col": 2},
		{"pos": Vector3(122.0, 38.0, -54.0), "size": Vector3(36.0, 3.4, 5.2), "col": 0},
		# High sky-bridges framing Market Terraces canyon (X=-46..+50 buried inside West & East Market towers!)
		{"pos": Vector3(2.0, 34.0, 30.0), "size": Vector3(96.0, 3.2, 5.0), "col": 0},
		{"pos": Vector3(2.0, 46.0, 46.0), "size": Vector3(96.0, 3.4, 5.2), "col": 1},
	]

	for sp in bridge_specs:
		var pos: Vector3 = sp["pos"]
		var sz: Vector3 = sp["size"]
		body_xforms.append(Transform3D(Basis.IDENTITY.scaled(sz), pos))
		var strip_sz := Vector3(sz.x + 0.15, 0.26, sz.z + 0.15)
		var strip_xf := Transform3D(Basis.IDENTITY.scaled(strip_sz), pos - Vector3(0.0, sz.y * 0.35, 0.0))
		match int(sp["col"]):
			0:
				amber_xforms.append(strip_xf)
			1:
				cyan_xforms.append(strip_xf)
			_:
				mag_xforms.append(strip_xf)

	_commit_box_mmi(self, "OverheadBridgeBodies", body_xforms, steel, 320.0)
	_commit_box_mmi(self, "OverheadBridgeAmber", amber_xforms, strip_amber, 320.0)
	_commit_box_mmi(self, "OverheadBridgeCyan", cyan_xforms, strip_cyan, 320.0)
	_commit_box_mmi(self, "OverheadBridgeMag", mag_xforms, strip_mag, 320.0)


func _build_hazy_fog_floor() -> void:
	## Soft glowing indigo-violet haze floor below the lower city strata so looking down
	## dissolves smoothly into atmospheric mist rather than empty darkness.
	var layers := [
		{"y": -38.0, "col": Color(0.18, 0.13, 0.34, 0.36)},
		{"y": -50.0, "col": Color(0.14, 0.10, 0.28, 0.72)},
		{"y": -64.0, "col": Color(0.10, 0.07, 0.20, 0.96)},
	]
	for idx in range(layers.size()):
		var cfg: Dictionary = layers[idx]
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = cfg["col"]
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

		var mi := MeshInstance3D.new()
		mi.name = "FogFloor_%d" % idx
		var pm := PlaneMesh.new()
		pm.size = Vector2(1400.0, 1400.0)
		mi.mesh = pm
		mi.material_override = mat
		mi.position = Vector3(10.0, float(cfg["y"]), -20.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)


func _commit_box_mmi(parent: Node3D, node_name: String, xforms: Array[Transform3D], mat: Material, vis_end: float) -> void:
	if xforms.is_empty():
		return
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
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
