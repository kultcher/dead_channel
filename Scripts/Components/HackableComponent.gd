# HackableComponent.gd
# Governs how Signals are disabled

class_name HackableComponent extends Resource

func try_command(cmd_context):
	print("trying command: " + cmd_context.command)
	match cmd_context.command:
		"KILL": _kill(cmd_context)
		"RUN": _run(cmd_context)
		"SPOOF": _spoof(cmd_context)
		"PROBE": _probe(cmd_context)
		"LINK": _link(cmd_context)

func _kill(cmd_context):
	cmd_context.active_sig.disable_signal()
	var name = cmd_context.active_sig.data.system_id
	cmd_context.log_text.append("Shutting down " + name + "...")

func _run(cmd_context):
	if !cmd_context.active_sig.data.puzzle:
		cmd_context.log_text.append("RUN " + cmd_context.arg.to_upper() + " failed. Signal is not locked.")
	elif !cmd_context.arg in ["sniff", "fuzz", "decrypt"]:
		cmd_context.log_text.append("RUN failed. No program named " + cmd_context.arg.to_upper() + " found.")
	else:
		var puzzle = cmd_context.active_sig.data.puzzle.puzzle_type
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


func _spoof(cmd_context):
	pass

func _probe(cmd_context):
	pass

func _link(cmd_context):
	pass
