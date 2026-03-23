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
@onready var objective_tracker = get_node_or_null("ObjectiveTracker")
@onready var help_overlay = get_node_or_null("HelpOverlay")

@export var default_spawn_offset := Vector2(75, 300)
@export var puzzle_spawn_position := Vector2(760, 430)
@export var cascade_step := Vector2(25, 25)  # Each window offsets by this amount

var window_count := 0
var _tutorial_dialogue_hold_tokens: Dictionary = {}

func _ready():
	CommandDispatch.window_manager = self
	GlobalEvents.puzzle_started.connect(_puzzle_started)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	if help_overlay != null:
		help_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
		help_overlay.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		toggle_help_overlay()
		get_viewport().set_input_as_handled()

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
	if active_sig == null:
		focus_overlay.clear_focus()
		return
	focus_overlay.set_focus_signal(active_sig, padding)

func focus_control(control: Control, padding: Vector2 = Vector2(64, 64)) -> void:
	focus_rect(get_control_focus_rect(control), padding)

func clear_focus_overlay() -> void:
	focus_overlay.clear_focus()

func set_tutorial_objective(text: String) -> void:
	if objective_tracker == null:
		return
	objective_tracker.set_objective(text)

func clear_tutorial_objective() -> void:
	if objective_tracker == null:
		return
	objective_tracker.clear_objective()

func show_help_overlay() -> void:
	if help_overlay == null:
		return
	help_overlay.visible = true
	move_child(help_overlay, get_child_count() - 1)
	get_tree().paused = true

func hide_help_overlay() -> void:
	if help_overlay == null:
		return
	help_overlay.visible = false
	get_tree().paused = false

func toggle_help_overlay() -> void:
	if help_overlay == null:
		return
	if help_overlay.visible:
		hide_help_overlay()
		return
	show_help_overlay()

func show_tutorial_dialogue(event: TutorialEvent, focus_rect: Rect2 = Rect2(), runner_hold_token: String = "") -> Control:
	var dialogue = dialogue_window_scene.instantiate()
	dialogue.dismissed.connect(_on_tutorial_dialogue_dismissed.bind(dialogue))
	add_child(dialogue)
	move_child(dialogue, get_child_count() - 1)
	if not runner_hold_token.is_empty():
		_tutorial_dialogue_hold_tokens[dialogue.get_instance_id()] = runner_hold_token
	dialogue.setup(event, focus_rect)
	return dialogue

func _on_tutorial_dialogue_dismissed(dialogue: Control) -> void:
	clear_focus_overlay()
	if dialogue != null:
		var tutorial_event_id = dialogue.get("tutorial_event_id")
		if tutorial_event_id is String and not tutorial_event_id.is_empty():
			GlobalEvents.tutorial_dialogue_finished.emit(tutorial_event_id)
	if dialogue != null:
		var dialogue_id := dialogue.get_instance_id()
		if _tutorial_dialogue_hold_tokens.has(dialogue_id):
			var runner_hold_token: String = _tutorial_dialogue_hold_tokens[dialogue_id]
			_tutorial_dialogue_hold_tokens.erase(dialogue_id)
			GlobalEvents.release_runner_hold(runner_hold_token)
	GlobalEvents.tutorial_lock_changed.emit(false)
	GlobalEvents.deactivate_null_spike.emit()

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

func _on_puzzle_solved(active_sig: ActiveSignal, puzzle_window: Control) -> void:
	if active_sig != null and active_sig.data != null and active_sig.data.puzzle != null:
		active_sig.data.puzzle.process_solve(active_sig)
		GlobalEvents.puzzle_solved.emit(active_sig.data)
	if puzzle_window != null and is_instance_valid(puzzle_window):
		puzzle_window.queue_free()

func _on_puzzle_failed(active_sig: ActiveSignal) -> void:
	if active_sig != null and active_sig.data != null:
		GlobalEvents.puzzle_failed.emit(active_sig.data)
