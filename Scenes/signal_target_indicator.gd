extends Node2D

enum VisualState { NONE, INACTIVE, ACTIVE }

const SPAWN_SCALE := 1.5
const SPAWN_ROTATION_DEG := 45.0
const TRANSITION_DURATION := 0.5
const ALPHA_TWEEN_DURATION := 0.18
const FORCED_DISCONNECT_FEEDBACK_DURATION := 0.22

@export var frame_size: Vector2 = Vector2(74.0, 74.0)
@export var corner_length: float = 18.0
@export var line_width: float = 2
@export var frame_color: Color = Color(0.65, 1.0, 0.72, 1.0)
@export var forced_disconnect_line_color: Color = Color(1.0, 0.25, 0.25, 1.0)
@export var active_alpha: float = 1.0
@export var inactive_alpha: float = 0.35
@export var frame_padding: Vector2 = Vector2(14.0, 14.0)

@onready var indicator_line: Line2D = $IndicatorLine

var _owner_entity: Node2D = null
var _current_state := VisualState.NONE
var _transition_tween: Tween = null
var _disconnect_feedback_tween: Tween = null
var _disconnect_feedback_active := false

func _ready() -> void:
	frame_size = Vector2(maxf(frame_size.x, 1.0), maxf(frame_size.y, 1.0))
	corner_length = maxf(corner_length, 1.0)
	line_width = maxf(line_width, 1.0)
	visible = false
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	scale = Vector2.ONE
	rotation_degrees = 0.0
	if indicator_line != null:
		indicator_line.visible = false
		indicator_line.top_level = true
		indicator_line.default_color = frame_color
	_refresh_processing()

func initialize(owner_entity: Node2D) -> void:
	_owner_entity = owner_entity
	_refresh_line_visuals()
	_refresh_line_geometry()

func configure_for_icon_size(icon_size: Vector2) -> void:
	frame_size = Vector2(
		maxf(icon_size.x + (frame_padding.x * 2.0), 1.0),
		maxf(icon_size.y + (frame_padding.y * 2.0), 1.0)
	)
	queue_redraw()
	_refresh_line_geometry()

func set_visual_state(new_state: int) -> void:
	if _current_state == new_state:
		_refresh_line_visuals()
		_refresh_line_geometry()
		return

	var previous_state := _current_state
	_current_state = new_state

	match new_state:
		VisualState.NONE:
			_refresh_line_visuals()
			_play_hide_animation()
		VisualState.INACTIVE, VisualState.ACTIVE:
			if previous_state == VisualState.NONE:
				_play_show_animation()
			else:
				_play_alpha_transition(_get_state_alpha(new_state))
			visible = true
			_refresh_line_visuals()
			_refresh_line_geometry()

	_refresh_processing()

func refresh_geometry() -> void:
	queue_redraw()
	_refresh_line_geometry()

func _process(_delta: float) -> void:
	_refresh_line_visuals()
	_refresh_line_geometry()

func _draw() -> void:
	var half_size := frame_size * 0.5
	var left := -half_size.x
	var right := half_size.x
	var top := -half_size.y
	var bottom := half_size.y
	var horizontal_corner := minf(corner_length, frame_size.x * 0.5)
	var vertical_corner := minf(corner_length, frame_size.y * 0.5)

	draw_line(Vector2(left, top), Vector2(left + horizontal_corner, top), frame_color, line_width)
	draw_line(Vector2(left, top), Vector2(left, top + vertical_corner), frame_color, line_width)

	draw_line(Vector2(right - horizontal_corner, top), Vector2(right, top), frame_color, line_width)
	draw_line(Vector2(right, top), Vector2(right, top + vertical_corner), frame_color, line_width)

	draw_line(Vector2(left, bottom), Vector2(left + horizontal_corner, bottom), frame_color, line_width)
	draw_line(Vector2(left, bottom - vertical_corner), Vector2(left, bottom), frame_color, line_width)

	draw_line(Vector2(right - horizontal_corner, bottom), Vector2(right, bottom), frame_color, line_width)
	draw_line(Vector2(right, bottom - vertical_corner), Vector2(right, bottom), frame_color, line_width)

func _play_show_animation() -> void:
	_stop_transition_tween()
	visible = true
	scale = Vector2.ONE * SPAWN_SCALE
	rotation_degrees = SPAWN_ROTATION_DEG
	modulate.a = 0.0
	_transition_tween = create_tween()
	var scale_tween := _transition_tween.tween_property(self, "scale", Vector2.ONE, TRANSITION_DURATION)
	scale_tween.set_trans(Tween.TRANS_QUAD)
	scale_tween.set_ease(Tween.EASE_OUT)
	var rotation_tween := _transition_tween.parallel().tween_property(self, "rotation_degrees", 0.0, TRANSITION_DURATION)
	rotation_tween.set_trans(Tween.TRANS_QUAD)
	rotation_tween.set_ease(Tween.EASE_OUT)
	var alpha_tween := _transition_tween.parallel().tween_property(self, "modulate:a", _get_state_alpha(_current_state), TRANSITION_DURATION)
	alpha_tween.set_trans(Tween.TRANS_QUAD)
	alpha_tween.set_ease(Tween.EASE_OUT)

func _play_hide_animation() -> void:
	_stop_transition_tween()
	if not visible:
		_apply_hidden_state()
		return

	_transition_tween = create_tween()
	var scale_tween := _transition_tween.tween_property(self, "scale", Vector2.ONE * SPAWN_SCALE, TRANSITION_DURATION)
	scale_tween.set_trans(Tween.TRANS_QUAD)
	scale_tween.set_ease(Tween.EASE_IN)
	var rotation_tween := _transition_tween.parallel().tween_property(self, "rotation_degrees", SPAWN_ROTATION_DEG, TRANSITION_DURATION)
	rotation_tween.set_trans(Tween.TRANS_QUAD)
	rotation_tween.set_ease(Tween.EASE_IN)
	var alpha_tween := _transition_tween.parallel().tween_property(self, "modulate:a", 0.0, TRANSITION_DURATION)
	alpha_tween.set_trans(Tween.TRANS_QUAD)
	alpha_tween.set_ease(Tween.EASE_IN)
	_transition_tween.finished.connect(_apply_hidden_state, CONNECT_ONE_SHOT)

func _play_alpha_transition(target_alpha: float) -> void:
	_stop_transition_tween()
	transition_to_alpha(target_alpha)

func transition_to_alpha(target_alpha: float) -> void:
	_transition_tween = create_tween()
	var alpha_tween := _transition_tween.tween_property(self, "modulate:a", target_alpha, ALPHA_TWEEN_DURATION)
	alpha_tween.set_trans(Tween.TRANS_SINE)
	alpha_tween.set_ease(Tween.EASE_OUT)

func _apply_hidden_state() -> void:
	visible = false
	scale = Vector2.ONE
	rotation_degrees = 0.0
	modulate.a = 0.0
	_disconnect_feedback_active = false
	if indicator_line != null:
		indicator_line.visible = false
	_refresh_processing()

func _stop_transition_tween() -> void:
	if _transition_tween != null:
		_transition_tween.kill()
		_transition_tween = null

func _refresh_processing() -> void:
	set_process(visible)

func _refresh_line_visuals() -> void:
	if indicator_line == null:
		return
	if _disconnect_feedback_active:
		return
	var line_color := frame_color
	line_color.a = modulate.a
	indicator_line.default_color = line_color
	indicator_line.width = line_width
	indicator_line.visible = _should_show_line()

func _refresh_line_geometry() -> void:
	if indicator_line == null:
		return
	if not _should_show_line():
		indicator_line.visible = false
		return

	var terminal_window = CommandDispatch.terminal_window
	if terminal_window == null or _owner_entity == null:
		indicator_line.visible = false
		return

	var active_sig = _owner_entity.get("my_active_sig")
	if active_sig == null or active_sig.terminal_session == null:
		indicator_line.visible = false
		return

	var tab_anchor_global: Vector2 = terminal_window.get_tab_anchor_global_position(active_sig.terminal_session)
	if is_inf(tab_anchor_global.x) or is_inf(tab_anchor_global.y):
		indicator_line.visible = false
		return

	var global_target := get_indicator_bottom_global_position()
	indicator_line.points = PackedVector2Array([tab_anchor_global, global_target])
	indicator_line.visible = true

func get_indicator_bottom_local_position() -> Vector2:
	return Vector2(0.0, frame_size.y * 0.5)

func get_indicator_bottom_global_position() -> Vector2:
	return get_global_transform_with_canvas() * get_indicator_bottom_local_position()

func _get_state_alpha(state: int) -> float:
	match state:
		VisualState.ACTIVE:
			return active_alpha
		VisualState.INACTIVE:
			return inactive_alpha
		_:
			return 0.0

func _should_show_line() -> bool:
	if not visible:
		return false
	if _current_state == VisualState.ACTIVE:
		return true
	if _current_state != VisualState.INACTIVE:
		return false

	var terminal_window = CommandDispatch.terminal_window
	return terminal_window != null and terminal_window.show_inactive_session_lines

func play_forced_disconnect_feedback() -> void:
	if indicator_line == null:
		return
	if not _should_show_line():
		return

	if _disconnect_feedback_tween != null:
		_disconnect_feedback_tween.kill()

	_disconnect_feedback_active = true
	var line_color := forced_disconnect_line_color
	line_color.a = modulate.a
	indicator_line.visible = true
	indicator_line.default_color = line_color
	var faded_color := line_color
	faded_color.a = 0.0
	_disconnect_feedback_tween = create_tween()
	var color_tween := _disconnect_feedback_tween.tween_property(
		indicator_line,
		"default_color",
		faded_color,
		FORCED_DISCONNECT_FEEDBACK_DURATION
	)
	color_tween.set_trans(Tween.TRANS_SINE)
	color_tween.set_ease(Tween.EASE_IN)
	await _disconnect_feedback_tween.finished
	_disconnect_feedback_tween = null
	_disconnect_feedback_active = false
	if indicator_line != null:
		indicator_line.visible = false
