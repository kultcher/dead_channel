class_name SniffPuzzleConfig extends Resource

enum ScrollDirection { VERTICAL, HORIZONTAL }

@export var grid_cols: int = 0
@export var grid_rows: int = 0
@export var cell_size: int = 0
@export var target_count: int = 0
@export var scroll_direction: ScrollDirection = ScrollDirection.VERTICAL
@export var base_speed: float = 0.0
@export var speed_variance: float = -1.0
@export var col_speeds: PackedFloat32Array = PackedFloat32Array()

func ensure_generated(difficulty: int) -> void:
	if grid_cols > 0:
		return

	match difficulty:
		1:
			grid_cols = 4
			grid_rows = 4
			cell_size = 80
			target_count = 1
			scroll_direction = ScrollDirection.VERTICAL
			base_speed = 50.0
			speed_variance = 0.5
		_:
			grid_cols = 5
			grid_rows = 4
			cell_size = 80
			target_count = 2
			scroll_direction = ScrollDirection.VERTICAL
			base_speed = 60.0
			speed_variance = 0.6
