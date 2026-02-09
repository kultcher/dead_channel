# signal_entity.gd
# Visual controller and input router for Signals on the Timeline

extends Node2D
@onready var shape = $Shape

@onready var scan_radial = $ScanRadial
@onready var tooltip_main = $DetailTooltip
@onready var tooltip_header = $DetailTooltip/TooltipHbox/TooltipVBox/HeaderPanel/MarginContainer/HeaderText
@onready var tooltip_body = $DetailTooltip/TooltipHbox/BodyText
@onready var tooltip_active_scan = $DetailTooltip/TooltipHbox/TooltipVBox/ActiveScanPanel
@onready var tooltip_active_scan_text = $DetailTooltip/TooltipHbox/TooltipVBox/ActiveScanPanel/MarginContainer/ActiveScanText

@onready var detection_controller = $DetectionController

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

func setup(signal_wrapper: ActiveSignal):
	my_data = signal_wrapper.data
	my_active_sig = signal_wrapper

	tooltip_main_initial_x = tooltip_main.size.x

	initialize_tooltip()

	GlobalEvents.signal_scanned.connect(check_scan_completion)

	detection_controller.initialize(self)
	update_visuals()
	
	
func update_visuals():
	match my_data.type:
		SignalData.Type.CAMERA:
			# Yellow Triangle
			shape.color = Color.YELLOW
			shape.polygon = PackedVector2Array([Vector2(-25, 25), Vector2(-25, -25), Vector2(25, 0)])
			
		SignalData.Type.DOOR:
			# Brown Square
			shape.color = Color.SADDLE_BROWN
			shape.polygon = PackedVector2Array([Vector2(-25, -25), Vector2(25, -25), Vector2(25, 25), Vector2(-25, 25)])
			
		SignalData.Type.GUARD:
			# Blue Circle (Approximated)
			shape.color = Color.BLUE
			# Draw a simple hexagon as a circle approximation
			shape.polygon = PackedVector2Array([Vector2(-20,-25), Vector2(20,-25), Vector2(25,0), Vector2(20,25), Vector2(-20,25), Vector2(-25,0)])
	
	if my_active_sig.is_disabled:
		print("is disabled")
		shape.color = Color.BLACK

func set_scan_highlight(active: bool):
	if active:
		shape.self_modulate = Color(0.5, 1.0, 0.5) # Turn Greenish
		tooltip_body.show()
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


func show_scanning_tooltip():
	tooltip_active_scan.visible = true
