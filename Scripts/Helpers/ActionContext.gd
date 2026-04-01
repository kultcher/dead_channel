class_name ActionContext extends RefCounted

enum ActionType {
	UNKNOWN,
	ACCESS_SIGNAL,
	SHOW_HELP,
	PROBE_SIGNAL,
	KILL_SIGNAL,
	ADD_HEAT,
	DISABLE_SIGNAL,
	ENABLE_SIGNAL,
	DISCONNECT_SESSION,
	TOGGLE_DOOR_LOCK,
	LAUNCH_PUZZLE,
	ACTIVATE_DISRUPTOR
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

var parent_action_type: ActionType = ActionType.UNKNOWN
var parent_action_source: SourceType = SourceType.UNKNOWN
var root_action_type: ActionType = ActionType.UNKNOWN
var root_action_source: SourceType = SourceType.UNKNOWN
var root_command_name: String = ""

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
		action.root_command_name = cmd_context.command
		action.source_signal = cmd_context.active_sig
		action.primary_target = cmd_context.active_sig
		for flag in cmd_context.flags:
			action.flags.append(str(flag))
	return action

static func create_system_action(
	type: ActionType,
	target: ActiveSignal = null,
	source: SourceType = SourceType.SYSTEM
) -> ActionContext:
	var action := ActionContext.new()
	action.action_type = type
	action.source_type = source
	action.source_signal = target
	action.primary_target = target
	action.root_action_type = type
	action.root_action_source = source
	return action

static func create_followup_action(
	parent_action: ActionContext,
	type: ActionType,
	target: ActiveSignal = null,
	source: SourceType = SourceType.UNKNOWN
) -> ActionContext:
	var resolved_source := source
	if resolved_source == SourceType.UNKNOWN and parent_action != null:
		resolved_source = parent_action.source_type

	var action := ActionContext.new()
	action.action_type = type
	action.source_type = resolved_source
	action.source_signal = target
	action.primary_target = target
	if parent_action != null:
		action.parent_action_type = parent_action.action_type
		action.parent_action_source = parent_action.source_type
		action.root_action_type = parent_action.root_action_type
		action.root_action_source = parent_action.root_action_source
		action.root_command_name = parent_action.root_command_name
		if action.root_action_type == ActionType.UNKNOWN:
			action.root_action_type = parent_action.action_type
		if action.root_action_source == SourceType.UNKNOWN:
			action.root_action_source = parent_action.source_type
	return action

func ensure_lineage_defaults() -> void:
	if root_action_type == ActionType.UNKNOWN:
		root_action_type = action_type
	if root_action_source == SourceType.UNKNOWN:
		root_action_source = source_type
	if root_command_name.is_empty():
		root_command_name = command_name

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
