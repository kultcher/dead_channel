# grid_layer.gd
# Handles drawing and animating grid

extends Node2D

@onready var timeline_manager = $"../TimelineManager"
@onready var runner_team = $RunnerTeam
@onready var debug_label = $Debug

# CONFIGURATION
var LANES = 5
var VISIBLE_CELLS = 8.0
var grid_color = Color(1, 0.441, 0.0, 1.0)

@onready var cell_width: float = timeline_manager.cell_width_px
@onready var lane_height: float = timeline_manager.lane_height
@onready var screen_width: float = timeline_manager.screen_width
@onready var screen_height: float = timeline_manager.screen_height


func _ready():
	if runner_team:
		runner_team.position = Vector2(cell_width / 2, (lane_height * 2.5))

func _process(delta):
	queue_redraw()

	var display_string = "%.0f" % timeline_manager.current_cell_pos
	debug_label.text = display_string

func _draw():
	# Update these every frame just in case window resizes or manager updates
	cell_width = timeline_manager.cell_width_px
	lane_height = timeline_manager.lane_height

	# --- DRAW HORIZONTAL LANES ---
	for i in range(LANES + 1):
		var y_pos = i * lane_height
		draw_line(
			Vector2(0, y_pos),
			Vector2(screen_width, y_pos),
			grid_color,
			1.0 
		)
	
	# --- DRAW MOVING VERTICAL LINES (CELLS/ROOMS) ---
	
	# 1. Get Distance in Cells
	var world_pos_cells = timeline_manager.current_cell_pos
	
	# 2. Find the index of the first vertical line visible
	var first_visible_index = floor(world_pos_cells)
	
	# 3. Calculate the offset
	var distance_in_cells = first_visible_index - world_pos_cells
	
	# 5. Apply Runner Offset
	var draw_x = timeline_manager.cells_to_pixels(distance_in_cells)

	while draw_x < screen_width + cell_width:
		if draw_x > -10: 
			draw_line(
				Vector2(draw_x, 0), 
				Vector2(draw_x, lane_height * LANES),
				grid_color, 
				2.0 
			)
		draw_x += cell_width
