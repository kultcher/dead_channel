# window_manager.gd
# Controls spawning and positioning of UI windows, links UI windows to the Signal that initiated them

extends CanvasLayer

@onready var timeline_manager = $"../SignalTimeline/TimelineManager"
@onready var signal_manager = $"../SignalTimeline/SignalManager"
@onready var terminal_window = preload("res://Scenes/terminal_window.tscn")

@export var default_spawn_offset := Vector2(75, 300)
@export var cascade_step := Vector2(25, 25)  # Each window offsets by this amount

var window_count := 0

func _ready():
	signal_manager.signal_clicked.connect(route_signal_to_window)
	CommandDispatch.window_manager = self
	
func route_signal_to_window(active_signal: ActiveSignal):
	var new_window = terminal_window.instantiate()
	new_window.active_signal = active_signal
	add_child(new_window)

	var offset = default_spawn_offset + (cascade_step * window_count)
	new_window.position = offset
	window_count += 1

	print("WindowManager: Opening window for ", active_signal.data.type)
