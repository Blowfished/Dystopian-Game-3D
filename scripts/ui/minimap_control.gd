class_name MinimapControl
extends Control

## Custom-drawn cozy-cyberpunk minimap showing districts, Maglev track,
## live moving tram dot, stations, POIs, and the player's position & heading.

@export var world_radius: float = 165.0
var player_node: Node3D = null


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5
	var center := size * 0.5
	var scale_f := (r - 6.0) / world_radius

	# Background circle
	draw_circle(center, r, Color(0.045, 0.065, 0.145, 0.84))
	draw_arc(center, r - 1.5, 0.0, TAU, 48, Color(0.24, 0.85, 0.80, 0.45), 2.0)

	var ppos := player_node.global_position if is_instance_valid(player_node) else Vector3.ZERO
	var p_yaw := 0.0
	if player_node is CourierController and player_node.visual_anchor:
		p_yaw = player_node.visual_anchor.rotation.y

	# Draw districts as soft colored rectangles
	for d in GameState.districts_data:
		var b: Array = d.get("bounds", [-50, -50, 50, 50])
		if b.size() < 4:
			continue
		var min_x := float(b[0])
		var min_z := float(b[1])
		var max_x := float(b[2])
		var max_z := float(b[3])
		var tl := _world_to_map(Vector3(min_x, 0, min_z), ppos, center, scale_f)
		var br := _world_to_map(Vector3(max_x, 0, max_z), ppos, center, scale_f)
		var rect := Rect2(tl, br - tl).abs()
		var col: Color = d.get("color", Palette.LANTERN_AMBER)
		col.a = 0.22
		draw_rect(rect, col, true)
		col.a = 0.65
		draw_rect(rect, col, false, 1.0)

	# Draw Maglev track line between stations
	var st_pts := PackedVector2Array()
	for s in GameState.stations_data:
		st_pts.append(_world_to_map(s["pos"], ppos, center, scale_f))
	if st_pts.size() >= 2:
		draw_polyline(st_pts, Color(0.14, 0.90, 0.82, 0.55), 2.0)

	# Draw POIs
	for poi in GameState.pois_data:
		var mp := _world_to_map(poi["pos"], ppos, center, scale_f)
		if mp.distance_to(center) <= r - 5.0:
			draw_circle(mp, 3.2, poi.get("color", Color.WHITE))

	# Draw Stations
	for s in GameState.stations_data:
		var mp := _world_to_map(s["pos"], ppos, center, scale_f)
		if mp.distance_to(center) <= r - 5.0:
			draw_rect(Rect2(mp - Vector2(4, 4), Vector2(8, 8)), Color("#24E5D0"), true)

	# Draw Live Moving Tram
	var tram_mp := _world_to_map(GameState.tram_world_position, ppos, center, scale_f)
	if tram_mp.distance_to(center) <= r - 5.0:
		draw_circle(tram_mp, 4.5, Color("#FFE49E"))

	# Draw Player arrow at center
	var fwd := Vector2(-sin(p_yaw), -cos(p_yaw))
	var right := Vector2(-fwd.y, fwd.x)
	var tri := PackedVector2Array([
		center + fwd * 8.0,
		center - fwd * 5.0 + right * 5.0,
		center - fwd * 5.0 - right * 5.0,
	])
	draw_colored_polygon(tri, Color("#FFB454"))


func _world_to_map(wpos: Vector3, ref_pos: Vector3, center: Vector2, scale_f: float) -> Vector2:
	var dx := (wpos.x - ref_pos.x) * scale_f
	var dz := (wpos.z - ref_pos.z) * scale_f
	return center + Vector2(dx, dz)
