# Autoload: GlobalEvents.gd
# Global signal distributor

extends Node

@warning_ignore("unused_signal")

# TERMINAL EVENTS
signal terminal_command_entered(signal_data, command, success)
signal terminal_command_failed(signal_data, command)

# GAMEPLAY EVENTS
signal cell_reached(cell: int)
signal signal_scanned(signal_data: SignalData, scan_depth)
signal signal_scan_complete(signal_data: SignalData)
signal signal_connect(data: SignalData)
signal signal_hacked(data: SignalData, success: bool)
signal signal_killed(active_sig: ActiveSignal)
signal mobile_investigating(active_sig: ActiveSignal)
signal heat_increased(amount, source)

signal runner_detected(active_sig: ActiveSignal)
signal runners_damaged(amount: float)
signal runners_stopped()
signal runners_resumed()
signal runner_slowdown()
signal runner_hustle()
signal runner_hold_count_changed(count: int)

signal ic_triggered(ice_type: String)

signal guard_alert_raised(alert: GuardAlertData)
signal guard_comms_ping_started(active_sig: ActiveSignal)
signal guard_comms_ping_ended(active_sig: ActiveSignal)

signal activate_null_spike()
signal deactivate_null_spike()

signal tutorial_lock_changed(locked: bool)
signal tutorial_feature_changed(feature_key: String, enabled: bool)

# PUZZLE EVENTS
signal puzzle_started(active_signal: ActiveSignal, puzzle_type: PuzzleComponent.Type)
signal puzzle_failed(signal_data)
signal puzzle_solved(signal_data)

var _runner_holds: Dictionary = {}
var _runner_hold_counter: int = 0
var _tutorial_feature_flags := {
	"scan": true,
	"connect": true,
	"terminal_commands": true,
	"null_spike": true,
}

func acquire_runner_hold(reason: String = "") -> String:
	_runner_hold_counter += 1
	var normalized_reason := reason.strip_edges()
	if normalized_reason.is_empty():
		normalized_reason = "hold"

	var token := "%s_%d" % [normalized_reason, _runner_hold_counter]
	var was_empty := _runner_holds.is_empty()
	_runner_holds[token] = normalized_reason

	if was_empty:
		runners_stopped.emit()
	runner_hold_count_changed.emit(_runner_holds.size())
	return token

func release_runner_hold(token: String) -> void:
	if token.is_empty():
		return
	if not _runner_holds.has(token):
		return

	_runner_holds.erase(token)
	runner_hold_count_changed.emit(_runner_holds.size())
	if _runner_holds.is_empty():
		runners_resumed.emit()

func has_runner_holds() -> bool:
	return not _runner_holds.is_empty()

func get_runner_hold_count() -> int:
	return _runner_holds.size()

func reset_tutorial_features() -> void:
	for feature_key in _tutorial_feature_flags.keys():
		_tutorial_feature_flags[feature_key] = true
		tutorial_feature_changed.emit(feature_key, true)

func set_tutorial_feature_enabled(feature_key: String, enabled: bool) -> void:
	if feature_key.is_empty():
		return
	_tutorial_feature_flags[feature_key] = enabled
	tutorial_feature_changed.emit(feature_key, enabled)

func is_tutorial_feature_enabled(feature_key: String) -> bool:
	if feature_key.is_empty():
		return true
	return _tutorial_feature_flags.get(feature_key, true)
