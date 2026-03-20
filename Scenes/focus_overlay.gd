extends Control

@export var focus_size := Vector2(360, 180)
@export var dim_color := Color(0.2, 0.2, 0.2, 0.6)
@export var reveal_duration := 0.5

@onready var top_rect: ColorRect = $TopRect
@onready var left_rect: ColorRect = $LeftRect
@onready var right_rect: ColorRect = $RightRect
@onready var bottom_rect: ColorRect = $BottomRect
@onready var focus_rect: ReferenceRect = $FocusRect

var reveal_progress := 0.0
var focus_center := Vector2.ZERO

func _ready() -> void:
	resized.connect(_update_layout)
	focus_center = size * 0.5
	visible = false
	_update_layout()

func _update_layout() -> void:
	var clamped_focus_size := Vector2(
		clampf(focus_size.x, 1.0, size.x),
		clampf(focus_size.y, 1.0, size.y)
	)
	var max_focus_position := size - clamped_focus_size
	var focus_position := focus_center - (clamped_focus_size * 0.5)
	focus_position.x = clampf(focus_position.x, 0.0, max_focus_position.x)
	focus_position.y = clampf(focus_position.y, 0.0, max_focus_position.y)

	focus_rect.position = focus_position
	focus_rect.size = clamped_focus_size

	top_rect.color = dim_color
	left_rect.color = dim_color
	right_rect.color = dim_color
	bottom_rect.color = dim_color

	var top_height := lerpf(0.0, focus_position.y, reveal_progress)
	var bottom_height := (size.y - (focus_position.y + clamped_focus_size.y)) * reveal_progress
	var side_y := top_height
	var side_height := maxf(0.0, size.y - top_height - bottom_height)
	var left_width := lerpf(0.0, focus_position.x, reveal_progress)
	var right_width := (size.x - (focus_position.x + clamped_focus_size.x)) * reveal_progress

	top_rect.position = Vector2.ZERO
	top_rect.size = Vector2(size.x, top_height)

	left_rect.position = Vector2(0, side_y)
	left_rect.size = Vector2(left_width, side_height)

	right_rect.position = Vector2(size.x - right_width, side_y)
	right_rect.size = Vector2(right_width, side_height)

	bottom_rect.position = Vector2(0, size.y - bottom_height)
	bottom_rect.size = Vector2(size.x, bottom_height)

	focus_rect.modulate.a = reveal_progress

func _set_reveal_progress(value: float) -> void:
	reveal_progress = clampf(value, 0.0, 1.0)
	_update_layout()

func play_reveal_animation() -> void:
	if reveal_duration <= 0.0:
		_set_reveal_progress(1.0)
		return

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(_set_reveal_progress, 0.0, 1.0, reveal_duration)

func reset_overlay() -> void:
	_set_reveal_progress(0.0)

func set_focus_rect(rect: Rect2, padding: Vector2 = Vector2(32, 32)) -> void:
	var padded_rect := rect.grow_individual(padding.x, padding.y, padding.x, padding.y)
	focus_size = padded_rect.size
	focus_center = padded_rect.get_center()
	visible = true
	reset_overlay()
	play_reveal_animation()

func clear_focus() -> void:
	visible = false
