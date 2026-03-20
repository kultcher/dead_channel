# tutorial_manager.gd

extends Node

@onready var timeline_manager = $"../SignalTimeline/TimelineManager"
@onready var signal_manager = $"../SignalTimeline/SignalManager"
@onready var terminal = $"../TerminalWindow"
@onready var run_manager = $"../RunManager"
@onready var window_manager = $"../WindowManager"

var events: Array[TutorialEvent] = []

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
	"tactical_pause_intro": false,
	"run_end_intro": false
}

func _ready():
	events = run_manager.get_tutorial_events()
	window_manager.clear_tutorial_objective()
	setup_triggers()

func setup_triggers():
	GlobalEvents.cell_reached.connect(_check_cell_triggers)
	GlobalEvents.signal_scan_complete.connect(_check_scan_triggers)
	GlobalEvents.signal_connect.connect(_check_connect_triggers)
	GlobalEvents.signal_killed.connect(_check_kill_triggers)
	GlobalEvents.puzzle_started.connect(_check_puzzle_started_triggers)
	GlobalEvents.puzzle_solved.connect(_check_puzzle_solved_triggers)

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

func _show_tutorial(event: TutorialEvent, custom_focus_rect: Rect2 = Rect2()):
	GlobalEvents.tutorial_lock_changed.emit(true)
	GlobalEvents.tactical_pause.emit()
	var resolved_focus_rect := _focus_tutorial_target(event, custom_focus_rect)
	window_manager.set_tutorial_objective(event.objective_text)
	window_manager.show_tutorial_dialogue(event, resolved_focus_rect)
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
		window_manager.focus_rect(resolved_focus_rect)
		return resolved_focus_rect

	window_manager.clear_focus_overlay()
	return Rect2()

func _has_focus_rect(focus_rect: Rect2) -> bool:
	return focus_rect.size.x > 0.0 and focus_rect.size.y > 0.0
