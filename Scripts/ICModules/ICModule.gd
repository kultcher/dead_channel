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

func apply_difficulty(_difficulty: int) -> void:
	pass

func apply_params(_params: Dictionary) -> void:
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

func _pick_difficulty_value(values: Array, difficulty: int):
	if values.is_empty():
		return null
	var clamped_index := clampi(difficulty - 1, 0, values.size() - 1)
	return values[clamped_index]
