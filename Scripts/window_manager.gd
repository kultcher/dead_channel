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
	pass
