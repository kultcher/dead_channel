class_name DetectionController extends Area2D

var parent_sig: Node2D # Reference to the main SignalEntity
var detection_poly: Polygon2D
var size: Vector2 = Vector2(1,1)
@onready var detection_shape: CollisionShape2D = $DetectionShape

var is_alert_active: bool = false
var alert_tween: Tween
var base_color: Color = Color(1, 0.8, 0.2, 0.25) # Yellowish
var fade_color: Color = Color(1, 0.8, 0.2, 0.05) # Yellowish
var alert_color: Color = Color(1, 0.0, 0.0, 0.6)   # Red, more opaque

var vision_timeout: float = 0.0
const VISION_GRACE_PERIOD: float = 0.1  # Small buffer to account for frame gaps
var runner_in_vision: bool = false

func initialize(parent: Node2D):
	parent_sig = parent
	handle_vision_overlay()
	if parent_sig and parent_sig.my_data and parent_sig.my_data.detection:
		parent_sig.my_data.detection.changed.connect(handle_vision_overlay)
		parent_sig.my_data.detection.changed.connect(_on_detection_changed)
	_setup_detection_shape()
	_connect_detection_signals()

func _ready() -> void:
	_connect_detection_signals()

func _connect_detection_signals() -> void:
	if not area_entered.is_connected(_on_detection_area_entered):
		area_entered.connect(_on_detection_area_entered)
	if not area_exited.is_connected(_on_detection_area_exited):
		area_exited.connect(_on_detection_area_exited)

func _setup_detection_shape() -> void:
	if parent_sig == null or parent_sig.my_data == null or parent_sig.my_data.detection == null:
		visible = false
		monitoring = false
		return

	var timeline_manager = CommandDispatch.timeline_manager
	detection_shape.shape = parent_sig.my_data.detection.build_collision_shape(timeline_manager.cell_width_px)
	monitoring = true

func _on_detection_changed() -> void:
	if parent_sig == null or parent_sig.my_data == null or parent_sig.my_data.detection == null:
		return
	_refresh_palette()
	var timeline_manager = CommandDispatch.timeline_manager
	detection_shape.shape = parent_sig.my_data.detection.build_collision_shape(timeline_manager.cell_width_px)
	
func handle_vision_overlay():
	if detection_poly:
		detection_poly.queue_free()
		detection_poly = null
		
	if parent_sig and parent_sig.my_data and parent_sig.my_data.detection:
		_build_detection_poly()

func _build_detection_poly():
	# Create the node dynamically
	detection_poly = Polygon2D.new()
	_refresh_palette()
	
	# Visual Style (Semi-transparent yellow/red)
	detection_poly.color = base_color
	
	# MATH: Calculate points based on DetectionComponent
	if parent_sig and parent_sig.my_data and parent_sig.my_data.detection:
		var cell_w = CommandDispatch.timeline_manager.cell_width_px
		detection_poly.polygon = parent_sig.my_data.detection.get_visual_polygon(cell_w)
	else:
		detection_poly.polygon = PackedVector2Array()

	add_child(detection_poly)
	detection_poly.z_index = -1

func _refresh_palette() -> void:
	var detection := _get_detection_component()
	if detection != null and detection.is_attack_state():
		base_color = Color(1.0, 0.18, 0.18, 0.3)
		fade_color = Color(1.0, 0.18, 0.18, 0.08)
		alert_color = Color(1.0, 0.0, 0.0, 0.7)
	else:
		base_color = Color(1, 0.8, 0.2, 0.25)
		fade_color = Color(1, 0.8, 0.2, 0.05)
		alert_color = Color(1, 0.0, 0.0, 0.6)
	if detection_poly != null and not is_alert_active:
		detection_poly.color = base_color

func set_overlay_visible(poly_visible: bool) -> void:
	if detection_poly:
		detection_poly.visible = poly_visible

func runner_spotted():
	var was_alert = is_alert_active
	is_alert_active = true
	vision_timeout = VISION_GRACE_PERIOD  # Reset the timer
	
	if not was_alert:
		_start_flash_sequence()

func _process(delta: float):
	if parent_sig != null and parent_sig.my_active_sig != null and not parent_sig.my_active_sig.is_disabled:
		_update_runtime_facing(delta)
	_sync_runtime_facing()
	if is_alert_active:
		vision_timeout -= delta
		if vision_timeout <= 0:
			is_alert_active = false
			_reset_visuals()
	if runner_in_vision and parent_sig and parent_sig.my_data and parent_sig.my_data.detection:
		parent_sig.my_data.detection.apply_detection(parent_sig.my_active_sig, delta)

func _update_runtime_facing(delta: float) -> void:
	if parent_sig == null or parent_sig.my_data == null or parent_sig.my_active_sig == null:
		return
	var detection = parent_sig.my_data.detection
	if detection == null:
		return
	if parent_sig.my_data.type == SignalData.Type.DRONE and parent_sig.mobility_controller != null and parent_sig.mobility_controller.has_alert_focus():
		parent_sig.my_active_sig.runtime_detection_facing_deg = parent_sig.mobility_controller.get_alert_focus_deg()
		return

	var movement_facing_deg = parent_sig.my_active_sig.runtime_body_facing_deg
	var movement_has_facing := false
	if parent_sig.mobility_controller != null:
		movement_facing_deg = parent_sig.mobility_controller.get_movement_facing_deg()
		movement_has_facing = parent_sig.mobility_controller.has_movement_facing()

	detection.update_runtime(parent_sig.my_active_sig, delta, movement_facing_deg, movement_has_facing)

func _sync_runtime_facing() -> void:
	if parent_sig == null:
		return
	if parent_sig.my_active_sig == null:
		return
	if not parent_sig.my_active_sig.runtime_position_initialized:
		return
	rotation_degrees = parent_sig.my_active_sig.runtime_detection_facing_deg

func _start_flash_sequence():
	alert_tween = create_tween().set_loops()
	
	if detection_poly:
		alert_tween.tween_property(detection_poly, "color", alert_color, 0.2)
		alert_tween.tween_property(detection_poly, "color", base_color, 0.4)

func _reset_visuals():
	if alert_tween:
		alert_tween.kill()
	if detection_poly:
		if detection_poly.color == fade_color:
			var fade_tween = create_tween()
			fade_tween.tween_property(detection_poly, "color", base_color, 0.5)
		else:
			detection_poly.color = base_color

		
func disable_vision():
	if not detection_poly:
		return
	_reset_visuals()
	var fade_tween = create_tween()
	fade_tween.tween_property(detection_poly, "color", fade_color, 0.5)
	await fade_tween.finished
	if detection_poly != null:
		detection_poly.visible = false

func enable_vision():
	if detection_poly == null:
		return
	detection_poly.visible = true
	_reset_visuals()

func _get_detection_component() -> DetectionComponent:
	if parent_sig == null or parent_sig.my_data == null:
		return null
	return parent_sig.my_data.detection

func _on_detection_area_entered(area: Area2D) -> void:
	if area.is_in_group("runner"):
		runner_in_vision = true

func _on_detection_area_exited(area: Area2D) -> void:
	if area.is_in_group("runner"):
		runner_in_vision = false
