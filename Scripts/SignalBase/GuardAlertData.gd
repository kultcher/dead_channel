class_name GuardAlertData extends Resource

enum SourceType { DISTRACTION, RUNNER_BREACH, OTHER }

@export var source_type: SourceType = SourceType.OTHER
@export var target_signal_id: String = ""
@export var target_instance_id: int = 0
@export var target_cell_x: float = 0.0
@export var target_lane: int = 2
@export var priority: int = 10
@export var ttl_sec: float = 10.0
@export var investigate_sec_override: float = -1.0
@export var source_id: String = ""
@export var emitted_time_sec: float = 0.0

func is_expired(now_sec: float) -> bool:
	return now_sec - emitted_time_sec > ttl_sec
