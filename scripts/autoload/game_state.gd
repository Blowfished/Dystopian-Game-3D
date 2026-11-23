extends Node

## Global GameState autoload.
## Manages graphics quality presets, current district, map/transit state,
## respawn checkpoints, and future NPC/quest stubs.

enum QualityLevel {
	LOW = 0,
	MEDIUM = 1,
	HIGH = 2,
}

signal quality_changed(level: QualityLevel)
signal cursor_mode_changed(captured: bool)
signal district_changed(district_id: String, district_name: String)
signal interact_prompt_changed(prompt_text: String)
signal map_opened(fast_travel_mode: bool)

var quality_level: QualityLevel = QualityLevel.MEDIUM
var last_safe_position: Vector3 = Vector3(-104.0, 0.35, 3.0)
var current_district_id: String = "noodle_alley"
var current_stratum_name: String = "NOODLE ALLEY // RAINY PROMENADE"
var is_map_open: bool = false
var debug_overlay_visible: bool = false

# City registry populated by CityLayoutLoader
var districts_data: Array[Dictionary] = []
var stations_data: Array[Dictionary] = []
var pois_data: Array[Dictionary] = []
var tram_world_position: Vector3 = Vector3.ZERO
var active_interactable: Node = null

# Future game-loop stubs (Stage 2+: NPCs, crowds, quests)
var parcels_delivered: int = 0
var active_delivery_id: String = ""
var discovered_pois: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_quality(level: QualityLevel) -> void:
	if quality_level == level:
		return
	quality_level = level
	quality_changed.emit(quality_level)


func cycle_quality() -> void:
	var next_level: QualityLevel = ((int(quality_level) + 1) % 3) as QualityLevel
	set_quality(next_level)


func get_quality_name() -> String:
	match quality_level:
		QualityLevel.LOW:
			return "Low"
		QualityLevel.MEDIUM:
			return "Medium"
		QualityLevel.HIGH:
			return "High"
	return "Medium"


func set_cursor_captured(captured: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE
	cursor_mode_changed.emit(captured)


func is_cursor_captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


func set_current_district(district_id: String, district_name: String) -> void:
	if current_district_id == district_id and current_stratum_name == district_name:
		return
	current_district_id = district_id
	current_stratum_name = district_name
	district_changed.emit(district_id, district_name)


func set_interact_prompt(prompt_text: String, source: Node = null) -> void:
	active_interactable = source if not prompt_text.is_empty() else null
	interact_prompt_changed.emit(prompt_text)


func request_open_map(fast_travel_mode: bool = false) -> void:
	map_opened.emit(fast_travel_mode)
