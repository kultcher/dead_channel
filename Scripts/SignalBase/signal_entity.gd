# signal_entity.gd
# Visual controller and input router for Signals on the Timeline

extends Node2D
@onready var shape = $Shape
@onready var signal_icon: Area2D = $SignalIcon

@onready var scan_radial = $ScanRadial
@onready var tooltip_main = $DetailTooltip
@onready var tooltip_header = $DetailTooltip/TooltipHbox/TooltipVBox/HeaderPanel/MarginContainer/HeaderText
@onready var tooltip_body_box = $DetailTooltip/TooltipHbox/BodyBox
@onready var tooltip_body = $DetailTooltip/TooltipHbox/BodyBox/BodyText
@onready var tooltip_active_scan = $DetailTooltip/TooltipHbox/TooltipVBox/ActiveScanPanel
@onready var tooltip_active_scan_text = $DetailTooltip/TooltipHbox/TooltipVBox/ActiveScanPanel/MarginContainer/ActiveScanText
@onready var tooltip_lock_state = $DetailTooltip/TooltipHbox/TooltipVBox/LockStatePanel
@onready var tooltip_lock_state_text = $DetailTooltip/TooltipHbox/TooltipVBox/LockStatePanel/MarginContainer/LockStateText

@onready var detection_controller = $DetectionController
@export var tooltip_gap_y: float = 32.0

const COLOR_STATUS_UNKNOWN := Color("4a2d64")
const COLOR_STATUS_SCANNING := Color("c56b1f")
const COLOR_STATUS_COMPLETE := Color("2f8a46")
const COLOR_STATUS_PARTIAL := Color("c1a126")

const COLOR_LOCK_UNKNOWN := Color("4a2d64")
const COLOR_LOCK_OPEN := Color("2d66c4")
const COLOR_LOCK_LOCKED := Color("111111")
const COLOR_LOCK_HACKED := Color("b3262e")

var mobility_controller: MobilityController = null
var _guard_revealed: bool = true
var _alert_visual_t: float = 0.0

var my_data: SignalData
var my_active_sig: ActiveSignal

var tooltip_main_initial_x: float
var tooltip_main_initial_y: float

var is_disabled: bool = false

signal signal_interaction(data: SignalData)
signal scan_requested(clicked_signal: ActiveSignal)
signal scan_aborted(scanning_signal: ActiveSignal)
signal scan_lock_requested(scanning_signal: ActiveSignal)

func _ready():
	scan_radial.visible = false
	set_process(true)

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

	tooltip_main_initial_x = tooltip_main.size.x
	tooltip_main_initial_y = tooltip_main.size.y


	initialize_tooltip()
	refresh_status_panels()
	set_tooltip_collapsed(my_active_sig.is_tooltip_collapsed)

	detection_controller.initialize(self)
	_setup_mobility(signal_wrapper)
	if my_data.type == SignalData.Type.GUARD and my_data.mobility != null:
		set_guard_revealed(false)
	update_visuals()
	
	
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
		return
	if my_data.type != SignalData.Type.GUARD and my_data.type != SignalData.Type.DRONE:
		return
	if not _guard_revealed:
		return

	if mobility_controller.is_in_alert_state():
		_alert_visual_t += delta * 8.0
		var pulse := 0.5 + (sin(_alert_visual_t) * 0.5)
		shape.self_modulate = Color(1.0, lerpf(0.45, 1.0, pulse), lerpf(0.45, 1.0, pulse))
		return

	_alert_visual_t = 0.0
	shape.self_modulate = Color.WHITE

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

func set_scan_highlight(active: bool):
	if active:
		shape.self_modulate = Color(0.5, 1.0, 0.5) # Turn Greenish
	else:
		if my_data != null and my_data.type == SignalData.Type.GUARD and mobility_controller != null and mobility_controller.is_in_alert_state():
			_alert_visual_t = 0.0
		else:
			shape.self_modulate = Color.WHITE
		tooltip_main.size.x = tooltip_main_initial_x

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
		set_tooltip_collapsed(my_active_sig.is_tooltip_collapsed)

func initialize_tooltip():
	tooltip_header.text = my_data.display_name

	var layers = my_active_sig.scan_layers
	for layer in layers:
		if layer.revealed:
			append_tooltip(layer.description)

func append_tooltip(info: String):
	tooltip_body.text += info + "\n"

func show_tooltip():
	tooltip_main.show()
	refresh_status_panels()
	set_tooltip_collapsed(my_active_sig.is_tooltip_collapsed)

func set_tooltip_collapsed(collapsed: bool):
	tooltip_main.show()
	tooltip_body_box.visible = not collapsed
	tooltip_body.visible = not collapsed
	tooltip_active_scan.visible = true
	tooltip_lock_state.visible = true
	tooltip_main.size.x = tooltip_main_initial_x

func refresh_status_panels():
	refresh_scan_status()
	refresh_lock_status()

func refresh_scan_status():
	if my_active_sig == null:
		return

	if my_active_sig.is_being_scanned and my_active_sig.current_scan_index < my_active_sig.scan_layers.size():
		_set_panel_state(tooltip_active_scan, tooltip_active_scan_text, "SCANNING", COLOR_STATUS_SCANNING)
		return

	if my_active_sig.scan_layers.is_empty() or my_active_sig.current_scan_index >= my_active_sig.scan_layers.size():
		_set_panel_state(tooltip_active_scan, tooltip_active_scan_text, "COMPLETE", COLOR_STATUS_COMPLETE)
		return

	if my_active_sig.current_scan_index > 0:
		_set_panel_state(tooltip_active_scan, tooltip_active_scan_text, "PARTIAL", COLOR_STATUS_PARTIAL)
		return

	_set_panel_state(tooltip_active_scan, tooltip_active_scan_text, "UNKNOWN", COLOR_STATUS_UNKNOWN)

func refresh_lock_status():
	if my_active_sig == null:
		return

	if not _is_access_layer_revealed():
		_set_panel_state(tooltip_lock_state, tooltip_lock_state_text, "UNKNOWN", COLOR_LOCK_UNKNOWN)
		return

	if my_data == null or my_data.puzzle == null:
		_set_panel_state(tooltip_lock_state, tooltip_lock_state_text, "OPEN", COLOR_LOCK_OPEN)
		return

	if my_data.puzzle.puzzle_locked:
		_set_panel_state(tooltip_lock_state, tooltip_lock_state_text, "LOCKED", COLOR_LOCK_LOCKED)
		return

	_set_panel_state(tooltip_lock_state, tooltip_lock_state_text, "HACKED", COLOR_LOCK_HACKED)

func _is_access_layer_revealed() -> bool:
	if my_active_sig == null:
		return false
	for layer in my_active_sig.scan_layers:
		if layer.name == "ACCESS":
			return layer.revealed
	return false

func _set_panel_state(panel: PanelContainer, label: Label, text: String, color: Color):
	if panel == null or label == null:
		return
	var base_style := panel.get_theme_stylebox("panel")
	var style: StyleBoxFlat
	if base_style is StyleBoxFlat:
		style = (base_style as StyleBoxFlat).duplicate()
	else:
		style = StyleBoxFlat.new()
	style.bg_color = color
	panel.add_theme_stylebox_override("panel", style)
	label.text = text


func bring_to_front():
	var parent = get_parent()
	if parent != null:
		parent.move_child(self, parent.get_child_count() - 1)

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			signal_interaction.emit(my_active_sig)
			
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			scan_lock_requested.emit(my_active_sig)

func _on_area_2d_mouse_entered() -> void:
	scan_requested.emit(my_active_sig)

func _on_area_2d_mouse_exited() -> void:
	scan_aborted.emit(my_active_sig)

func _on_detail_tooltip_resized() -> void:
	#NOTE: Not needed?
	# reposition tooltip based on new size
	if !is_node_ready(): return
	tooltip_main.position.x = (tooltip_main.size.x / 2) * -1
#	tooltip_main.position.y = -tooltip_main.size.y - tooltip_gap_y

func get_focus_rect() -> Rect2:
	var icon_shape: CollisionShape2D = $SignalIcon/IconCollision
	var rect_shape := icon_shape.shape as RectangleShape2D
	var local_size := Vector2(64, 64)
	if rect_shape != null:
		local_size = rect_shape.size

	var center := get_global_transform_with_canvas().origin
	return Rect2(center - (local_size * 0.5), local_size)

func get_lock_state_focus_rect() -> Rect2:
	if tooltip_lock_state == null or not tooltip_lock_state.is_visible_in_tree():
		return Rect2()
	return tooltip_lock_state.get_global_rect()


func show_scanning_tooltip():
	if my_active_sig != null:
		refresh_scan_status()
		set_tooltip_collapsed(my_active_sig.is_tooltip_collapsed)

func show_scan_complete():
	if my_active_sig != null:
		refresh_status_panels()
		set_tooltip_collapsed(my_active_sig.is_tooltip_collapsed)
