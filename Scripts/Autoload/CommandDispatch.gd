# Autoload: CommandDispatch.gd
# Receives terminal commands and routes responses back to terminal, timeline, signals, etc.

extends Node

var timeline_manager: Node2D = null
var window_manager: CanvasLayer = null

# === SIGNALS ===
signal command_success(command: String, args: Array, flags: Array, context: SignalData)
signal command_error(error_msg: String, context: SignalData)

# === COMMAND REGISTRY ===
# Easy to expand later
const VALID_COMMANDS = {
	"ACC": {
		"requires_arg": true,
		"valid_flag": ["-bp"],
		"description": "Access: Access a system"
	},
	"INS": {
		"requires_arg": false,
		"valid_flags": [],
		"description": "Inspect: Inspect a system"
	},
	"SPF": {
		"requires_arg": true,
		"valid_flags": [],
		"description": "Spoof: Deceive a system"
	},
	"KIL": {
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

# === MAIN ENTRY POINT ===
func process_command(input: String, signal_context: SignalData) -> void:
	print("CommandDispatch: process_command ->", input)
	var parsed = parse_input(input)
	
	if parsed.has("error"):
		command_error.emit(parsed.error, signal_context)
		return
	
	# Dispatch to handler
	var handler_method = "_cmd_" + parsed.command.to_lower()
	if has_method(handler_method):
		call(handler_method, parsed, signal_context)
	else:
		command_error.emit("Command not implemented: " + parsed.command, signal_context)

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
func _cmd_acc(parsed: Dictionary, context: SignalData) -> void:
	if parsed.arg == context.system_id:
		command_success.emit("ACCESS", parsed.arg, parsed.flags, context)
	else:
		command_error.emit("error: " + parsed.arg + " not found.", context)
		

func _cmd_ins(parsed: Dictionary, context: SignalData) -> void:
	command_success.emit("SCAN", parsed.arg, parsed.flags, context)
