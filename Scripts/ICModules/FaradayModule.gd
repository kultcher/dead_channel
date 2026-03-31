class_name FaradayModule extends ICModule

@export var max_runner_distance_cells: float = 2.0

func get_desc():
	return "Faraday(%.1fc)" % max_runner_distance_cells

func get_codex_id():
	return &"codex_faraday"

func process_action(action_context: ActionContext) -> void:
	if action_context == null or action_context.primary_target == null:
		return
	if action_context.action_type == ActionContext.ActionType.ACCESS_SIGNAL:
		return
	if CommandDispatch.signal_manager == null:
		return

	var runner_distance = CommandDispatch.signal_manager.get_horizontal_runner_distance_cells(action_context.primary_target)
	if runner_distance <= max_runner_distance_cells:
		return

	action_context.fail(
		"COMMAND BLOCKED. [b][color=orange]FARADAY[/color][/b] shielding active. Move within %.1f cells to establish a stable link." % max_runner_distance_cells
	)
