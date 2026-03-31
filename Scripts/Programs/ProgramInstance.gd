class_name ProgramInstance extends RefCounted

enum State {
	DOCKED,
	LOADING,
	RUNNING,
	CLEANUP
}

var definition: ProgramDefinition
var state: State = State.DOCKED
var time_remaining_sec: float = 0.0
var was_used: bool = false

func _init(program_definition: ProgramDefinition = null) -> void:
	definition = program_definition

func get_program_id() -> StringName:
	return definition.program_id if definition != null else StringName()

func get_display_name() -> String:
	if definition == null:
		return ""
	return definition.get_display_name()

func is_running() -> bool:
	return state == State.RUNNING

func get_current_ram_cost() -> int:
	if definition == null:
		return 0
	return definition.get_phase_ram_cost(state)

func begin_loading() -> void:
	state = State.LOADING
	time_remaining_sec = definition.load_time_sec if definition != null else 0.0
	was_used = false
	if time_remaining_sec <= 0.0:
		_enter_running()

func mark_used() -> void:
	was_used = true

func begin_cleanup(used_cleanup: bool) -> void:
	if definition == null:
		dock()
		return
	state = State.CLEANUP
	time_remaining_sec = definition.cleanup_time_sec if used_cleanup else definition.get_cancel_cleanup_time_sec()
	if time_remaining_sec <= 0.0:
		dock()

func dock() -> void:
	state = State.DOCKED
	time_remaining_sec = 0.0
	was_used = false

func tick(delta: float) -> bool:
	if state != State.LOADING and state != State.CLEANUP:
		return false
	if delta <= 0.0:
		return false

	time_remaining_sec = maxf(0.0, time_remaining_sec - delta)
	if time_remaining_sec > 0.0:
		return false

	match state:
		State.LOADING:
			_enter_running()
		State.CLEANUP:
			dock()
	return true

func preprocess_action(action_context: ActionContext) -> void:
	if definition == null or state != State.RUNNING:
		return
	definition.preprocess_action(self, action_context)

func postprocess_action(action_context: ActionContext) -> void:
	if definition == null or state != State.RUNNING:
		return
	definition.postprocess_action(self, action_context)

func _enter_running() -> void:
	state = State.RUNNING
	time_remaining_sec = 0.0
