class_name CityLifeManager
extends Node3D

## Pooled & distance-culled ambient city life rendered via MultiMeshInstance3D:
## 1. Background pedestrians with colorful rain umbrellas strolling every street & plaza.
## 2. Stall vendors tending noodle booths & bazaar canopies.
## 3. Overhead canyon drones & flying vehicles cruising through sky-lanes & lower city strata.
## All pooled into ~7 draw calls total for locked 60 FPS on Medium!

@export var player_path: NodePath
@export var active_pedestrian_radius: float = 115.0

var _player: Node3D = null
var _time: float = 0.0

# Pedestrians (pooled MultiMeshes: coat body, head, umbrella canopy)
var _ped_data: Array[Dictionary] = []
var _ped_body_mmi: MultiMeshInstance3D
var _ped_head_mmi: MultiMeshInstance3D
var _ped_umbrella_mmi: MultiMeshInstance3D

# Vendors at stalls (pooled MultiMeshes: torso/apron + head)
var _vendor_data: Array[Dictionary] = []
var _vendor_body_mmi: MultiMeshInstance3D
var _vendor_head_mmi: MultiMeshInstance3D

# Overhead drones & flying vehicles (hull + glowing light bar)
var _drone_data: Array[Dictionary] = []
var _drone_hull_mmi: MultiMeshInstance3D
var _drone_glow_mmi: MultiMeshInstance3D


func _ready() -> void:
	if not player_path.is_empty():
		_player = get_node_or_null(player_path) as Node3D
	_build_city_life()


func _build_city_life() -> void:
	PropUtils.clear_children(self)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9042026

	_setup_pedestrians(rng)
	_setup_vendors(rng)
	_setup_drones(rng)


func _setup_pedestrians(rng: RandomNumberGenerator) -> void:
	_ped_data.clear()

	# Patrol corridors across every walkable street, alley, plaza, and terrace!
	var routes := [
		# Noodle Alley Main Street (both sidewalks)
		{"a": Vector3(-124.0, 0.0, -2.2), "b": Vector3(-48.0, 0.0, -2.2), "count": 7},
		{"a": Vector3(-122.0, 0.0, 8.2), "b": Vector3(-48.0, 0.0, 8.2), "count": 7},
		# Noodle Alley South Lantern Lane
		{"a": Vector3(-108.0, 0.0, 12.0), "b": Vector3(-108.0, 0.0, 36.0), "count": 4},
		# Noodle Alley Tier 2 Balcony
		{"a": Vector3(-120.0, 5.0, 10.2), "b": Vector3(-58.0, 5.0, 10.2), "count": 3},
		# Maglev Promenade
		{"a": Vector3(-104.0, 0.0, -14.5), "b": Vector3(-88.0, 0.0, -14.5), "count": 3},
		{"a": Vector3(-28.0, 0.0, -14.0), "b": Vector3(28.0, 0.0, -14.0), "count": 5},
		# Market Terraces Tier 1, Tier 2, Tier 3
		{"a": Vector3(-30.0, 0.0, 2.0), "b": Vector3(32.0, 0.0, 2.0), "count": 6},
		{"a": Vector3(-28.0, 0.0, 14.0), "b": Vector3(28.0, 0.0, 14.0), "count": 5},
		{"a": Vector3(-28.0, 5.0, 36.0), "b": Vector3(28.0, 5.0, 36.0), "count": 5},
		{"a": Vector3(-26.0, 10.0, 62.0), "b": Vector3(26.0, 10.0, 62.0), "count": 4},
		# Neon Gate Connector & Neon South Station Plaza
		{"a": Vector3(44.0, 0.0, -2.0), "b": Vector3(84.0, 0.0, -2.0), "count": 4},
		{"a": Vector3(76.0, 0.0, -10.0), "b": Vector3(128.0, 0.0, -10.0), "count": 5},
		# Neon Boulevard Main Canyon (West & East sidewalks at X=112 and X=132)
		{"a": Vector3(112.0, 0.0, -22.0), "b": Vector3(112.0, 0.0, -102.0), "count": 8},
		{"a": Vector3(132.0, 0.0, -22.0), "b": Vector3(132.0, 0.0, -102.0), "count": 8},
		# Neon Boulevard Overpass Tier 2
		{"a": Vector3(122.0, 7.0, -34.0), "b": Vector3(122.0, 7.0, -90.0), "count": 4},
		# Synth Alley East Branch
		{"a": Vector3(138.0, 0.0, -66.0), "b": Vector3(160.0, 0.0, -66.0), "count": 3},
		# Rooftop Gardens Tiers 14m & 19m
		{"a": Vector3(104.0, 14.0, 44.0), "b": Vector3(162.0, 14.0, 44.0), "count": 4},
		{"a": Vector3(126.0, 19.0, 58.0), "b": Vector3(162.0, 19.0, 58.0), "count": 3},
	]

	var coat_colors := [
		Color("#25223D"), Color("#3D2B4F"), Color("#2E3E59"),
		Color("#5E383B"), Color("#3B5252"), Color("#4A3D33")
	]
	var umbrella_colors := [
		Color("#E8A44A"), Color("#D96259"), Color("#4BB8B0"),
		Color("#F0DFC2"), Color("#C97AE0"), Color("#6394E0")
	]

	for r in routes:
		var a: Vector3 = r["a"]
		var b: Vector3 = r["b"]
		var cnt: int = r["count"]
		var dir := (b - a)
		var perp := Vector3(-dir.z, 0.0, dir.x).normalized()
		for i in range(cnt):
			var lane_off := rng.randf_range(-1.4, 1.4)
			var forward_dir := 1.0 if (i % 2 == 0) else -1.0
			_ped_data.append({
				"a": a + perp * lane_off,
				"b": b + perp * lane_off,
				"t": rng.randf(),
				"dir": forward_dir,
				"speed": rng.randf_range(1.25, 2.05) / maxf(a.distance_to(b), 2.0),
				"phase": rng.randf_range(0.0, TAU),
				"height_scale": rng.randf_range(0.92, 1.08),
				"coat_col": coat_colors[rng.randi() % coat_colors.size()],
				"umb_col": umbrella_colors[rng.randi() % umbrella_colors.size()],
			})

	var total := _ped_data.size()

	# Coat/body capsule MultiMesh
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.24
	body_mesh.height = 1.25
	body_mesh.radial_segments = 8
	body_mesh.rings = 3
	var body_mat := StandardMaterial3D.new()
	body_mat.vertex_color_use_as_albedo = true
	body_mat.roughness = 0.82
	body_mat.rim_enabled = true
	body_mat.rim = 0.25
	body_mesh.material = body_mat
	_ped_body_mmi = _create_colored_mmi("PedestrianBodies", body_mesh, total, 130.0)

	# Head sphere MultiMesh
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.16
	head_mesh.height = 0.32
	head_mesh.radial_segments = 8
	head_mesh.rings = 4
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color("#DFB89B")
	head_mat.roughness = 0.72
	head_mesh.material = head_mat
	_ped_head_mmi = _create_colored_mmi("PedestrianHeads", head_mesh, total, 115.0)

	# Stylized rain umbrella dome (flattened cone!) with subtle warm translucency
	var umb_mesh := CylinderMesh.new()
	umb_mesh.top_radius = 0.05
	umb_mesh.bottom_radius = 0.62
	umb_mesh.height = 0.26
	umb_mesh.radial_segments = 8
	var umb_mat := StandardMaterial3D.new()
	umb_mat.vertex_color_use_as_albedo = true
	umb_mat.roughness = 0.42
	umb_mat.emission_enabled = true
	umb_mat.emission = Color(0.28, 0.22, 0.32)
	umb_mat.emission_energy_multiplier = 0.35
	umb_mesh.material = umb_mat
	_ped_umbrella_mmi = _create_colored_mmi("PedestrianUmbrellas", umb_mesh, total, 135.0)

	for i in range(total):
		_ped_body_mmi.multimesh.set_instance_color(i, _ped_data[i]["coat_col"])
		_ped_head_mmi.multimesh.set_instance_color(i, Color.WHITE)
		_ped_umbrella_mmi.multimesh.set_instance_color(i, _ped_data[i]["umb_col"])

	_update_pedestrians(0.0, true)


func _setup_vendors(rng: RandomNumberGenerator) -> void:
	_vendor_data.clear()
	# Positioned snugly behind the food stalls and market canopies
	var spots := [
		{"pos": Vector3(-114.0, 0.0, 9.6), "yaw": PI},
		{"pos": Vector3(-76.0, 0.0, 9.6), "yaw": PI},
		{"pos": Vector3(-108.0, 0.0, 35.8), "yaw": PI},
		{"pos": Vector3(-18.0, 0.0, 4.4), "yaw": 0.35},
		{"pos": Vector3(16.0, 0.0, 4.4), "yaw": -0.35},
		{"pos": Vector3(-22.0, 0.0, 16.0), "yaw": PI * 0.5},
		{"pos": Vector3(20.0, 0.0, 16.0), "yaw": -PI * 0.5},
		{"pos": Vector3(-16.0, 5.0, 39.4), "yaw": PI},
		{"pos": Vector3(16.0, 5.0, 39.4), "yaw": PI},
		{"pos": Vector3(0.0, 10.0, 68.5), "yaw": PI},
		{"pos": Vector3(148.0, 14.0, 45.4), "yaw": PI},
		{"pos": Vector3(150.0, 24.0, 75.5), "yaw": PI},
	]

	for s in spots:
		_vendor_data.append({
			"pos": s["pos"],
			"yaw": float(s["yaw"]),
			"phase": rng.randf_range(0.0, TAU),
		})

	var total := _vendor_data.size()
	var torso := CapsuleMesh.new()
	torso.radius = 0.25
	torso.height = 1.24
	torso.radial_segments = 8
	torso.rings = 3
	torso.material = Palette.make_stylized_material(Color("#D69B4F"), 0.78, 0.0, Color("#FFE2B0"), 0.28)
	_vendor_body_mmi = _create_colored_mmi("VendorBodies", torso, total, 110.0)

	var head := SphereMesh.new()
	head.radius = 0.165
	head.height = 0.33
	head.radial_segments = 8
	head.rings = 4
	head.material = Palette.make_flat_material(Color("#E6C0A2"), 0.72)
	_vendor_head_mmi = _create_colored_mmi("VendorHeads", head, total, 105.0)
	_update_vendors()


func _setup_drones(rng: RandomNumberGenerator) -> void:
	_drone_data.clear()

	# Canyon sky-lanes & lower city flying traffic!
	var lanes := [
		# Above Noodle Alley canyon
		{"a": Vector3(-160.0, 16.0, 2.0), "b": Vector3(150.0, 16.0, 2.0), "count": 5, "scale": Vector3(1.1, 0.55, 2.4)},
		{"a": Vector3(150.0, 24.0, -26.0), "b": Vector3(-160.0, 24.0, -26.0), "count": 6, "scale": Vector3(1.4, 0.65, 3.2)},
		# Along Neon Boulevard sky canyon (X=116..128)
		{"a": Vector3(118.0, 17.5, -135.0), "b": Vector3(118.0, 17.5, 45.0), "count": 6, "scale": Vector3(1.0, 0.5, 2.2)},
		{"a": Vector3(126.0, 26.0, 55.0), "b": Vector3(126.0, 26.0, -135.0), "count": 5, "scale": Vector3(1.3, 0.6, 2.9)},
		# Lower city flying cars visible below promenade railings!
		{"a": Vector3(-175.0, -14.5, -34.0), "b": Vector3(165.0, -14.5, -34.0), "count": 8, "scale": Vector3(1.5, 0.6, 3.4)},
		{"a": Vector3(165.0, -17.0, -44.0), "b": Vector3(-175.0, -17.0, -44.0), "count": 8, "scale": Vector3(1.5, 0.6, 3.4)},
		# Delivery drones hovering gently near Market Terraces & Rooftop Gardens
		{"a": Vector3(-40.0, 19.0, 32.0), "b": Vector3(170.0, 29.0, 64.0), "count": 5, "scale": Vector3(0.85, 0.4, 1.3)},
	]

	var glow_cols := [Palette.NEON_CYAN, Palette.LANTERN_AMBER, Palette.BEACON_MAGENTA, Palette.LANDMARK_TEAL]
	for lane in lanes:
		var a: Vector3 = lane["a"]
		var b: Vector3 = lane["b"]
		var cnt: int = lane["count"]
		var dist := maxf(a.distance_to(b), 10.0)
		for i in range(cnt):
			_drone_data.append({
				"a": a + Vector3(0.0, rng.randf_range(-1.8, 1.8), rng.randf_range(-2.0, 2.0)),
				"b": b + Vector3(0.0, rng.randf_range(-1.8, 1.8), rng.randf_range(-2.0, 2.0)),
				"t": float(i) / float(cnt) + rng.randf_range(0.0, 0.08),
				"speed": rng.randf_range(11.0, 20.0) / dist,
				"bob_phase": rng.randf_range(0.0, TAU),
				"scale": lane["scale"],
				"col": glow_cols[rng.randi() % glow_cols.size()],
			})

	var total := _drone_data.size()
	var hull_box := BoxMesh.new()
	hull_box.size = Vector3.ONE
	hull_box.material = Palette.make_stylized_material(Color("#241F3D"), 0.45, 0.55, Color("#9B8CE0"), 0.35)
	_drone_hull_mmi = _create_colored_mmi("OverheadDroneHulls", hull_box, total, 260.0)

	var glow_box := BoxMesh.new()
	glow_box.size = Vector3(1.06, 0.35, 1.04)
	var gmat := StandardMaterial3D.new()
	gmat.vertex_color_use_as_albedo = true
	gmat.emission_enabled = true
	gmat.emission = Color.WHITE
	gmat.emission_energy_multiplier = 2.6
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_box.material = gmat
	_drone_glow_mmi = _create_colored_mmi("OverheadDroneGlows", glow_box, total, 280.0)

	for i in range(total):
		_drone_hull_mmi.multimesh.set_instance_color(i, Color.WHITE)
		_drone_glow_mmi.multimesh.set_instance_color(i, _drone_data[i]["col"])

	_update_drones(0.0)


func _create_colored_mmi(node_name: String, mesh: Mesh, count: int, vis_end: float) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = vis_end
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = count
	mmi.multimesh = mm
	add_child(mmi)
	return mmi


func _process(delta: float) -> void:
	_time += delta
	_update_pedestrians(delta, false)
	_update_vendors()
	_update_drones(delta)


func _update_pedestrians(delta: float, force_all: bool) -> void:
	if _ped_body_mmi == null:
		return
	var ppos := _player.global_position if is_instance_valid(_player) else Vector3.ZERO
	var body_mm := _ped_body_mmi.multimesh
	var head_mm := _ped_head_mmi.multimesh
	var umb_mm := _ped_umbrella_mmi.multimesh
	var cull_sq := active_pedestrian_radius * active_pedestrian_radius

	for i in range(_ped_data.size()):
		var pd := _ped_data[i]
		pd["t"] = float(pd["t"]) + float(pd["dir"]) * float(pd["speed"]) * delta
		if float(pd["t"]) >= 1.0:
			pd["t"] = 1.0
			pd["dir"] = -1.0
		elif float(pd["t"]) <= 0.0:
			pd["t"] = 0.0
			pd["dir"] = 1.0

		var pos: Vector3 = (pd["a"] as Vector3).lerp(pd["b"] as Vector3, float(pd["t"]))
		if not force_all and is_instance_valid(_player):
			var d_sq := Vector2(pos.x - ppos.x, pos.z - ppos.z).length_squared()
			if d_sq > cull_sq:
				# Park far-away pedestrians collapsed at zero scale to skip transform work & GPU fill
				var zero_xf := Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), pos)
				body_mm.set_instance_transform(i, zero_xf)
				head_mm.set_instance_transform(i, zero_xf)
				umb_mm.set_instance_transform(i, zero_xf)
				continue

		var walk_dir: Vector3 = ((pd["b"] as Vector3) - (pd["a"] as Vector3)) * float(pd["dir"])
		var yaw := atan2(-walk_dir.x, -walk_dir.z)
		var hs: float = pd["height_scale"]
		var bob := absf(sin(_time * 6.4 + float(pd["phase"]))) * 0.055
		var sway := sin(_time * 3.2 + float(pd["phase"])) * 0.045
		var rot_b := Basis(Vector3.UP, yaw) * Basis(Vector3.FORWARD, sway)

		body_mm.set_instance_transform(i, Transform3D(rot_b.scaled(Vector3(1.0, hs, 1.0)), pos + Vector3(0.0, 0.72 * hs + bob, 0.0)))
		head_mm.set_instance_transform(i, Transform3D(rot_b, pos + Vector3(0.0, 1.54 * hs + bob, 0.0)))
		var umb_rot := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, 0.14) * Basis(Vector3.FORWARD, sway * 1.4)
		umb_mm.set_instance_transform(i, Transform3D(umb_rot, pos + Vector3(0.0, 1.98 * hs + bob * 1.1, 0.0)))


func _update_vendors() -> void:
	if _vendor_body_mmi == null:
		return
	var body_mm := _vendor_body_mmi.multimesh
	var head_mm := _vendor_head_mmi.multimesh
	for i in range(_vendor_data.size()):
		var vd := _vendor_data[i]
		var pos: Vector3 = vd["pos"]
		var yaw: float = vd["yaw"]
		var sway := sin(_time * 1.6 + float(vd["phase"])) * 0.06
		var rot_b := Basis(Vector3.UP, yaw + sway)
		body_mm.set_instance_transform(i, Transform3D(rot_b, pos + Vector3(0.0, 0.72, 0.0)))
		head_mm.set_instance_transform(i, Transform3D(rot_b, pos + Vector3(0.0, 1.54 + sin(_time * 2.4 + float(vd["phase"])) * 0.02, 0.0)))


func _update_drones(delta: float) -> void:
	if _drone_hull_mmi == null:
		return
	var hull_mm := _drone_hull_mmi.multimesh
	var glow_mm := _drone_glow_mmi.multimesh
	for i in range(_drone_data.size()):
		var dd := _drone_data[i]
		var t := fmod(float(dd["t"]) + float(dd["speed"]) * delta, 1.0)
		dd["t"] = t
		var a: Vector3 = dd["a"]
		var b: Vector3 = dd["b"]
		var pos := a.lerp(b, t)
		pos.y += sin(_time * 1.8 + float(dd["bob_phase"])) * 0.35
		var dir := (b - a).normalized()
		var yaw := atan2(-dir.x, -dir.z)
		var sc: Vector3 = dd["scale"]
		var rot_b := Basis(Vector3.UP, yaw).scaled(sc)
		hull_mm.set_instance_transform(i, Transform3D(rot_b, pos))
		glow_mm.set_instance_transform(i, Transform3D(rot_b, pos))
