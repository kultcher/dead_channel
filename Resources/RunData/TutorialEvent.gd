class_name TutorialEvent extends Resource

enum Trigger {
	CELL_REACHED,
	SCAN_COMPLETE,
	SIGNAL_CONNECT,
	SIGNAL_KILLED,
	PUZZLE_STARTED,
	PUZZLE_SOLVED,
	DIALOGUE_FINISHED,
	TIMER_ELAPSED
}

var trigger: Trigger
var value: int
var trigger_key: String = ""
var id: String
var signal_index: int = -1 
var text: Array[String] = []
var default_position: Vector2
var has_custom_position: bool = false
var focus_rect: Rect2
var objective_text: String = ""
var action: Callable
var hold_runners: bool = false
var release_runner_hold: bool = false
var runner_hold_key: String = ""
var start_timer_key: String = ""
var start_timer_duration: float = -1.0
var feature_gates: Dictionary = {}

static func build_event(
	event_id: String,
	event_trigger: Trigger,
	event_value: int = -1,
	event_signal_index: int = -1,
	event_text: Array[String] = [],
	event_position: Vector2 = Vector2(),
	event_focus_rect: Rect2 = Rect2(),
	event_objective_text: String = "",
	event_hold_runners: bool = false,
	event_release_runner_hold: bool = false,
	event_runner_hold_key: String = "",
	event_trigger_key: String = "",
	event_start_timer_key: String = "",
	event_start_timer_duration: float = -1.0,
	event_feature_gates: Dictionary = {}
) -> TutorialEvent:
	var event := TutorialEvent.new()
	event.id = event_id
	event.trigger = event_trigger
	event.value = event_value
	event.trigger_key = event_trigger_key
	event.signal_index = event_signal_index
	event.text.assign(event_text)
	event.default_position = event_position
	event.has_custom_position = event_position != Vector2()
	event.focus_rect = event_focus_rect
	event.objective_text = event_objective_text
	event.hold_runners = event_hold_runners
	event.release_runner_hold = event_release_runner_hold
	event.runner_hold_key = event_runner_hold_key
	event.start_timer_key = event_start_timer_key
	event.start_timer_duration = event_start_timer_duration
	event.feature_gates = event_feature_gates.duplicate(true)
	return event

static func _build_event(
	event_id: String,
	event_trigger: Trigger,
	event_value: int,
	event_signal_index: int,
	event_text: Array[String],
	event_position: Vector2 = Vector2(),
	event_focus_rect: Rect2 = Rect2(),
	event_objective_text: String = "",
	event_hold_runners: bool = false,
	event_release_runner_hold: bool = false,
	event_runner_hold_key: String = "",
	event_trigger_key: String = "",
	event_start_timer_key: String = "",
	event_start_timer_duration: float = -1.0,
	event_feature_gates: Dictionary = {}
) -> TutorialEvent:
	return build_event(
		event_id,
		event_trigger,
		event_value,
		event_signal_index,
		event_text,
		event_position,
		event_focus_rect,
		event_objective_text,
		event_hold_runners,
		event_release_runner_hold,
		event_runner_hold_key,
		event_trigger_key,
		event_start_timer_key,
		event_start_timer_duration,
		event_feature_gates
	)

func has_dialogue() -> bool:
	return not text.is_empty()

# events for later-game dynamic tutorials
# TODO: List of seen tutorials
static func build_dynamic_tutorials() -> Array[TutorialEvent]:
	var events: Array[TutorialEvent] = []
	return events
