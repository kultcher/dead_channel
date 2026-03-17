class_name TutorialEvent extends Resource

enum Trigger { CELL_REACHED, SCAN_COMPLETE }

var trigger: Trigger
var value: int
var id: String
var signal_index: int = -1
var text: Array[String] = []
var default_position: Vector2
var action: Callable

# events for tutorial level
static func build_tutorial_events() -> Array[TutorialEvent]:
	var events: Array[TutorialEvent] = []
	
	var e1 = TutorialEvent.new()
	e1.id = "first_signal"
	e1.text.append("This is a SIGNAL. Signals represent all the networked devices in the facility.\n
The shape of the signal can tell you what of device it is, but you can learn more information by SCANNING the signal.\n
To SCAN a signal, hold the mouse over it. Keep scanning this signal until all it's info is revealed.")
	e1.trigger = Trigger.CELL_REACHED
	e1.value = 1
	e1.signal_index = 0		# first signal seen
	e1.default_position = Vector2(1400, 300)
	events.append(e1)

	var e2 = TutorialEvent.new()
	e2.id = "first_scan"
	e2.text.append("Scanning this Signal has revealed it's type, it's access parameters and any IC (Intrusion Countermeasures) on the Signal.
Since it's ACCESS type is open, hacking it will be a breeze.")
	e2.text.append("Just one thing to watch for: the Reboot IC. Reboot IC will cause the Signal to reboot itself after a delay.
If you hack it too soon, it might be up and running again in time to spot the team.")
	e2.trigger = Trigger.SCAN_COMPLETE
	e2.value = 1
	e2.signal_index = 0		# first signal seen
	e2.default_position = Vector2(1400, 300)
	events.append(e2)

	return events

# events for later-game dynamic tutorials
# TODO: List of seen tutorials
static func build_dynamic_tutorials() -> Array[TutorialEvent]:
	var events: Array[TutorialEvent] = []
	return events
