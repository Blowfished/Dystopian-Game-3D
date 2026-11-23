class_name KitZipline
extends Node3D

## Interactive overhead zipline from local origin to end_offset.

@export var end_offset: Vector3 = Vector3(36.0, -8.0, 0.0)
@export var speed: float = 20.0
@export var label_text: String = "Zipline"


func _ready() -> void:
	_build_zipline()


func _build_zipline() -> void:
	PropUtils.clear_children(self)
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.52, 0.45, Color("#6C8DC9"), 0.25)
	var glow := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 2.2)

	# Start & end anchor pylons
	PropUtils.add_cylinder(self, 0.08, 0.1, 2.8, Vector3(0.0, 1.4, 0.0), steel, Vector3.ZERO, 8)
	PropUtils.add_sphere(self, 0.18, Vector3(0.0, 2.75, 0.0), glow, Vector3.ONE, 8)
	PropUtils.add_cylinder(self, 0.08, 0.1, 2.8, end_offset + Vector3(0.0, 1.4, 0.0), steel, Vector3.ZERO, 8)
	PropUtils.add_sphere(self, 0.18, end_offset + Vector3(0.0, 2.75, 0.0), glow, Vector3.ONE, 8)

	# Cable
	PropUtils.add_strut(self, Vector3(0.0, 2.75, 0.0), end_offset + Vector3(0.0, 2.75, 0.0), 0.04, glow)

	# Start trigger
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 2.1
	cs.shape = shape
	cs.position = Vector3(0.0, 1.1, 0.0)
	area.add_child(cs)
	area.body_entered.connect(func(b: Node3D) -> void:
		if b is CourierController:
			GameState.set_interact_prompt("[F] Ride %s" % label_text, self)
	)
	area.body_exited.connect(func(b: Node3D) -> void:
		if b is CourierController and GameState.active_interactable == self:
			GameState.set_interact_prompt("", null)
	)
	add_child(area)


func interact(player: Node) -> void:
	if player is CourierController:
		GameState.set_interact_prompt("", null)
		var start_w := global_position + Vector3(0.0, 2.75, 0.0)
		var end_w := to_global(end_offset + Vector3(0.0, 2.75, 0.0))
		player.start_zipline(start_w, end_w, speed)
