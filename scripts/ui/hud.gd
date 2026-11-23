extends CanvasLayer

@onready var title_label: Label = %TitleLabel
@onready var quality_button: Button = %QualityButton
@onready var fps_label: Label = %FpsLabel
@onready var debug_label: Label = %DebugLabel
@onready var controls_panel: PanelContainer = %ControlsPanel
@onready var cursor_hint: Label = %CursorHint
@onready var interact_prompt: Label = %InteractPrompt
@onready var minimap: MinimapControl = %Minimap
@onready var full_map: FullMapOverlay = %FullMapOverlay

var _controls_visible: bool = true
var _user_toggled_help: bool = false
var _player_ref: Node3D = null


func _ready() -> void:
	layer = 20
	title_label.text = GameState.current_stratum_name
	quality_button.pressed.connect(_on_quality_button_pressed)
	GameState.quality_changed.connect(_on_quality_changed)
	GameState.cursor_mode_changed.connect(_on_cursor_mode_changed)
	GameState.district_changed.connect(_on_district_changed)
	GameState.interact_prompt_changed.connect(_on_interact_prompt_changed)
	GameState.map_opened.connect(_on_map_opened)
	full_map.travel_requested.connect(_on_fast_travel_requested)

	_on_quality_changed(GameState.quality_level)
	_on_cursor_mode_changed(GameState.is_cursor_captured())
	debug_label.visible = GameState.debug_overlay_visible
	interact_prompt.visible = false
	_schedule_help_auto_hide()


func set_player(player: Node3D) -> void:
	_player_ref = player
	if minimap:
		minimap.player_node = player
	if full_map:
		full_map.player_node = player


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_help"):
		_user_toggled_help = true
		_controls_visible = not _controls_visible
		controls_panel.modulate.a = 1.0
		controls_panel.visible = _controls_visible
	elif event.is_action_pressed("toggle_debug"):
		GameState.debug_overlay_visible = not GameState.debug_overlay_visible
		debug_label.visible = GameState.debug_overlay_visible
	elif event.is_action_pressed("toggle_map"):
		if full_map.visible:
			full_map.close_map()
		else:
			full_map.open_map(false)
	elif event.is_action_pressed("ui_cancel") and full_map.visible:
		full_map.close_map()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	var fps := Engine.get_frames_per_second()
	fps_label.text = "%d FPS" % fps
	if debug_label.visible:
		var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		var lights := get_tree().get_nodes_in_group("secondary_lights").filter(func(n: Node) -> bool: return n is Light3D and n.is_visible_in_tree()).size()
		debug_label.text = "FPS: %d\nDraw Calls: %d\nPrimitives: %d\nActive Local Lights: %d\nDistrict: %s" % [fps, draw_calls, prims, lights, GameState.current_district_id]


func _schedule_help_auto_hide() -> void:
	await get_tree().create_timer(8.0).timeout
	if _user_toggled_help or not _controls_visible:
		return
	var tw := create_tween()
	tw.tween_property(controls_panel, "modulate:a", 0.0, 0.45)
	await tw.finished
	if not _user_toggled_help:
		_controls_visible = false
		controls_panel.visible = false
		controls_panel.modulate.a = 1.0


func _on_quality_button_pressed() -> void:
	GameState.cycle_quality()


func _on_quality_changed(_level: GameState.QualityLevel) -> void:
	quality_button.text = "Quality: %s  [F1]" % GameState.get_quality_name()


func _on_cursor_mode_changed(captured: bool) -> void:
	cursor_hint.visible = not captured and not full_map.visible


func _on_district_changed(_id: String, district_name: String) -> void:
	title_label.text = district_name


func _on_interact_prompt_changed(prompt_text: String) -> void:
	interact_prompt.text = prompt_text
	interact_prompt.visible = not prompt_text.is_empty()


func _on_map_opened(fast_travel_mode: bool) -> void:
	full_map.open_map(fast_travel_mode)


func _on_fast_travel_requested(target_pos: Vector3, _label: String) -> void:
	if _player_ref is CourierController:
		SceneTransition.fade_blink(func() -> void:
			_player_ref.teleport_to(target_pos)
			AudioManager.play_chime(1.0)
		)
