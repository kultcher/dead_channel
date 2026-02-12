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

func runner_spotted():
	var was_alert = is_alert_active
	is_alert_active = true
	vision_timeout = VISION_GRACE_PERIOD  # Reset the timer
	
	if not was_alert:
		_start_flash_sequence()

func _process(delta: float):
	if is_alert_active:
		vision_timeout -= delta
		if vision_timeout <= 0:
			is_alert_active = false
			_reset_visuals()
	if runner_in_vision and parent_sig and parent_sig.my_data and parent_sig.my_data.detection:
		parent_sig.my_data.detection.apply_detection(parent_sig.my_active_sig, delta)

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
	if !detection_poly: return
	await _reset_visuals()
	var fade_tween = create_tween()
	fade_tween.tween_property(detection_poly, "color", fade_color, 0.5)

func enable_vision():
	await _reset_visuals()
	# WARNING: this is maybe a little fragile

func _on_detection_area_entered(area: Area2D) -> void:
	if area.is_in_group("runner"):
		runner_in_vision = true

func _on_detection_area_exited(area: Area2D) -> void:
	if area.is_in_group("runner"):
		runner_in_vision = false
