# tutorial_manager.gd

extends Node

@onready var timeline_manager = $"../SignalTimeline/TimelineManager"
@onready var signal_manager = $"../SignalTimeline/SignalManager"
@onready var terminal = $"../TerminalWindow"
@onready var run_manager = $"../RunManager"
@onready var window_manager = $"../WindowManager"

var events: Array[TutorialEvent] = []
var _active_runner_hold_tokens: Dictionary = {}
var _active_timer_versions: Dictionary = {}

var tutorial_level_flags: Dictionary = {
	"first_signal": false,
	"first_scan": false,
	"terminal_intro": false,
	"heat_intro": false,
	"minigame_intro": false,
	"decrypt_intro": false,
	"decrypt_continued": false,
	"decrypt_complete": false,
	"ic_intro": false,
	"ic_timing": false,
	"guards_intro": false,
	"distraction_intro": false,
	"skill_test": false,
	"null_spike_intro": false,
	"run_end_intro": false
}

func _ready():
	events = run_manager.get_tutorial_events()
	GlobalEvents.reset_tutorial_features()
	window_manager.clear_tutorial_objective()
	setup_triggers()

func setup_triggers():
	GlobalEvents.cell_reached.connect(_check_cell_triggers)
	GlobalEvents.signal_scan_complete.connect(_check_scan_triggers)
	GlobalEvents.signal_connect.connect(_check_connect_triggers)
	GlobalEvents.signal_killed.connect(_check_kill_triggers)
	GlobalEvents.puzzle_started.connect(_check_puzzle_started_triggers)
	GlobalEvents.puzzle_solved.connect(_check_puzzle_solved_triggers)
	GlobalEvents.tutorial_dialogue_finished.connect(_check_dialogue_finished_triggers)
	GlobalEvents.tutorial_timer_elapsed.connect(_check_timer_elapsed_triggers)

func _check_cell_triggers(cell: int):
	for event in events:
		if event.trigger == TutorialEvent.Trigger.CELL_REACHED and event.value == cell:
			_show_tutorial_once(event)
			return


func _check_scan_triggers(signal_data: SignalData):
	for event in events:
		if event.trigger != TutorialEvent.Trigger.SCAN_COMPLETE:
			continue
		if not _event_matches_signal(event, signal_data):
			continue
		_show_tutorial_once(event)
		return

func _check_connect_triggers(signal_data: SignalData):
	for event in events:
		if event.trigger == TutorialEvent.Trigger.SIGNAL_CONNECT:
			_show_tutorial_once(event)
			return

func _check_kill_triggers(signal_data: SignalData):
	for event in events:
		if event.trigger == TutorialEvent.Trigger.SIGNAL_KILLED:
			_show_tutorial_once(event)
			return

func _check_puzzle_started_triggers(active_signal: ActiveSignal, puzzle_type: PuzzleComponent.Type):
	for event in events:
		if event.trigger != TutorialEvent.Trigger.PUZZLE_STARTED:
			continue
		if event.value != int(puzzle_type):
			continue
		_show_tutorial_once(event)
		return

func _check_puzzle_solved_triggers(signal_data: SignalData):
	for event in events:
		if event.trigger == TutorialEvent.Trigger.PUZZLE_SOLVED:
			_show_tutorial_once(event)
			return

func _check_dialogue_finished_triggers(event_id: String):
	for event in events:
		if event.trigger != TutorialEvent.Trigger.DIALOGUE_FINISHED:
			continue
		if event.trigger_key != event_id:
			continue
		_show_tutorial_once(event)
		return

func _check_timer_elapsed_triggers(timer_key: String):
	for event in events:
		if event.trigger != TutorialEvent.Trigger.TIMER_ELAPSED:
			continue
		if event.trigger_key != timer_key:
			continue
		_show_tutorial_once(event)
		return

func _show_tutorial(event: TutorialEvent, custom_focus_rect: Rect2 = Rect2()):
	_execute_event(event, custom_focus_rect)
	events.erase(event)

func _show_tutorial_once(event: TutorialEvent, custom_focus_rect: Rect2 = Rect2()) -> void:
	if not tutorial_level_flags.has(event.id):
		tutorial_level_flags[event.id] = false
	if tutorial_level_flags[event.id]:
		return
	_show_tutorial(event, custom_focus_rect)
	tutorial_level_flags[event.id] = true

func _event_matches_signal(event: TutorialEvent, signal_data: SignalData) -> bool:
	if event.signal_index < 0:
		return true
	if event.signal_index >= signal_manager.signal_queue.size():
		return false

	var target_signal: ActiveSignal = signal_manager.signal_queue[event.signal_index]
	return target_signal != null and target_signal.data == signal_data

func _focus_tutorial_target(event: TutorialEvent, custom_focus_rect: Rect2 = Rect2()) -> Rect2:
	if _has_focus_rect(custom_focus_rect):
		window_manager.focus_rect(custom_focus_rect)
		return custom_focus_rect

	if _has_focus_rect(event.focus_rect):
		window_manager.focus_rect(event.focus_rect, Vector2(32, 32))
		return event.focus_rect

	if event.signal_index < 0:
		window_manager.clear_focus_overlay()
		return Rect2()

	if event.signal_index >= signal_manager.signal_queue.size():
		window_manager.clear_focus_overlay()
		return Rect2()

	var active_sig: ActiveSignal = signal_manager.signal_queue[event.signal_index]
	var resolved_focus_rect = window_manager.get_signal_focus_rect(active_sig)
	if _has_focus_rect(resolved_focus_rect):
		window_manager.focus_signal(active_sig)
		return resolved_focus_rect

	window_manager.clear_focus_overlay()
	return Rect2()

func _has_focus_rect(focus_rect: Rect2) -> bool:
	return focus_rect.size.x > 0.0 and focus_rect.size.y > 0.0

func _execute_event(event: TutorialEvent, custom_focus_rect: Rect2 = Rect2()) -> void:
	var resolved_focus_rect := _apply_event_focus(event, custom_focus_rect)
	_apply_event_state_changes(event)
	_present_event_dialogue(event, resolved_focus_rect)

func _apply_event_focus(event: TutorialEvent, custom_focus_rect: Rect2 = Rect2()) -> Rect2:
	return _focus_tutorial_target(event, custom_focus_rect)

func _apply_event_state_changes(event: TutorialEvent) -> void:
	_apply_runner_hold_changes(event)
	_apply_objective_text(event)
	_apply_feature_gates(event)
	_apply_event_timer(event)

func _present_event_dialogue(event: TutorialEvent, resolved_focus_rect: Rect2) -> void:
	if not event.has_dialogue():
		return

	GlobalEvents.tutorial_lock_changed.emit(true)
	var runner_hold_token := ""
	if event.hold_runners:
		runner_hold_token = _consume_runner_hold_token(event)
	window_manager.show_tutorial_dialogue(event, resolved_focus_rect, runner_hold_token)

func _apply_objective_text(event: TutorialEvent) -> void:
	if event.objective_text.is_empty():
		return
	window_manager.set_tutorial_objective(event.objective_text)

func _apply_feature_gates(event: TutorialEvent) -> void:
	for feature_key in event.feature_gates.keys():
		GlobalEvents.set_tutorial_feature_enabled(feature_key, bool(event.feature_gates[feature_key]))

func _apply_event_timer(event: TutorialEvent) -> void:
	if event.start_timer_key.is_empty():
		return
	if event.start_timer_duration < 0.0:
		return
	_start_named_timer(event.start_timer_key, event.start_timer_duration)

func _apply_runner_hold_changes(event: TutorialEvent) -> void:
	var hold_key := _get_runner_hold_key(event)
	if event.release_runner_hold:
		_release_runner_hold(hold_key)
	if event.hold_runners:
		_acquire_runner_hold(hold_key)

func _get_runner_hold_key(event: TutorialEvent) -> String:
	if event == null:
		return ""
	if not event.runner_hold_key.is_empty():
		return event.runner_hold_key
	return event.id

func _acquire_runner_hold(hold_key: String) -> void:
	if hold_key.is_empty():
		return
	if _active_runner_hold_tokens.has(hold_key):
		return
	_active_runner_hold_tokens[hold_key] = GlobalEvents.acquire_runner_hold("tutorial_%s" % hold_key)

func _release_runner_hold(hold_key: String) -> void:
	if hold_key.is_empty():
		return
	if not _active_runner_hold_tokens.has(hold_key):
		return
	var token: String = _active_runner_hold_tokens[hold_key]
	_active_runner_hold_tokens.erase(hold_key)
	GlobalEvents.release_runner_hold(token)

func _consume_runner_hold_token(event: TutorialEvent) -> String:
	var hold_key := _get_runner_hold_key(event)
	if hold_key.is_empty():
		return ""
	if not _active_runner_hold_tokens.has(hold_key):
		return ""
	var token: String = _active_runner_hold_tokens[hold_key]
	_active_runner_hold_tokens.erase(hold_key)
	return token

func _start_named_timer(timer_key: String, duration: float) -> void:
	var version := int(_active_timer_versions.get(timer_key, 0)) + 1
	_active_timer_versions[timer_key] = version
	_emit_timer_when_ready(timer_key, duration, version)

func _emit_timer_when_ready(timer_key: String, duration: float, version: int) -> void:
	await get_tree().create_timer(maxf(0.0, duration)).timeout
	if int(_active_timer_versions.get(timer_key, 0)) != version:
		return
	GlobalEvents.tutorial_timer_elapsed.emit(timer_key)
