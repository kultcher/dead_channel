class_name TutorialEvent extends Resource

enum Trigger { CELL_REACHED, SCAN_COMPLETE, SIGNAL_CONNECT, SIGNAL_KILLED }

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
	e2.value = -1
	e2.signal_index = -1		# first signal seen
	e2.default_position = Vector2(1400, 300)
	events.append(e2)

	var e3 = TutorialEvent.new()
	e3.id = "terminal_intro"
	e3.text.append("You're connected to the camera, now let's take it out.
	There are a few different ways to deal with obstacles like these, but for now, we're going to do it fast and loud: with KILL.")
	e3.text.append("Since you're already connected to the signal, all you have to do is type KILL and hit enter.")
	e3.trigger = Trigger.SIGNAL_CONNECT
	e3.value = -1
	e3.signal_index = -1
	e3.default_position = Vector2(1400, 300)
	events.append(e3)

	var e4 = TutorialEvent.new()
	e4.id = "heat_intro"
	e4.text.append("KILL is easy, but it's not subtle. See how your HEAT gauge spiked?
	Too much HEAT can cause you all kinds of problems down the line, so don't just KILL every signal.
	Don't worry, soon you'll learn other, quieter ways of disabling Signals.")
	e4.trigger = Trigger.SIGNAL_KILLED
	e4.value = -1
	e4.signal_index = -1
	e4.default_position = Vector2(1400, 300)
	events.append(e4)

	return events

# events for later-game dynamic tutorials
# TODO: List of seen tutorials
static func build_dynamic_tutorials() -> Array[TutorialEvent]:
	var events: Array[TutorialEvent] = []
	return events
