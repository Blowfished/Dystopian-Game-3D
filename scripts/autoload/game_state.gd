extends Node

## Global GameState autoload.
## Manages graphics quality presets, respawn checkpoints, and future game-state stubs.

enum QualityLevel {
	LOW = 0,
	MEDIUM = 1,
	HIGH = 2,
}

signal quality_changed(level: QualityLevel)
signal cursor_mode_changed(captured: bool)

var quality_level: QualityLevel = QualityLevel.MEDIUM
var last_safe_position: Vector3 = Vector3(0.0, 0.35, 0.0)
var current_stratum_name: String = "LATTICE STRATUM 47 // RAINY PROMENADE"

# Future game-loop stubs (Stage 2+)
var parcels_delivered: int = 0
var active_delivery_id: String = ""


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
