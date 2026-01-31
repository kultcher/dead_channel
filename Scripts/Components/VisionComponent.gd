# VisionComponent.gd
# Signal component for vision behaviors

class_name VisionComponent extends BehaviorComponent

@export var watch_offset_cells: float = -1.0
@export var watch_width_cells: float = 1.0
@export var heat_per_second: float = 1.0

func process_behavior(active_sig: ActiveSignal, delta: float, timeline):
	var camera_cell = active_sig.start_cell_index
	var runner_cell = timeline.current_cell_pos

	var watch_start = camera_cell + watch_offset_cells - .5		#WARNING: Watch out for this offset maybe?
	var watch_end = watch_start + watch_width_cells

	if runner_cell >= watch_start and runner_cell < watch_end:
		_apply_detection(active_sig, delta)
		
func _apply_detection(active_sig: ActiveSignal, delta):
	var heat = active_sig.data.effect_area.heat_per_second * delta
	GlobalEvents.heat_generated.emit(heat)
	GlobalEvents.runner_in_vision.emit(active_sig)

func get_desc():
	return "Static"
