class_name MobilityComponent extends Resource

enum PatrolMode { LOOP, PING_PONG }

@export var enabled: bool = true
@export var move_speed_cells_per_sec: float = 0.15
@export var patrol_mode: PatrolMode = PatrolMode.LOOP
@export var patrol_points: Array[MobilityPatrolPoint] = []

@export var investigate_duration_sec: float = 4.0

@export var reveal_range_from_runner_cells: float = 2.5
@export var reveal_range_from_camera_cells: float = 3.5

@export var alert_queue_capacity: int = 8
@export var default_alert_ttl_sec: float = 10.0

# Future hooks
@export var block_on_walls: bool = false
@export var comms_ping_enabled: bool = false
@export var comms_ping_interval_min_sec: float = 8.0
@export var comms_ping_interval_max_sec: float = 16.0
@export var comms_ping_duration_sec: float = 2.5
