class_name KitTramStation
extends Node3D

## Architectural Maglev Tram Station with solid substructure piers extending down
## into the lower city, warm sheltered canopy, safety edge markers, and interactive
## fast-travel kiosk. Flush-aligned with the promenade and Maglev Tram deck.

@export var station_id: String = "station_noodle"
@export var station_name: String = "Noodle Alley West"


func _ready() -> void:
	add_to_group("walkable_surfaces")
	set_meta("walkable_type", "tram_station")
	set_meta("walkable_size", Vector3(20.0, 0.6, 6.4))
	set_meta("support_type", "solid_station_podium")
	_build_station()


func _build_station() -> void:
	PropUtils.clear_children(self)
	var concrete := Palette.make_stylized_material(Palette.CONCRETE_DARK, 0.80, 0.08, Color("#6E5CA8"), 0.22)
	var steel := Palette.make_stylized_material(Palette.STEEL_MID, 0.48, 0.50, Color("#8C7DD1"), 0.30)
	var teal := Palette.make_emissive_material(Palette.LANDMARK_TEAL, 2.5)
	var amber := Palette.make_emissive_material(Palette.LANTERN_AMBER, 2.4)
	var warm_ceiling := Palette.make_emissive_material(Palette.STALL_WARM, 2.0)

	# Station boarding platform (raised 0.025m above street/plaza top to prevent Z-fighting while remaining completely flush!)
	PropUtils.add_box(self, Vector3(20.0, 0.65, 6.4), Vector3(0.0, -0.30, 0.0), concrete)
	PropUtils.add_static_box_collider(self, Vector3(20.6, 0.9, 7.0), Vector3(0.0, -0.45, 0.2))

	# Solid concrete substructure podium extending down into the lower city strata (never floating!)
	var base := PropUtils.add_box(self, Vector3(19.6, 26.0, 5.8), Vector3(0.0, -13.65, 0.0), concrete)
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	base.visibility_range_end = 260.0

	# Glowing amber safety line facing the track (-Z at z = -3.0)
	PropUtils.add_box(self, Vector3(19.4, 0.04, 0.16), Vector3(0.0, 0.025, -2.92), amber)

	# Partial safety barrier rails on the left & right ends of the platform edge (leaving 13m center boarding zone!)
	for sx in [-8.2, 8.2]:
		PropUtils.add_box(self, Vector3(3.4, 0.07, 0.08), Vector3(sx, 1.0, -3.08), steel)
		PropUtils.add_box(self, Vector3(3.4, 0.05, 0.05), Vector3(sx, 0.5, -3.08), steel)
		PropUtils.add_static_box_collider(self, Vector3(3.5, 1.08, 0.16), Vector3(sx, 0.54, -3.08))

	# Cantilevered station canopy roof
	for px in [-7.5, -2.5, 2.5, 7.5]:
		PropUtils.add_box(self, Vector3(0.30, 3.8, 0.30), Vector3(px, 1.9, 1.9), steel)
	PropUtils.add_box(self, Vector3(18.8, 0.28, 5.6), Vector3(0.0, 3.85, 0.15), steel, Vector3(5.0, 0.0, 0.0))
	PropUtils.add_box(self, Vector3(18.4, 0.08, 0.10), Vector3(0.0, 3.56, -2.58), teal)
	PropUtils.add_box(self, Vector3(15.6, 0.08, 0.55), Vector3(0.0, 3.66, 0.2), warm_ceiling)

	# Transit Map Kiosk terminal
	PropUtils.add_box(self, Vector3(1.2, 1.85, 0.38), Vector3(0.0, 0.925, 1.6), steel)
	PropUtils.add_box(self, Vector3(0.95, 0.78, 0.08), Vector3(0.0, 1.30, 1.40), teal)

	# Warm ground glow pools + distance-faded non-shadow station light
	PropUtils.add_ground_glow_pool(self, Vector3(0.0, 0.0, 0.0), Vector2(18.0, 5.8), Palette.LANTERN_AMBER, 0.24, 110.0)
	PropUtils.make_fade_omni(self, Vector3(0.0, 3.1, 0.0), Palette.STALL_WARM, 2.4, 14.0, 44.0)

	# Interaction trigger around the kiosk
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5.0, 2.5, 4.0)
	cs.shape = shape
	cs.position = Vector3(0.0, 1.25, 0.8)
	area.add_child(cs)
	area.body_entered.connect(func(b: Node3D) -> void:
		if b is CourierController:
			GameState.set_interact_prompt("[F] Transit Map (%s)" % station_name, self)
	)
	area.body_exited.connect(func(b: Node3D) -> void:
		if b is CourierController and GameState.active_interactable == self:
			GameState.set_interact_prompt("", null)
	)
	add_child(area)


func interact(_player: Node) -> void:
	GameState.request_open_map(true)
