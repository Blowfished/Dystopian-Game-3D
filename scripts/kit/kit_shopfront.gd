@tool
class_name KitShopfront
extends Node3D

## Detailed ground-floor shopfront module (ramen, bar, arcade, karaoke, florist, tea, bakery, tech).
## Features recessed glowing interior depth (back wall, shelves/counter, ceiling light),
## doorway, striped awning, rolled metal shutter box, glowing menu board, and
## cheap additive warm wet-ground light pool so every street glows warmly!

@export_enum("ramen", "bar", "arcade", "karaoke", "florist", "tea", "bakery", "tech") var shop_type: String = "ramen":
	set(v):
		shop_type = v
		if is_inside_tree():
			_rebuild()

@export var width: float = 5.6
@export var add_light: bool = true


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	PropUtils.clear_children(self)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var frame_mat := Palette.make_stylized_material(Palette.STEEL_DARK, 0.55, 0.42, Color("#7A6BB5"), 0.24)
	var shutter_mat := Palette.make_stylized_material(Palette.STEEL_MID, 0.62, 0.38, Color("#8878C4"), 0.22)
	var wood_mat := Palette.make_stylized_material(Palette.WOOD_WARM, 0.74, 0.04, Color("#FFD29A"), 0.25)
	var interior_dark := Palette.make_stylized_material(Color("#2D1F28"), 0.85, 0.0, Color("#FFBF75"), 0.20)

	var glow_col := Palette.STALL_WARM
	var sign_col := Palette.LANTERN_AMBER
	var awning_col := Palette.AWNING_STRIPE_A
	var pool_col := Palette.LANTERN_AMBER

	match shop_type:
		"ramen":
			glow_col = Palette.STALL_WARM
			sign_col = Palette.LANTERN_AMBER
			awning_col = Palette.AWNING_STRIPE_A
			pool_col = Palette.LANTERN_AMBER
		"bar":
			glow_col = Color("#FFA066")
			sign_col = Palette.BEACON_MAGENTA
			awning_col = Color("#6E284D")
			pool_col = Color("#FF6B8A")
		"arcade":
			glow_col = Color("#72EBFF")
			sign_col = Palette.NEON_CYAN
			awning_col = Color("#24486E")
			pool_col = Palette.NEON_CYAN
		"karaoke":
			glow_col = Color("#FF8AC4")
			sign_col = Palette.BEACON_MAGENTA
			awning_col = Color("#702A60")
			pool_col = Palette.BEACON_MAGENTA
		"florist":
			glow_col = Palette.GREENHOUSE_GLOW
			sign_col = Palette.FLOWER_GOLD
			awning_col = Palette.CANOPY_SAGE
			pool_col = Palette.WINDOW_WARM_B
		"tea":
			glow_col = Palette.WINDOW_WARM_B
			sign_col = Palette.LANDMARK_TEAL
			awning_col = Palette.CANOPY_TEAL
			pool_col = Palette.LANTERN_AMBER
		"bakery":
			glow_col = Palette.WINDOW_WARM_A
			sign_col = Palette.STALL_WARM
			awning_col = Palette.CANOPY_OCHRE
			pool_col = Palette.STALL_WARM
		"tech":
			glow_col = Color("#A8D8FF")
			sign_col = Palette.LANDMARK_TEAL
			awning_col = Color("#2C3566")
			pool_col = Palette.LANDMARK_TEAL

	var win_mat := Palette.make_emissive_material(glow_col, 1.95)
	var sign_mat := Palette.make_emissive_material(sign_col, 2.75)
	var awning_a := Palette.make_stylized_material(awning_col, 0.84, 0.0, Color("#FFE2B8"), 0.25)
	var awning_b := Palette.make_stylized_material(Palette.AWNING_STRIPE_B, 0.82, 0.0, Color("#FFF0D4"), 0.25)

	# Outer surround frame (faces +Z, sits flush against building facade at z = 0)
	PropUtils.add_box(visual, Vector3(width, 3.6, 0.45), Vector3(0.0, 1.8, 0.0), frame_mat)

	# Recessed warm glowing interior box (visible depth through window!)
	var win_w := width * 0.62
	var win_x := -width * 0.14
	PropUtils.add_box(visual, Vector3(win_w, 2.15, 0.12), Vector3(win_x, 1.55, 0.20), win_mat)
	# Interior counter & shelf silhouettes in front of glowing back wall for cozy depth!
	PropUtils.add_box(visual, Vector3(win_w - 0.24, 0.65, 0.18), Vector3(win_x, 0.80, 0.27), wood_mat)
	PropUtils.add_box(visual, Vector3(win_w - 0.35, 0.08, 0.16), Vector3(win_x, 1.82, 0.26), interior_dark)
	# Crisp wooden window mullions
	for mx in [-win_w * 0.28, 0.0, win_w * 0.28]:
		PropUtils.add_box(visual, Vector3(0.07, 2.2, 0.12), Vector3(win_x + mx, 1.55, 0.30), frame_mat)
	PropUtils.add_box(visual, Vector3(win_w + 0.1, 0.10, 0.22), Vector3(win_x, 0.48, 0.32), frame_mat)

	# Glass & wood doorway on right side (+X)
	var door_x := width * 0.33
	var door_w := width * 0.24
	PropUtils.add_box(visual, Vector3(door_w, 2.45, 0.16), Vector3(door_x, 1.24, 0.22), wood_mat)
	PropUtils.add_box(visual, Vector3(door_w * 0.68, 1.25, 0.08), Vector3(door_x, 1.62, 0.29), win_mat)
	PropUtils.add_box(visual, Vector3(0.06, 0.32, 0.08), Vector3(door_x - door_w * 0.28, 1.12, 0.34), shutter_mat)

	# Rolled metal shutter housing box above window & door
	PropUtils.add_box(visual, Vector3(width - 0.15, 0.36, 0.42), Vector3(0.0, 2.86, 0.36), shutter_mat)

	# Striped overhanging storefront awning
	var stripes := 7
	var sw := (width - 0.1) / float(stripes)
	for i in range(stripes):
		var sx := -(width - 0.1) * 0.5 + sw * (float(i) + 0.5)
		var am := awning_a if i % 2 == 0 else awning_b
		var panel := PropUtils.add_box(visual, Vector3(sw - 0.01, 0.07, 1.35), Vector3(sx, 2.66, 0.88), am, Vector3(20.0, 0.0, 0.0))
		panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Upper glowing fascia signboard
	PropUtils.add_box(visual, Vector3(width * 0.82, 0.62, 0.24), Vector3(0.0, 3.35, 0.36), frame_mat)
	var sign_face := PropUtils.add_box(visual, Vector3(width * 0.76, 0.46, 0.10), Vector3(0.0, 3.35, 0.46), sign_mat)
	sign_face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Sidewalk standing menu A-frame board beside doorway
	var menu_x := door_x + door_w * 0.45
	PropUtils.add_box(visual, Vector3(0.55, 0.92, 0.32), Vector3(menu_x, 0.46, 0.92), wood_mat)
	var menu_glow := PropUtils.add_box(visual, Vector3(0.42, 0.62, 0.05), Vector3(menu_x, 0.54, 1.09), win_mat)
	menu_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Cheap fake wet-ground light pool spilling onto the sidewalk in front of the window!
	PropUtils.add_ground_glow_pool(visual, Vector3(0.0, 0.0, 2.1), Vector2(width * 1.15, 4.4), pool_col, 0.30, 95.0)

	# Optional soft distance-faded non-shadow local light for warm street illumination
	if add_light:
		PropUtils.make_fade_omni(self, Vector3(0.0, 2.1, 1.75), glow_col, 2.1, 10.5, 32.0)

	PropUtils.add_static_box_collider(self, Vector3(width, 3.6, 0.55), Vector3(0.0, 1.8, 0.05))
