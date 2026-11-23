@tool
class_name SkylineBuilder
extends Node3D

## Builds the planet-wide Lattice megastructure skyline using MultiMeshInstance3D
## depth rings in deep indigo-violet twilight haze, colossal distant sky-bridges,
## sweeping volumetric searchlights, and the glowing teal landmark tower.

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
var _traffic_mmi: MultiMeshInstance3D
var _traffic_data: Array[Dictionary] = []
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

	if _traffic_mmi != null and _traffic_mmi.multimesh != null:
		var mm := _traffic_mmi.multimesh
		for i in range(_traffic_data.size()):
			var td := _traffic_data[i]
			var angle: float = td["angle"] + td["speed"] * _time
			var radius: float = td["radius"]
			var y: float = td["y"]
			var pos := Vector3(cos(angle) * radius, y, sin(angle) * radius)
			var tangent := angle + (PI * 0.5 if td["speed"] >= 0.0 else -PI * 0.5)
			var b := Basis(Vector3.UP, -tangent).scaled(td["scale"])
			mm.set_instance_transform(i, Transform3D(b, pos))


func _rebuild() -> void:
	PropUtils.clear_children(self)
	_searchlight_pivots.clear()
	_searchlight_phases.clear()
	_searchlight_speeds.clear()
	_searchlight_base_rots.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = city_seed

	var window_shader: Shader = load("res://shaders/skyline_windows.gdshader")

	# 1. Near Canyon Megastructures (360° surrounding the dense urban fabric)
	_build_tower_layer(
		"NearTowers",
		window_shader,
		rng,
		155,
		225.0, 345.0,
		Vector2(16.0, 32.0),
		Vector2(85.0, 175.0),
		Vector2(-95.0, -35.0),
		2.00, 0.58, 0.90, 0.12,
		Color("#15102B"), Color("#231B45")
	)

	# 2. Mid Skyline Ring (360° taller towers, warm amber + teal windows, indigo-violet haze)
	_build_tower_layer(
		"MidTowers",
		window_shader,
		rng,
		190,
		350.0, 535.0,
		Vector2(22.0, 44.0),
		Vector2(130.0, 285.0),
		Vector2(-125.0, -55.0),
		1.65, 0.54, 0.72, 0.34,
		Color("#120E26"), Color("#201842")
	)

	# 3. Far Colossus Monoliths
	_build_tower_layer(
		"ColossusTowers",
		window_shader,
		rng,
		115,
		545.0, 860.0,
		Vector2(42.0, 86.0),
		Vector2(250.0, 520.0),
		Vector2(-190.0, -90.0),
		1.25, 0.46, 0.58, 0.62,
		Color("#0F0B21"), Color("#1D163C")
	)

	# 4. Massive Horizontal Lattice Sky-Bridges spanning between distant megastructures
	_build_sky_bridges(rng)

	# 5. Hero Glowing Teal Landmark Tower with Magenta Beacon framed cleanly down the -Z canyon!
	var landmark := LANDMARK_SCENE.instantiate()
	landmark.name = "HeroLandmarkTower"
	landmark.position = Vector3(18.0, -48.0, -285.0)
	landmark.rotation_degrees = Vector3(0.0, -18.0, 0.0)
	add_child(landmark)

	# 6. Sweeping Volumetric Searchlight Beams rising behind the midground skyline
	_build_searchlights()

	# 7. Distant Moving Sky-Trains & Flying Vehicles (MultiMeshInstance3D)
	_build_distant_traffic(rng)

	# 8. Subtle Atmospheric Violet-Indigo Mist Ribbons between depth layers
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
	mat.set_shader_parameter("haze_color", Color("#221942"))
	mat.set_shader_parameter("emission_boost", emission_boost)
	mat.set_shader_parameter("window_density", window_density)
	mat.set_shader_parameter("window_scale", window_scale)
	mat.set_shader_parameter("layer_haze", layer_haze)
	mmi.material_override = mat

	var transforms: Array[Transform3D] = []
	var customs: Array[Color] = []

	for i in range(count):
		var angle := 0.0
		if i < int(count * 0.42):
			angle = rng.randf_range(-PI * 0.90, -PI * 0.10)
		else:
			angle = rng.randf_range(0.0, TAU)

		var dist := rng.randf_range(min_dist, max_dist)
		var x := cos(angle) * dist
		var z := sin(angle) * dist

		var to_landmark := Vector2(x - 18.0, z - (-285.0)).length()
		if to_landmark < 38.0:
			continue
		if absf(x) < 215.0 and absf(z) < 160.0:
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

	var steel_far := Palette.make_stylized_material(Color("#1A1436"), 0.85, 0.15, Color("#5E4D99"), 0.25)
	var strip_warm := Palette.make_emissive_material(Palette.WINDOW_WARM_A, 1.65)
	var strip_teal := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 1.95)

	var specs := [
		{"pos": Vector3(-55.0, 48.0, -165.0), "size": Vector3(155.0, 5.5, 8.0), "rot": Vector3(0.0, 14.0, 0.0), "teal": false},
		{"pos": Vector3(88.0, 68.0, -215.0), "size": Vector3(175.0, 6.8, 9.0), "rot": Vector3(0.0, -19.0, 4.0), "teal": true},
		{"pos": Vector3(-115.0, 92.0, -260.0), "size": Vector3(210.0, 8.5, 11.0), "rot": Vector3(0.0, 22.0, -6.0), "teal": false},
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

	var _unused := rng.randf()


func _build_searchlights() -> void:
	var holder := Node3D.new()
	holder.name = "Searchlights"
	add_child(holder)

	var beam_shader: Shader = load("res://shaders/searchlight_beam.gdshader")
	var configs := [
		{"pos": Vector3(-24.0, -18.0, -152.0), "rot": Vector3(6.0, 0.0, 18.0), "len": 250.0, "r_top": 20.0, "speed": 0.24, "phase": 0.4, "col": Color("#FFF1CF")},
		{"pos": Vector3(72.0, -20.0, -190.0), "rot": Vector3(8.0, 0.0, -21.0), "len": 280.0, "r_top": 24.0, "speed": 0.19, "phase": 2.1, "col": Color("#FFD6E8")},
		{"pos": Vector3(-92.0, -16.0, -205.0), "rot": Vector3(5.0, 0.0, -12.0), "len": 265.0, "r_top": 22.0, "speed": 0.22, "phase": 4.2, "col": Color("#B8EFEA")},
		{"pos": Vector3(8.0, -25.0, -225.0), "rot": Vector3(-4.0, 0.0, 12.0), "len": 300.0, "r_top": 26.0, "speed": 0.16, "phase": 1.3, "col": Color("#FFF3D4")},
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
		cyl.radial_segments = 16
		cyl.cap_top = false
		cyl.cap_bottom = false

		var mat := ShaderMaterial.new()
		mat.shader = beam_shader
		mat.set_shader_parameter("beam_color", cfg["col"])
		mat.set_shader_parameter("intensity", 0.22)
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


func _build_distant_traffic(rng: RandomNumberGenerator) -> void:
	_traffic_data.clear()
	_traffic_mmi = MultiMeshInstance3D.new()
	_traffic_mmi.name = "DistantSkyTraffic"
	_traffic_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 1.0, 1.0)
	box.material = Palette.make_emissive_material(Palette.LANTERN_AMBER, 2.6)
	mm.mesh = box

	var total := 44
	mm.instance_count = total
	for i in range(total):
		var is_train := i < 12
		_traffic_data.append({
			"angle": rng.randf_range(0.0, TAU),
			"radius": rng.randf_range(235.0, 460.0),
			"y": rng.randf_range(-10.0, 85.0),
			"speed": rng.randf_range(0.018, 0.045) * (1.0 if i % 2 == 0 else -1.0),
			"scale": Vector3(1.2, 0.9, 14.0) if is_train else Vector3(0.7, 0.45, 2.4),
		})
	_traffic_mmi.multimesh = mm
	add_child(_traffic_mmi)


func _build_haze_layers() -> void:
	var haze_root := Node3D.new()
	haze_root.name = "AtmosphericHazeLayers"
	add_child(haze_root)

	var haze_tex := _make_vertical_haze_texture()
	var ring_specs := [
		{"radius": 240.0, "height": 260.0, "y": 40.0, "col": Color(0.18, 0.13, 0.34, 0.24)},
		{"radius": 390.0, "height": 360.0, "y": 65.0, "col": Color(0.16, 0.12, 0.32, 0.30)},
	]
	for spec in ring_specs:
		var cyl := CylinderMesh.new()
		cyl.top_radius = spec["radius"]
		cyl.bottom_radius = spec["radius"]
		cyl.height = spec["height"]
		cyl.radial_segments = 32
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
		var alpha := smoothstep(0.0, 0.25, v) * (1.0 - smoothstep(0.38, 1.0, v))
		for x in range(4):
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(img)
