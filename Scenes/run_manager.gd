# run_manager.gd
# Handles parsing (if necessary) and loading run data
# Also checks for in-run events (tutorial messages, etc.)

extends Node

@onready var timeline_manager = $"../SignalTimeline/TimelineManager"
@onready var signal_manager = $"../SignalTimeline/SignalManager"

@export_file("*.gd") var level_script_path := "res://Resources/RunData/AuthoredRuns/TutorialRun.gd"

var current_run: RunDefinition

func _ready():
	start_run()

func _process(delta: float):
	pass

func start_run():
	var level_script = load(level_script_path)
	current_run = level_script.new()
	propagate()

func propagate():
	for spawn in current_run.get_spawns():
		signal_manager.spawn_signal_data(_build_signal_from_spawn(spawn), spawn["cell_index"])

func get_run_id() -> String:
	if current_run == null:
		return ""
	return current_run.get_run_id()

func get_display_name() -> String:
	if current_run == null:
		return ""
	return current_run.get_display_name()

func get_tutorial_events() -> Array[TutorialEvent]:
	if current_run == null:
		return []
	return current_run.get_tutorial_events()

func _build_signal_from_spawn(spawn: Dictionary) -> SignalData:
	var signal_data: SignalData = spawn["signal_data"]
	var runtime_signal := signal_data.duplicate(true) as SignalData

	if spawn.has("lane"):
		runtime_signal.lane = spawn["lane"]
	if spawn.has("display_name"):
		runtime_signal.display_name = spawn["display_name"]
	if spawn.has("spoof_id"):
		runtime_signal.spoof_id = spawn["spoof_id"]
	if spawn.has("puzzle"):
		runtime_signal.puzzle = spawn["puzzle"].duplicate(true)
	if spawn.has("ic_modules"):
		runtime_signal.ic_modules = spawn["ic_modules"].duplicate(true)
	if spawn.has("add_ic_modules"):
		_append_ic_modules(runtime_signal, spawn["add_ic_modules"])

	return runtime_signal

func _append_ic_modules(runtime_signal: SignalData, modules_to_add: Array) -> void:
	if runtime_signal.ic_modules == null:
		runtime_signal.ic_modules = ICComponent.new()

	for module in modules_to_add:
		if module == null:
			continue
		runtime_signal.ic_modules.add_module(module.duplicate(true))
