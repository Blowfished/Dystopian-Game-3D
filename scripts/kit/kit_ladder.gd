class_name KitLadder
extends Node3D

## Vertical climbable steel ladder from y=0 to ladder_height.

@export var ladder_height: float = 6.0
@export var width: float = 0.72


func _ready() -> void:
	_build_ladder()


func _build_ladder() -> void:
	PropUtils.clear_children(self)
	var steel := Palette.make_stylized_material(Palette.STEEL_LIGHT, 0.45, 0.55, Color("#8BB0EE"), 0.35)
	var rung_mat := Palette.make_emissive_material(Palette.LANTERN_AMBER, 1.2)

	for sx in [-width * 0.5, width * 0.5]:
		PropUtils.add_cylinder(self, 0.035, 0.035, ladder_height, Vector3(sx, ladder_height * 0.5, 0.0), steel, Vector3.ZERO, 8)

	var rungs := maxi(4, int(floorf(ladder_height / 0.45)))
	for r in range(rungs):
		var ry := 0.35 + float(r) * (ladder_height - 0.5) / float(maxi(1, rungs - 1))
		PropUtils.add_cylinder(self, 0.025, 0.025, width, Vector3(0.0, ry, 0.0), rung_mat if r % 4 == 0 else steel, Vector3(0.0, 0.0, 90.0), 8)

	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width + 0.5, ladder_height + 0.4, 0.9)
	cs.shape = shape
	cs.position = Vector3(0.0, ladder_height * 0.5, 0.2)
	area.add_child(cs)
	area.body_entered.connect(func(b: Node3D) -> void:
		if b is CourierController:
			b.set_on_ladder(true, self)
	)
	area.body_exited.connect(func(b: Node3D) -> void:
		if b is CourierController:
			b.set_on_ladder(false, null)
	)
	add_child(area)
