@tool
class_name KitGreenhouse
extends Node3D

## Warm glowing rooftop greenhouse pavilion with glass panels and lush interior foliage.

@export var size: Vector3 = Vector3(11.0, 5.4, 8.0)


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var frame := Palette.make_stylized_material(Palette.STEEL_MID, 0.48, 0.45, Color("#7AD4C4"), 0.32)
	var stone := Palette.make_stylized_material(Palette.CONCRETE_WARM, 0.78, 0.04, Color("#7A94C7"), 0.24)
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.55, 0.92, 0.78, 0.28)
	glass.emission_enabled = true
	glass.emission = Palette.GREENHOUSE_GLOW
	glass.emission_energy_multiplier = 0.85
	glass.roughness = 0.15

	var leaf := Palette.make_stylized_material(Palette.FOLIAGE_LIGHT, 0.75, 0.0, Color("#B2EDD9"), 0.40)
	var warm_core := Palette.make_emissive_material(Palette.STALL_WARM, 2.2)

	# Stone planter base
	PropUtils.add_box(visual, Vector3(size.x, 0.9, size.z), Vector3(0.0, 0.45, 0.0), stone)
	# Glass volume
	PropUtils.add_box(visual, Vector3(size.x - 0.3, size.y - 1.2, size.z - 0.3), Vector3(0.0, size.y * 0.5 + 0.3, 0.0), glass)

	# Steel ribs
	var ribs := 5
	for i in range(ribs):
		var rx := lerpf(-size.x * 0.48, size.x * 0.48, float(i) / float(ribs - 1))
		PropUtils.add_box(visual, Vector3(0.14, size.y, 0.14), Vector3(rx, size.y * 0.5, size.z * 0.48), frame)
		PropUtils.add_box(visual, Vector3(0.14, size.y, 0.14), Vector3(rx, size.y * 0.5, -size.z * 0.48), frame)
		PropUtils.add_box(visual, Vector3(0.14, 0.14, size.z), Vector3(rx, size.y, 0.0), frame)

	# Interior warm trees & lantern core
	for tx in [-size.x * 0.26, 0.0, size.x * 0.26]:
		PropUtils.add_sphere(visual, 1.15, Vector3(tx, 2.2, 0.0), leaf, Vector3(1.1, 1.3, 1.0), 10)
	PropUtils.add_sphere(visual, 0.35, Vector3(0.0, 3.8, 0.0), warm_core, Vector3.ONE, 8)
	PropUtils.make_fade_omni(self, Vector3(0.0, 3.2, 0.0), Palette.GREENHOUSE_GLOW, 2.8, 15.0, 48.0)

	PropUtils.add_static_box_collider(self, Vector3(size.x, size.y, size.z), Vector3(0.0, size.y * 0.5, 0.0))
