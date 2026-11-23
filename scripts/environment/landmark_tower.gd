@tool
class_name LandmarkTower
extends Node3D

## Iconic glowing teal tiered Lattice megastructure landmark with a pulsing magenta beacon spire.

var _beacon_mat: StandardMaterial3D
var _beacon_light: OmniLight3D
var _time: float = 0.0


func _ready() -> void:
	_rebuild()


func _process(delta: float) -> void:
	_time += delta
	var pulse := 0.72 + 0.28 * sin(_time * 2.4)
	if _beacon_mat:
		_beacon_mat.emission_energy_multiplier = 4.2 * pulse + 1.4
	if _beacon_light:
		_beacon_light.light_energy = 8.0 * pulse


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var body_mat := Palette.make_stylized_material(Color("#0E2538"), 0.55, 0.35, Palette.LANDMARK_TEAL, 0.45)
	var core_mat := Palette.make_stylized_material(Color("#12394A"), 0.48, 0.30, Palette.LANDMARK_TEAL, 0.55)
	var teal_glow := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 3.2, 0.2)
	var teal_soft := Palette.make_emissive_material(Color("#1AC7B8"), 1.6, 0.3)
	var magenta_trim := Palette.make_emissive_material(Palette.BEACON_MAGENTA, 3.8, 0.15)
	_beacon_mat = Palette.make_emissive_material(Palette.BEACON_MAGENTA, 5.2, 0.1)

	# Deep megastructure plinth descending into the abyss
	PropUtils.add_box(visual, Vector3(26.0, 48.0, 26.0), Vector3(0.0, 24.0, 0.0), body_mat)
	PropUtils.add_box(visual, Vector3(26.6, 0.9, 26.6), Vector3(0.0, 46.5, 0.0), teal_glow)

	# 7 stacked tapered/flared pagoda-style tiers (iconic silhouette!)
	var tier_count := 7
	var base_y := 48.0
	var tier_h := 13.5
	for i in range(tier_count):
		var shrink := 1.0 - float(i) * 0.055
		var w := 20.5 * shrink
		var cy := base_y + float(i) * tier_h + tier_h * 0.5

		# Inner recessed shaft
		PropUtils.add_box(visual, Vector3(w * 0.80, tier_h * 0.85, w * 0.80), Vector3(0.0, cy - 0.6, 0.0), core_mat)
		# Flared upper crown collar of each tier
		PropUtils.add_box(visual, Vector3(w, tier_h * 0.46, w), Vector3(0.0, cy + tier_h * 0.24, 0.0), body_mat)
		# Glowing teal architectural eaves wrapping each tier
		PropUtils.add_box(visual, Vector3(w + 0.7, 0.75, w + 0.7), Vector3(0.0, cy + tier_h * 0.46, 0.0), teal_glow)
		PropUtils.add_box(visual, Vector3(w * 0.86, 0.55, w * 0.86), Vector3(0.0, cy - tier_h * 0.12, 0.0), teal_soft)

		# Delicate magenta corner accent verticals on alternating tiers
		for cx in [-1.0, 1.0]:
			for cz in [-1.0, 1.0]:
				PropUtils.add_box(
					visual,
					Vector3(0.55, tier_h * 0.68, 0.55),
					Vector3(cx * (w * 0.5 + 0.15), cy + 1.2, cz * (w * 0.5 + 0.15)),
					magenta_trim if (i % 2 == 0) else teal_glow
				)

	# Vertical glowing teal spine ribs along all 4 faces
	var spine_h := float(tier_count) * tier_h
	var spine_cy := base_y + spine_h * 0.5
	PropUtils.add_box(visual, Vector3(1.1, spine_h, 19.2), Vector3(0.0, spine_cy, 0.0), teal_soft)
	PropUtils.add_box(visual, Vector3(19.2, spine_h, 1.1), Vector3(0.0, spine_cy, 0.0), teal_soft)

	# Stepped spire crown & glowing magenta beacon
	var top_y := base_y + spine_h
	PropUtils.add_box(visual, Vector3(10.5, 8.0, 10.5), Vector3(0.0, top_y + 4.0, 0.0), core_mat)
	PropUtils.add_box(visual, Vector3(11.0, 0.85, 11.0), Vector3(0.0, top_y + 8.0, 0.0), teal_glow)
	PropUtils.add_box(visual, Vector3(5.6, 10.0, 5.6), Vector3(0.0, top_y + 13.0, 0.0), body_mat)
	PropUtils.add_box(visual, Vector3(6.2, 0.75, 6.2), Vector3(0.0, top_y + 18.0, 0.0), magenta_trim)

	# Tall slender antenna spire
	PropUtils.add_cylinder(visual, 0.45, 1.35, 34.0, Vector3(0.0, top_y + 35.0, 0.0), teal_glow, Vector3.ZERO, 10)
	PropUtils.add_cylinder(visual, 0.65, 0.65, 10.0, Vector3(0.0, top_y + 46.0, 0.0), _beacon_mat, Vector3.ZERO, 10)
	# Pulsing Magenta Beacon Orb at peak
	PropUtils.add_sphere(visual, 2.35, Vector3(0.0, top_y + 52.5, 0.0), _beacon_mat, Vector3.ONE, 14)

	# Soft magenta sky halo around beacon
	_beacon_light = OmniLight3D.new()
	_beacon_light.position = Vector3(0.0, top_y + 52.5, 0.0)
	_beacon_light.light_color = Palette.BEACON_MAGENTA
	_beacon_light.light_energy = 7.5
	_beacon_light.omni_range = 65.0
	_beacon_light.omni_attenuation = 1.2
	add_child(_beacon_light)
