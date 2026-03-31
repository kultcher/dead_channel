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

func interrupts_commands(cmd_context: CommandContext) -> bool:
	if cmd_context == null or cmd_context.active_sig == null:
		return false
	if CommandDispatch.signal_manager == null:
		return false

	var runner_distance = CommandDispatch.signal_manager.get_horizontal_runner_distance_cells(cmd_context.active_sig)
	if runner_distance <= max_runner_distance_cells:
		return false

	cmd_context.status = CommandContext.CommandStatus.FAILURE
	cmd_context.log_text.append(
		"COMMAND BLOCKED. [b][color=orange]FARADAY[/color][/b] shielding active. Move within %.1f cells to establish a stable link." % max_runner_distance_cells
	)
	return true
