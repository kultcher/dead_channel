# HackableComponent.gd
# Governs how Signals are disabled

class_name HackableComponent extends Resource

func try_command(cmd_context):
	print("trying command: " + cmd_context.command)
	if cmd_context.active_sig.is_disabled:
		cmd_context.status = CommandContext.CommandStatus.FAILURE
		cmd_context.log_text.append("No response. Signal disabled.")
		return
	match cmd_context.command:
		"KILL": _kill(cmd_context)
		"RUN": _run(cmd_context)
		"OP": _op(cmd_context)
		"SPOOF": _spoof(cmd_context)
		"PROBE": _probe(cmd_context)
		"LINK": _link(cmd_context)

func _kill(cmd_context):
	if cmd_context.active_sig.data.type == SignalData.Type.DOOR:
		cmd_context.status = CommandContext.CommandStatus.FAILURE
		cmd_context.log_text.append("KILL failed. No active process to kill on signal type: DOOR.")
	cmd_context.active_sig.disable_signal()
	var name = cmd_context.active_sig.data.system_id
	cmd_context.log_text.append("Shutting down " + name + "...")
	GlobalEvents.signal_killed.emit(cmd_context.active_sig)
	GlobalEvents.heat_increased.emit(500, "Shutting down " + name + ".")

func _run(cmd_context):
	if !cmd_context.active_sig.data.puzzle:
		cmd_context.log_text.append("RUN " + cmd_context.arg.to_upper() + " failed. Signal is not locked.")
	elif !cmd_context.arg in ["sniff", "fuzz", "decrypt"]:
		cmd_context.log_text.append("RUN failed. No program named " + cmd_context.arg.to_upper() + " found.")
	else:
		var puzzle = cmd_context.active_sig.data.puzzle.puzzle_type
		print("matching puzzle: " + str(puzzle))
		match_puzzle(puzzle, cmd_context)


var puzzle_mismatch = {
	"sniff": "SNIFF: No avaiable datastream.",
	"fuzz": "FUZZ: No vulnerability detected.",
	"decrypt": "DECRYPT: Signal not encrypted."
}

func match_puzzle(puzzle, cmd_context):
	var arg: String = cmd_context.arg
	match puzzle:
		PuzzleComponent.Type.SNIFF:
			if arg == "sniff": 
				cmd_context.log_text.append("Launching SNIFF...")
				GlobalEvents.puzzle_started.emit(cmd_context.active_sig, PuzzleComponent.Type.SNIFF)
				return
		PuzzleComponent.Type.FUZZ:
			if arg == "fuzz":
				cmd_context.log_text.append("Launching FUZZ...")
				GlobalEvents.puzzle_started.emit(cmd_context.active_sig, PuzzleComponent.Type.FUZZ)
				return
		PuzzleComponent.Type.DECRYPT:
			if arg == "decrypt":
				cmd_context.log_text.append("Launching DECRYPT...")
				GlobalEvents.puzzle_started.emit(cmd_context.active_sig, PuzzleComponent.Type.DECRYPT)
				return
	cmd_context.log_text.append(puzzle_mismatch[arg])


func _spoof(_cmd_context):
	pass

func _probe(_cmd_context):
	pass

func _link(_cmd_context):
	pass

func _op(cmd_context):
	if cmd_context.active_sig == null or cmd_context.active_sig.data == null:
		cmd_context.log_text.append("Invalid context, no operation available.")
		return

	var signal_data = cmd_context.active_sig.data
	match signal_data.type:
		SignalData.Type.DISRUPTOR:
			_op_disruptor(cmd_context)
		SignalData.Type.DOOR:
			var new_locked = not signal_data.door_locked
			cmd_context.active_sig.set_door_locked(new_locked)
			if new_locked:
				cmd_context.log_text.append(signal_data.display_name + " locked.")
			else:
				cmd_context.log_text.append(signal_data.display_name + " unlocked.")
		_:
			cmd_context.log_text.append("Invalid context, no operation available.")

func _op_disruptor(cmd_context) -> void:
	var signal_data = cmd_context.active_sig.data
	if signal_data.disruptor == null or not signal_data.disruptor.enabled:
		cmd_context.log_text.append("OP failed. " + signal_data.display_name + " has no active disruption profile.")
		return
	if signal_data.disruptor.used:
		cmd_context.log_text.append("OP failed. " + signal_data.display_name + " can only be activated once.")
		return
	if CommandDispatch.signal_manager == null:
		cmd_context.log_text.append("OP failed. Signal manager unavailable.")
		return

	var source_cell = cmd_context.active_sig.start_cell_index
	if cmd_context.active_sig.runtime_position_initialized:
		source_cell = cmd_context.active_sig.runtime_cell_x
	var source_lane = signal_data.lane
	if cmd_context.active_sig.runtime_position_initialized:
		source_lane = cmd_context.active_sig.runtime_lane

	var range_cells := maxi(0, signal_data.disruptor.horizontal_range_cells)
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
		alert.target_cell_x = source_cell
		alert.target_lane = source_lane
		alert.priority = signal_data.disruptor.severity
		alert.ttl_sec = signal_data.disruptor.ttl_sec
		alert.investigate_sec_override = signal_data.disruptor.investigate_duration_sec
		alert.source_id = signal_data.system_id
		alert.emitted_time_sec = Time.get_ticks_msec() / 1000.0
		GlobalEvents.guard_alert_raised.emit(alert)
		matched_targets += 1

	if matched_targets <= 0:
		signal_data.disruptor.used = true
		cmd_context.log_text.append(signal_data.display_name + " activated. No valid targets in range.")
		return

	signal_data.disruptor.used = true
	cmd_context.log_text.append(signal_data.display_name + " activated. Alerted " + str(matched_targets) + " target(s).")
