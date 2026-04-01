class_name AssassinProgram extends ProgramDefinition

func get_ready_notice(_program_instance: ProgramInstance) -> String:
	return "Assassin loaded. Awaiting next KILL."

func get_executed_notice(_program_instance: ProgramInstance) -> String:
	return "Assassin fired. Heat signature suppressed."

func get_cleanup_finished_notice(_program_instance: ProgramInstance) -> String:
	return "Assassin cleanup complete."

func preprocess_action(program_instance: ProgramInstance, action_context: ActionContext) -> void:
	if program_instance == null or action_context == null:
		return
	if action_context.action_type != ActionContext.ActionType.ADD_HEAT:
		return
	if action_context.heat_delta <= 0.0:
		return
	if action_context.root_action_source != ActionContext.SourceType.TERMINAL_COMMAND:
		return
	if action_context.root_command_name != "KILL":
		return

	action_context.heat_delta = 0.0
	action_context.add_tag(&"assassin_silenced")
	ProgramManager.mark_program_used(program_instance.get_program_id())
