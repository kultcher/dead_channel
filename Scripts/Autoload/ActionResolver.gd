extends Node

signal action_started(action_context: ActionContext)
signal action_resolved(action_context: ActionContext)
signal action_failed(action_context: ActionContext)

func build_action_from_command(cmd_context: CommandContext) -> ActionContext:
	var action := ActionContext.from_command(cmd_context)
	if cmd_context == null:
		action.fail("Invalid action context.")
		return action

	match cmd_context.command:
		"KILL":
			action.action_type = ActionContext.ActionType.DISABLE_SIGNAL
			action.add_tag(&"hostile")
			action.add_tag(&"terminal")
			action.heat_delta = 500.0
		"PROBE":
			action.action_type = ActionContext.ActionType.PROBE_SIGNAL
			action.add_tag(&"terminal")
		"OP":
			if cmd_context.active_sig != null and cmd_context.active_sig.data != null:
				match cmd_context.active_sig.data.type:
					SignalData.Type.DOOR:
						action.action_type = ActionContext.ActionType.TOGGLE_DOOR_LOCK
					SignalData.Type.DISRUPTOR:
						action.action_type = ActionContext.ActionType.ACTIVATE_DISRUPTOR
					_:
						action.action_type = ActionContext.ActionType.LEGACY_COMMAND
			else:
				action.action_type = ActionContext.ActionType.LEGACY_COMMAND
		"RUN":
			action.action_type = ActionContext.ActionType.LAUNCH_PUZZLE
		"ACCESS":
			action.action_type = ActionContext.ActionType.ACCESS_SIGNAL
			action.add_tag(&"terminal")
			action.set_metadata(&"show_connection_banner", true)
		"HELP":
			action.action_type = ActionContext.ActionType.SHOW_HELP
		_:
			action.action_type = ActionContext.ActionType.LEGACY_COMMAND

	return action

func resolve_action(action_context: ActionContext) -> ActionContext:
	if action_context == null:
		return null

	action_context.mark_processing()
	action_started.emit(action_context)

	_run_preprocessors(action_context)
	if action_context.was_unsuccessful():
		_emit_terminal_outcome(action_context)
		return action_context

	_apply_core_effect(action_context)
	_run_postprocessors(action_context)
	_emit_terminal_outcome(action_context)
	return action_context

func _run_preprocessors(action_context: ActionContext) -> void:
	var target := action_context.primary_target
	if target == null or target.data == null or target.data.ic_modules == null:
		return
	target.data.ic_modules.process_action(action_context)

func _apply_core_effect(action_context: ActionContext) -> void:
	if action_context == null or action_context.was_unsuccessful():
		return

	match action_context.action_type:
		ActionContext.ActionType.ACCESS_SIGNAL:
			_apply_access_signal(action_context)
		ActionContext.ActionType.PROBE_SIGNAL:
			_apply_probe_signal(action_context)
		ActionContext.ActionType.DISABLE_SIGNAL:
			_apply_disable_signal(action_context)
		ActionContext.ActionType.TOGGLE_DOOR_LOCK:
			_apply_toggle_door_lock(action_context)
		ActionContext.ActionType.LAUNCH_PUZZLE:
			_apply_launch_puzzle(action_context)
		ActionContext.ActionType.ACTIVATE_DISRUPTOR:
			_apply_activate_disruptor(action_context)
		_:
			_apply_legacy_command(action_context)

func _run_postprocessors(_action_context: ActionContext) -> void:
	pass

func _apply_access_signal(action_context: ActionContext) -> void:
	var target := action_context.primary_target
	if target == null or target.data == null:
		action_context.fail("Invalid context, no signal available.")
		return

	var show_connection_banner := bool(action_context.get_metadata(&"show_connection_banner", false))
	CommandDispatch.switch_terminal_session(target, show_connection_banner)
	action_context.succeed()

func _ensure_target_is_responding(action_context: ActionContext) -> bool:
	var target := action_context.primary_target
	if target == null or target.data == null:
		action_context.fail("Invalid context, no signal available.")
		return false
	if target.is_disabled:
		action_context.fail("No response. Signal disabled.")
		return false
	return true

func _apply_probe_signal(action_context: ActionContext) -> void:
	if not _ensure_target_is_responding(action_context):
		return
	action_context.succeed()

func _apply_disable_signal(action_context: ActionContext) -> void:
	if not _ensure_target_is_responding(action_context):
		return

	var target := action_context.primary_target
	if target.data.type == SignalData.Type.DOOR:
		action_context.fail("KILL failed. No active process to kill on signal type: DOOR.")
		return

	target.disable_signal()
	action_context.succeed("Shutting down " + target.data.system_id + "...")
	GlobalEvents.signal_killed.emit(target)
	if action_context.heat_delta != 0.0:
		GlobalEvents.heat_increased.emit(action_context.heat_delta, "Shutting down " + target.data.system_id + ".")

func _apply_toggle_door_lock(action_context: ActionContext) -> void:
	if not _ensure_target_is_responding(action_context):
		return

	var target := action_context.primary_target
	if target.data.type != SignalData.Type.DOOR:
		action_context.fail("Invalid context, no operation available.")
		return

	var new_locked := not target.data.door_locked
	target.set_door_locked(new_locked)
	if new_locked:
		action_context.succeed(target.data.display_name + " locked.")
	else:
		action_context.succeed(target.data.display_name + " unlocked.")

func _apply_launch_puzzle(action_context: ActionContext) -> void:
	var cmd_context := action_context.command_context
	if cmd_context == null:
		action_context.fail("RUN failed. Invalid action context.")
		return
	if not _ensure_target_is_responding(action_context):
		return

	var target := action_context.primary_target
	if target.data.puzzle == null:
		action_context.fail("RUN " + cmd_context.arg.to_upper() + " failed. Signal is not locked.")
		return
	if not target.data.puzzle.puzzle_locked:
		action_context.fail("RUN " + cmd_context.arg.to_upper() + " failed. Signal already unlocked.")
		return

	var program_name := cmd_context.arg
	var puzzle_type = target.data.puzzle.puzzle_type
	match puzzle_type:
		PuzzleComponent.Type.SNIFF:
			if program_name == "sniff":
				action_context.succeed("Launching SNIFF...")
				GlobalEvents.puzzle_started.emit(target, PuzzleComponent.Type.SNIFF)
				return
		PuzzleComponent.Type.FUZZ:
			if program_name == "fuzz":
				action_context.succeed("Launching FUZZ...")
				GlobalEvents.puzzle_started.emit(target, PuzzleComponent.Type.FUZZ)
				return
		PuzzleComponent.Type.DECRYPT:
			if program_name == "decrypt":
				action_context.succeed("Launching DECRYPT...")
				GlobalEvents.puzzle_started.emit(target, PuzzleComponent.Type.DECRYPT)
				return

	var mismatch := {
		"sniff": "SNIFF: No avaiable datastream.",
		"fuzz": "FUZZ: No vulnerability detected.",
		"decrypt": "DECRYPT: Signal not encrypted."
	}
	if not mismatch.has(program_name):
		action_context.fail("RUN failed. No program named " + program_name.to_upper() + " found.")
		return
	action_context.fail(mismatch[program_name])

func _apply_activate_disruptor(action_context: ActionContext) -> void:
	if not _ensure_target_is_responding(action_context):
		return

	var target := action_context.primary_target
	var signal_data := target.data
	if signal_data.type != SignalData.Type.DISRUPTOR:
		action_context.fail("Invalid context, no operation available.")
		return

	if signal_data.disruptor == null or not signal_data.disruptor.enabled:
		action_context.fail("OP failed. " + signal_data.display_name + " has no active disruption profile.")
		return
	if signal_data.disruptor.get_uses() <= 0:
		action_context.fail("OP failed. " + signal_data.display_name + ": no activations remaining.")
		return
	if CommandDispatch.signal_manager == null:
		action_context.fail("OP failed. Signal manager unavailable.")
		return

	var source_cell := target.start_cell_index
	if target.runtime_position_initialized:
		source_cell = target.runtime_cell_x
	var source_lane := signal_data.lane
	if target.runtime_position_initialized:
		source_lane = target.runtime_lane

	var range_cells := maxi(0, signal_data.disruptor.horizontal_range_cells)
	var max_alert_targets := maxi(1, signal_data.disruptor.max_alert_targets)
	var alerted_targets: int = 0
	var matched_targets: int = 0
	for other_sig in CommandDispatch.signal_manager.signal_queue:
		if other_sig == null or other_sig.data == null:
			continue
		if other_sig.is_disabled:
			continue
		if other_sig.data.mobility == null:
			continue
		if not signal_data.disruptor.matches_distraction_target(other_sig.data.type):
			continue

		var target_cell = other_sig.start_cell_index
		if other_sig.runtime_position_initialized:
			target_cell = other_sig.runtime_cell_x
		if absf(target_cell - source_cell) > float(range_cells):
			continue

		var alert := GuardAlertData.new()
		alert.source_type = GuardAlertData.SourceType.DISTRACTION
		alert.target_signal_id = other_sig.data.system_id
		alert.target_instance_id = other_sig.get_instance_id()
		alert.target_cell_x = source_cell
		alert.target_lane = source_lane
		alert.priority = signal_data.disruptor.severity
		alert.ttl_sec = signal_data.disruptor.ttl_sec
		alert.investigate_sec_override = signal_data.disruptor.investigate_duration_sec
		alert.source_id = signal_data.system_id
		alert.emitted_time_sec = Time.get_ticks_msec() / 1000.0
		GlobalEvents.guard_alert_raised.emit(alert)
		matched_targets += 1
		alerted_targets += 1
		if alerted_targets >= max_alert_targets:
			break

	signal_data.disruptor.uses -= 1
	if matched_targets <= 0:
		action_context.succeed(signal_data.display_name + " activated. No valid targets in range.")
		return

	action_context.succeed(signal_data.display_name + " activated. Alerted " + str(matched_targets) + " target(s).")

func _apply_legacy_command(action_context: ActionContext) -> void:
	var cmd_context := action_context.command_context
	if cmd_context == null:
		action_context.fail("Invalid action context.")
		return
	if cmd_context.active_sig == null or cmd_context.active_sig.data == null or cmd_context.active_sig.data.hackable == null:
		action_context.fail("Invalid context, no operation available.")
		return

	cmd_context.log_text.clear()
	cmd_context.status = CommandContext.CommandStatus.PROCESS
	cmd_context.active_sig.data.hackable.try_command(cmd_context)
	for line in cmd_context.log_text:
		action_context.append_log(line)
	match cmd_context.status:
		CommandContext.CommandStatus.FAILURE:
			action_context.status = ActionContext.Status.FAILURE
		_:
			action_context.status = ActionContext.Status.SUCCESS

func _emit_terminal_outcome(action_context: ActionContext) -> void:
	if action_context == null:
		return

	var cmd_context := action_context.command_context
	if cmd_context != null:
		cmd_context.log_text = action_context.log_text.duplicate()
		match action_context.status:
			ActionContext.Status.FAILURE, ActionContext.Status.BLOCKED:
				cmd_context.status = CommandContext.CommandStatus.FAILURE
			ActionContext.Status.SUCCESS:
				cmd_context.status = CommandContext.CommandStatus.SUCCESS
			_:
				cmd_context.status = CommandContext.CommandStatus.PROCESS

	if action_context.was_unsuccessful():
		action_failed.emit(action_context)
	else:
		action_resolved.emit(action_context)
