# ICModule.gd
# Base class for IC modules

class_name ICModule extends Resource

@export var codex_id: StringName

# Virtual function to be overridden
func get_desc():
	return ""

func get_codex_id():
	return &""

func bind_to_context(signal_data: SignalData, terminal_ref: Control):
	pass

func process_action(action_context: ActionContext) -> void:
	if action_context == null or action_context.command_context == null:
		return
	if interrupts_commands(action_context.command_context):
		if action_context.command_context.status == CommandContext.CommandStatus.FAILURE:
			action_context.status = ActionContext.Status.FAILURE
		else:
			action_context.status = ActionContext.Status.BLOCKED
		for line in action_context.command_context.log_text:
			action_context.append_log(line)

func blocks_action(_action_context: ActionContext) -> bool:
	return false

func interrupts_commands(_cmd_context: CommandContext) -> bool:
	return false

func on_connect(active_sig: ActiveSignal):
	pass

func on_session_closed(active_sig: ActiveSignal):
	pass

func on_disabled(active_sig: ActiveSignal):
	pass

func on_enabled(active_sig: ActiveSignal):
	pass

func get_connection_flow_lines(_active_sig: ActiveSignal) -> Array[String]:
	return []
