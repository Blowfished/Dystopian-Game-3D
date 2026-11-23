class_name MaglevTram
extends AnimatableBody3D

## Physical 2-car cozy-cyberpunk Maglev Tram gliding along a continuous
## pillar-supported elevated viaduct past all 3 canyon stations.
## Aligned flush with station platforms at Z = -23.1 (deck width 4.2 -> edge at -21.0).

@export var cruise_speed: float = 22.0
@export var station_dwell_time: float = 6.5

var _waypoints: Array[Dictionary] = [
	{"pos": Vector3(-96.0, 0.0, -23.1), "station": "Noodle Alley West", "dwell": true},
	{"pos": Vector3(0.0, 0.0, -23.1), "station": "Market Terraces Central", "dwell": true},
	{"pos": Vector3(76.0, 0.0, -23.1), "station": "Neon Boulevard South", "dwell": true},
	{"pos": Vector3(88.0, 0.0, -34.0), "station": "", "dwell": false},
	{"pos": Vector3(84.0, 0.0, -64.0), "station": "", "dwell": false},
	{"pos": Vector3(0.0, 0.0, -72.0), "station": "", "dwell": false},
	{"pos": Vector3(-150.0, 0.0, -58.0), "station": "", "dwell": false},
	{"pos": Vector3(-150.0, 0.0, -23.1), "station": "", "dwell": false},
]

var _seg_idx: int = 0
var _seg_t: float = 0.0
var _dwell_timer: float = 4.0
var _is_dwelling: bool = true


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	_build_tram_visuals_and_track()
	global_position = _waypoints[0]["pos"]
	_orient_toward(_waypoints[1]["pos"])
	GameState.tram_world_position = global_position


func _physics_process(delta: float) -> void:
	if _is_dwelling:
		_dwell_timer -= delta
		if _dwell_timer <= 0.0:
			_is_dwelling = false
			AudioManager.play_chime(1.18)
		GameState.tram_world_position = global_position
		return

	var p0: Vector3 = _waypoints[_seg_idx]["pos"]
	var next_idx := (_seg_idx + 1) % _waypoints.size()
	var p1: Vector3 = _waypoints[next_idx]["pos"]
	var dist := maxf(p0.distance_to(p1), 0.1)

	var speed_factor := 1.0
	if _waypoints[_seg_idx]["dwell"] and _seg_t < 0.15:
		speed_factor = lerpf(0.28, 1.0, _seg_t / 0.15)
	elif _waypoints[next_idx]["dwell"] and _seg_t > 0.85:
		speed_factor = lerpf(1.0, 0.28, (_seg_t - 0.85) / 0.15)

	_seg_t += (cruise_speed * speed_factor * delta) / dist
	if _seg_t >= 1.0:
		_seg_t = 0.0
		_seg_idx = next_idx
		global_position = p1
		if _waypoints[_seg_idx]["dwell"]:
			_is_dwelling = true
			_dwell_timer = station_dwell_time
			AudioManager.play_chime(0.92)
	else:
		global_position = p0.lerp(p1, _seg_t)

	var look_idx := (_seg_idx + 1) % _waypoints.size()
	_orient_toward(_waypoints[look_idx]["pos"])
	GameState.tram_world_position = global_position


func _orient_toward(target_pos: Vector3) -> void:
	var dir := target_pos - global_position
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		var target_yaw := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 0.14)


func _build_tram_visuals_and_track() -> void:
	var hull_mat := Palette.make_stylized_material(Color("#201C3D"), 0.45, 0.45, Palette.LANDMARK_TEAL, 0.35)
	var roof_mat := Palette.make_stylized_material(Palette.STEEL_LIGHT, 0.48, 0.42, Color("#A496EB"), 0.30)
	var deck_mat := Palette.make_stylized_material(Palette.STEEL_MID, 0.65, 0.25, Color("#8878C4"), 0.22)
	var teal_glow := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 2.8)
	var warm_win := Palette.make_emissive_material(Palette.STALL_WARM, 2.3)

	# Walkable flat tram boarding deck (16m long x 4.2m wide, top at y = 0.0)
	PropUtils.add_box(self, Vector3(4.2, 0.45, 16.0), Vector3(0.0, -0.225, 0.0), deck_mat)
	PropUtils.add_static_box_collider(self, Vector3(4.4, 0.5, 16.2), Vector3(0.0, -0.25, 0.0))

	# Sleek open-sided transit cabin roof & glowing cyan-trimmed nose/tail
	PropUtils.add_box(self, Vector3(4.0, 0.24, 15.2), Vector3(0.0, 2.95, 0.0), roof_mat)
	PropUtils.add_box(self, Vector3(4.18, 0.12, 15.6), Vector3(0.0, -0.08, 0.0), teal_glow)
	PropUtils.add_box(self, Vector3(4.06, 0.10, 15.0), Vector3(0.0, 2.86, 0.0), teal_glow)
	PropUtils.add_box(self, Vector3(3.8, 1.35, 1.4), Vector3(0.0, 1.45, -7.1), hull_mat)
	PropUtils.add_box(self, Vector3(3.8, 1.35, 1.4), Vector3(0.0, 1.45, 7.1), hull_mat)
	PropUtils.add_box(self, Vector3(3.1, 0.55, 0.12), Vector3(0.0, 1.85, -7.82), warm_win)
	PropUtils.add_box(self, Vector3(3.1, 0.55, 0.12), Vector3(0.0, 1.85, 7.82), warm_win)

	# Pillars with wide open doorways so player can walk right on/off cleanly
	for pz in [-6.0, -1.8, 1.8, 6.0]:
		for px in [-1.88, 1.88]:
			PropUtils.add_box(self, Vector3(0.18, 2.95, 0.28), Vector3(px, 1.47, pz), hull_mat)
	PropUtils.add_box(self, Vector3(1.2, 0.08, 12.0), Vector3(0.0, 2.82, 0.0), warm_win)

	# End cab colliders
	PropUtils.add_static_box_collider(self, Vector3(3.8, 2.8, 1.4), Vector3(0.0, 1.4, -7.1))
	PropUtils.add_static_box_collider(self, Vector3(3.8, 2.8, 1.4), Vector3(0.0, 1.4, 7.1))

	# Warm interior transit light (non-shadow, distance faded)
	PropUtils.make_fade_omni(self, Vector3(0.0, 2.2, 0.0), Palette.STALL_WARM, 2.4, 12.0, 55.0)

	call_deferred("_spawn_guideway_track")


func _spawn_guideway_track() -> void:
	var p := get_parent()
	if p == null:
		return
	var track_root := Node3D.new()
	track_root.name = "MaglevGuideway"
	p.add_child(track_root)

	var rail_mat := Palette.make_stylized_material(Palette.STEEL_DARK, 0.55, 0.45, Color("#7362AD"), 0.22)
	var concrete := Palette.make_stylized_material(Palette.CONCRETE_DARK, 0.84, 0.06, Color("#6E5CA8"), 0.20)
	var strip_mat := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 2.0)

	for i in range(_waypoints.size()):
		var a: Vector3 = _waypoints[i]["pos"] - Vector3(0.0, 0.72, 0.0)
		var b: Vector3 = _waypoints[(i + 1) % _waypoints.size()]["pos"] - Vector3(0.0, 0.72, 0.0)
		var beam := PropUtils.add_strut(track_root, a, b, 1.25, rail_mat)
		if beam:
			beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var strip := PropUtils.add_strut(track_root, a + Vector3(0.0, 0.65, 0.0), b + Vector3(0.0, 0.65, 0.0), 0.14, strip_mat)
		if strip:
			strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		# Heavy concrete viaduct piers supporting the track all the way down into the lower city!
		var seg_len := a.distance_to(b)
		var pier_count := maxi(1, int(floorf(seg_len / 28.0)))
		for k in range(pier_count):
			var t := (float(k) + 0.5) / float(pier_count)
			var pp := a.lerp(b, t)
			var pier := PropUtils.add_box(track_root, Vector3(1.5, 32.0, 1.5), Vector3(pp.x, pp.y - 16.5, pp.z), concrete)
			pier.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			pier.visibility_range_end = 260.0
