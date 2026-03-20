# signal_entity.gd
# Visual controller and input router for Signals on the Timeline

extends Node2D
@onready var shape = $Shape
@onready var signal_icon: Area2D = $SignalIcon

@onready var scan_radial = $ScanRadial
@onready var tooltip_main = $DetailTooltip
@onready var tooltip_header = $DetailTooltip/TooltipHbox/TooltipVBox/HeaderPanel/MarginContainer/HeaderText
@onready var tooltip_body = $DetailTooltip/TooltipHbox/BodyText
@onready var tooltip_active_scan = $DetailTooltip/TooltipHbox/TooltipVBox/ActiveScanPanel
@onready var tooltip_active_scan_text = $DetailTooltip/TooltipHbox/TooltipVBox/ActiveScanPanel/MarginContainer/ActiveScanText

@onready var detection_controller = $DetectionController
var mobility_controller: MobilityController = null
var _guard_revealed: bool = true
var _alert_visual_t: float = 0.0

var my_data: SignalData
var my_active_sig: ActiveSignal

var tooltip_main_initial_x: float
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

	tooltip_main_initial_x = tooltip_main.size.x

	initialize_tooltip()

	GlobalEvents.signal_scanned.connect(check_scan_completion)

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

func _process(delta: float) -> void:
	if my_data == null or my_data.type != SignalData.Type.GUARD or mobility_controller == null:
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
		tooltip_body.show()
	else:
		if my_data != null and my_data.type == SignalData.Type.GUARD and mobility_controller != null and mobility_controller.is_in_alert_state():
			_alert_visual_t = 0.0
		else:
			shape.self_modulate = Color.WHITE
		tooltip_body.hide()
		tooltip_main.size.x = tooltip_main_initial_x

func update_scan_progress(current: float, max_duration: float):
	if not scan_radial.visible:
		scan_radial.visible = true
	
	scan_radial.max_value = max_duration
	scan_radial.value = current

func check_scan_completion(data: SignalData, scan_index: int):
	if data != my_data:
		return
	if scan_index >= my_active_sig.scan_layers.size():
		tooltip_active_scan_text.text = "COMPLETE"
		GlobalEvents.signal_scan_complete.emit(data)

func hide_scan_progress():
	scan_radial.visible = false

func scan_cleanup():
	scan_radial.value = 0
	scan_radial.visible = false
	tooltip_active_scan.visible = false
	tooltip_body.visible = false

func initialize_tooltip():
	tooltip_header.text = my_data.display_name

	var layers = my_active_sig.scan_layers
	for layer in layers:
		if layer.revealed:
			append_tooltip(layer.description)

func append_tooltip(info: String):
	tooltip_body.text += info + "\n"

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
	# reposition tooltip based on new size
	if !is_node_ready(): return
	tooltip_main.position.x = (tooltip_main.size.x / 2) * -1

func get_focus_rect() -> Rect2:
	var icon_shape: CollisionShape2D = $SignalIcon/IconCollision
	var rect_shape := icon_shape.shape as RectangleShape2D
	var local_size := Vector2(64, 64)
	if rect_shape != null:
		local_size = rect_shape.size

	var center := get_global_transform_with_canvas().origin
	return Rect2(center - (local_size * 0.5), local_size)


func show_scanning_tooltip():
	tooltip_active_scan.visible = true
