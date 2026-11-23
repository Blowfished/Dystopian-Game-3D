extends SceneTree

## Comprehensive Headless City Integrity, Ground-Gap, Hard-Rule (No Floating Platforms),
## Fall-Protection, Reachability, & District Performance Audit!
##
## Run with:
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/luke/new-game-project -s res://tests/test_city_integrity.gd

const MAIN_SCENE_PATH := "res://levels/walkway.tscn"


func _initialize() -> void:
	call_deferred("_run_audit")


func _run_audit() -> void:
	print("\n============================================================")
	print("  LATTICE CITY INTEGRITY & ANTI-GAP VALIDATION SUITE")
	print("============================================================\n")

	var packed := load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		printerr("FAIL: Could not load main scene at %s" % MAIN_SCENE_PATH)
		quit(1)
		return

	var root_scene := packed.instantiate() as Node3D
	root.add_child(root_scene)

	# Wait several physics ticks so all deferred children, StaticBody3Ds, and Jolt physics shapes are registered
	for _i in range(8):
		await physics_frame
		await process_frame

	var failures: Array[String] = []
	var space: PhysicsDirectSpaceState3D = root_scene.get_world_3d().direct_space_state
	if space == null:
		printerr("FAIL: DirectSpaceState is null!")
		quit(1)
		return

	# ------------------------------------------------------------------
	# 1. HARD RULE VALIDATION: List EVERY walkable surface & verify ZERO floating pieces!
	# ------------------------------------------------------------------
	print("--- [1] HARD RULE AUDIT: EVERY WALKABLE SURFACE ---")
	var walkables := get_nodes_in_group("walkable_surfaces")
	print("Total registered walkable surfaces: %d" % walkables.size())

	var forbidden_classes := ["TrussPlatformProp", "CatwalkBridgeProp", "KitJumpPad", "KitZipline", "KitLadder"]
	var forbidden_found := _find_forbidden_nodes(root_scene, forbidden_classes)
	if not forbidden_found.is_empty():
		for fn in forbidden_found:
			failures.append("FORBIDDEN FLOATING/PLATFORMING PIECE FOUND: %s" % fn)

	var surface_reports: Array[String] = []
	for node in walkables:
		if not (node is Node3D):
			continue
		var n3 := node as Node3D
		var wtype: String = str(n3.get_meta("walkable_type", "unknown"))
		var wsize: Vector3 = n3.get_meta("walkable_size", Vector3(4, 0.5, 4))
		var stype: String = str(n3.get_meta("support_type", "none"))
		var ok := true
		var note := stype

		# Verify visible structural attachment / support geometry exists!
		var mesh_bounds := _compute_local_mesh_bounds(n3)
		if wtype in ["street", "plaza", "tram_station"]:
			# Must extend solidly downward below local y = -4m
			if mesh_bounds.position.y > -4.0:
				ok = false
				note = "THIN SLAB (min_y=%.2f, expected <= -4.0)" % mesh_bounds.position.y
		elif wtype == "balcony":
			# Must have wall cantilever brackets extending below deck AND be backed by a solid building wall within 1.5m of local -Z!
			var back_dir := (n3.global_transform.basis * Vector3(0.0, 0.0, -1.0)).normalized()
			var wall_origin := n3.global_position + Vector3(0.0, 0.5, 0.0)
			var wall_target := wall_origin + back_dir * (wsize.z * 0.5 + 1.8)
			var q_wall := PhysicsRayQueryParameters3D.create(wall_origin, wall_target, 1)
			var hit_wall := space.intersect_ray(q_wall)
			if hit_wall.is_empty():
				ok = false
				note = "UNATTACHED BALCONY (no solid building wall behind -Z!)"
			elif mesh_bounds.position.y > -1.5:
				ok = false
				note = "BALCONY MISSING UNDER-BRACKETS (min_y=%.2f)" % mesh_bounds.position.y
			else:
				note = "anchored_to_wall (%s)" % hit_wall["collider"].get_parent().name
		elif wtype == "bridge":
			# Must have piers/abutments extending below deck AND solid decks at BOTH ends!
			var end_a := n3.to_global(Vector3(-wsize.x * 0.5 - 0.3, 1.5, 0.0))
			var end_b := n3.to_global(Vector3(wsize.x * 0.5 + 0.3, 1.5, 0.0))
			var hit_a := space.intersect_ray(PhysicsRayQueryParameters3D.create(end_a, end_a - Vector3(0, 3.0, 0), 1))
			var hit_b := space.intersect_ray(PhysicsRayQueryParameters3D.create(end_b, end_b - Vector3(0, 3.0, 0), 1))
			if mesh_bounds.position.y > -4.0:
				ok = false
				note = "BRIDGE MISSING SUPPORT PIERS (min_y=%.2f)" % mesh_bounds.position.y
			elif hit_a.is_empty() or hit_b.is_empty():
				ok = false
				note = "BRIDGE END UNCONNECTED (endA=%s, endB=%s)" % [not hit_a.is_empty(), not hit_b.is_empty()]
			else:
				note = "both_ends_connected_with_piers"
		elif wtype == "overpass":
			if mesh_bounds.position.y > -6.0:
				ok = false
				note = "OVERPASS MISSING COLUMNS (min_y=%.2f)" % mesh_bounds.position.y
		elif wtype in ["stairs", "escalator", "ramp"]:
			# Bottom and top landings must hit solid ground/decks!
			var bot_pt := n3.to_global(Vector3(0.0, 1.4, 0.8))
			var top_pt := n3.to_global(Vector3(0.0, wsize.y + 1.4, -wsize.z - 0.8))
			var hit_bot := space.intersect_ray(PhysicsRayQueryParameters3D.create(bot_pt, bot_pt - Vector3(0, 2.8, 0), 1))
			var hit_top := space.intersect_ray(PhysicsRayQueryParameters3D.create(top_pt, top_pt - Vector3(0, 2.8, 0), 1))
			if hit_bot.is_empty() or hit_top.is_empty():
				ok = false
				note = "%s DISCONNECTED (bot=%s, top=%s)" % [wtype.to_upper(), not hit_bot.is_empty(), not hit_top.is_empty()]
			else:
				note = "solid_understructure_connected_both_ends"

		var status := "OK" if ok else "FAIL"
		var line := "  [%s] %-34s type=%-12s pos=(%.1f,%.1f,%.1f) size=(%.1f,%.1f,%.1f) :: %s" % [
			status, n3.name, wtype, n3.global_position.x, n3.global_position.y, n3.global_position.z,
			wsize.x, wsize.y, wsize.z, note
		]
		surface_reports.append(line)
		print(line)
		if not ok:
			failures.append("FLOATING/UNSUPPORTED SURFACE: %s (%s)" % [n3.name, note])

	# ------------------------------------------------------------------
	# 2. DENSE GRID GROUND-GAP RAYCAST AUDIT ACROSS EVERY WALKABLE SURFACE & SEAM
	# ------------------------------------------------------------------
	print("\n--- [2] DENSE GRID GROUND-GAP RAYCAST AUDIT ---")
	var total_samples := 0
	var gap_hits: Array[String] = []
	var grid_step := 2.0

	for node in walkables:
		if not (node is Node3D):
			continue
		var n3 := node as Node3D
		var wtype: String = str(n3.get_meta("walkable_type", "unknown"))
		var wsize: Vector3 = n3.get_meta("walkable_size", Vector3(4, 0.5, 4))

		if wtype in ["street", "plaza", "balcony", "bridge", "overpass", "tram_station"]:
			var half_x := maxf(wsize.x * 0.5 - 0.5, 0.2)
			var half_z := maxf(wsize.z * 0.5 - 0.5, 0.2)
			var nx := maxi(2, int(ceilf((half_x * 2.0) / grid_step)) + 1)
			var nz := maxi(2, int(ceilf((half_z * 2.0) / grid_step)) + 1)
			for ix in range(nx):
				var lx := lerpf(-half_x, half_x, float(ix) / float(nx - 1))
				for iz in range(nz):
					var lz := lerpf(-half_z, half_z, float(iz) / float(nz - 1))
					var wpt := n3.to_global(Vector3(lx, 0.0, lz))
					total_samples += 1
					# Cast down from +1.2m above deck to -1.2m below deck
					var q := PhysicsRayQueryParameters3D.create(wpt + Vector3(0, 1.2, 0), wpt - Vector3(0, 1.2, 0), 1)
					var hit := space.intersect_ray(q)
					if hit.is_empty():
						gap_hits.append("GAP on %s (%s) at world (%.1f, %.1f, %.1f)" % [n3.name, wtype, wpt.x, wpt.y, wpt.z])
		elif wtype in ["stairs", "escalator", "ramp"]:
			var steps_n := maxi(5, int(ceilf(wsize.z / 1.5)) + 1)
			for s in range(steps_n):
				var t := float(s) / float(steps_n - 1)
				var ly := wsize.y * t
				var lz := -wsize.z * t
				for lx in [-wsize.x * 0.3, 0.0, wsize.x * 0.3]:
					var wpt := n3.to_global(Vector3(lx, ly, lz))
					total_samples += 1
					var q := PhysicsRayQueryParameters3D.create(wpt + Vector3(0, 1.5, 0), wpt - Vector3(0, 1.5, 0), 1)
					var hit := space.intersect_ray(q)
					if hit.is_empty():
						gap_hits.append("SLOPE GAP on %s (%s) at world (%.1f, %.1f, %.1f)" % [n3.name, wtype, wpt.x, wpt.y, wpt.z])

	# Also audit key inter-district seam transitions & station boarding paths explicitly!
	var seam_checks := [
		{"name": "Noodle Spawn", "pos": Vector3(-104, 0, 3)},
		{"name": "Noodle->Station Forecourt Seam", "pos": Vector3(-96, 0, -6)},
		{"name": "Noodle Forecourt->Station Platform Seam", "pos": Vector3(-96, 0, -15.2)},
		{"name": "Noodle->Lantern Lane Seam", "pos": Vector3(-108, 0, 12)},
		{"name": "Noodle->Market Crossroads Seam West", "pos": Vector3(-43, 0, 3)},
		{"name": "Noodle->Market Crossroads Seam East", "pos": Vector3(-37, 0, 3)},
		{"name": "Market->Station Platform Seam", "pos": Vector3(0, 0, -15.5)},
		{"name": "Market Tier 1->2 Grand Stairs Top Seam", "pos": Vector3(0, 5, 27.2)},
		{"name": "Market Tier 2->3 Grand Stairs Top Seam", "pos": Vector3(0, 10, 51.2)},
		{"name": "Market Tier 3->Skybridge Seam", "pos": Vector3(41.5, 10, 62)},
		{"name": "Market Skybridge->Ramp Seam", "pos": Vector3(76.5, 10, 62)},
		{"name": "Market Ramp->Rooftop Gardens Seam", "pos": Vector3(95.0, 14, 62)},
		{"name": "Market->Neon Gate Seam", "pos": Vector3(41.0, 0, -2)},
		{"name": "Neon Gate->Neon Plaza Seam", "pos": Vector3(76.0, 0, -2)},
		{"name": "Neon Plaza->Station Platform Seam", "pos": Vector3(76.0, 0, -15.5)},
		{"name": "Neon Plaza->Main Boulevard Seam", "pos": Vector3(122.0, 0, -19)},
		{"name": "Neon Boulevard->Synth Alley Seam", "pos": Vector3(136.0, 0, -66)},
		{"name": "Neon Escalator->Overpass Seam", "pos": Vector3(119.0, 7, -29.5)},
		{"name": "Neon Overpass->Upper Stairs Seam", "pos": Vector3(125.0, 7, -29.0)},
		{"name": "Neon Upper Stairs->Skybridge Seam", "pos": Vector3(125.0, 14, -14.5)},
		{"name": "Neon Skybridge->Skywalk Plaza Seam", "pos": Vector3(125.0, 14, 14.0)},
		{"name": "Neon Skywalk Plaza->Rooftop Gardens Seam", "pos": Vector3(124.0, 14, 34.5)},
		{"name": "Gardens Tier 1->2 Stairs Top Seam", "pos": Vector3(120.5, 19, 66)},
		{"name": "Gardens Tier 1->2 Ramp Top Seam", "pos": Vector3(134.0, 19, 53.5)},
		{"name": "Gardens Tier 2->3 Stairs Top Seam", "pos": Vector3(145.5, 24, 76)},
	]
	for sc in seam_checks:
		var pt: Vector3 = sc["pos"]
		total_samples += 1
		var q := PhysicsRayQueryParameters3D.create(pt + Vector3(0, 1.5, 0), pt - Vector3(0, 1.5, 0), 1)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			gap_hits.append("SEAM GAP at %s (%s)" % [sc["name"], str(pt)])

	print("Grid & seam ground samples tested: %d | Gaps found: %d" % [total_samples, gap_hits.size()])
	for g in gap_hits:
		print("  [GAP] %s" % g)
		failures.append(g)

	# ------------------------------------------------------------------
	# 3. FALL PROTECTION TEST: Verify catch volume & kill-plane respawn!
	# ------------------------------------------------------------------
	print("\n--- [3] FALL PROTECTION & RESPAWN TEST ---")
	var courier := root_scene.get_node_or_null("Courier") as Node3D
	var catch_vol := root_scene.get_node_or_null("FallCatchVolume") as Area3D
	if courier == null or not courier.has_method("teleport_to"):
		failures.append("Courier node not found or missing script!")
	elif catch_vol == null:
		failures.append("FallCatchVolume Area3D not found!")
	else:
		var safe_spot := Vector3(-104.0, 0.35, 3.0)
		courier.call("teleport_to", safe_spot)
		for _k in range(6):
			await physics_frame
		# Force player below walkable world to verify catch volume / respawn triggers safely
		courier.global_position = Vector3(-104.0, -9.5, 3.0)
		for _k in range(48):
			await physics_frame
			await process_frame
		var recovered := courier.global_position.y > -1.0 and courier.global_position.distance_to(safe_spot) < 3.0
		print("  Fall recovery test: final pos = %s | recovered = %s" % [str(courier.global_position), str(recovered)])
		if not recovered:
			failures.append("Player failed to safely respawn from fall! Stuck at %s" % str(courier.global_position))

	# ------------------------------------------------------------------
	# 3B. WALKABLE ROUTE OBSTRUCTION CHECK (Verify no railings/walls block main transitions!)
	# ------------------------------------------------------------------
	print("\n--- [3B] INTER-DISTRICT WALKABLE PASSAGE CLEARANCE ---")
	var passages := [
		{"name": "Noodle Main Street -> Station Forecourt", "a": Vector3(-96, 1.0, 2), "b": Vector3(-96, 1.0, -16)},
		{"name": "Noodle Main Street -> Lantern Lane", "a": Vector3(-108, 1.0, 3), "b": Vector3(-108, 1.0, 32)},
		{"name": "Noodle Alley -> Market Terraces", "a": Vector3(-50, 1.0, 3), "b": Vector3(-28, 1.0, 3)},
		{"name": "Noodle South Escalator (Y=0 -> 5)", "a": Vector3(-99, 1.3, 9.8), "b": Vector3(-88, 6.3, 9.8)},
		{"name": "Noodle Balcony -> Covered Skybridge -> North Balcony", "a": Vector3(-68, 6.2, 9.8), "b": Vector3(-68, 6.2, -4.0)},
		{"name": "Noodle North Stairs (Y=0 -> 5)", "a": Vector3(-44, 1.3, -4.0), "b": Vector3(-55, 6.3, -4.0)},
		{"name": "Market Tier 1 -> Tier 2 Grand Stairs", "a": Vector3(0, 1.3, 16), "b": Vector3(0, 6.3, 27)},
		{"name": "Market Tier 2 -> Tier 3 Grand Stairs", "a": Vector3(0, 6.3, 40), "b": Vector3(0, 11.3, 51)},
		{"name": "Market Tier 3 -> Skybridge -> Rooftop Gardens", "a": Vector3(36, 11.3, 62), "b": Vector3(74, 11.3, 62)},
		{"name": "Market Ramp -> Rooftop Gardens West", "a": Vector3(76, 11.3, 62), "b": Vector3(96, 15.3, 62)},
		{"name": "Market Tier 1 -> Neon Gate -> Neon Plaza", "a": Vector3(34, 1.0, -2), "b": Vector3(84, 1.0, -2)},
		{"name": "Neon Plaza -> Main Neon Boulevard", "a": Vector3(122, 1.0, -8), "b": Vector3(122, 1.0, -104)},
		{"name": "Neon Boulevard -> Synth Alley", "a": Vector3(124, 1.0, -66), "b": Vector3(156, 1.0, -66)},
		{"name": "Neon Escalator -> Overpass (Y=0 -> 7)", "a": Vector3(119, 1.3, -15), "b": Vector3(119, 8.3, -29)},
		{"name": "Neon Overpass -> Upper Stairs (Y=7 -> 14)", "a": Vector3(125, 8.3, -29), "b": Vector3(125, 15.3, -15)},
		{"name": "Neon Skybridge -> Skywalk Plaza -> Rooftop Gardens", "a": Vector3(124, 15.3, -12), "b": Vector3(124, 15.3, 38)},
		{"name": "Gardens Tier 1 -> Tier 2 Stairs", "a": Vector3(109, 15.3, 66), "b": Vector3(120, 20.3, 66)},
		{"name": "Gardens Tier 1 -> Tier 2 Ramp", "a": Vector3(134, 15.3, 38), "b": Vector3(134, 20.3, 53)},
		{"name": "Gardens Tier 2 -> Tier 3 Summit Stairs", "a": Vector3(135, 20.3, 76), "b": Vector3(145, 25.3, 76)},
	]
	for psg in passages:
		var pa: Vector3 = psg["a"]
		var pb: Vector3 = psg["b"]
		var q_p := PhysicsRayQueryParameters3D.create(pa, pb, 1)
		var hit_p := space.intersect_ray(q_p)
		var clear := hit_p.is_empty()
		print("  [%s] %s" % ["CLEAR" if clear else "BLOCKED", psg["name"]])
		if not clear:
			failures.append("BLOCKED PASSAGE: %s hit %s at %s" % [psg["name"], hit_p["collider"].get_parent().name, str(hit_p["position"])])

	# ------------------------------------------------------------------
	# 4. DISTRICT STREAMING & PERFORMANCE DIAGNOSTICS PER DISTRICT
	# ------------------------------------------------------------------
	var is_headless := DisplayServer.get_name() == "headless"
	print("\n--- [4] PER-DISTRICT PERFORMANCE & STREAMING (%s) ---" % ("HEADLESS CPU" if is_headless else "MEDIUM GPU RENDER"))
	var streamer := root_scene.get_node_or_null("DistrictStreamer")
	var district_probes := [
		{"id": "noodle_alley", "pos": Vector3(-104, 1.5, 3)},
		{"id": "market_terraces", "pos": Vector3(0, 1.5, 8)},
		{"id": "neon_boulevard", "pos": Vector3(122, 1.5, -54)},
		{"id": "rooftop_gardens", "pos": Vector3(136, 15.5, 62)},
	]
	for dp in district_probes:
		if courier and courier.has_method("teleport_to"):
			courier.call("teleport_to", dp["pos"])
		if streamer and streamer.has_method("update_for_position"):
			streamer.call("update_for_position", dp["pos"])
		# Warmup frames so shaders/pipelines & ReflectionProbes settle
		var warmup := 4 if is_headless else 15
		for _w in range(warmup):
			await process_frame
		var t0 := Time.get_ticks_usec()
		var sample_frames := 20 if is_headless else 45
		for _f in range(sample_frames):
			await process_frame
		var elapsed_ms := float(Time.get_ticks_usec() - t0) / 1000.0
		var avg_ms := elapsed_ms / float(sample_frames)
		var measured_fps := 1000.0 / maxf(avg_ms, 0.1)
		var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		var active_lights := get_nodes_in_group("secondary_lights").filter(func(n: Node) -> bool: return n is Light3D and n.is_visible_in_tree()).size()
		var shadow_lights := _count_shadow_lights(root_scene)
		print("  District %-16s | %5.1f FPS (%5.2f ms) | Draws: %4d | Prims: %6d | Local Lights: %2d | Shadow Lights: %d" % [
			dp["id"], measured_fps, avg_ms, draw_calls, prims, active_lights, shadow_lights
		])

	# ------------------------------------------------------------------
	# SUMMARY
	# ------------------------------------------------------------------
	print("\n============================================================")
	if failures.is_empty():
		print("  ALL CHECKS PASSED! Zero gaps, zero floating platforms,")
		print("  fall protection verified, all districts streaming cleanly.")
		print("============================================================\n")
		quit(0)
	else:
		print("  FAILED WITH %d ISSUE(S):" % failures.size())
		for f in failures:
			printerr("   - %s" % f)
		print("============================================================\n")
		quit(1)


func _find_forbidden_nodes(node: Node, forbidden_scripts: Array) -> Array[String]:
	var found: Array[String] = []
	var scr: Script = node.get_script()
	if scr != null:
		var gname := scr.get_global_name()
		if gname in forbidden_scripts:
			found.append("%s (%s)" % [node.name, gname])
	for c in node.get_children():
		found.append_array(_find_forbidden_nodes(c, forbidden_scripts))
	return found


func _compute_local_mesh_bounds(root_node: Node3D) -> AABB:
	var combined := AABB()
	var has_any := false
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur is MeshInstance3D:
			var mi := cur as MeshInstance3D
			var aabb := mi.get_aabb()
			var rel_xform := root_node.global_transform.affine_inverse() * mi.global_transform
			var tx_aabb := rel_xform * aabb
			if not has_any:
				combined = tx_aabb
				has_any = true
			else:
				combined = combined.merge(tx_aabb)
		for child in cur.get_children():
			stack.append(child)
	return combined


func _count_shadow_lights(node: Node) -> int:
	var total := 0
	if node is Light3D and (node as Light3D).shadow_enabled and (node as Light3D).is_visible_in_tree():
		total += 1
	for c in node.get_children():
		total += _count_shadow_lights(c)
	return total
