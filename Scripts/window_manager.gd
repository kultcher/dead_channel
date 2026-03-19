# window_manager.gd
# Controls spawning and positioning of UI windows, links UI windows to the Signal that initiated them

extends CanvasLayer

var sniff = preload("res://Scenes/sniff.tscn")
#var fuzz = preload("res://Scenes/fuzz.tscn")
var decrypt = preload("res://Scenes/decrypt.tscn")
var dialogue_window_scene = preload("res://Scenes/dialogue_window.tscn")

@onready var timeline_manager = $"../SignalTimeline/TimelineManager"
@onready var signal_manager = $"../SignalTimeline/SignalManager"
@onready var terminal_window = preload("res://Scenes/terminal_window.tscn")
@onready var focus_overlay = $FocusOverlay

@export var default_spawn_offset := Vector2(75, 300)
@export var cascade_step := Vector2(25, 25)  # Each window offsets by this amount

var window_count := 0

func _ready():
	GlobalEvents.puzzle_started.connect(_puzzle_started)

func focus_signal(active_sig: ActiveSignal, padding: Vector2 = Vector2(64, 64)) -> void:
	if active_sig == null or active_sig.instance_node == null:
		focus_overlay.clear_focus()
		return

	var focus_rect = active_sig.instance_node.get_focus_rect()
	focus_overlay.set_focus_rect(focus_rect, padding)

func clear_focus_overlay() -> void:
	focus_overlay.clear_focus()

func show_tutorial_dialogue(event: TutorialEvent) -> Control:
	var dialogue = dialogue_window_scene.instantiate()
	dialogue.setup(event)
	dialogue.dismissed.connect(_on_tutorial_dialogue_dismissed)
	add_child(dialogue)
	move_child(dialogue, get_child_count() - 1)
	return dialogue

func _on_tutorial_dialogue_dismissed() -> void:
	clear_focus_overlay()
	GlobalEvents.tutorial_lock_changed.emit(false)
	GlobalEvents.tactical_unpause.emit()

func _puzzle_started(active_sig: ActiveSignal, puzzle_type: PuzzleComponent.Type):
	var puzzle_window
	match puzzle_type:
		PuzzleComponent.Type.DECRYPT:
			puzzle_window = decrypt.instantiate()
		_:
			puzzle_window = sniff.instantiate()

	puzzle_window.linked_signal = active_sig
	puzzle_window.puzzle_solved.connect(_on_puzzle_solved.bind(active_sig, puzzle_window))
	puzzle_window.puzzle_failed.connect(_on_puzzle_failed.bind(active_sig))
	add_child(puzzle_window)

func _on_puzzle_solved(active_sig: ActiveSignal, puzzle_window: Control) -> void:
	if active_sig != null and active_sig.data != null and active_sig.data.puzzle != null:
		active_sig.data.puzzle.process_solve(active_sig)
		GlobalEvents.puzzle_solved.emit(active_sig.data)
	if puzzle_window != null and is_instance_valid(puzzle_window):
		puzzle_window.queue_free()

func _on_puzzle_failed(active_sig: ActiveSignal) -> void:
	if active_sig != null and active_sig.data != null:
		GlobalEvents.puzzle_failed.emit(active_sig.data)
