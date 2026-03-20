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
@export var puzzle_spawn_position := Vector2(760, 430)
@export var cascade_step := Vector2(25, 25)  # Each window offsets by this amount

var window_count := 0

func _ready():
	GlobalEvents.puzzle_started.connect(_puzzle_started)

func get_signal_focus_rect(active_sig: ActiveSignal) -> Rect2:
	if active_sig == null or active_sig.instance_node == null:
		return Rect2()

	return active_sig.instance_node.get_focus_rect()

func get_control_focus_rect(control: Control) -> Rect2:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
		return Rect2()
	return control.get_global_rect()

func focus_rect(rect: Rect2, padding: Vector2 = Vector2(64, 64)) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		focus_overlay.clear_focus()
		return

	focus_overlay.set_focus_rect(rect, padding)

func focus_signal(active_sig: ActiveSignal, padding: Vector2 = Vector2(64, 64)) -> void:
	focus_rect(get_signal_focus_rect(active_sig), padding)

func focus_control(control: Control, padding: Vector2 = Vector2(64, 64)) -> void:
	focus_rect(get_control_focus_rect(control), padding)

func clear_focus_overlay() -> void:
	focus_overlay.clear_focus()

func show_tutorial_dialogue(event: TutorialEvent, focus_rect: Rect2 = Rect2()) -> Control:
	var dialogue = dialogue_window_scene.instantiate()
	dialogue.dismissed.connect(_on_tutorial_dialogue_dismissed)
	add_child(dialogue)
	move_child(dialogue, get_child_count() - 1)
	dialogue.setup(event, focus_rect)
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
	move_child(puzzle_window, get_child_count() - 1)
	puzzle_window.position = puzzle_spawn_position
	await get_tree().process_frame
	if puzzle_window == null or not is_instance_valid(puzzle_window):
		return
	focus_control(puzzle_window, Vector2(32, 32))
	if timeline_manager.is_paused and puzzle_window.has_method("_on_pause"):
		puzzle_window.call("_on_pause")

func _on_puzzle_solved(active_sig: ActiveSignal, puzzle_window: Control) -> void:
	if active_sig != null and active_sig.data != null and active_sig.data.puzzle != null:
		active_sig.data.puzzle.process_solve(active_sig)
		GlobalEvents.puzzle_solved.emit(active_sig.data)
	if puzzle_window != null and is_instance_valid(puzzle_window):
		puzzle_window.queue_free()

func _on_puzzle_failed(active_sig: ActiveSignal) -> void:
	if active_sig != null and active_sig.data != null:
		GlobalEvents.puzzle_failed.emit(active_sig.data)
