# Autoload: CommandDispatch.gd
# Receives terminal commands and routes responses back to terminal, timeline, signals, etc.

extends Node

var timeline_manager: Node2D = null
var signal_manager: Node2D = null
var terminal_window: Control = null

var window_manager: CanvasLayer = null

# === SIGNALS ===
signal set_terminal_signal(active_sig: ActiveSignal)
signal command_complete(cmd_context: CommandContext)
signal command_error(error_msg: String, context: ActiveSignal)

# === COMMAND REGISTRY ===
# Easy to expand later
const VALID_COMMANDS = {
	"ACCESS": {
		"requires_arg": true,
		"valid_flag": ["-bp"],
		"description": "Access: Access a system"
	},
	"INSPECT": {
		"requires_arg": false,
		"valid_flags": [],
		"description": "Inspect: Inspect a system"
	},
	"SPOOF": {
		"requires_arg": true,
		"valid_flags": [],
		"description": "Spoof: Deceive a system"
	},
	"KILL": {
		"requires_arg": true,
		"valid_flags": [],
		"description": "Kill: Disable a system"
	},
	"RUN": {
		"requires_arg": true,
		"valid_flags": ["-dc", "-ms", "-nl"],
		"description": "Run: Run a local program"
	}
}

const COMMAND_SHORTCUTS = {
	"ACC": "ACCESS", "INS": "INSPECT", "SPF": "SPOOF", "KIL": "KILL"
}

func switch_terminal_session(active_sig: ActiveSignal):
	terminal_window.switch_session(active_sig)

# === MAIN ENTRY POINT ===

# Package commands and sorts it depending on if terminal session matches signal
func process_command(input: String, active_sig: ActiveSignal = null) -> void:
	var parsed = parse_input(input.to_lower())
	var session_sig = terminal_window.active_signal
	var target_sig = signal_manager.get_active_signal(parsed.arg)

	# syntax error
	if parsed.has("error"):
		command_error.emit(parsed.error, active_sig)
		return

	# Signal despawned
	if !target_sig in signal_manager.signal_queue:
		command_error.emit("!!> " + parsed.command + " failed. Connection lost.")
		return

	var cmd_context = CommandContext.new()
	cmd_context.active_sig = active_sig
	cmd_context.flags = parsed.flags
	cmd_context.command = parsed.command
	cmd_context.arg = parsed.arg

	# ACCESS can switch sessions from the terminal regardless
	if cmd_context.command == "ACCESS":
		cmd_context.active_sig = target_sig
		_cmd_access(cmd_context)
		return

	if !session_sig:
		command_error.emit("!!> " + parsed.command + " failed. Incorrect context.")
		return

	# Wrong session TODO: Add auto-connect to new other session name with prompt
	if session_sig.data.system_id != cmd_context.arg:
		command_error.emit("!!> " + parsed.command + " failed. " + parsed.arg + " out of context.", cmd_context.active_sig)
		return	
		
	# execute
	var handler_method = "_cmd_" + cmd_context.command.to_lower()
	if has_method(handler_method):
		call(handler_method, cmd_context)
	else:
		command_error.emit("Invalid command: " + cmd_context.command, cmd_context.active_sig)


# === PARSER ===
func parse_input(input: String) -> Dictionary:
	var result = {
		"command": "",
		"arg": "",
		"flags": []
	}
	
	var trimmed = input.strip_edges()
	if trimmed.is_empty():
		return {"error": "No command entered"}
	
	var parts = trimmed.split(" ", false)  # false = skip empty strings
	var cmd = parts[0].to_upper()
	
	if cmd in COMMAND_SHORTCUTS:
		cmd = COMMAND_SHORTCUTS[cmd]
	
	if not cmd in VALID_COMMANDS:
		return {"error": "Unknown command: " + cmd}
	
	result.command = cmd
	
	# Parse arg and flags
	for i in range(1, parts.size()):
		var part = parts[i]
		if part.begins_with("-"):
			result.flags.append(part)
		else:
			result.arg = part
	
	# Validate
	if VALID_COMMANDS[cmd].requires_arg and result.arg.is_empty():
		return {"error": cmd + " requires a target"}
	
	return result



# === COMMAND HANDLERS ===
func _cmd_access(cmd_context: CommandContext) -> void:
	cmd_context.log.append("ACCESS GRANTED")
	terminal_window.switch_session(cmd_context.active_sig)
	_finalize_command(cmd_context)
		
func _cmd_kill(cmd_context: CommandContext) -> void:
	for ic in cmd_context.active_sig.data.ic_protection:
		var stopped = (ic.try_kill())
		if stopped:
			_interrupt_command(cmd_context)
			return
	cmd_context.active_sig.data.killable.try_kill(cmd_context)
	_finalize_command(cmd_context)
		
func _cmd_inspect(parsed: Dictionary, context: ActiveSignal) -> void:
	command_complete.emit("SCAN", parsed.arg, parsed.flags, context)
	
func _interrupt_command(cmd_context: CommandContext):
	pass
	
func _finalize_command(cmd_context: CommandContext):
	command_complete.emit(cmd_context)
