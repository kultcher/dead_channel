class_name TutorialEvent extends Resource

enum Trigger {
	CELL_REACHED,
	SCAN_COMPLETE,
	SIGNAL_CONNECT,
	SIGNAL_KILLED,
	PUZZLE_STARTED,
	PUZZLE_SOLVED
}

var trigger: Trigger
var value: int
var id: String
var signal_index: int = -1 
var text: Array[String] = []
var default_position: Vector2
var has_custom_position: bool = false
var focus_rect: Rect2
var action: Callable

static func _build_event(
	event_id: String,
	event_trigger: Trigger,
	event_value: int,
	event_signal_index: int,
	event_text: Array[String],
	event_position: Vector2 = Vector2(),
	event_focus_rect: Rect2 = Rect2()
) -> TutorialEvent:
	var event := TutorialEvent.new()
	event.id = event_id
	event.trigger = event_trigger
	event.value = event_value
	event.signal_index = event_signal_index
	event.text.assign(event_text)
	event.default_position = event_position
	event.has_custom_position = event_position != Vector2()
	event.focus_rect = event_focus_rect
	return event

# events for later-game dynamic tutorials
# TODO: List of seen tutorials
static func build_dynamic_tutorials() -> Array[TutorialEvent]:
	var events: Array[TutorialEvent] = []
	return events
