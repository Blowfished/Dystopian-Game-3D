extends CanvasLayer

@onready var title_label: Label = %TitleLabel
@onready var quality_button: Button = %QualityButton
@onready var fps_label: Label = %FpsLabel
@onready var controls_panel: PanelContainer = %ControlsPanel
@onready var cursor_hint: Label = %CursorHint

var _controls_visible: bool = true


func _ready() -> void:
	layer = 20
	title_label.text = GameState.current_stratum_name
	quality_button.pressed.connect(_on_quality_button_pressed)
	GameState.quality_changed.connect(_on_quality_changed)
	GameState.cursor_mode_changed.connect(_on_cursor_mode_changed)
	_on_quality_changed(GameState.quality_level)
	_on_cursor_mode_changed(GameState.is_cursor_captured())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_help"):
		_controls_visible = not _controls_visible
		controls_panel.visible = _controls_visible


func _process(_delta: float) -> void:
	fps_label.text = "%d FPS" % Engine.get_frames_per_second()


func _on_quality_button_pressed() -> void:
	GameState.cycle_quality()


func _on_quality_changed(_level: GameState.QualityLevel) -> void:
	quality_button.text = "Quality: %s  [F1]" % GameState.get_quality_name()


func _on_cursor_mode_changed(captured: bool) -> void:
	cursor_hint.visible = not captured
