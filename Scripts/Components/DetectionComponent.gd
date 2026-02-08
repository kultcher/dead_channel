# DetectionComponent.gd
# Signal component for vision behaviors

class_name DetectionComponent extends Resource

@export var watch_offset_cells: float = -1.0
@export var watch_width_cells: float = 1.0
@export var heat_per_second: float = 10

var parent_entity: Node2D
var detection_disabled: bool = false

func process_detection(active_sig: ActiveSignal, delta: float, timeline):
	if active_sig.is_disabled: return
	var camera_cell = active_sig.start_cell_index
	var runner_cell = timeline.current_cell_pos

	# If offset is -1.0, the vision starts 1 cell behind camera.
	# If width is 3.0, it extends 3 cells further back from there.
	
	# Start checking from the Camera's position + offset
	var zone_start = camera_cell + watch_offset_cells 
	
	var dist = camera_cell - runner_cell
	
	# If Camera is 100, Runner is 97. Dist is 3.
	# If vision is 0 to 4 meters in front of camera:
	if dist >= 0 and dist <= watch_width_cells:
		_apply_detection(active_sig, delta)

func _apply_detection(active_sig: ActiveSignal, delta):
	var heat = heat_per_second * delta
	GlobalEvents.heat_modified.emit(heat_per_second, "Detected by camera.")
	GlobalEvents.runner_in_vision.emit(active_sig)

func disable_detection():
	detection_disabled = true

func get_desc():
	return "Static"
