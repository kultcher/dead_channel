class_name ActionContext extends RefCounted

enum ActionType {
	UNKNOWN,
	ACCESS_SIGNAL,
	SHOW_HELP,
	PROBE_SIGNAL,
	DISABLE_SIGNAL,
	TOGGLE_DOOR_LOCK,
	LAUNCH_PUZZLE,
	ACTIVATE_DISRUPTOR,
	LEGACY_COMMAND
}

enum SourceType {
	UNKNOWN,
	TERMINAL_COMMAND,
	PROGRAM,
	IC_MODULE,
	SYSTEM
}

enum Status {
	PENDING,
	PROCESSING,
	SUCCESS,
	FAILURE,
	BLOCKED
}

var action_type: ActionType = ActionType.UNKNOWN
var source_type: SourceType = SourceType.UNKNOWN
var status: Status = Status.PENDING

var command_name: String = ""
var command_context: CommandContext = null

var source_signal: ActiveSignal = null
var primary_target: ActiveSignal = null
var secondary_targets: Array[ActiveSignal] = []

var flags: Array[String] = []
var tags: Array[StringName] = []
var log_text: Array[String] = []
var metadata: Dictionary = {}

var blocked_by: Array[StringName] = []
var heat_delta: float = 0.0

static func from_command(cmd_context: CommandContext) -> ActionContext:
	var action := ActionContext.new()
	action.source_type = SourceType.TERMINAL_COMMAND
	action.command_context = cmd_context
	if cmd_context != null:
		action.command_name = cmd_context.command
		action.source_signal = cmd_context.active_sig
		action.primary_target = cmd_context.active_sig
		for flag in cmd_context.flags:
			action.flags.append(str(flag))
	return action

func add_tag(tag: StringName) -> void:
	if tag == StringName():
		return
	if not tags.has(tag):
		tags.append(tag)

func has_tag(tag: StringName) -> bool:
	return tags.has(tag)

func append_log(line: String) -> void:
	if line.is_empty():
		return
	log_text.append(line)

func set_metadata(key: StringName, value) -> void:
	if key == StringName():
		return
	metadata[key] = value

func get_metadata(key: StringName, default_value = null):
	if key == StringName():
		return default_value
	return metadata.get(key, default_value)

func mark_processing() -> void:
	status = Status.PROCESSING

func succeed(line: String = "") -> void:
	status = Status.SUCCESS
	append_log(line)

func fail(line: String = "") -> void:
	status = Status.FAILURE
	append_log(line)

func block(blocker_id: StringName, line: String = "") -> void:
	status = Status.BLOCKED
	if blocker_id != StringName() and not blocked_by.has(blocker_id):
		blocked_by.append(blocker_id)
	append_log(line)

func was_blocked() -> bool:
	return status == Status.BLOCKED

func was_successful() -> bool:
	return status == Status.SUCCESS

func was_unsuccessful() -> bool:
	return status == Status.FAILURE or status == Status.BLOCKED
