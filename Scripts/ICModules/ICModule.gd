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

func process_action(_action_context: ActionContext) -> void:
	pass

func postprocess_action(_action_context: ActionContext) -> void:
	pass

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
