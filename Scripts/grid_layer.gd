# grid_layer.gd
# Handles drawing and animating grid

extends Node2D

@onready var timeline_manager = $"../TimelineManager"
@onready var runner_team = $RunnerTeam
@onready var runner_icon = $RunnerTeam/RunnerIcon
@onready var debug_label = $Debug



# CONFIGURATION
var grid_color = Color(1, 0.441, 0.0, 1.0)

@onready var cell_width: float = timeline_manager.cell_width_px
@onready var lane_height: float = timeline_manager.lane_height
@onready var screen_width: float = timeline_manager.screen_width
@onready var screen_height: float = timeline_manager.screen_height

var time_elapsed: float = 0.0

func _ready():
	print("Cell width: ", cell_width, "Lane height: ", lane_height)
	if runner_team:
		var x_pos = timeline_manager.cells_to_pixels(timeline_manager.runner_screen_offset_cells)
		var y_pos = (lane_height * 2.5)
		runner_team.position = Vector2(x_pos, y_pos)

func _process(delta):
	queue_redraw()
	time_elapsed += delta
	var display_string = "Current cell pos:%.1f" % floor(timeline_manager.current_cell_pos) + "Time elapsed: %.1f" % time_elapsed
	debug_label.text = display_string

func _draw():
	cell_width = timeline_manager.cell_width_px
	lane_height = timeline_manager.lane_height

	## --- DRAW HORIZONTAL LANES ---
	for i in range(timeline_manager.LANES + 1):
		var y_pos = i * lane_height
		draw_line(
			Vector2(0, y_pos),
			Vector2(screen_width, y_pos),
			grid_color,
			1.0 
		)

	# 1. Where is the Runner?
	var runner_pos = timeline_manager.current_cell_pos

	# 2. Where is the Left Edge of the screen in "World Coordinates"?
	# If runner is at 100, and offset is 1.5... Left edge is 98.5.
	var left_edge_world_pos = runner_pos - timeline_manager.runner_screen_offset_cells

	# 3. Find first visible grid line index based on Left Edge
	var first_visible_index = floor(left_edge_world_pos)

	# 4. Calculate offset from the Left Edge of the screen
	# e.g. Line 99 - Edge 98.5 = 0.5 cells from left
	var distance_from_edge_cells = first_visible_index - left_edge_world_pos

	# 5. Convert to pixels
	var draw_x = timeline_manager.cells_to_pixels(distance_from_edge_cells)


	while draw_x < screen_width + cell_width:
		if draw_x > -10: 
			draw_line(
				Vector2(draw_x, 0), 
				Vector2(draw_x, lane_height * timeline_manager.LANES),
				grid_color, 
				2.0) 
		draw_x += cell_width
