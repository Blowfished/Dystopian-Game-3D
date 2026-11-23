extends Node3D

## Controller for levels/walkway.tscn.
## Builds the sheltered megastructure back facade & promenade base geometry,
## configures cozy-cyberpunk lighting/post-process, and manages Quality presets.

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var post_rect: ColorRect = $PostProcessLayer/PostProcessRect
@onready var reflection_probe: ReflectionProbe = $ReflectionProbe
@onready var architecture_root: Node3D = $WalkwayArchitecture
@onready var bounce_lights_root: Node3D = $BounceFillLights


func _ready() -> void:
	_build_promenade_and_facade()
	GameState.quality_changed.connect(_apply_quality)
	_apply_quality(GameState.quality_level)
	# Capture mouse cleanly on launch when running interactively (harmless in headless)
	if DisplayServer.get_name() != "headless":
		GameState.set_cursor_captured(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cycle_quality"):
		GameState.cycle_quality()
	elif event.is_action_pressed("ui_cancel"):
		GameState.set_cursor_captured(not GameState.is_cursor_captured())


func _apply_quality(level: GameState.QualityLevel) -> void:
	var env := world_env.environment if world_env else null
	var post_mat := post_rect.material as ShaderMaterial if post_rect else null
	var secondary_lights := get_tree().get_nodes_in_group("secondary_lights")

	match level:
		GameState.QualityLevel.LOW:
			if env:
				env.volumetric_fog_enabled = false
				env.ssr_enabled = false
				env.ssao_enabled = false
				env.sdfgi_enabled = false
				env.fog_density = 0.0046
			if post_mat:
				post_mat.set_shader_parameter("grain_strength", 0.0)
				post_mat.set_shader_parameter("vignette_strength", 0.24)
			for node in secondary_lights:
				if node is Light3D:
					node.visible = false
			if bounce_lights_root:
				bounce_lights_root.visible = true

		GameState.QualityLevel.MEDIUM:
			if env:
				env.volumetric_fog_enabled = true
				env.volumetric_fog_density = 0.011
				env.ssr_enabled = true
				env.ssr_max_steps = 40
				env.ssao_enabled = true
				env.sdfgi_enabled = false
				env.fog_density = 0.0038
			if post_mat:
				post_mat.set_shader_parameter("grain_strength", 0.016)
				post_mat.set_shader_parameter("vignette_strength", 0.28)
			for node in secondary_lights:
				if node is Light3D:
					node.visible = true
			if bounce_lights_root:
				bounce_lights_root.visible = true

		GameState.QualityLevel.HIGH:
			if env:
				env.volumetric_fog_enabled = true
				env.volumetric_fog_density = 0.014
				env.ssr_enabled = true
				env.ssr_max_steps = 64
				env.ssao_enabled = true
				env.sdfgi_enabled = true
				env.fog_density = 0.0036
			if post_mat:
				post_mat.set_shader_parameter("grain_strength", 0.018)
				post_mat.set_shader_parameter("vignette_strength", 0.30)
			for node in secondary_lights:
				if node is Light3D:
					node.visible = true
			if bounce_lights_root:
				bounce_lights_root.visible = false


func _build_promenade_and_facade() -> void:
	if architecture_root == null:
		return
	PropUtils.clear_children(architecture_root)

	var wet_mat := ShaderMaterial.new()
	wet_mat.shader = load("res://shaders/wet_walkway.gdshader")
	wet_mat.set_shader_parameter("tile_size", 1.65)
	wet_mat.set_shader_parameter("puddle_amount", 0.56)
	wet_mat.set_shader_parameter("rain_intensity", 1.0)

	var concrete_dark := Palette.make_stylized_material(Palette.CONCRETE_DARK, 0.80, 0.08, Color("#5674AD"), 0.22)
	var facade_wall := Palette.make_stylized_material(Palette.FACADE_WALL, 0.82, 0.05, Color("#607EB5"), 0.22)
	var facade_trim := Palette.make_stylized_material(Palette.FACADE_TRIM, 0.62, 0.28, Color("#7A9BD6"), 0.28)
	var steel_dark := Palette.make_stylized_material(Palette.STEEL_DARK, 0.56, 0.45, Color("#5978B0"), 0.24)
	var warm_win_a := Palette.make_emissive_material(Palette.WINDOW_WARM_A, 1.85, 0.4)
	var warm_win_b := Palette.make_emissive_material(Palette.WINDOW_WARM_B, 1.55, 0.4)
	var teal_trim := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 2.0, 0.25)

	# --- 1. Main Wet Promenade Deck (top at y = 0.0) ---
	# Main promenade slab: x in [-20, +22] (42m), z in [-4.5, +4.5] (9m)
	PropUtils.add_box(architecture_root, Vector3(42.0, 0.45, 9.0), Vector3(1.0, -0.225, 0.0), wet_mat)
	PropUtils.add_static_box_collider(architecture_root, Vector3(42.0, 0.45, 9.0), Vector3(1.0, -0.225, 0.0))

	# Vista overlook bay jutting out toward -Z on the East end (x in [11, 20], z in [-8.2, -4.5])
	PropUtils.add_box(architecture_root, Vector3(9.0, 0.45, 3.8), Vector3(15.5, -0.225, -6.35), wet_mat)
	PropUtils.add_static_box_collider(architecture_root, Vector3(9.0, 0.45, 3.8), Vector3(15.5, -0.225, -6.35))

	# Underside megastructure support beams & glowing teal edge curb along the abyss edge
	PropUtils.add_box(architecture_root, Vector3(42.4, 1.25, 9.4), Vector3(1.0, -1.06, 0.0), concrete_dark)
	PropUtils.add_box(architecture_root, Vector3(9.4, 1.25, 4.1), Vector3(15.5, -1.06, -6.35), concrete_dark)
	PropUtils.add_box(architecture_root, Vector3(42.2, 0.14, 0.14), Vector3(1.0, -0.08, -4.52), steel_dark)
	PropUtils.add_box(architecture_root, Vector3(31.0, 0.045, 0.045), Vector3(-4.5, -0.24, -4.56), teal_trim)
	PropUtils.add_box(architecture_root, Vector3(9.0, 0.045, 0.045), Vector3(15.5, -0.24, -8.28), teal_trim)

	# Heavy support girders underneath plunging into the misty abyss
	for gx in [-16.0, -6.0, 4.0, 14.0]:
		PropUtils.add_box(architecture_root, Vector3(1.3, 32.0, 2.2), Vector3(gx, -17.5, -2.8), steel_dark)

	# --- 2. Sheltered Cozy Lattice Building Facade along +Z (z = +4.5 .. +13.5) ---
	# Main building mass (gives intimate street enclosure + wall-slide/ledge surfaces!)
	PropUtils.add_box(architecture_root, Vector3(46.0, 24.0, 9.0), Vector3(1.0, 11.5, 9.0), facade_wall)
	PropUtils.add_static_box_collider(architecture_root, Vector3(46.0, 24.0, 9.0), Vector3(1.0, 11.5, 9.0))
	# Deep substructure beneath facade
	PropUtils.add_box(architecture_root, Vector3(48.0, 38.0, 11.0), Vector3(1.0, -19.5, 9.5), concrete_dark)

	# Architectural horizontal cornice bands & vertical pilasters
	for cy in [4.2, 8.6, 13.4, 18.2]:
		PropUtils.add_box(architecture_root, Vector3(46.4, 0.38, 0.55), Vector3(1.0, cy, 4.45), facade_trim)

	for px in [-19.0, -11.5, -4.0, 6.2, 13.0, 20.5]:
		PropUtils.add_box(architecture_root, Vector3(0.68, 24.0, 0.52), Vector3(px, 11.5, 4.42), facade_trim)

	# Cozy sheltered rain canopy overhanging the facade shopfront zone (West & East wings)
	PropUtils.add_box(architecture_root, Vector3(11.0, 0.24, 2.0), Vector3(-13.5, 4.15, 3.65), steel_dark, Vector3(7.0, 0.0, 0.0))
	PropUtils.add_box(architecture_root, Vector3(12.0, 0.24, 2.0), Vector3(14.0, 4.15, 3.65), steel_dark, Vector3(7.0, 0.0, 0.0))

	# Warm lit residential & shop windows across the upper stories of the facade
	var window_floors := [6.2, 10.8, 15.6]
	var window_cols := [-16.5, -13.5, -8.5, -5.8, -1.2, 1.5, 4.1, 8.8, 11.2, 15.6, 18.2]
	var idx := 0
	for wy in window_floors:
		for wx in window_cols:
			idx += 1
			# Keep a natural rhythm of lit and dim cozy apartments
			var is_lit := (idx % 5 != 0) and (idx % 7 != 3)
			PropUtils.add_box(architecture_root, Vector3(1.52, 1.72, 0.16), Vector3(wx, wy, 4.48), steel_dark)
			if is_lit:
				var wmat := warm_win_a if (idx % 2 == 0) else warm_win_b
				PropUtils.add_box(architecture_root, Vector3(1.32, 1.48, 0.08), Vector3(wx, wy, 4.44), wmat)
				# Window sill
				PropUtils.add_box(architecture_root, Vector3(1.66, 0.10, 0.30), Vector3(wx, wy - 0.88, 4.38), facade_trim)

	# Ground-floor cozy lit storefront window on the West wing (balances the Food Stall!)
	PropUtils.add_box(architecture_root, Vector3(5.2, 2.5, 0.18), Vector3(-14.2, 1.85, 4.46), steel_dark)
	PropUtils.add_box(architecture_root, Vector3(4.7, 2.1, 0.10), Vector3(-14.2, 1.85, 4.42), warm_win_b)
	for mx in [-15.6, -14.2, -12.8]:
		PropUtils.add_box(architecture_root, Vector3(0.09, 2.2, 0.16), Vector3(mx, 1.85, 4.40), steel_dark)

	# End-cap industrial bulkhead arches on far West (x = -20) and East (x = +22) to frame the walkway cleanly
	PropUtils.add_box(architecture_root, Vector3(1.2, 10.5, 9.2), Vector3(-20.5, 5.2, 0.0), concrete_dark)
	PropUtils.add_static_box_collider(architecture_root, Vector3(1.2, 10.5, 9.2), Vector3(-20.5, 5.2, 0.0))
	PropUtils.add_box(architecture_root, Vector3(1.2, 10.5, 9.2), Vector3(22.5, 5.2, 0.0), concrete_dark)
	PropUtils.add_static_box_collider(architecture_root, Vector3(1.2, 10.5, 9.2), Vector3(22.5, 5.2, 0.0))
	# Glowing transit gate strips on the end bulkheads
	PropUtils.add_box(architecture_root, Vector3(0.14, 3.2, 4.2), Vector3(-19.86, 1.9, 0.0), steel_dark)
	PropUtils.add_box(architecture_root, Vector3(0.18, 0.10, 4.3), Vector3(-19.84, 3.6, 0.0), teal_trim)
	PropUtils.add_box(architecture_root, Vector3(0.14, 3.2, 4.2), Vector3(21.86, 1.9, 0.0), steel_dark)
	PropUtils.add_box(architecture_root, Vector3(0.18, 0.10, 4.3), Vector3(21.84, 3.6, 0.0), teal_trim)
