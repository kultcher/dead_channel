class_name FaradayEffect extends ICOverlay

var max_runner_distance_cells: float = 0.0

func configure_faraday(active_sig: ActiveSignal, max_distance_cells: float, shader_resource: Shader) -> void:
	configure(active_sig, shader_resource)
	max_runner_distance_cells = max_distance_cells
	set_process(true)
	_update_state()

func _process(_delta: float) -> void:
	_update_state()

func _update_state() -> void:
	if _active_sig == null or _active_sig.is_disabled:
		set_active(false)
		return
	if CommandDispatch.signal_manager == null:
		set_active(false)
		return
	var runner_distance = CommandDispatch.signal_manager.get_horizontal_runner_distance_cells(_active_sig)
	set_active(runner_distance > max_runner_distance_cells)
