@tool
class_name TrussPillarProp
extends Node3D

@export var height: float = 12.0:
	set(v):
		height = maxf(v, 2.0)
		if is_inside_tree():
			_rebuild()

@export var width: float = 0.75:
	set(v):
		width = maxf(v, 0.35)
		if is_inside_tree():
			_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.56, 0.48, Color("#5E7EB8"), 0.25)
	var h := width * 0.5

	# Four vertical corner chords (extends from y = 0 up to y = height)
	for cx in [-h, h]:
		for cz in [-h, h]:
			PropUtils.add_box(visual, Vector3(0.09, height, 0.09), Vector3(cx, height * 0.5, cz), steel)

	# Horizontal ties & diagonal X-bracing
	var bays := maxi(2, int(roundf(height / 1.5)))
	for b in range(bays):
		var y0 := lerpf(0.0, height, float(b) / float(bays))
		var y1 := lerpf(0.0, height, float(b + 1) / float(bays))
		PropUtils.add_box(visual, Vector3(width, 0.06, 0.06), Vector3(0.0, y1, h), steel)
		PropUtils.add_box(visual, Vector3(width, 0.06, 0.06), Vector3(0.0, y1, -h), steel)
		PropUtils.add_box(visual, Vector3(0.06, 0.06, width), Vector3(h, y1, 0.0), steel)
		PropUtils.add_box(visual, Vector3(0.06, 0.06, width), Vector3(-h, y1, 0.0), steel)

		if b % 2 == 0:
			PropUtils.add_strut(visual, Vector3(-h, y0, h), Vector3(h, y1, h), 0.045, steel)
			PropUtils.add_strut(visual, Vector3(h, y0, -h), Vector3(-h, y1, -h), 0.045, steel)
			PropUtils.add_strut(visual, Vector3(h, y0, -h), Vector3(h, y1, h), 0.045, steel)
			PropUtils.add_strut(visual, Vector3(-h, y0, h), Vector3(-h, y1, -h), 0.045, steel)
		else:
			PropUtils.add_strut(visual, Vector3(h, y0, h), Vector3(-h, y1, h), 0.045, steel)
			PropUtils.add_strut(visual, Vector3(-h, y0, -h), Vector3(h, y1, -h), 0.045, steel)
			PropUtils.add_strut(visual, Vector3(h, y0, h), Vector3(h, y1, -h), 0.045, steel)
			PropUtils.add_strut(visual, Vector3(-h, y0, -h), Vector3(-h, y1, h), 0.045, steel)

	PropUtils.add_static_box_collider(self, Vector3(width + 0.08, height, width + 0.08), Vector3(0.0, height * 0.5, 0.0))
