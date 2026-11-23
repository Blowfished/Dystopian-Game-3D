@tool
class_name KitStairs
extends Node3D

## Solid architectural staircase or urban escalator rising along -Z from y=0 to y=height over run_length.
## Features solid concrete/steel under-mass (never floating!), smooth sloped collider with
## overlapping top & bottom landing aprons so the courier walks seamlessly onto every tier.

@export var width: float = 4.5:
	set(v):
		width = maxf(v, 1.8)
		if is_inside_tree():
			_rebuild()

@export var height: float = 5.0:
	set(v):
		height = maxf(v, 1.0)
		if is_inside_tree():
			_rebuild()

@export var run_length: float = 10.0:
	set(v):
		run_length = maxf(v, 2.5)
		if is_inside_tree():
			_rebuild()

@export var accent_color: Color = Palette.LANTERN_AMBER
@export var is_escalator: bool = false


func _ready() -> void:
	add_to_group("walkable_surfaces")
	set_meta("walkable_type", "escalator" if is_escalator else "stairs")
	set_meta("walkable_size", Vector3(width, height, run_length))
	set_meta("support_type", "solid_stair_mass")
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	set_meta("walkable_size", Vector3(width, height, run_length))
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var step_col := Palette.STEEL_MID if is_escalator else Palette.CONCRETE_WARM
	var step_mat := Palette.make_stylized_material(step_col, 0.55 if is_escalator else 0.74, 0.35 if is_escalator else 0.08, Color("#8878C4"), 0.26)
	var base_mat := Palette.make_stylized_material(Palette.CONCRETE_DARK, 0.84, 0.06, Color("#6E5CA8"), 0.20)
	var steel := Palette.make_stylized_material(Palette.STEEL_DARK, 0.50, 0.48, Color("#7D6EC4"), 0.25)
	var trim := Palette.make_emissive_material(accent_color, 2.0)

	var steps := maxi(8, int(roundf(height / 0.26)))
	var step_h := height / float(steps)
	var step_d := run_length / float(steps)

	# Build solid stepped blocks extending all the way down to y = 0.0 (zero floating gap underneath!)
	for i in range(steps):
		var top_y := float(i + 1) * step_h
		var z := -(float(i) + 0.5) * step_d
		# Solid architectural support block beneath each step
		var block := PropUtils.add_box(visual, Vector3(width, top_y + 0.2, step_d + 0.08), Vector3(0.0, top_y * 0.5 - 0.1, z), base_mat if i < steps - 1 else step_mat)
		block.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Crisp step tread cap
		var tread := PropUtils.add_box(visual, Vector3(width + 0.04, 0.08, step_d + 0.08), Vector3(0.0, top_y - 0.04, z), step_mat)
		tread.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if is_escalator or i % 3 == 0:
			var glow := PropUtils.add_box(visual, Vector3(width - 0.14, 0.03, 0.04), Vector3(0.0, top_y - 0.01, z + step_d * 0.5), trim)
			glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Side cheek walls / escalator glass-steel balustrades & handrails
	var slope_len := sqrt(run_length * run_length + height * height)
	var angle_rad := atan2(height, run_length)
	var angle_deg := rad_to_deg(angle_rad)
	var mid := Vector3(0.0, height * 0.5, -run_length * 0.5)

	for sx in [-width * 0.5 - 0.12, width * 0.5 + 0.12]:
		# Solid side cheek beam
		PropUtils.add_box(visual, Vector3(0.22, 0.65 if is_escalator else 0.36, slope_len + 0.3), mid + Vector3(sx, 0.25 if is_escalator else -0.02, 0.0), steel, Vector3(angle_deg, 0.0, 0.0))
		# Handrail
		PropUtils.add_box(visual, Vector3(0.10, 0.08, slope_len + 0.3), mid + Vector3(sx, 1.02, 0.0), steel, Vector3(angle_deg, 0.0, 0.0))
		if is_escalator:
			# Glowing side guide strip on escalator balustrade
			PropUtils.add_box(visual, Vector3(0.06, 0.07, slope_len), mid + Vector3(sx - signf(sx) * 0.10, 0.58, 0.0), trim, Vector3(angle_deg, 0.0, 0.0))
		PropUtils.add_box(visual, Vector3(0.10, 1.02, 0.10), Vector3(sx, 0.51, 0.0), steel)
		PropUtils.add_box(visual, Vector3(0.10, 1.02, 0.10), Vector3(sx, height + 0.51, -run_length), steel)
		PropUtils.add_static_box_collider(self, Vector3(0.24, 1.15, slope_len + 0.2), mid + Vector3(sx, 0.55, 0.0), Vector3(angle_deg, 0.0, 0.0))

	# Smooth sloped collider extending slightly at bottom & top so player never snags or hits a seam!
	PropUtils.add_static_box_collider(self, Vector3(width + 0.25, 0.55, slope_len + 0.7), mid - Vector3(0.0, 0.22, 0.0), Vector3(angle_deg, 0.0, 0.0))
	# Overlapping top & bottom landing aprons (flush at y=0 and y=height)
	PropUtils.add_static_box_collider(self, Vector3(width + 0.3, 0.5, 1.0), Vector3(0.0, -0.25, 0.3))
	PropUtils.add_static_box_collider(self, Vector3(width + 0.3, 0.5, 1.2), Vector3(0.0, height - 0.25, -run_length - 0.4))
