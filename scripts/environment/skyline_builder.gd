@tool
class_name SkylineBuilder
extends Node3D

## Builds the planet-wide Lattice megastructure skyline using MultiMeshInstance3D
## depth rings, colossal distant sky-bridges, sweeping volumetric searchlights,
## layered haze bands, and the glowing teal landmark tower.

const LANDMARK_SCENE := preload("res://scenes/environment/landmark_tower.tscn")

@export var city_seed: int = 472026:
	set(v):
		city_seed = v
		if is_inside_tree():
			_rebuild()

var _searchlight_pivots: Array[Node3D] = []
var _searchlight_phases: Array[float] = []
var _searchlight_speeds: Array[float] = []
var _searchlight_base_rots: Array[Vector3] = []
var _time: float = 0.0


func _ready() -> void:
	_rebuild()


func _process(delta: float) -> void:
	_time += delta
	for i in range(_searchlight_pivots.size()):
		var p := _searchlight_pivots[i]
		if is_instance_valid(p):
			var base_rot := _searchlight_base_rots[i]
			var sweep := sin(_time * _searchlight_speeds[i] + _searchlight_phases[i]) * 14.0
			var tilt := cos(_time * _searchlight_speeds[i] * 0.65 + _searchlight_phases[i]) * 5.0
			p.rotation_degrees = Vector3(base_rot.x + tilt, base_rot.y, base_rot.z + sweep)


func _rebuild() -> void:
	PropUtils.clear_children(self)
	_searchlight_pivots.clear()
	_searchlight_phases.clear()
	_searchlight_speeds.clear()
	_searchlight_base_rots.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = city_seed

	var window_shader: Shader = load("res://shaders/skyline_windows.gdshader")

	# 1. Near Canyon Megastructures (crisp warm windows, surrounds the walkway canyon)
	_build_tower_layer(
		"NearTowers",
		window_shader,
		rng,
		115,
		54.0, 128.0,
		Vector2(10.0, 24.0),
		Vector2(52.0, 138.0),
		Vector2(-85.0, -32.0),
		1.85, 0.54, 0.92, 0.06,
		Color("#10162B"), Color("#192240")
	)

	# 2. Mid Skyline Ring (taller towers, denser tiny windows, soft indigo haze)
	_build_tower_layer(
		"MidTowers",
		window_shader,
		rng,
		165,
		135.0, 275.0,
		Vector2(16.0, 36.0),
		Vector2(95.0, 240.0),
		Vector2(-115.0, -55.0),
		1.55, 0.50, 0.72, 0.28,
		Color("#0C1226"), Color("#17203F")
	)

	# 3. Far Colossus Monoliths (planet-wide Lattice megastructures fading into indigo mist)
	_build_tower_layer(
		"ColossusTowers",
		window_shader,
		rng,
		105,
		285.0, 560.0,
		Vector2(34.0, 74.0),
		Vector2(210.0, 480.0),
		Vector2(-180.0, -90.0),
		1.15, 0.44, 0.56, 0.58,
		Color("#0A0F22"), Color("#161E3B")
	)

	# 4. Abyssal Lower Strata (visible when peering over the promenade railing!)
	_build_tower_layer(
		"AbyssTowers",
		window_shader,
		rng,
		55,
		22.0, 78.0,
		Vector2(9.0, 20.0),
		Vector2(45.0, 82.0),
		Vector2(-102.0, -92.0),
		1.25, 0.46, 0.80, 0.34,
		Color("#090E1E"), Color("#131B34")
	)

	# 5. Massive Horizontal Lattice Sky-Bridges spanning between distant megastructures
	_build_sky_bridges(rng)

	# 6. Hero Glowing Teal Landmark Tower with Magenta Beacon (framed cleanly in the -Z vista!)
	var landmark := LANDMARK_SCENE.instantiate()
	landmark.name = "HeroLandmarkTower"
	landmark.position = Vector3(26.0, -48.0, -172.0)
	landmark.rotation_degrees = Vector3(0.0, -18.0, 0.0)
	add_child(landmark)

	# 7. Sweeping Volumetric Searchlight Beams rising behind the midground skyline
	_build_searchlights()

	# 8. Subtle Atmospheric Mist Ribbons between depth layers
	_build_haze_layers()


func _build_tower_layer(
	layer_name: String,
	shader: Shader,
	rng: RandomNumberGenerator,
	count: int,
	min_dist: float,
	max_dist: float,
	width_range: Vector2,
	height_range: Vector2,
	base_y_range: Vector2,
	emission_boost: float,
	window_density: float,
	window_scale: float,
	layer_haze: float,
	dark_col: Color,
	mid_col: Color
) -> void:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = layer_name
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true

	var box := BoxMesh.new()
	box.size = Vector3.ONE
	mm.mesh = box

	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("tower_dark", dark_col)
	mat.set_shader_parameter("tower_mid", mid_col)
	mat.set_shader_parameter("emission_boost", emission_boost)
	mat.set_shader_parameter("window_density", window_density)
	mat.set_shader_parameter("window_scale", window_scale)
	mat.set_shader_parameter("layer_haze", layer_haze)
	mmi.material_override = mat

	var transforms: Array[Transform3D] = []
	var customs: Array[Color] = []

	for i in range(count):
		# Concentrate ~65% of skyline density in the sweeping -Z vista arc, rest all around 360°
		var angle := 0.0
		if i < int(count * 0.65):
			angle = rng.randf_range(-PI * 0.88, -PI * 0.12)
		else:
			angle = rng.randf_range(0.0, TAU)

		var dist := rng.randf_range(min_dist, max_dist)
		var x := cos(angle) * dist
		var z := sin(angle) * dist

		# Keep a clean viewing corridor right in front of the Hero Landmark Tower!
		if layer_name != "AbyssTowers":
			var to_landmark := Vector2(x - 26.0, z - (-172.0)).length()
			if to_landmark < 34.0:
				continue
			# Also keep clear of the playable promenade footprint itself
			if absf(x) < 34.0 and z > -18.0 and z < 28.0:
				continue

		var w := rng.randf_range(width_range.x, width_range.y)
		var d := w * rng.randf_range(0.72, 1.32)
		var h := rng.randf_range(height_range.x, height_range.y)
		var base_y := rng.randf_range(base_y_range.x, base_y_range.y)
		var yaw := rng.randf_range(0.0, PI * 0.5)

		var b := Basis(Vector3.UP, yaw).scaled(Vector3(w, h, d))
		var pos := Vector3(x, base_y + h * 0.5, z)
		transforms.append(Transform3D(b, pos))
		customs.append(Color(rng.randf(), w, h, rng.randf()))

	mm.instance_count = transforms.size()
	for idx in range(transforms.size()):
		mm.set_instance_transform(idx, transforms[idx])
		mm.set_instance_custom_data(idx, customs[idx])

	mmi.multimesh = mm
	add_child(mmi)


func _build_sky_bridges(rng: RandomNumberGenerator) -> void:
	var bridges := Node3D.new()
	bridges.name = "MegastructureBridges"
	add_child(bridges)

	var steel_far := Palette.make_stylized_material(Color("#121933"), 0.85, 0.15, Color("#3E548A"), 0.25)
	var strip_warm := Palette.make_emissive_material(Palette.WINDOW_WARM_A, 1.55)
	var strip_teal := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 1.85)

	var specs := [
		{"pos": Vector3(-55.0, 28.0, -145.0), "size": Vector3(135.0, 5.2, 7.5), "rot": Vector3(0.0, 14.0, 0.0), "teal": false},
		{"pos": Vector3(88.0, 56.0, -210.0), "size": Vector3(175.0, 6.8, 9.0), "rot": Vector3(0.0, -19.0, 4.0), "teal": true},
		{"pos": Vector3(-115.0, 82.0, -260.0), "size": Vector3(210.0, 8.5, 11.0), "rot": Vector3(0.0, 22.0, -6.0), "teal": false},
		{"pos": Vector3(12.0, -26.0, -92.0), "size": Vector3(120.0, 4.2, 6.5), "rot": Vector3(0.0, -8.0, 0.0), "teal": true},
		{"pos": Vector3(-140.0, 12.0, -35.0), "size": Vector3(150.0, 5.5, 7.5), "rot": Vector3(0.0, 74.0, 0.0), "teal": false},
	]

	for spec in specs:
		var holder := Node3D.new()
		holder.position = spec["pos"]
		holder.rotation_degrees = spec["rot"]
		bridges.add_child(holder)
		var sz: Vector3 = spec["size"]
		var body := PropUtils.add_box(holder, sz, Vector3.ZERO, steel_far)
		body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var smat := strip_teal if spec["teal"] else strip_warm
		var strip := PropUtils.add_box(holder, Vector3(sz.x * 0.94, 0.55, sz.z + 0.3), Vector3(0.0, 0.4, 0.0), smat)
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Avoid unused rng warning
	var _unused := rng.randf()


func _build_searchlights() -> void:
	var holder := Node3D.new()
	holder.name = "Searchlights"
	add_child(holder)

	var beam_shader: Shader = load("res://shaders/searchlight_beam.gdshader")
	var configs := [
		{"pos": Vector3(-24.0, -22.0, -152.0), "rot": Vector3(6.0, 0.0, 18.0), "len": 250.0, "r_top": 20.0, "speed": 0.24, "phase": 0.4, "col": Color("#FFF1CF")},
		{"pos": Vector3(72.0, -25.0, -190.0), "rot": Vector3(8.0, 0.0, -21.0), "len": 280.0, "r_top": 24.0, "speed": 0.19, "phase": 2.1, "col": Color("#F5E7C4")},
		{"pos": Vector3(-92.0, -18.0, -205.0), "rot": Vector3(5.0, 0.0, -12.0), "len": 265.0, "r_top": 22.0, "speed": 0.22, "phase": 4.2, "col": Color("#B8EFEA")},
		{"pos": Vector3(8.0, -35.0, -225.0), "rot": Vector3(-4.0, 0.0, 12.0), "len": 300.0, "r_top": 26.0, "speed": 0.16, "phase": 1.3, "col": Color("#FFF3D4")},
	]

	for cfg in configs:
		var pivot := Node3D.new()
		pivot.position = cfg["pos"]
		pivot.rotation_degrees = cfg["rot"]
		holder.add_child(pivot)

		var beam_len: float = cfg["len"]
		var cyl := CylinderMesh.new()
		cyl.bottom_radius = 1.8
		cyl.top_radius = cfg["r_top"]
		cyl.height = beam_len
		cyl.radial_segments = 20
		cyl.cap_top = false
		cyl.cap_bottom = false

		var mat := ShaderMaterial.new()
		mat.shader = beam_shader
		mat.set_shader_parameter("beam_color", cfg["col"])
		mat.set_shader_parameter("intensity", 0.21)
		mat.set_shader_parameter("edge_softness", 2.35)
		mat.set_shader_parameter("beam_height", beam_len)

		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.material_override = mat
		mi.position = Vector3(0.0, beam_len * 0.5, 0.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pivot.add_child(mi)

		_searchlight_pivots.append(pivot)
		_searchlight_base_rots.append(cfg["rot"])
		_searchlight_speeds.append(cfg["speed"])
		_searchlight_phases.append(cfg["phase"])


func _build_haze_layers() -> void:
	# Soft translucent painterly haze veils in the abyss below and between skyline depth rings
	var haze_root := Node3D.new()
	haze_root.name = "AtmosphericHazeLayers"
	add_child(haze_root)

	var abyss_mat := StandardMaterial3D.new()
	abyss_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	abyss_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	abyss_mat.albedo_color = Color(0.09, 0.12, 0.25, 0.56)
	abyss_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

	var abyss_plane := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1100.0, 1100.0)
	abyss_plane.mesh = pm
	abyss_plane.material_override = abyss_mat
	abyss_plane.position = Vector3(0.0, -56.0, -120.0)
	abyss_plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	haze_root.add_child(abyss_plane)

	# Vertical gradient mist curtains between Near/Mid and Mid/Colossus rings
	var haze_tex := _make_vertical_haze_texture()
	var ring_specs := [
		{"radius": 130.0, "height": 220.0, "y": 24.0, "col": Color(0.11, 0.145, 0.30, 0.22)},
		{"radius": 278.0, "height": 340.0, "y": 52.0, "col": Color(0.12, 0.155, 0.32, 0.28)},
	]
	for spec in ring_specs:
		var cyl := CylinderMesh.new()
		cyl.top_radius = spec["radius"]
		cyl.bottom_radius = spec["radius"]
		cyl.height = spec["height"]
		cyl.radial_segments = 36
		cyl.cap_top = false
		cyl.cap_bottom = false

		var cmat := StandardMaterial3D.new()
		cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cmat.cull_mode = BaseMaterial3D.CULL_DISABLED
		cmat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		cmat.albedo_color = spec["col"]
		cmat.albedo_texture = haze_tex

		var ring := MeshInstance3D.new()
		ring.mesh = cyl
		ring.material_override = cmat
		ring.position = Vector3(0.0, spec["y"], 0.0)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		haze_root.add_child(ring)


func _make_vertical_haze_texture() -> ImageTexture:
	var h := 64
	var img := Image.create(4, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var v := float(y) / float(h - 1)
		# Dense in the lower/mid city strata, fading smoothly toward the night zenith
		var alpha := smoothstep(0.0, 0.25, v) * (1.0 - smoothstep(0.35, 1.0, v))
		for x in range(4):
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(img)
