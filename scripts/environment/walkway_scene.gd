extends Node3D

## Root controller for the enclosed multi-district Lattice City Hub (levels/walkway.tscn).
## Manages Quality presets (Low / Medium / High), fall-protection catch volume,
## cursor capture, and links the HUD to the player.

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var post_rect: ColorRect = $PostProcessLayer/PostProcessRect
@onready var bounce_lights_root: Node3D = $BounceFillLights
@onready var courier: CourierController = $Courier
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	_setup_fall_catch_volume()

	if hud and hud.has_method("set_player"):
		hud.set_player(courier)

	GameState.quality_changed.connect(_apply_quality)
	_apply_quality(GameState.quality_level)

	if DisplayServer.get_name() != "headless":
		GameState.set_cursor_captured(true)


func _setup_fall_catch_volume() -> void:
	## Invisible safety catch volume spanning the entire city footprint below all walkable
	## levels (Y = -6.5 to -16.5) so the player can NEVER fall out of the world.
	var catch_area := Area3D.new()
	catch_area.name = "FallCatchVolume"
	catch_area.collision_layer = 0
	catch_area.collision_mask = 2
	catch_area.monitorable = false
	catch_area.position = Vector3(15.0, -11.5, -10.0)

	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(520.0, 10.0, 420.0)
	cs.shape = shape
	catch_area.add_child(cs)

	catch_area.body_entered.connect(func(body: Node3D) -> void:
		if body is CourierController:
			body.trigger_fall_respawn()
	)
	add_child(catch_area)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cycle_quality"):
		GameState.cycle_quality()
	elif event.is_action_pressed("ui_cancel") and not GameState.is_map_open:
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
				post_mat.set_shader_parameter("vignette_strength", 0.20)
			for node in secondary_lights:
				if node is Light3D:
					node.visible = false
			if bounce_lights_root:
				bounce_lights_root.visible = true

		GameState.QualityLevel.MEDIUM:
			if env:
				env.volumetric_fog_enabled = true
				env.volumetric_fog_density = 0.010
				env.ssr_enabled = true
				env.ssr_max_steps = 40
				env.ssao_enabled = true
				env.sdfgi_enabled = false
				env.fog_density = 0.0042
			if post_mat:
				post_mat.set_shader_parameter("grain_strength", 0.014)
				post_mat.set_shader_parameter("vignette_strength", 0.24)
			for node in secondary_lights:
				if node is Light3D:
					node.visible = true
			if bounce_lights_root:
				bounce_lights_root.visible = true

		GameState.QualityLevel.HIGH:
			if env:
				env.volumetric_fog_enabled = true
				env.volumetric_fog_density = 0.013
				env.ssr_enabled = true
				env.ssr_max_steps = 64
				env.ssao_enabled = true
				env.sdfgi_enabled = true
				env.fog_density = 0.0038
			if post_mat:
				post_mat.set_shader_parameter("grain_strength", 0.016)
				post_mat.set_shader_parameter("vignette_strength", 0.26)
			for node in secondary_lights:
				if node is Light3D:
					node.visible = true
			if bounce_lights_root:
				bounce_lights_root.visible = true
