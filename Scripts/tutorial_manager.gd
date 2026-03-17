# tutorial_manager.gd

extends Node

@onready var timeline_manager = $"../SignalTimeline/TimelineManager"
@onready var signal_manager = $"../SignalTimeline/SignalManager"
@onready var run_manager = $"../RunManager"

@onready var dialogue_window = preload("res://Scenes/dialogue_window.tscn")

var events: Array[TutorialEvent] = []

var tutorial_level_flags: Dictionary = {
	"first_signal": false,
	"first_scan": false,
}
func _ready():
	if run_manager.current_run.run_id == "tutorial":
		events = TutorialEvent.build_tutorial_events()
	setup_triggers()

func setup_triggers():
	GlobalEvents.cell_reached.connect(_check_cell_triggers)
	GlobalEvents.signal_scan_complete.connect(_check_scan_triggers)

func _check_cell_triggers(cell: int):
	for event in events:
		print(event.id)
		if event.trigger == TutorialEvent.Trigger.CELL_REACHED and event.value == cell:
			_show_tutorial(event)
			tutorial_level_flags["first_signal"] = true


func _check_scan_triggers(signal_data: SignalData):
	for event in events:
		if event.trigger == TutorialEvent.Trigger.SCAN_COMPLETE:
			print("Event ID: ", event.id)
			if event.id == "first_scan" and tutorial_level_flags["first_scan"] == false:
				_show_tutorial(event)
				signal_manager.handle_lock_toggle(signal_manager.signal_queue[0])
				tutorial_level_flags["first_scan"] = true
			else:
				pass	# check against characteristics of signal?

func _show_tutorial(event: TutorialEvent):
	GlobalEvents.tactical_pause.emit()
	var dialogue = dialogue_window.instantiate()
	dialogue.setup(event)
	add_child(dialogue)
	events.erase(event)
