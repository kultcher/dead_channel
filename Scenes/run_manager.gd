# run_manager.gd
# Handles parsing (if necessary) and loading run data
# Also checks for in-run events (tutorial messages, etc.)

extends Node

@onready var timeline_manager = $"../SignalTimeline/TimelineManager"
@onready var signal_manager = $"../SignalTimeline/SignalManager"

# use for safer string mapping to prefabs if using a simple data format
@export var prefab_registry: Dictionary

var current_run: RunDef

func _ready():
	start_run()

func _process(delta: float):
	pass

func start_run():
	current_run = load("res://Resources/RunData/AuthoredRuns/run_tutorial.tres")
	propagate()

func propagate():
	for spawn in current_run.spawns:
		signal_manager.spawn_signal_data(spawn.signal_data, spawn.cell_index)
