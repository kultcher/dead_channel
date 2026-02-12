# DetectionComponent.gd
# Signal component for vision behaviors

class_name DetectionComponent extends Resource

enum ShapeType { CONE, ARC, CIRCLE }

@export var watch_offset_cells: float = -1.0:
	set = _set_watch_offset_cells
@export var vision_length_cells: float = 2.0:
	set = _set_vision_length_cells
@export var vision_angle_deg: float = 30.0:
	set = _set_vision_angle_deg
@export var vision_segments: int = 12:
	set = _set_vision_segments
@export var shape_type: ShapeType = ShapeType.CONE:
	set = _set_shape_type
@export var delay: float = 0.0

var detection_disabled: bool = false

func _set_vision_length_cells(value: float) -> void:
	vision_length_cells = max(0.0, value)
	emit_changed()

func _set_watch_offset_cells(value: float) -> void:
	watch_offset_cells = value
	emit_changed()

func _set_vision_angle_deg(value: float) -> void:
	vision_angle_deg = clamp(value, 1.0, 179.0)
	emit_changed()

func _set_vision_segments(value: int) -> void:
	vision_segments = max(3, value)
	emit_changed()

func _set_shape_type(value: ShapeType) -> void:
	shape_type = value
	emit_changed()

func apply_detection(active_sig: ActiveSignal, delta: float) -> void:
	if active_sig.is_disabled or detection_disabled:
		return
	_apply_detection(active_sig, delta)

func build_collision_shape(cell_width_px: float) -> Shape2D:

	match shape_type:
		ShapeType.CIRCLE:
			var circle = CircleShape2D.new()
			circle.radius = max(1.0, vision_length_cells * cell_width_px)
			return circle
		ShapeType.CONE:
			var poly = ConvexPolygonShape2D.new()
			poly.points = _build_polygon_points(cell_width_px)
			return poly
	return

func get_visual_polygon(cell_width_px: float) -> PackedVector2Array:
	return _build_polygon_points(cell_width_px)

func _build_polygon_points(cell_width_px: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var offset_px = watch_offset_cells * cell_width_px
	var length_px = max(1.0, vision_length_cells * cell_width_px)


	match shape_type:
		ShapeType.CONE:
			var half_width = tan(deg_to_rad(vision_angle_deg * 0.5)) * length_px
			points.append(Vector2(offset_px, 0)) # tip
			points.append(Vector2(offset_px - length_px, -half_width))
			points.append(Vector2(offset_px - length_px, half_width))
		ShapeType.ARC:
			var radius = length_px
			var angle_rad = deg_to_rad(vision_angle_deg)
			var start_angle = PI - (angle_rad * 0.5)
			var end_angle = PI + (angle_rad * 0.5)
			points.append(Vector2(offset_px, 0)) # fan center
			for i in range(vision_segments + 1):
				var t = float(i) / float(vision_segments)
				var theta = lerp(start_angle, end_angle, t)
				points.append(Vector2(offset_px, 0) + Vector2(cos(theta), sin(theta)) * radius)
		ShapeType.CIRCLE:
			var radius = length_px
			for i in range(vision_segments):
				var t = float(i) / float(vision_segments)
				var theta = lerp(0.0, TAU, t)
				points.append(Vector2(offset_px, 0) + Vector2(cos(theta), sin(theta)) * radius)

	return points

func _apply_detection(active_sig: ActiveSignal, delta):
	active_sig.instance_node.detection_controller.runner_spotted()
	if active_sig.data.response:
		active_sig.data.response.on_detection(active_sig, delta, delay)

func disable_detection():
	detection_disabled = true

func get_desc():
	return "Static"
