class_name MobilityController extends Node

enum State { PATROL, RESPONDING_ALERT, INVESTIGATING, RETURNING_TO_PATROL }

var active_sig: ActiveSignal
var _mobility: MobilityComponent
var _timeline_manager: Node2D
var _signal_manager: Node2D

var _state: State = State.PATROL
var _patrol_index: int = 0
var _patrol_direction: int = 1
var _dwell_timer: float = 0.0
var _investigate_timer: float = 0.0

var _alert_queue: Array[GuardAlertData] = []
var _current_alert: GuardAlertData = null

func initialize(target_active_sig: ActiveSignal) -> void:
	active_sig = target_active_sig
	_mobility = active_sig.data.mobility
	_timeline_manager = CommandDispatch.timeline_manager
	_signal_manager = CommandDispatch.signal_manager

	if _mobility == null or not _mobility.enabled:
		set_process(false)
		return

	if _mobility.patrol_points.is_empty():
		var fallback_point: MobilityPatrolPoint = MobilityPatrolPoint.new()
		fallback_point.cell_x = active_sig.start_cell_index
		fallback_point.lane = active_sig.data.lane
		_mobility.patrol_points.append(fallback_point)

	active_sig.runtime_cell_x = active_sig.start_cell_index
	active_sig.runtime_lane = active_sig.data.lane
	active_sig.runtime_lane_pos = float(active_sig.data.lane)
	active_sig.runtime_facing_deg = _mobility.patrol_points[0].facing_deg
	active_sig.runtime_position_initialized = true

	GlobalEvents.guard_alert_raised.connect(_on_guard_alert_raised)
	set_process(true)

func _exit_tree() -> void:
	if GlobalEvents.guard_alert_raised.is_connected(_on_guard_alert_raised):
		GlobalEvents.guard_alert_raised.disconnect(_on_guard_alert_raised)

func _process(delta: float) -> void:
	if _mobility == null or _mobility.patrol_points.is_empty():
		return

	_prune_expired_alerts()
	_try_preempt_with_queued_alert()
	_update_reveal_state()

	match _state:
		State.PATROL:
			_process_patrol(delta)
		State.RESPONDING_ALERT:
			_process_alert_move(delta)
		State.INVESTIGATING:
			_process_investigate(delta)
		State.RETURNING_TO_PATROL:
			_process_return(delta)

func _process_patrol(delta: float) -> void:
	if _dwell_timer > 0.0:
		_dwell_timer -= delta
		return

	var target: MobilityPatrolPoint = _mobility.patrol_points[_patrol_index]
	var arrived := _move_toward(target.cell_x, target.lane, delta)
	if not arrived:
		return

	_dwell_timer = maxf(0.0, target.dwell_sec)
	_patrol_index = _next_patrol_index()

func _process_alert_move(delta: float) -> void:
	if _current_alert == null:
		_state = State.RETURNING_TO_PATROL
		return

	var arrived := _move_toward(_current_alert.target_cell_x, _current_alert.target_lane, delta)
	if not arrived:
		return

	_investigate_timer = _mobility.investigate_duration_sec
	if _current_alert.investigate_sec_override >= 0.0:
		_investigate_timer = _current_alert.investigate_sec_override
	_state = State.INVESTIGATING

func _process_investigate(delta: float) -> void:
	_investigate_timer -= delta
	if _investigate_timer > 0.0:
		return

	_current_alert = null
	_state = State.RETURNING_TO_PATROL

func _process_return(delta: float) -> void:
	var nearest_index: int = _find_nearest_patrol_index()
	var target: MobilityPatrolPoint = _mobility.patrol_points[nearest_index]
	var arrived := _move_toward(target.cell_x, target.lane, delta)
	if not arrived:
		return

	_patrol_index = nearest_index
	_state = State.PATROL

func _move_toward(target_cell_x: float, target_lane: int, delta: float) -> bool:
	var current: Vector2 = Vector2(active_sig.runtime_cell_x, active_sig.runtime_lane_pos)
	var target: Vector2 = Vector2(target_cell_x, float(target_lane))

	var cell_w: float = 1.0
	var lane_h: float = 1.0
	if _timeline_manager != null:
		cell_w = maxf(1.0, _timeline_manager.cell_width_px)
		lane_h = maxf(1.0, _timeline_manager.lane_height)

	var current_visual: Vector2 = Vector2(current.x * cell_w, current.y * lane_h)
	var target_visual: Vector2 = Vector2(target.x * cell_w, target.y * lane_h)
	var to_target_visual: Vector2 = target_visual - current_visual
	var distance_visual: float = to_target_visual.length()

	if distance_visual <= 0.001:
		active_sig.runtime_cell_x = target_cell_x
		active_sig.runtime_lane_pos = float(target_lane)
		active_sig.runtime_lane = target_lane
		return true

	# Keep speed authored in "cells/sec" but enforce equal perceived speed in screen space.
	var step_visual: float = _mobility.move_speed_cells_per_sec * cell_w * delta
	if step_visual >= distance_visual:
		active_sig.runtime_cell_x = target_cell_x
		active_sig.runtime_lane_pos = float(target_lane)
		active_sig.runtime_lane = target_lane
		_update_facing(to_target_visual)
		return true

	var dir_visual: Vector2 = to_target_visual / distance_visual
	var next_visual: Vector2 = current_visual + (dir_visual * step_visual)

	active_sig.runtime_cell_x = next_visual.x / cell_w
	active_sig.runtime_lane_pos = next_visual.y / lane_h
	active_sig.runtime_lane = int(round(active_sig.runtime_lane_pos))
	_update_facing(dir_visual)
	return false

func _update_facing(dir: Vector2) -> void:
	if dir.length_squared() <= 0.0001:
		return
	# Convert timeline units to screen-proportional vector so facing
	# matches actual rendered movement direction.
	var visual_dir := dir
	if _timeline_manager != null:
		visual_dir = Vector2(
			dir.x * _timeline_manager.cell_width_px,
			dir.y * _timeline_manager.lane_height
		)
	active_sig.runtime_facing_deg = rad_to_deg(atan2(visual_dir.y, visual_dir.x))

func _next_patrol_index() -> int:
	var max_i := _mobility.patrol_points.size() - 1
	if max_i <= 0:
		return 0

	if _mobility.patrol_mode == MobilityComponent.PatrolMode.LOOP:
		return (_patrol_index + 1) % _mobility.patrol_points.size()

	var candidate := _patrol_index + _patrol_direction
	if candidate < 0 or candidate > max_i:
		_patrol_direction *= -1
		candidate = _patrol_index + _patrol_direction
	return clampi(candidate, 0, max_i)

func _find_nearest_patrol_index() -> int:
	var nearest: int = 0
	var best_dist: float = INF
	var pos: Vector2 = Vector2(active_sig.runtime_cell_x, active_sig.runtime_lane_pos)
	for i in range(_mobility.patrol_points.size()):
		var point: MobilityPatrolPoint = _mobility.patrol_points[i]
		var dist: float = pos.distance_to(Vector2(point.cell_x, point.lane))
		if dist < best_dist:
			best_dist = dist
			nearest = i
	return nearest

func _on_guard_alert_raised(alert: GuardAlertData) -> void:
	if alert == null:
		return
	if _mobility == null:
		return
	if alert.ttl_sec <= 0.0:
		alert.ttl_sec = _mobility.default_alert_ttl_sec
	if alert.emitted_time_sec <= 0.0:
		alert.emitted_time_sec = Time.get_ticks_msec() / 1000.0

	_alert_queue.append(alert)
	_sort_alert_queue()
	if _alert_queue.size() > _mobility.alert_queue_capacity:
		_alert_queue.resize(_mobility.alert_queue_capacity)

func _sort_alert_queue() -> void:
	_alert_queue.sort_custom(func(a: GuardAlertData, b: GuardAlertData) -> bool:
		if a.priority == b.priority:
			return a.emitted_time_sec > b.emitted_time_sec
		return a.priority > b.priority
	)

func _prune_expired_alerts() -> void:
	var now_sec := Time.get_ticks_msec() / 1000.0
	_alert_queue = _alert_queue.filter(func(a: GuardAlertData) -> bool:
		return not a.is_expired(now_sec)
	)
	if _current_alert != null and _current_alert.is_expired(now_sec):
		_current_alert = null
		_state = State.RETURNING_TO_PATROL

func _try_preempt_with_queued_alert() -> void:
	if _alert_queue.is_empty():
		return

	var best: GuardAlertData = _alert_queue[0]
	var current_priority: int = -9999
	if _current_alert != null:
		current_priority = _current_alert.priority

	if _current_alert == null or best.priority > current_priority:
		_current_alert = best
		_alert_queue.remove_at(0)
		_state = State.RESPONDING_ALERT

func _update_reveal_state() -> void:
	if active_sig.instance_node == null:
		return
	var reveal := _is_revealed_to_player()
	active_sig.instance_node.set_guard_revealed(reveal)

func _is_revealed_to_player() -> bool:
	if _timeline_manager == null:
		return true
	if _signal_manager == null:
		return true

	var runner_cell: float = _timeline_manager.current_cell_pos
	var guard_cell: float = active_sig.runtime_cell_x
	var lane_delta: float = absf(active_sig.runtime_lane_pos - 2.0)
	var runner_dist: float = absf(guard_cell - runner_cell)
	if runner_dist <= _mobility.reveal_range_from_runner_cells and lane_delta <= 1.5:
		return true

	for other_sig in _signal_manager.signal_queue:
		if other_sig == active_sig:
			continue
		if other_sig.data.type != SignalData.Type.CAMERA:
			continue
		if other_sig.is_disabled:
			continue
		if not _camera_has_active_session(other_sig):
			continue
		if _camera_is_puzzle_locked(other_sig):
			continue

		var cam_cell: float = other_sig.start_cell_index
		if other_sig.runtime_position_initialized:
			cam_cell = other_sig.runtime_cell_x
		var dist: float = absf(cam_cell - guard_cell)
		if dist <= _mobility.reveal_range_from_camera_cells:
			return true

	return false

func _camera_has_active_session(camera_sig: ActiveSignal) -> bool:
	if camera_sig == null:
		return false
	if camera_sig.terminal_session == null:
		return false
	return camera_sig.terminal_session.has_tab

func _camera_is_puzzle_locked(camera_sig: ActiveSignal) -> bool:
	if camera_sig == null or camera_sig.data == null:
		return false
	if camera_sig.data.puzzle == null:
		return false
	return camera_sig.data.puzzle.is_locked()
