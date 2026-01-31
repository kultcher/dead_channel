class_name SignalVisionController extends Node2D

var parent_sig: Node2D # Reference to the main SignalEntity
var vision_poly: Polygon2D

var is_alert_active: bool = false
var alert_tween: Tween
var base_color: Color = Color(1, 0.8, 0.2, 0.25) # Yellowish
var alert_color: Color = Color(1, 0.0, 0.0, 0.6)   # Red, more opaque

var vision_timeout: float = 0.0
const VISION_GRACE_PERIOD: float = 0.1  # Small buffer to account for frame gaps

func initialize(parent: Node2D):
	parent_sig = parent
	handle_vision_overlay()
	GlobalEvents.runner_in_vision.connect(runner_spotted)
	
func handle_vision_overlay():
	if vision_poly:
		vision_poly.queue_free()
		vision_poly = null
		
	if parent_sig.my_data.type == SignalData.Type.CAMERA and parent_sig.my_data.effect_area:
		_build_vision_poly(parent_sig.my_data.effect_area)

func _build_vision_poly(area_comp: EffectAreaComponent):
	# Create the node dynamically
	vision_poly = Polygon2D.new()
	
	# Visual Style (Semi-transparent yellow/red)
	vision_poly.color = base_color
	
	# MATH: Calculate points based on Logical Data
	var cell_w = CommandDispatch.timeline_manager.cell_width_px
	var lane_h = CommandDispatch.timeline_manager.lane_height
	
	# Example for Rectangle (adapt for Cone logic we discussed earlier)
	# Logic: "I am 3 cells long, 1 lane wide"
	var width_px = area_comp.size.x * cell_w
	var height_px = area_comp.size.y * lane_h
	
	# Draw centered on the signal's lane
	var points = PackedVector2Array([
		Vector2(0, -height_px/8),						# Origin (Relative to Signal center)
		Vector2(5, height_px/8),
		Vector2(-width_px, height_px/2),	# Bottom Left (Extending backward/left)
		Vector2(-width_px, -height_px/2)	# Bottom Left
	])
	
	vision_poly.polygon = points
	add_child(vision_poly)
	vision_poly.z_index = -1

func runner_spotted(active_sig: ActiveSignal):
	if active_sig != parent_sig.my_active_sig:
		return
	
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

func _start_flash_sequence():
	alert_tween = create_tween().set_loops()
	
	if vision_poly:
		alert_tween.tween_property(vision_poly, "color", alert_color, 0.2)
		alert_tween.tween_property(vision_poly, "color", base_color, 0.4)

func _reset_visuals():
	if vision_poly:
		alert_tween.kill()
		vision_poly.color = base_color
