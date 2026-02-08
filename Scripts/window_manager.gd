# window_manager.gd
# Controls spawning and positioning of UI windows, links UI windows to the Signal that initiated them

extends CanvasLayer

var sniff = preload("res://Scenes/sniff.tscn")
#var fuzz = preload("res://Scenes/fuzz.tscn")
var decrypt = preload("res://Scenes/decrypt.tscn")

@onready var timeline_manager = $"../SignalTimeline/TimelineManager"
@onready var signal_manager = $"../SignalTimeline/SignalManager"
@onready var terminal_window = preload("res://Scenes/terminal_window.tscn")

@export var default_spawn_offset := Vector2(75, 300)
@export var cascade_step := Vector2(25, 25)  # Each window offsets by this amount

var window_count := 0

func _ready():
	GlobalEvents.puzzle_started.connect(_puzzle_started)

func _puzzle_started(active_sig: ActiveSignal, puzzle_type: PuzzleComponent.Type):
	var puzzle_window = sniff.instantiate()
	puzzle_window.linked_signal = active_sig
	add_child(puzzle_window)
