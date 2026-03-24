extends PanelContainer

@onready var glitch_texture = $CutsceneGlitchTexture
@onready var key_texture = $CutsceneKeyTexture
@onready var black_fade = $CutsceneRect

func set_black_screen(enabled: bool) -> void:
	visible = enabled
	modulate = Color(1, 1, 1, 1.0 if enabled else 0.0)
	_set_black_fade_alpha(1.0 if enabled else 0.0)

func play_intro_glitch_transition(duration: float = 1.0) -> void:
	if not is_inside_tree():
		await get_tree().create_timer(duration).timeout
		return

	visible = true
	modulate = Color.WHITE
	_set_black_fade_alpha(1.0)
	if glitch_texture != null:
		glitch_texture.visible = true
		glitch_texture.modulate.a = 1.0
		_set_glitch_intensity(1.0)
	if key_texture != null:
		key_texture.visible = false

	var fade_tween := create_tween()
	var overlay_fade_duration := maxf(0.1, duration * 0.7)
	var texture_fade_duration := maxf(0.08, duration * 0.35)
	fade_tween.tween_method(_set_black_fade_alpha, 1.0, 0.0, overlay_fade_duration)
	if glitch_texture != null:
		fade_tween.parallel().tween_method(_apply_intro_glitch_progress, 0.0, 1.0, duration)
		fade_tween.parallel().tween_property(glitch_texture, "modulate:a", 0.0, texture_fade_duration).set_delay(maxf(0.0, duration - texture_fade_duration))
	await fade_tween.finished
	visible = false
	modulate = Color.WHITE
	_set_black_fade_alpha(1.0)
	if glitch_texture != null:
		_set_glitch_intensity(0.0)
		glitch_texture.visible = false
		glitch_texture.modulate.a = 1.0
		glitch_texture.texture = null

func play_reverse_glitch_transition(duration: float = 1.0, hold_duration: float = 1.0) -> void:
	if not is_inside_tree():
		await get_tree().create_timer(duration + hold_duration).timeout
		return

	var captured_texture := await _capture_viewport_texture()
	visible = true
	modulate = Color.WHITE
	_set_black_fade_alpha(0.0)
	if glitch_texture != null:
		glitch_texture.texture = captured_texture
		glitch_texture.visible = true
		glitch_texture.modulate.a = 1.0
		_set_glitch_intensity(0.0)
	if key_texture != null:
		key_texture.visible = false

	if glitch_texture != null and hold_duration > 0.0:
		var hold_tween := create_tween()
		hold_tween.tween_method(_apply_reverse_glitch_progress, 0.0, 0.45, hold_duration)
		await hold_tween.finished

	var fade_tween := create_tween()
	var overlay_fade_duration := maxf(0.1, duration * 0.8)
	var texture_fade_duration := maxf(0.08, duration * 0.3)
	fade_tween.tween_method(_set_black_fade_alpha, 0.0, 1.0, overlay_fade_duration)
	if glitch_texture != null:
		fade_tween.parallel().tween_method(_apply_reverse_glitch_progress, 0.45, 1.0, duration)
		fade_tween.parallel().tween_property(glitch_texture, "modulate:a", 0.0, texture_fade_duration).set_delay(maxf(0.0, duration - texture_fade_duration))
	await fade_tween.finished
	visible = true
	modulate = Color.WHITE
	_set_black_fade_alpha(1.0)
	if glitch_texture != null:
		_set_glitch_intensity(0.0)
		glitch_texture.visible = false
		glitch_texture.modulate.a = 1.0
		glitch_texture.texture = null

func play_still_reveal(duration: float = 1.5) -> void:
	if not is_inside_tree():
		await get_tree().create_timer(duration).timeout
		return

	visible = true
	modulate = Color.WHITE
	_set_black_fade_alpha(1.0)
	if glitch_texture != null:
		glitch_texture.visible = false
		glitch_texture.texture = null
	if key_texture != null:
		key_texture.visible = true
		move_child(key_texture, get_child_count() - 1)
		key_texture.modulate.a = 0.0
		key_texture.scale = Vector2(1.12, 1.12)
		key_texture.position = Vector2(-60, -36)

	var reveal_tween := create_tween()
	reveal_tween.tween_method(_set_black_fade_alpha, 1.0, 0.0, maxf(0.1, duration))
	if key_texture != null:
		reveal_tween.parallel().tween_property(key_texture, "modulate:a", 1.0, maxf(0.1, duration * 0.85))
		reveal_tween.parallel().tween_property(key_texture, "scale", Vector2.ONE, maxf(0.1, duration))
		reveal_tween.parallel().tween_property(key_texture, "position", Vector2.ZERO, maxf(0.1, duration))
	await reveal_tween.finished
	visible = true
	modulate = Color.WHITE
	_set_black_fade_alpha(0.0)

func _capture_viewport_texture() -> Texture2D:
	var viewport := get_viewport()
	if viewport == null:
		return null

	var overlay_was_visible := visible
	var overlay_alpha := modulate.a
	var rect_alpha := _get_black_fade_alpha()
	visible = false

	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var viewport_texture := viewport.get_texture()
	if viewport_texture == null:
		visible = overlay_was_visible
		modulate = Color(1, 1, 1, overlay_alpha)
		_set_black_fade_alpha(rect_alpha)
		return null
	var image := viewport_texture.get_image()
	visible = overlay_was_visible
	modulate = Color(1, 1, 1, overlay_alpha)
	_set_black_fade_alpha(rect_alpha)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _set_black_fade_alpha(alpha: float) -> void:
	if black_fade == null:
		return
	black_fade.visible = alpha > 0.001
	var color = black_fade.color
	color.a = clampf(alpha, 0.0, 1.0)
	black_fade.color = color

func _get_black_fade_alpha() -> float:
	if black_fade == null:
		return 0.0
	return black_fade.color.a

func _set_glitch_intensity(intensity: float) -> void:
	if glitch_texture == null:
		return
	var texture_material := glitch_texture.material as ShaderMaterial
	if texture_material == null:
		return
	texture_material.set_shader_parameter("intensity", clampf(intensity, 0.0, 1.0))

func _apply_intro_glitch_progress(progress: float) -> void:
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var base_intensity := 1.0 - clamped_progress
	var pulse_a := 0.42 * exp(-pow((clamped_progress - 0.18) / 0.09, 2.0))
	var pulse_b := 0.28 * exp(-pow((clamped_progress - 0.46) / 0.1, 2.0))
	var pulse_c := 0.18 * exp(-pow((clamped_progress - 0.72) / 0.08, 2.0))
	_set_glitch_intensity(minf(1.0, base_intensity + pulse_a + pulse_b + pulse_c))

func _apply_reverse_glitch_progress(progress: float) -> void:
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var pulse_a := 0.12 * exp(-pow((clamped_progress - 0.28) / 0.08, 2.0))
	var pulse_b := 0.24 * exp(-pow((clamped_progress - 0.58) / 0.1, 2.0))
	var pulse_c := 0.35 * exp(-pow((clamped_progress - 0.84) / 0.07, 2.0))
	_set_glitch_intensity(minf(1.0, clamped_progress + pulse_a + pulse_b + pulse_c))
