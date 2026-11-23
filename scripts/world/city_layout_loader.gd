class_name CityLayoutLoader
extends Node3D

## Reads data/city_layout.json and assembles the enclosed multi-district street-canyon
## city hub from scenes/kit/ and scenes/props/, registering each district with DistrictStreamer.

@export_file("*.json") var layout_path: String = "res://data/city_layout.json"
@export var streamer_path: NodePath

var _scenes: Dictionary = {}


func _ready() -> void:
	_preload_scenes()
	build_city()


func _preload_scenes() -> void:
	_scenes = {
		"street": preload("res://scenes/kit/kit_street_segment.tscn"),
		"plaza": preload("res://scenes/kit/kit_plaza_deck.tscn"),
		"stairs": preload("res://scenes/kit/kit_stairs.tscn"),
		"escalator": preload("res://scenes/kit/kit_stairs.tscn"),
		"ramp": preload("res://scenes/kit/kit_ramp.tscn"),
		"bridge": preload("res://scenes/kit/kit_bridge.tscn"),
		"overpass": preload("res://scenes/kit/kit_overpass.tscn"),
		"facade": preload("res://scenes/kit/kit_facade.tscn"),
		"shopfront": preload("res://scenes/kit/kit_shopfront.tscn"),
		"canopy": preload("res://scenes/kit/kit_canopy.tscn"),
		"balcony": preload("res://scenes/kit/kit_balcony.tscn"),
		"greenhouse": preload("res://scenes/kit/kit_greenhouse.tscn"),
		"elevator": preload("res://scenes/kit/kit_elevator.tscn"),
		"station": preload("res://scenes/kit/kit_tram_station.tscn"),
		"food_stall": preload("res://scenes/props/food_stall.tscn"),
		"scooter": preload("res://scenes/props/scooter.tscn"),
		"cone": preload("res://scenes/props/traffic_cone.tscn"),
		"plant": preload("res://scenes/props/potted_plant.tscn"),
		"lamp": preload("res://scenes/props/street_lamp.tscn"),
		"lantern_string": preload("res://scenes/props/lantern_string.tscn"),
		"crates": preload("res://scenes/props/crate_stack.tscn"),
		"vent": preload("res://scenes/props/vent_pipe.tscn"),
		"neon_sign": preload("res://scenes/props/neon_sign.tscn"),
		"bench": preload("res://scenes/props/bench.tscn"),
		"railing": preload("res://scenes/props/railing.tscn"),
		"vending_machine": preload("res://scenes/props/street_clutter.tscn"),
		"bike_rack": preload("res://scenes/props/street_clutter.tscn"),
		"trash_can": preload("res://scenes/props/street_clutter.tscn"),
		"utility_box": preload("res://scenes/props/street_clutter.tscn"),
		"cable_span": preload("res://scenes/props/street_clutter.tscn"),
		"light_shaft": preload("res://scenes/props/street_clutter.tscn"),
		"glow_pool": preload("res://scenes/props/street_clutter.tscn"),
	}


func build_city() -> void:
	PropUtils.clear_children(self)
	if not FileAccess.file_exists(layout_path):
		push_error("CityLayoutLoader: Missing layout file at %s" % layout_path)
		return

	var json_text := FileAccess.get_file_as_string(layout_path)
	var parsed: Variant = JSON.parse_string(json_text)
	if not (parsed is Dictionary):
		push_error("CityLayoutLoader: Invalid JSON in %s" % layout_path)
		return

	var data: Dictionary = parsed
	var streamer := get_node_or_null(streamer_path) as DistrictStreamer

	GameState.districts_data.clear()
	GameState.stations_data.clear()
	GameState.pois_data.clear()

	# Build Districts
	var districts: Array = data.get("districts", [])
	for d in districts:
		if not (d is Dictionary):
			continue
		var d_id: String = str(d.get("id", "district"))
		var d_name: String = str(d.get("name", d_id))
		var center := _to_vec3(d.get("center", [0, 0, 0]))
		var radius := float(d.get("radius", 75.0))

		GameState.districts_data.append({
			"id": d_id,
			"name": d_name,
			"color": Color(str(d.get("map_color", "#FFB454"))),
			"center": center,
			"bounds": d.get("bounds", [-50, -50, 50, 50]),
		})

		var chunk_root := Node3D.new()
		chunk_root.name = "District_%s" % d_id
		add_child(chunk_root)

		var shell_root := Node3D.new()
		shell_root.name = "Shell"
		chunk_root.add_child(shell_root)

		var detail_root := Node3D.new()
		detail_root.name = "Details"
		chunk_root.add_child(detail_root)

		var pieces: Array = d.get("pieces", [])
		for idx in range(pieces.size()):
			var p: Variant = pieces[idx]
			if p is Dictionary:
				_spawn_piece(p, shell_root, detail_root, d_id, idx)

		if streamer:
			streamer.register_district_chunk(d_id, d_name, center, radius, chunk_root, detail_root)

	# Build Maglev Stations
	var stations_root := Node3D.new()
	stations_root.name = "MaglevStations"
	add_child(stations_root)
	for s in data.get("stations", []):
		if not (s is Dictionary):
			continue
		var st_pos := _to_vec3(s.get("pos", [0, 0, 0]))
		var sp_pos := _to_vec3(s.get("spawn_pos", [0, 0.4, 0]))
		var st_id: String = str(s.get("id", "station"))
		var st_name: String = str(s.get("name", "Station"))
		GameState.stations_data.append({
			"id": st_id,
			"name": st_name,
			"district_id": str(s.get("district_id", "")),
			"pos": st_pos,
			"spawn_pos": sp_pos,
		})
		var st_node := (_scenes["station"] as PackedScene).instantiate() as KitTramStation
		st_node.name = "Station_%s" % st_id
		st_node.station_id = st_id
		st_node.station_name = st_name
		st_node.position = st_pos
		stations_root.add_child(st_node)

	# Register POIs
	for poi in data.get("pois", []):
		if poi is Dictionary:
			GameState.pois_data.append({
				"id": str(poi.get("id", "")),
				"name": str(poi.get("name", "")),
				"district_id": str(poi.get("district_id", "")),
				"pos": _to_vec3(poi.get("pos", [0, 0, 0])),
				"color": Color(str(poi.get("color", "#FFB454"))),
			})


func _spawn_piece(p: Dictionary, shell_root: Node3D, detail_root: Node3D, d_id: String, idx: int) -> void:
	var ptype: String = str(p.get("type", ""))
	if not _scenes.has(ptype):
		push_warning("CityLayoutLoader: Unknown piece type '%s'" % ptype)
		return

	var node := (_scenes[ptype] as PackedScene).instantiate() as Node3D
	node.name = "%s_%s_%d" % [d_id, ptype, idx]
	node.position = _to_vec3(p.get("pos", [0, 0, 0]))
	if p.has("rot_y"):
		node.rotation_degrees.y = float(p["rot_y"])

	var is_shell := ptype in ["street", "plaza", "stairs", "escalator", "ramp", "bridge", "overpass", "facade", "balcony", "elevator", "railing"]
	var target_parent := shell_root if is_shell else detail_root

	match ptype:
		"street":
			node.set("size", _to_vec3(p.get("size", [24, 0.5, 10])))
			node.set("puddle_amount", float(p.get("puddle", 0.62)))
			node.set("edge_trim_color", Color(str(p.get("trim", "#000000"))))
			node.set("reflect_warmth", float(p.get("warmth", 0.68)))
			node.set("foundation_depth", float(p.get("foundation", 26.0)))
			node.set("has_curbs", bool(p.get("curbs", false)))
		"plaza":
			node.set("size", _to_vec3(p.get("size", [36, 0.8, 30])))
			node.set("puddle_amount", float(p.get("puddle", 0.52)))
			node.set("accent_color", Color(str(p.get("trim", "#FFB454"))))
			node.set("reflect_warmth", float(p.get("warmth", 0.68)))
			node.set("foundation_depth", float(p.get("foundation", 28.0)))
		"stairs", "escalator":
			node.set("width", float(p.get("width", 4.5)))
			node.set("height", float(p.get("height", 5.0)))
			node.set("run_length", float(p.get("run", 10.0)))
			node.set("accent_color", Color(str(p.get("trim", "#FFB454"))))
			node.set("is_escalator", ptype == "escalator" or bool(p.get("escalator", false)))
		"ramp":
			node.set("width", float(p.get("width", 4.5)))
			node.set("height", float(p.get("height", 5.0)))
			node.set("run_length", float(p.get("run", 16.0)))
			node.set("accent_color", Color(str(p.get("trim", "#24E5D0"))))
			node.set("foundation_depth", float(p.get("foundation", 16.0)))
		"bridge":
			node.set("length", float(p.get("length", 22.0)))
			node.set("width", float(p.get("width", 5.5)))
			node.set("accent_color", Color(str(p.get("trim", "#FFB454"))))
			node.set("support_height", float(p.get("support_height", 16.0)))
			node.set("covered", bool(p.get("covered", true)))
			node.set("has_mid_piers", bool(p.get("mid_piers", true)))
		"overpass":
			node.set("size", _to_vec3(p.get("size", [68, 0.75, 11])))
			node.set("support_height", float(p.get("height", 7.0)))
			node.set("accent_color", Color(str(p.get("trim", "#FF3FA4"))))
			node.set("rail_left_side", bool(p.get("rail_left", true)))
			node.set("rail_right_side", bool(p.get("rail_right", true)))
		"facade":
			node.set("size", _to_vec3(p.get("size", [24, 68, 12])))
			node.set("district_theme", str(p.get("theme", "noodle")))
			node.set("detail_faces", str(p.get("faces", "both")))
			node.set("seed_offset", idx * 17)
		"shopfront":
			node.set("shop_type", str(p.get("shop", "ramen")))
			node.set("width", float(p.get("width", 5.6)))
			node.set("add_light", bool(p.get("light", true)))
		"canopy":
			node.set("color_a", Color(str(p.get("col_a", "#D9963B"))))
			node.set("color_b", Color(str(p.get("col_b", "#EFE0C6"))))
			node.set("is_flower_stall", bool(p.get("flowers", false)))
			node.set("add_light", bool(p.get("light", true)))
		"balcony":
			node.set("size", _to_vec3(p.get("size", [12, 0.5, 4.2])))
			node.set("accent_color", Color(str(p.get("trim", "#FFB454"))))
			node.set("rail_front", bool(p.get("rail_front", true)))
			node.set("rail_left", bool(p.get("rail_left", false)))
			node.set("rail_right", bool(p.get("rail_right", false)))
			node.set("add_columns", bool(p.get("columns", false)))
			node.set("column_height", float(p.get("col_height", 5.0)))
		"greenhouse":
			node.set("size", _to_vec3(p.get("size", [11, 5.4, 8])))
		"elevator":
			node.set("travel_height", float(p.get("height", 10.0)))
			node.set("label_text", str(p.get("label", "Building Lift")))
			node.set("pass_through", bool(p.get("pass_through", false)))
		"cone":
			node.set("glowing_tip", bool(p.get("glow", false)))
		"plant":
			node.set("planter_style", int(p.get("style", 0)))
		"crates":
			node.set("layout", int(p.get("layout", 0)))
		"vent":
			node.set("pipe_height", float(p.get("height", 8.0)))
		"neon_sign":
			var sz: Array = p.get("size", [1.2, 3.8])
			node.set("sign_size", Vector2(float(sz[0]), float(sz[1])))
			node.set("primary_color", Color(str(p.get("col_a", "#24E5D0"))))
			node.set("secondary_color", Color(str(p.get("col_b", "#FF3FA4"))))
			node.set("emit_spill_light", bool(p.get("light", true)))
		"lantern_string":
			node.set("end_offset", _to_vec3(p.get("end", [12, 0, 0])))
			node.set("lantern_count", int(p.get("count", 6)))
			node.set("emit_light_pools", bool(p.get("light", true)))
		"railing":
			node.set("length", float(p.get("length", 6.0)))
		"vending_machine", "bike_rack", "trash_can", "utility_box", "cable_span", "light_shaft", "glow_pool":
			node.set("prop_kind", ptype)
			if p.has("color"):
				node.set("accent_color", Color(str(p["color"])))
			if p.has("end"):
				node.set("end_offset", _to_vec3(p["end"]))
			if p.has("pool_size"):
				var ps: Array = p["pool_size"]
				node.set("pool_size", Vector2(float(ps[0]), float(ps[1])))
			if p.has("shaft_height"):
				node.set("shaft_height", float(p["shaft_height"]))
			if p.has("tilt"):
				node.set("shaft_tilt_deg", _to_vec3(p["tilt"]))

	target_parent.add_child(node)


func _to_vec3(arr: Variant) -> Vector3:
	if arr is Array and arr.size() >= 3:
		return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
	return Vector3.ZERO
