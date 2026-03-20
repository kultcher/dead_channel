# timeline_manager.gd
# Primary "source of truth," tracks distance from Runners to each Signal

extends Node2D

# SETTINGS
@export var BASE_CELLS_PER_SECOND: float = 0.2
@export var slow_speed_modifier: float = 0.5
@export var fast_speed_modifier: float = 2.5
@export var runner_screen_offset_cells: float = 1
@export var timeline_height_ratio: float = 0.25
@export var min_timeline_height_px: float = 180.0
@export var max_timeline_height_px: float = 360.0


# TIMELINE DIMENSIONS
var LANES = 5
var VISIBLE_CELLS = 8.0
var screen_width: float
var screen_height: float
var cell_width_px: float
var lane_height: float

# STATE
var cells_per_second: float = BASE_CELLS_PER_SECOND
var current_cell_pos: float = 15.0
var last_emitted_cell: int = -1
var current_cell: int
var current_speed_mult: float = 1.0
var is_paused: bool = false
var tutorial_locked: bool = false

# REGISTRATION
@onready var signal_manager = $"../SignalManager"

# SIGNALS (to update UI later)
signal speed_changed(new_speed)
signal layout_changed(viewport_size: Vector2)

func _ready():
	CommandDispatch.timeline_manager = self
	get_viewport().size_changed.connect(_refresh_layout_metrics)
	_refresh_layout_metrics()

	GlobalEvents.runners_stopped.connect(_on_runners_stopped)
	GlobalEvents.runners_resumed.connect(_on_runners_resumed)
	GlobalEvents.tactical_pause.connect(_on_pause)
	GlobalEvents.tactical_unpause.connect(_on_unpause)
	GlobalEvents.tutorial_lock_changed.connect(_on_tutorial_lock_changed)


func _process(delta):
	_handle_input()

	if is_paused:
		return
	
	var actual_speed = cells_per_second * current_speed_mult
	current_cell_pos += actual_speed * delta
	
	current_cell = floor(current_cell_pos) as int
	if current_cell != last_emitted_cell:
		last_emitted_cell = current_cell
		GlobalEvents.cell_reached.emit(current_cell)

func cells_to_pixels(cells: float):
	return cells * cell_width_px

func get_timeline_height() -> float:
	return lane_height * LANES

func get_viewport_size() -> Vector2:
	return Vector2(screen_width, screen_height)

func _refresh_layout_metrics() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	screen_width = viewport_size.x
	screen_height = viewport_size.y

	cell_width_px = screen_width / VISIBLE_CELLS
	var timeline_height := clampf(screen_height * timeline_height_ratio, min_timeline_height_px, max_timeline_height_px)
	lane_height = timeline_height / LANES
	layout_changed.emit(viewport_size)

func _handle_input():
	if Input.is_action_just_pressed("tactical_pause"):
		toggle_pause()

	if is_paused: return

	# runner speed handling
	current_speed_mult = 1.0
	if Input.is_action_pressed("ui_left"): 
		current_speed_mult = slow_speed_modifier
	elif Input.is_action_pressed("ui_right"):
		current_speed_mult = fast_speed_modifier
		
	# Optional: Emit signal if you want UI to show "FAST FORWARD" text
	# emit_signal("speed_changed", current_speed_mult)

func toggle_pause():
	if tutorial_locked: return
	if is_paused:
		GlobalEvents.tactical_unpause.emit()
	else:
		GlobalEvents.tactical_pause.emit()

func _on_unpause():
	is_paused = false

func _on_pause():
	is_paused = true

func _on_tutorial_lock_changed(locked: bool):
	tutorial_locked = locked

func _on_runners_stopped():
	cells_per_second = 0

func _on_runners_resumed():
	cells_per_second = BASE_CELLS_PER_SECOND
