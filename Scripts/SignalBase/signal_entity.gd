# signal_entity.gd
# Visual controller and input router for Signals on the Timeline

extends Node2D
@onready var shape = $Shape
@onready var signal_icon: Area2D = $SignalIcon
@onready var target_indicator: Node2D = $TargetIndicator

@onready var scan_radial = $ScanRadial
@onready var scan_queue_label: Label = $ScanQueueLabel

@onready var tooltip_main = $DetailTooltip

@onready var detection_controller = $DetectionController

var mobility_controller: MobilityController = null
var _guard_revealed: bool = true
var _alert_visual_t: float = 0.0
var _is_hover_highlighted: bool = false

var my_data: SignalData
var my_active_sig: ActiveSignal

var is_disabled: bool = false

signal signal_interaction(data: SignalData)
signal scan_toggle_requested(clicked_signal: ActiveSignal)
signal tooltip_lock_requested(target_signal: ActiveSignal)
signal hover_started(hovered_signal: ActiveSignal)
signal hover_ended(hovered_signal: ActiveSignal)

func _ready():
	scan_radial.visible = false
	scan_queue_label.visible = false
	set_process(true)
	if target_indicator != null and target_indicator.has_method("initialize"):
		target_indicator.initialize(self)

func setup(signal_wrapper: ActiveSignal):
	my_data = signal_wrapper.data
	my_active_sig = signal_wrapper

	if my_active_sig != null and not my_active_sig.runtime_position_initialized:
		my_active_sig.runtime_cell_x = my_active_sig.start_cell_index
		my_active_sig.runtime_lane = my_data.lane
		my_active_sig.runtime_lane_pos = float(my_data.lane)
		my_active_sig.runtime_body_facing_deg = my_data.facing_deg
		my_active_sig.runtime_detection_facing_deg = my_data.facing_deg
		my_active_sig.runtime_position_initialized = true
	if my_data != null and my_data.detection != null and my_active_sig != null:
		my_data.detection.initialize_runtime(my_active_sig)


	initialize_tooltip()
	refresh_status_panels()
	tooltip_main.set_tooltip_collapsed(my_active_sig.is_tooltip_collapsed)

	detection_controller.initialize(self)
	_setup_mobility(signal_wrapper)
	if my_data.type == SignalData.Type.GUARD and my_data.mobility != null:
		set_guard_revealed(false)
	update_visuals()
	if my_active_sig != null and my_active_sig.is_disabled and detection_controller != null:
		detection_controller.disable_vision()
	refresh_session_indicator_geometry()
	_sync_session_indicator_state()
	
	
func update_visuals():
	var visual_source: SignalVisuals = my_data.visuals
	if my_data.use_alternate_visuals and my_data.alternate_visuals != null:
		visual_source = my_data.alternate_visuals

	if visual_source != null:
		shape.color = visual_source.fill_color
		shape.polygon = visual_source.polygon
	else:
		shape.color = Color.WHITE
		shape.polygon = PackedVector2Array([Vector2(-25, -25), Vector2(25, -25), Vector2(25, 25), Vector2(-25, 25)])

	if my_data.type == SignalData.Type.GUARD and my_data.mobility != null:
		set_guard_revealed(_guard_revealed)

	if my_active_sig.is_disabled:
		shape.color = Color.DIM_GRAY

	shape.rotation_degrees = _get_visual_facing_deg()

func _process(delta: float) -> void:
	if my_active_sig != null:
		shape.rotation_degrees = _get_visual_facing_deg()

	if my_data == null or mobility_controller == null:
		_apply_base_highlight_state()
		return
	if my_data.type != SignalData.Type.GUARD and my_data.type != SignalData.Type.DRONE:
		_apply_base_highlight_state()
		return
	if not _guard_revealed:
		return

	if mobility_controller.is_in_alert_state():
		_alert_visual_t += delta * 8.0
		var pulse := 0.5 + (sin(_alert_visual_t) * 0.5)
		shape.self_modulate = Color(1.0, lerpf(0.45, 1.0, pulse), lerpf(0.45, 1.0, pulse))
		return

	_alert_visual_t = 0.0
	_apply_base_highlight_state()

func _get_visual_facing_deg() -> float:
	if my_active_sig == null:
		return 0.0
	if my_data != null and (my_data.type == SignalData.Type.DRONE or my_data.type == SignalData.Type.CAMERA):
		return my_active_sig.runtime_detection_facing_deg
	return my_active_sig.runtime_body_facing_deg

func _setup_mobility(signal_wrapper: ActiveSignal) -> void:
	if signal_wrapper == null:
		return
	if signal_wrapper.data == null:
		return
	if signal_wrapper.data.mobility == null:
		return

	mobility_controller = MobilityController.new()
	add_child(mobility_controller)
	mobility_controller.initialize(signal_wrapper)

func set_guard_revealed(is_revealed: bool) -> void:
	_guard_revealed = is_revealed
	if my_data == null or my_data.type != SignalData.Type.GUARD:
		return

	shape.visible = is_revealed
	tooltip_main.visible = is_revealed
	signal_icon.input_pickable = is_revealed
	detection_controller.set_overlay_visible(is_revealed)
	if is_revealed:
		_sync_session_indicator_state()
	else:
		set_session_indicator_state(0)

func set_hover_highlight(active: bool):
	_is_hover_highlighted = active
	_apply_base_highlight_state()

func _apply_base_highlight_state() -> void:
	if _is_hover_highlighted:
		shape.self_modulate = Color(0.5, 1.0, 0.5) # Turn Greenish
	else:
		shape.self_modulate = Color.WHITE

func update_scan_progress(current: float, max_duration: float):
	if not scan_radial.visible:
		scan_radial.visible = true
	
	scan_radial.max_value = max_duration
	scan_radial.value = current

func hide_scan_progress():
	scan_radial.visible = false

func scan_cleanup():
	scan_radial.value = 0
	scan_radial.visible = false
	if my_active_sig != null:
		refresh_scan_status()

func set_scan_queue_position(queue_position: int) -> void:
	if scan_queue_label == null:
		return
	if queue_position <= 0:
		clear_scan_queue_position()
		return
	scan_queue_label.text = str(queue_position)
	scan_queue_label.visible = true

func clear_scan_queue_position() -> void:
	if scan_queue_label == null:
		return
	scan_queue_label.text = ""
	scan_queue_label.visible = false

func initialize_tooltip():
	tooltip_main.tt_header.text = my_data.display_name

	for description in my_active_sig.get_revealed_scan_descriptions():
		append_tooltip(description)

func append_tooltip(info: String):
	tooltip_main.tt_body.text += info + "\n"

func show_tooltip():
	tooltip_main.show()
	refresh_status_panels()
	tooltip_main.set_tooltip_collapsed(my_active_sig.is_tooltip_collapsed)

func show_hover_tooltip():
	tooltip_main.show()
	refresh_status_panels()
	tooltip_main.show_body()

func fade_tooltip_body():
	if my_active_sig == null:
		return
	if my_active_sig.is_tooltip_collapsed:
		tooltip_main.fade_body_out()
		return
	tooltip_main.show_body()

func refresh_status_panels():
	refresh_scan_status()
	refresh_lock_status()
	refresh_ic_status()

func refresh_scan_status():
	if my_active_sig == null:
		return
	tooltip_main.set_panel_state(
		tooltip_main.tt_scan_icon,
		my_active_sig.get_scan_status_icon_state()
	)

func refresh_lock_status():
	if my_active_sig == null:
		return
	tooltip_main.set_panel_state(
		tooltip_main.tt_lock_icon,
		my_active_sig.get_lock_status_icon_state()
	)

func refresh_ic_status():
	if my_active_sig == null:
		return
	var ic_state := my_active_sig.get_ic_status_icon_state()
	if ic_state == ActiveSignal.TooltipIconState.UNKNOWN_SCAN:
		return
	tooltip_main.set_panel_state(tooltip_main.tt_ic_icon, ic_state)

func bring_to_front():
	var parent = get_parent()
	if parent != null:
		parent.move_child(self, parent.get_child_count() - 1)

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			signal_interaction.emit(my_active_sig)
			
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			scan_toggle_requested.emit(my_active_sig)
			
		elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			tooltip_lock_requested.emit(my_active_sig)

func _on_area_2d_mouse_entered() -> void:
	hover_started.emit(my_active_sig)

func _on_area_2d_mouse_exited() -> void:
	hover_ended.emit(my_active_sig)

func get_focus_rect() -> Rect2:
	var icon_shape: CollisionShape2D = $SignalIcon/IconCollision
	var rect_shape := icon_shape.shape as RectangleShape2D
	var local_size := Vector2(64, 64)
	if rect_shape != null:
		local_size = rect_shape.size

	var center := get_global_transform_with_canvas().origin
	return Rect2(center - (local_size * 0.5), local_size)

func set_session_indicator_state(state: int) -> void:
	if target_indicator != null and target_indicator.has_method("set_visual_state"):
		target_indicator.set_visual_state(state)

func refresh_session_indicator_geometry() -> void:
	if target_indicator == null:
		return
	var icon_shape: CollisionShape2D = $SignalIcon/IconCollision
	var rect_shape := icon_shape.shape as RectangleShape2D
	var local_size := Vector2(64, 64)
	if rect_shape != null:
		local_size = rect_shape.size
	if target_indicator.has_method("configure_for_icon_size"):
		target_indicator.configure_for_icon_size(local_size)
	if target_indicator.has_method("refresh_geometry"):
		target_indicator.refresh_geometry()

func play_forced_disconnect_feedback() -> void:
	if target_indicator != null and target_indicator.has_method("play_forced_disconnect_feedback"):
		await target_indicator.play_forced_disconnect_feedback()

func _sync_session_indicator_state() -> void:
	var terminal_window = CommandDispatch.terminal_window
	if terminal_window == null or my_active_sig == null:
		set_session_indicator_state(0)
		return
	set_session_indicator_state(terminal_window.get_session_visual_state(my_active_sig))


func show_scanning_tooltip():
	if my_active_sig != null:
		refresh_scan_status()
		tooltip_main.show_body()

func show_scan_complete():
	if my_active_sig != null:
		refresh_status_panels()
		tooltip_main.show_body()
