extends CanvasLayer

## SceneTransition autoload stub.
## Provides smooth indigo fade transitions for future scene changes and chasm respawns.

var _fade_rect: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color("#080C1C")
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade_rect)


func transition_to_scene(scene_path: String, duration: float = 0.45) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	var tw := create_tween()
	tw.tween_property(_fade_rect, "modulate:a", 1.0, duration * 0.5)
	await tw.finished
	get_tree().change_scene_to_file(scene_path)
	var tw2 := create_tween()
	tw2.tween_property(_fade_rect, "modulate:a", 0.0, duration * 0.5)
	await tw2.finished
	_is_transitioning = false


func fade_blink(mid_callback: Callable, duration: float = 0.42) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	var tw := create_tween()
	tw.tween_property(_fade_rect, "modulate:a", 1.0, duration * 0.45)
	await tw.finished
	if mid_callback.is_valid():
		mid_callback.call()
	var tw2 := create_tween()
	tw2.tween_property(_fade_rect, "modulate:a", 0.0, duration * 0.55)
	await tw2.finished
	_is_transitioning = false
