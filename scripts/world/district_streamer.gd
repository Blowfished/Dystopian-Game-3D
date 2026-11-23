class_name DistrictStreamer
extends Node

## Streams district detail props & local lights in/out around the player
## for steady 60 FPS, and updates GameState.current_district_id as the courier explores.

@export var player_path: NodePath
@export var active_radius: float = 95.0

var _player: Node3D
var _districts: Array[Dictionary] = []
var _check_timer: float = 0.0


func register_district_chunk(id: String, display_name: String, center: Vector3, radius: float, chunk_root: Node3D, detail_root: Node3D) -> void:
	_districts.append({
		"id": id,
		"name": display_name,
		"center": center,
		"radius": radius,
		"chunk": chunk_root,
		"detail": detail_root,
	})


func _ready() -> void:
	if not player_path.is_empty():
		_player = get_node_or_null(player_path) as Node3D


func _process(delta: float) -> void:
	if _player == null or _districts.is_empty():
		return
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = 0.25
	update_for_position(_player.global_position)


func update_for_position(ppos: Vector3) -> void:
	var best_id := ""
	var best_name := ""
	var best_dist := INF

	for d in _districts:
		var center: Vector3 = d["center"]
		var dist := Vector2(ppos.x - center.x, ppos.z - center.z).length()
		var detail: Node3D = d["detail"]
		var should_be_active := dist <= (active_radius + float(d["radius"]) * 0.45)
		if is_instance_valid(detail):
			detail.visible = should_be_active
			detail.process_mode = Node.PROCESS_MODE_INHERIT if should_be_active else Node.PROCESS_MODE_DISABLED

		if dist < best_dist:
			best_dist = dist
			best_id = d["id"]
			best_name = d["name"]

	if not best_id.is_empty():
		GameState.set_current_district(best_id, best_name)
