class_name KitElevator
extends Node3D

## Architectural glass-and-steel Elevator Tower Shaft integrated into a building wall.
## Connects y=0 to y=travel_height with full 4-post shaft structure, penthouse,
## call triggers at BOTH bottom and top landings, and zero-gap landing aprons.

@export var travel_height: float = 10.0
@export var travel_speed: float = 6.5
@export var platform_size: Vector3 = Vector3(3.8, 0.38, 3.8)
@export var label_text: String = "Building Lift"
@export var pass_through: bool = false

var _car: AnimatableBody3D
var _is_at_top: bool = false
var _is_moving: bool = false
var _player_on_car: Node = null


func _ready() -> void:
	add_to_group("walkable_surfaces")
	set_meta("walkable_type", "elevator")
	set_meta("walkable_size", platform_size)
	set_meta("support_type", "architectural_elevator_shaft")
	_build_elevator()


func _build_elevator() -> void:
	PropUtils.clear_children(self)
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.52, 0.48, Color("#7D6EC4"), 0.25)
	var frame := Palette.make_stylized_material(Palette.STEEL_MID, 0.48, 0.48, Color("#9688D9"), 0.30)
	var concrete := Palette.make_stylized_material(Palette.CONCRETE_DARK, 0.84, 0.06, Color("#6E5CA8"), 0.20)
	var teal_glow := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 2.4)
	var amber_glow := Palette.make_emissive_material(Palette.LANTERN_AMBER, 2.2)

	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.55, 0.72, 0.96, 0.18)
	glass.roughness = 0.12
	glass.metallic = 0.2

	var shaft_h := travel_height + 4.2
	var hx := platform_size.x * 0.5 + 0.18
	var hz := platform_size.z * 0.5 + 0.18

	# Solid elevator pit & foundation base extending down into the building foundation
	PropUtils.add_box(self, Vector3(platform_size.x + 0.6, 6.0, platform_size.z + 0.6), Vector3(0.0, -3.4, 0.0), concrete)

	# 4 heavy corner shaft columns extending full height + top penthouse cap
	for cx in [-hx, hx]:
		for cz in [-hz, hz]:
			PropUtils.add_box(self, Vector3(0.24, shaft_h, 0.24), Vector3(cx, shaft_h * 0.5 - 0.4, cz), steel)
	# Rear structural wall anchoring shaft into building facade (-Z), omitted when pass_through is true
	if not pass_through:
		PropUtils.add_box(self, Vector3(platform_size.x + 0.5, shaft_h, 0.32), Vector3(0.0, shaft_h * 0.5 - 0.4, -hz), concrete)
		PropUtils.add_static_box_collider(self, Vector3(platform_size.x + 0.5, shaft_h, 0.36), Vector3(0.0, shaft_h * 0.5 - 0.4, -hz))

	# Glass side panels (left & right) + glowing vertical teal guide strips
	for cx in [-hx, hx]:
		var pane := PropUtils.add_box(self, Vector3(0.08, shaft_h - 0.6, platform_size.z), Vector3(cx, shaft_h * 0.5 - 0.4, 0.0), glass)
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		PropUtils.add_box(self, Vector3(0.06, travel_height + 1.8, 0.06), Vector3(cx, (travel_height + 1.8) * 0.5, hz - 0.1), teal_glow)
		# Side guard collider so player stays cleanly inside shaft
		PropUtils.add_static_box_collider(self, Vector3(0.22, shaft_h, platform_size.z), Vector3(cx, shaft_h * 0.5 - 0.4, 0.0))

	# Top mechanical penthouse roof + glowing header sign
	PropUtils.add_box(self, Vector3(platform_size.x + 0.7, 0.65, platform_size.z + 0.7), Vector3(0.0, shaft_h - 0.3, 0.0), frame)
	PropUtils.add_box(self, Vector3(platform_size.x * 0.75, 0.22, 0.12), Vector3(0.0, shaft_h - 0.7, hz + 0.05), amber_glow)

	# Bottom & top overlapping landing threshold aprons
	if pass_through:
		# Bottom opens on -Z, top opens on +Z (terraced retaining-wall shaft!)
		PropUtils.add_box(self, Vector3(platform_size.x + 0.4, 0.36, 1.6), Vector3(0.0, -0.18, -hz - 0.7), frame)
		PropUtils.add_static_box_collider(self, Vector3(platform_size.x + 0.6, 0.5, 2.0), Vector3(0.0, -0.25, -hz - 0.8))
		PropUtils.add_box(self, Vector3(platform_size.x + 0.4, 0.36, 1.6), Vector3(0.0, travel_height - 0.18, hz + 0.7), frame)
		PropUtils.add_static_box_collider(self, Vector3(platform_size.x + 0.6, 0.5, 2.0), Vector3(0.0, travel_height - 0.25, hz + 0.8))
		_add_call_zone(Vector3(0.0, 0.0, -hz - 1.0), false)
		_add_call_zone(Vector3(0.0, travel_height, hz + 1.0), true)
	else:
		PropUtils.add_box(self, Vector3(platform_size.x + 0.4, 0.36, 1.4), Vector3(0.0, -0.18, hz + 0.6), frame)
		PropUtils.add_static_box_collider(self, Vector3(platform_size.x + 0.6, 0.5, 1.8), Vector3(0.0, -0.25, hz + 0.7))
		PropUtils.add_box(self, Vector3(platform_size.x + 0.4, 0.36, 1.4), Vector3(0.0, travel_height - 0.18, hz + 0.6), frame)
		PropUtils.add_static_box_collider(self, Vector3(platform_size.x + 0.6, 0.5, 1.8), Vector3(0.0, travel_height - 0.25, hz + 0.7))
		_add_call_zone(Vector3(0.0, 0.0, hz + 0.9), false)
		_add_call_zone(Vector3(0.0, travel_height, hz + 0.9), true)

	# Moving AnimatableBody3D elevator cab
	_car = AnimatableBody3D.new()
	_car.sync_to_physics = true
	_car.collision_layer = 1
	_car.collision_mask = 0
	add_child(_car)

	PropUtils.add_box(_car, platform_size, Vector3(0.0, -platform_size.y * 0.5, 0.0), frame)
	PropUtils.add_box(_car, Vector3(platform_size.x - 0.35, 0.05, platform_size.z - 0.35), Vector3(0.0, 0.025, 0.0), amber_glow)
	# Overhead cab canopy frame
	PropUtils.add_box(_car, Vector3(platform_size.x - 0.1, 0.16, platform_size.z - 0.1), Vector3(0.0, 2.85, 0.0), frame)
	PropUtils.add_box(_car, Vector3(platform_size.x * 0.5, 0.06, platform_size.z * 0.5), Vector3(0.0, 2.75, 0.0), amber_glow)

	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(platform_size.x + 0.2, platform_size.y + 0.2, platform_size.z + 0.2)
	cs.shape = shape
	cs.position = Vector3(0.0, -shape.size.y * 0.5, 0.0)
	_car.add_child(cs)

	var trigger := Area3D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = 2
	trigger.monitorable = false
	var tcs := CollisionShape3D.new()
	var tshape := BoxShape3D.new()
	tshape.size = Vector3(platform_size.x, 2.4, platform_size.z)
	tcs.shape = tshape
	tcs.position = Vector3(0.0, 1.2, 0.0)
	trigger.add_child(tcs)
	trigger.body_entered.connect(_on_car_entered)
	trigger.body_exited.connect(_on_car_exited)
	_car.add_child(trigger)


func _add_call_zone(pos: Vector3, is_top_floor: bool) -> void:
	var area := Area3D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitorable = false
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(platform_size.x, 2.4, 2.2)
	cs.shape = shape
	cs.position = Vector3(0.0, 1.2, 0.0)
	area.add_child(cs)
	area.body_entered.connect(func(b: Node3D) -> void:
		if b is CourierController and not _is_moving and _is_at_top != is_top_floor:
			# Automatically summon elevator to the player's floor when they step up!
			_move_to(is_top_floor)
	)
	add_child(area)


func _on_car_entered(body: Node3D) -> void:
	if body is CourierController:
		_player_on_car = body
		_update_prompt()


func _on_car_exited(body: Node3D) -> void:
	if body == _player_on_car:
		_player_on_car = null
		if GameState.active_interactable == self:
			GameState.set_interact_prompt("", null)


func _update_prompt() -> void:
	if _player_on_car == null:
		return
	if _is_moving:
		GameState.set_interact_prompt("", null)
		return
	var dir_word := "Down" if _is_at_top else "Up"
	GameState.set_interact_prompt("[F] Ride %s (%s)" % [label_text, dir_word], self)


func interact(_player: Node) -> void:
	if _is_moving:
		return
	_move_to(not _is_at_top)


func _move_to(go_top: bool) -> void:
	if _is_moving or _is_at_top == go_top:
		return
	_is_moving = true
	if GameState.active_interactable == self:
		GameState.set_interact_prompt("", null)
	AudioManager.play_chime(1.1 if go_top else 0.88)

	var target_y := travel_height if go_top else 0.0
	var duration := maxf(absf(target_y - _car.position.y) / maxf(travel_speed, 1.0), 0.45)
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_car, "position:y", target_y, duration)
	await tw.finished

	_is_at_top = go_top
	_is_moving = false
	_update_prompt()
