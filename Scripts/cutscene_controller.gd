extends PanelContainer

@onready var glitch_texture = $CutsceneGlitchTexture
@onready var key_texture = $CutsceneKeyTexture
@onready var black_fade = $CutsceneRect
@onready var strobe_rect = $StrobeRect
@onready var flash_rect = $FlashRect

var _alarm_tween: Tween
var _alarm_active := false
var _base_glitch_texture: Texture2D
var _damage_pulse_tween: Tween

func _ready() -> void:
	if glitch_texture != null:
		_base_glitch_texture = glitch_texture.texture
	GlobalEvents.runners_damaged.connect(_on_runners_damaged)

func set_black_screen(enabled: bool) -> void:
	visible = enabled
	modulate = Color(1, 1, 1, 1.0 if enabled else 0.0)
	_set_black_fade_alpha(1.0 if enabled else 0.0)

func start_alarm_effects() -> void:
	if not is_inside_tree():
		return

	_stop_alarm_tween()
	_alarm_active = true
	visible = true
	modulate = Color.WHITE

	if key_texture != null:
		key_texture.visible = true
		key_texture.modulate = Color(1.0, 0.92, 0.92, 1.0)

	if black_fade != null:
		black_fade.visible = true
		black_fade.color = Color(0.0, 0.0, 0.0, 0.28)

	if strobe_rect != null:
		strobe_rect.visible = true
		strobe_rect.color = Color(0.95, 0.06, 0.06, 0.0)

	if flash_rect != null:
		flash_rect.visible = true
		flash_rect.color = Color(1.0, 0.96, 0.96, 0.0)

	_alarm_tween = create_tween()
	_alarm_tween.set_loops()
	_alarm_tween.set_parallel(true)
	_alarm_tween.tween_method(_set_alarm_strobe_alpha, 0.0, 0.95, 0.54).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_alarm_tween.tween_method(_set_alarm_flash_alpha, 0.0, 0.3, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_alarm_tween.tween_method(_set_alarm_key_tint, 0.0, 0.34, 0.44).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_alarm_tween.chain().set_parallel(true)
	_alarm_tween.tween_method(_set_alarm_strobe_alpha, 0.72, 0.38, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_alarm_tween.tween_method(_set_alarm_flash_alpha, 0.22, 0.03, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_alarm_tween.tween_method(_set_alarm_key_tint, 0.34, 0.14, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_alarm_tween.chain().set_parallel(true)
	_alarm_tween.tween_method(_set_alarm_strobe_alpha, 0.38, 0.1, 0.64).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_alarm_tween.tween_method(_set_alarm_flash_alpha, 0.03, 0.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_alarm_tween.tween_method(_set_alarm_key_tint, 0.14, 0.06, 0.44).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func stop_alarm_effects(fade_duration: float = 0.35) -> void:
	_alarm_active = false
	_stop_alarm_tween()

	if not is_inside_tree():
		_reset_alarm_visuals()
		return

	var fade_tween := create_tween()
	if key_texture != null:
		fade_tween.parallel().tween_property(key_texture, "modulate:a", 0.0, fade_duration)
	if strobe_rect != null:
		fade_tween.parallel().tween_method(_set_alarm_strobe_alpha, strobe_rect.color.a, 0.0, fade_duration)
	if flash_rect != null:
		fade_tween.parallel().tween_method(_set_alarm_flash_alpha, flash_rect.color.a, 0.0, fade_duration)
	fade_tween.parallel().tween_method(_set_alarm_key_tint, 0.18, 0.0, fade_duration)
	await fade_tween.finished
	_reset_alarm_visuals()

func play_intro_glitch_transition(duration: float = 1.0) -> void:
	if not is_inside_tree():
		await get_tree().create_timer(duration).timeout
		return

	_stop_alarm_tween()
	_alarm_active = false
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

	_stop_alarm_tween()
	_alarm_active = false
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

	_stop_alarm_tween()
	_alarm_active = false
	visible = true
	modulate = Color.WHITE
	_set_black_fade_alpha(1.0)
	if glitch_texture != null:
		glitch_texture.visible = false
		glitch_texture.texture = null
	if key_texture != null:
		key_texture.visible = true
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

func play_cutscene_return_transition(duration: float = 1.2, blackout_duration: float = 0.18) -> void:
	if not is_inside_tree():
		await get_tree().create_timer(duration + blackout_duration).timeout
		return

	_stop_alarm_tween()
	await _reset_alarm_visuals()

	_alarm_active = false
	visible = true
	modulate = Color.WHITE
	var fade_to_black_duration := maxf(0.2, duration * 0.5)
	var reveal_duration := maxf(0.35, duration * 0.85)

	if key_texture != null:
		key_texture.visible = true
		key_texture.modulate = Color.WHITE
	if glitch_texture != null:
		if key_texture != null and key_texture.texture != null:
			glitch_texture.texture = key_texture.texture
		else:
			glitch_texture.texture = _base_glitch_texture
		glitch_texture.visible = true
		key_texture.visible = false
		glitch_texture.modulate = Color(1.0, 0.92, 0.92, 0.78)
		_apply_key_collapse_glitch_progress(0.0)
	_set_black_fade_alpha(0.0)

	var collapse_tween := create_tween()
	collapse_tween.set_parallel(true)
	collapse_tween.tween_method(_set_black_fade_alpha, 0.0, 1.0, fade_to_black_duration)
	if key_texture != null:
		collapse_tween.tween_property(key_texture, "modulate", Color(0.92, 0.7, 0.7, 1.0), fade_to_black_duration)
	if glitch_texture != null:
		collapse_tween.tween_method(_apply_key_collapse_glitch_progress, 0.0, 1.0, fade_to_black_duration)
	await collapse_tween.finished

	if blackout_duration > 0.0:
		await get_tree().create_timer(blackout_duration).timeout

	var captured_texture := await _capture_viewport_texture()
	if key_texture != null:
		key_texture.visible = false
	if glitch_texture != null:
		if captured_texture != null:
			glitch_texture.texture = captured_texture
		elif _base_glitch_texture != null:
			glitch_texture.texture = _base_glitch_texture
		glitch_texture.visible = true
		glitch_texture.modulate = Color.WHITE
		glitch_texture.modulate.a = 1.0
		_set_glitch_intensity(1.0)
	_set_black_fade_alpha(1.0)

	var reveal_tween := create_tween()
	var overlay_fade_duration := maxf(0.12, reveal_duration * 0.72)
	var texture_fade_duration := maxf(0.1, reveal_duration * 0.42)
	reveal_tween.tween_method(_set_black_fade_alpha, 1.0, 0.0, overlay_fade_duration)
	if glitch_texture != null:
		reveal_tween.parallel().tween_method(_apply_intro_glitch_progress, 0.0, 1.0, reveal_duration)
		reveal_tween.parallel().tween_property(glitch_texture, "modulate:a", 0.0, texture_fade_duration).set_delay(maxf(0.0, reveal_duration - texture_fade_duration))
	await reveal_tween.finished

	modulate = Color.WHITE
	visible = false

func play_null_spike_init_transition() -> void:
	if not is_inside_tree():
		return

	_stop_alarm_tween()
	_alarm_active = false
	var captured_texture := await _capture_viewport_texture()
	visible = true
	modulate = Color.WHITE
	_set_black_fade_alpha(1.0)
	if key_texture != null:
		key_texture.visible = false
	if glitch_texture != null:
		if captured_texture != null:
			glitch_texture.texture = captured_texture
		else:
			glitch_texture.texture = _base_glitch_texture
		glitch_texture.visible = true
		glitch_texture.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_set_glitch_speed(2.0)
		_set_glitch_intensity(0.12)

	var phase_1 := create_tween()
	phase_1.set_parallel(true)
	phase_1.tween_method(_set_black_fade_alpha, 1.0, 0.0, 0.7)
	phase_1.tween_method(_set_glitch_intensity, 0.12, 0.48, 1.65)
	phase_1.tween_method(_set_glitch_speed, 2.0, 4.5, 1.65)
	await phase_1.finished

	await _play_blackout_pulse(0.11, 0.16)

	var phase_2 := create_tween()
	phase_2.set_parallel(true)
	phase_2.tween_method(_set_glitch_intensity, 0.48, 0.72, 2.1)
	phase_2.tween_method(_set_glitch_speed, 4.5, 7.5, 2.1)
	phase_2.tween_property(glitch_texture, "modulate", Color(1.0, 0.92, 1.04, 1.0), 2.1)
	await phase_2.finished

	await _play_blackout_pulse(0.09, 0.12)

	var phase_3 := create_tween()
	phase_3.set_parallel(true)
	phase_3.tween_method(_set_glitch_intensity, 0.72, 1.0, 0.52)
	phase_3.tween_method(_set_glitch_speed, 7.5, 13.5, 0.52)
	phase_3.tween_property(glitch_texture, "modulate", Color(1.0, 0.86, 1.08, 1.0), 0.52)
	await phase_3.finished
	await get_tree().create_timer(0.34).timeout

	_set_black_fade_alpha(1.0)
	await get_tree().create_timer(0.72).timeout
	_set_glitch_intensity(0.58)
	_set_glitch_speed(6.0)
	if glitch_texture != null:
		glitch_texture.modulate = Color(1.0, 0.94, 1.02, 1.0)

	var phase_4 := create_tween()
	phase_4.set_parallel(true)
	phase_4.tween_method(_set_black_fade_alpha, 1.0, 0.0, 0.55)
	phase_4.tween_method(_set_glitch_intensity, 0.58, 0.0, 2.1)
	phase_4.tween_method(_set_glitch_speed, 6.0, 2.0, 2.1)
	phase_4.tween_property(glitch_texture, "modulate", Color(1.0, 1.0, 1.0, 0.0), 2.1)
	await phase_4.finished

	_reset_alarm_visuals()
	visible = false

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

func _set_glitch_speed(speed: float) -> void:
	if glitch_texture == null:
		return
	var texture_material := glitch_texture.material as ShaderMaterial
	if texture_material == null:
		return
	texture_material.set_shader_parameter("speed", maxf(0.0, speed))

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

func _apply_cutscene_return_progress(progress: float) -> void:
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var base_intensity := lerpf(0.55, 0.0, clamped_progress)
	var pulse_a := 0.28 * exp(-pow((clamped_progress - 0.16) / 0.08, 2.0))
	var pulse_b := 0.22 * exp(-pow((clamped_progress - 0.42) / 0.1, 2.0))
	var pulse_c := 0.16 * exp(-pow((clamped_progress - 0.71) / 0.09, 2.0))
	_set_glitch_intensity(minf(1.0, base_intensity + pulse_a + pulse_b + pulse_c))
	if glitch_texture != null:
		var red_mix := 0.55 * (1.0 - clamped_progress)
		var green_blue := 1.0 - 0.38 * red_mix
		glitch_texture.modulate = Color(1.0, green_blue, green_blue, 1.0 - clamped_progress)

func _apply_key_collapse_glitch_progress(progress: float) -> void:
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var base_intensity := lerpf(0.34, 0.62, clamped_progress)
	var pulse_a := 0.18 * exp(-pow((clamped_progress - 0.22) / 0.1, 2.0))
	var pulse_b := 0.14 * exp(-pow((clamped_progress - 0.58) / 0.12, 2.0))
	var intensity := minf(1.0, base_intensity + pulse_a + pulse_b)
	_set_glitch_intensity(intensity)
	if glitch_texture != null:
		var red_mix := lerpf(0.1, 0.42, clamped_progress)
		var green_blue := 1.0 - 0.34 * red_mix
		glitch_texture.modulate = Color(1.0, green_blue, green_blue, lerpf(0.78, 0.92, clamped_progress))

func _set_alarm_strobe_alpha(alpha: float) -> void:
	if strobe_rect == null:
		return
	strobe_rect.visible = alpha > 0.001
	strobe_rect.color = Color(0.95, 0.06, 0.06, clampf(alpha, 0.0, 1.0))

func _set_alarm_flash_alpha(alpha: float) -> void:
	if flash_rect == null:
		return
	flash_rect.visible = alpha > 0.001
	flash_rect.color = Color(1.0, 0.96, 0.96, clampf(alpha, 0.0, 1.0))

func _on_runners_damaged(_amount: float) -> void:
	if flash_rect == null or not is_inside_tree():
		return
	if _damage_pulse_tween != null and _damage_pulse_tween.is_valid():
		_damage_pulse_tween.kill()

	var was_visible := visible
	visible = true
	flash_rect.visible = true
	flash_rect.color = Color(1.0, 0.08, 0.08, 0.0)

	_damage_pulse_tween = create_tween()
	_damage_pulse_tween.tween_method(_set_damage_flash_alpha, 0.0, 0.5, 0.06)
	_damage_pulse_tween.tween_method(_set_damage_flash_alpha, 0.5, 0.0, 0.16)
	await _damage_pulse_tween.finished
	_damage_pulse_tween = null

	if not was_visible and not _alarm_active:
		visible = false

func _set_damage_flash_alpha(alpha: float) -> void:
	if flash_rect == null:
		return
	flash_rect.visible = alpha > 0.001
	flash_rect.color = Color(1.0, 0.08, 0.08, clampf(alpha, 0.0, 1.0))

func _set_alarm_key_tint(intensity: float) -> void:
	if key_texture == null:
		return
	var clamped := clampf(intensity, 0.0, 1.0)
	key_texture.visible = true
	key_texture.modulate = Color(
		1.0,
		1.0 - 0.26 * clamped,
		1.0 - 0.26 * clamped,
		1
	)

func _stop_alarm_tween() -> void:
	if _alarm_tween != null and _alarm_tween.is_valid():
		_alarm_tween.kill()
	_alarm_tween = null

func _play_blackout_pulse(fade_duration: float, hold_duration: float = 0.0) -> void:
	var blackout_tween := create_tween()
	blackout_tween.tween_method(_set_black_fade_alpha, _get_black_fade_alpha(), 1.0, maxf(0.01, fade_duration))
	await blackout_tween.finished
	if hold_duration > 0.0:
		await get_tree().create_timer(hold_duration).timeout
	var reveal_tween := create_tween()
	reveal_tween.tween_method(_set_black_fade_alpha, 1.0, 0.0, maxf(0.01, fade_duration))
	await reveal_tween.finished

func _reset_alarm_visuals() -> void:
	_stop_alarm_tween()
	_set_glitch_intensity(0.0)
	if glitch_texture != null:
		glitch_texture.visible = false
		glitch_texture.modulate = Color(1, 1, 1, 1)
		glitch_texture.texture = _base_glitch_texture
	if key_texture != null:
		key_texture.visible = false
		key_texture.modulate = Color(1, 1, 1, 1)
	if black_fade != null:
		black_fade.visible = false
		black_fade.color = Color(0, 0, 0, 1)
	if strobe_rect != null:
		strobe_rect.visible = false
		strobe_rect.color = Color(0.95, 0.06, 0.06, 0.0)
	if flash_rect != null:
		flash_rect.visible = false
		flash_rect.color = Color(1.0, 0.96, 0.96, 0.0)
	if not _alarm_active:
		visible = false
