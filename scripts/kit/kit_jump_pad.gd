class_name KitJumpPad
extends Node3D

## Cozy-tech pneumatic updraft pad for optional fast vertical shortcuts.

@export var boost_velocity: float = 16.5


func _ready() -> void:
	_build_pad()


func _build_pad() -> void:
	PropUtils.clear_children(self)
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.5, 0.48, Color("#6C8DC9"), 0.25)
	var ring := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 2.6)

	PropUtils.add_cylinder(self, 0.95, 1.15, 0.22, Vector3(0.0, 0.11, 0.0), steel, Vector3.ZERO, 14)
	PropUtils.add_cylinder(self, 0.72, 0.72, 0.08, Vector3(0.0, 0.23, 0.0), ring, Vector3.ZERO, 14)

	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.85
	shape.height = 0.7
	cs.shape = shape
	cs.position = Vector3(0.0, 0.4, 0.0)
	area.add_child(cs)
	area.body_entered.connect(func(b: Node3D) -> void:
		if b is CourierController:
			b.apply_jump_pad(boost_velocity)
	)
	add_child(area)
