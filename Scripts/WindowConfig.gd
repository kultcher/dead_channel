# WindowConfig.gd
# Future home of custom window spawning logic

class_name WindowSpawnConfig extends Resource

enum SpawnMode { CASCADE, RANDOM, ANCHOR_POINTS, GRID }

@export var mode: SpawnMode = SpawnMode.CASCADE
@export var anchor_points: Array[Vector2] = []
@export var preferred_quadrants: Array[String] = ["bottom_left", "bottom_right"]

#func get_next_spawn_position(window_type: String) -> Vector2:
	#match mode:
		#SpawnMode.ANCHOR_POINTS:
			#return anchor_points[randi() % anchor_points.size()]
	#pass
