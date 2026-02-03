# timeline_manager.gd
# Primary "source of truth," tracks distance from Runners to each Signal

extends Node2D

# SETTINGS
@export var cells_per_second: float = 0.25 # Cells moved per second
@export var slow_speed_modifier: float = 0.5
@export var fast_speed_modifier: float = 2.0
@export var runner_screen_offset_cells: float = 1


# TIMELINE DIMENSIONS
var LANES = 5
var VISIBLE_CELLS = 8.0
var screen_width: float
var screen_height: float
var cell_width_px: float
var lane_height: float

# STATE
var current_cell_pos: float = 0.0
var current_speed_mult: float = 1.0
var is_paused: bool = false

# REGISTRATION
@onready var signal_manager = $"../SignalManager"

# SIGNALS (to update UI later)
signal speed_changed(new_speed)

func _ready():
	CommandDispatch.timeline_manager = self
	
	var viewport_size = get_viewport().get_visible_rect().size
	screen_width = viewport_size.x
	screen_height = viewport_size.y
	
	cell_width_px = screen_width / VISIBLE_CELLS
	lane_height = (screen_height * 0.25) / LANES
	
func _process(delta):
	if is_paused:
		return

	_handle_speed_input()
	
	var actual_speed = cells_per_second * current_speed_mult
	current_cell_pos += actual_speed * delta

func cells_to_pixels(cells: float):
	return cells * cell_width_px

func _handle_speed_input():
	# Reset to normal
	current_speed_mult = 1.0
	
	if Input.is_action_pressed("ui_left"): 
		current_speed_mult = slow_speed_modifier
	elif Input.is_action_pressed("ui_right"):
		current_speed_mult = fast_speed_modifier
		
	# Optional: Emit signal if you want UI to show "FAST FORWARD" text
	# emit_signal("speed_changed", current_speed_mult)
