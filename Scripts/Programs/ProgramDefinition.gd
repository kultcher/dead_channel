class_name ProgramDefinition extends Resource

enum ProgramKind {
	PASSIVE,
	ACTIVE
}

enum ActivationMode {
	AUTOMATIC,
	MANUAL
}

@export var program_id: StringName
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var kind: ProgramKind = ProgramKind.PASSIVE
@export var activation_mode: ActivationMode = ActivationMode.MANUAL
@export var load_time_sec: float = 0.0
@export var cleanup_time_sec: float = 0.0
@export_range(0.0, 1.0, 0.05) var cancel_cleanup_multiplier: float = 0.25

@export var ram_cost: int = 1
@export var loading_ram_cost: int = -1
@export var running_ram_cost: int = -1
@export var cleanup_ram_cost: int = -1

func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	return str(program_id)

func get_description() -> String:
	if not description.is_empty():
		return description
	return ""

func is_passive() -> bool:
	return kind == ProgramKind.PASSIVE

func is_manual_activation() -> bool:
	return activation_mode == ActivationMode.MANUAL

func get_phase_ram_cost(state: int) -> int:
	match state:
		ProgramInstance.State.LOADING:
			return loading_ram_cost if loading_ram_cost >= 0 else ram_cost
		ProgramInstance.State.RUNNING:
			return running_ram_cost if running_ram_cost >= 0 else ram_cost
		ProgramInstance.State.CLEANUP:
			return cleanup_ram_cost if cleanup_ram_cost >= 0 else ram_cost
		_:
			return 0

func get_cancel_cleanup_time_sec() -> float:
	return cleanup_time_sec * cancel_cleanup_multiplier

func get_ready_notice(_program_instance: ProgramInstance) -> String:
	return get_display_name() + " ready."

func get_executed_notice(_program_instance: ProgramInstance) -> String:
	return get_display_name() + " executed."

func get_cleanup_finished_notice(_program_instance: ProgramInstance) -> String:
	return get_display_name() + " cleanup complete."

func preprocess_action(_program_instance: ProgramInstance, _action_context: ActionContext) -> void:
	pass

func postprocess_action(_program_instance: ProgramInstance, _action_context: ActionContext) -> void:
	pass
