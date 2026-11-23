class_name FullMapOverlay
extends PanelContainer

## Full-screen Lattice City Map & Interactive Maglev Transit Fast-Travel screen.

signal travel_requested(target_pos: Vector3, label: String)
signal closed

var fast_travel_enabled: bool = false
var player_node: Node3D = null

@onready var map_canvas: Control = %FullMapCanvas
@onready var station_list: VBoxContainer = %StationButtons
@onready var mode_label: Label = %MapModeLabel


func _ready() -> void:
	visible = false
	map_canvas.draw.connect(_on_canvas_draw)


func open_map(allow_fast_travel: bool) -> void:
	fast_travel_enabled = allow_fast_travel
	visible = true
	GameState.is_map_open = true
	GameState.set_cursor_captured(false)
	mode_label.text = "MAGLEV TRANSIT TERMINAL — Click a station to Fast Travel" if allow_fast_travel else "LATTICE CITY MAP  (Use a Maglev Station kiosk for Fast Travel)"
	_rebuild_station_buttons()
	map_canvas.queue_redraw()


func close_map() -> void:
	visible = false
	GameState.is_map_open = false
	GameState.set_cursor_captured(true)
	closed.emit()


func _process(_delta: float) -> void:
	if visible:
		map_canvas.queue_redraw()


func _rebuild_station_buttons() -> void:
	for c in station_list.get_children():
		c.queue_free()

	for s in GameState.stations_data:
		var btn := Button.new()
		btn.text = ("Fast Travel: " if fast_travel_enabled else "Station: ") + str(s["name"])
		btn.disabled = not fast_travel_enabled
		var target: Vector3 = s["spawn_pos"]
		var sname: String = s["name"]
		btn.pressed.connect(func() -> void:
			close_map()
			travel_requested.emit(target, sname)
		)
		station_list.add_child(btn)

	if fast_travel_enabled:
		for poi in GameState.pois_data:
			var btn := Button.new()
			btn.text = "POI: " + str(poi["name"])
			var target: Vector3 = poi["pos"] + Vector3(0.0, 0.8, 0.0)
			var pname: String = poi["name"]
			btn.pressed.connect(func() -> void:
				close_map()
				travel_requested.emit(target, pname)
			)
			station_list.add_child(btn)

	var close_btn := Button.new()
	close_btn.text = "Close Map [M / Esc]"
	close_btn.pressed.connect(close_map)
	station_list.add_child(close_btn)


func _on_canvas_draw() -> void:
	var csize := map_canvas.size
	var center := csize * 0.5
	var world_w := 430.0
	var world_h := 280.0
	var scale_f := minf((csize.x - 40.0) / world_w, (csize.y - 40.0) / world_h)
	var world_origin := Vector3(30.0, 0.0, -15.0)

	map_canvas.draw_rect(Rect2(Vector2.ZERO, csize), Color(0.04, 0.06, 0.13, 0.92), true)

	var font := ThemeDB.fallback_font

	# Districts
	for d in GameState.districts_data:
		var b: Array = d.get("bounds", [-50, -50, 50, 50])
		if b.size() < 4:
			continue
		var tl := center + Vector2(float(b[0]) - world_origin.x, float(b[1]) - world_origin.z) * scale_f
		var br := center + Vector2(float(b[2]) - world_origin.x, float(b[3]) - world_origin.z) * scale_f
		var rect := Rect2(tl, br - tl).abs()
		var col: Color = d.get("color", Palette.LANTERN_AMBER)
		col.a = 0.20
		map_canvas.draw_rect(rect, col, true)
		col.a = 0.80
		map_canvas.draw_rect(rect, col, false, 2.0)
		map_canvas.draw_string(font, rect.position + Vector2(8, 18), str(d["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.92, 0.85))

	# Maglev line
	var st_pts := PackedVector2Array()
	for s in GameState.stations_data:
		var sp: Vector3 = s["pos"]
		st_pts.append(center + Vector2(sp.x - world_origin.x, sp.z - world_origin.z) * scale_f)
	if st_pts.size() >= 2:
		map_canvas.draw_polyline(st_pts, Color("#24E5D0"), 3.0)

	# POIs
	for poi in GameState.pois_data:
		var pp: Vector3 = poi["pos"]
		var mp := center + Vector2(pp.x - world_origin.x, pp.z - world_origin.z) * scale_f
		map_canvas.draw_circle(mp, 5.5, poi.get("color", Color.WHITE))
		map_canvas.draw_string(font, mp + Vector2(8, 4), str(poi["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.92, 1.0))

	# Stations
	for s in GameState.stations_data:
		var sp: Vector3 = s["pos"]
		var mp := center + Vector2(sp.x - world_origin.x, sp.z - world_origin.z) * scale_f
		map_canvas.draw_rect(Rect2(mp - Vector2(6, 6), Vector2(12, 12)), Color("#24E5D0"), true)
		map_canvas.draw_string(font, mp + Vector2(9, -6), str(s["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#9AF5EB"))

	# Live Tram
	var tp := GameState.tram_world_position
	var tmp := center + Vector2(tp.x - world_origin.x, tp.z - world_origin.z) * scale_f
	map_canvas.draw_circle(tmp, 6.5, Color("#FFE49E"))

	# Player
	if is_instance_valid(player_node):
		var wp := player_node.global_position
		var pmp := center + Vector2(wp.x - world_origin.x, wp.z - world_origin.z) * scale_f
		map_canvas.draw_circle(pmp, 6.5, Color("#FFB454"))
		map_canvas.draw_arc(pmp, 9.5, 0.0, TAU, 24, Color.WHITE, 1.5)
