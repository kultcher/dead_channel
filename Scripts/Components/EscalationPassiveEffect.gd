class_name EscalationPassiveEffect extends Resource

@export var enabled: bool = true
@export_multiline var debug_description: String = ""

func on_started(_active_sig: ActiveSignal, _component: EscalationComponent) -> void:
	pass

func on_stopped(_active_sig: ActiveSignal, _component: EscalationComponent) -> void:
	pass
