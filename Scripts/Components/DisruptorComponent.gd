class_name DisruptorComponent extends Resource

enum DistractionTargets {
	BIOLOGICAL,
	MECHANICAL,
	BOTH,
}

@export var enabled: bool = true
@export var used: bool = false
@export var investigate_duration_sec: float = -1.0
@export var horizontal_range_cells: int = 0
@export var severity: int = 10
@export var ttl_sec: float = -1.0
@export var distraction_targets: DistractionTargets = DistractionTargets.BOTH

func matches_distraction_target(signal_type: SignalData.Type) -> bool:
	match distraction_targets:
		DistractionTargets.BIOLOGICAL:
			return signal_type == SignalData.Type.GUARD
		DistractionTargets.MECHANICAL:
			return signal_type == SignalData.Type.DRONE
		DistractionTargets.BOTH:
			return signal_type == SignalData.Type.GUARD or signal_type == SignalData.Type.DRONE
	return false
