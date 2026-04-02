extends Control

const NULL_SPIKE_SYNC_SHADER = preload("res://Shaders/null_spike_sync.gdshader")

@onready var glitch_texture = $CutsceneGlitchTexture
@onready var key_texture = $CutsceneKeyTexture
@onready var black_fade = $CutsceneRect
@onready var strobe_rect = $StrobeRect
@onready var flash_rect = $FlashRect
@onready var null_spike_sync_wash = $NullSpikeSyncWash
@onready var null_spike_sync_overlay = $"../SignalTimeline/NullSpikeSyncOverlay"

var _alarm_tween: Tween
var _alarm_active := false
var _base_glitch_texture: Texture2D
var _damage_pulse_tween: Tween
var _null_spike_sync_tween: Tween
var _null_spike_active_tween: Tween
var _null_spike_active_visual_enabled := false

signal null_spike_sync_finished

func _ready() -> void:
	if glitch_texture != null:
		_base_glitch_texture = glitch_texture.texture
	GlobalEvents.runners_damaged.connect(_on_runners_damaged)
	GlobalEvents.activate_null_spike.connect(_on_activate_null_spike)
	GlobalEvents.deactivate_null_spike.connect(_on_deactivate_null_spike)
	_setup_null_spike_sync_layers()

func set_black_screen(enabled: bool) -> void:
	visible = enabled
	modulate = Color.WHITE
	_set_black_fade_alpha(1.0 if enabled else 0.0)

func start_alarm_effects() -> void:
	if not is_inside_tree():
		return

	_stop_alarm_tween()
	_alarm_active = true
	_begin_cutscene_visuals(0.28)
	_show_key_layer(1.0, Color(1.0, 0.92, 0.92, 1.0))
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
		_reset_cutscene_visuals()
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
	_reset_cutscene_visuals()

func play_intro_glitch_transition(duration: float = 1.0) -> void:
	if not is_inside_tree():
		await get_tree().create_timer(duration).timeout
		return

	_stop_alarm_tween()
	_alarm_active = false
	_begin_cutscene_visuals(1.0)
	_hide_key_layer()
	_show_glitch_layer(_get_default_glitch_texture(), Color.WHITE, 1.0)
	_set_glitch_intensity(1.0)

	var fade_tween := create_tween()
	var overlay_fade_duration := maxf(0.1, duration * 0.7)
	var texture_fade_duration := maxf(0.08, duration * 0.35)
	fade_tween.tween_method(_set_black_fade_alpha, 1.0, 0.0, overlay_fade_duration)
	if glitch_texture != null:
			fade_tween.parallel().tween_method(_apply_intro_glitch_progress, 0.0, 1.0, duration)
			fade_tween.parallel().tween_property(glitch_texture, "modulate:a", 0.0, texture_fade_duration).set_delay(maxf(0.0, duration - texture_fade_duration))
	await fade_tween.finished
	_set_glitch_intensity(0.0)
	_set_black_fade_alpha(1.0)
	_hide_glitch_layer()
	_hide_if_idle()

func play_reverse_glitch_transition(duration: float = 1.0, hold_duration: float = 1.0) -> void:
	if not is_inside_tree():
		await get_tree().create_timer(duration + hold_duration).timeout
		return

	_stop_alarm_tween()
	_alarm_active = false
	var captured_texture := await _capture_viewport_texture()
	_begin_cutscene_visuals(0.0)
	_hide_key_layer()
	_show_glitch_layer(captured_texture, Color.WHITE, 1.0)
	_set_glitch_intensity(0.0)

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
	_set_black_fade_alpha(1.0)
	_set_glitch_intensity(0.0)
	_hide_glitch_layer()

func play_still_reveal(duration: float = 1.5) -> void:
	if not is_inside_tree():
		await get_tree().create_timer(duration).timeout
		return

	_stop_alarm_tween()
	_alarm_active = false
	_begin_cutscene_visuals(1.0)
	_hide_glitch_layer()
	_show_key_layer(0.0, Color.WHITE, Vector2(1.12, 1.12), Vector2(-60, -36))

	var reveal_tween := create_tween()
	reveal_tween.tween_method(_set_black_fade_alpha, 1.0, 0.0, maxf(0.1, duration))
	if key_texture != null:
		reveal_tween.parallel().tween_property(key_texture, "modulate:a", 1.0, maxf(0.1, duration * 0.85))
		reveal_tween.parallel().tween_property(key_texture, "scale", Vector2.ONE, maxf(0.1, duration))
		reveal_tween.parallel().tween_property(key_texture, "position", Vector2.ZERO, maxf(0.1, duration))
	await reveal_tween.finished
	_set_black_fade_alpha(0.0)

func play_cutscene_return_transition(duration: float = 1.2, blackout_duration: float = 0.18) -> void:
	if not is_inside_tree():
		await get_tree().create_timer(duration + blackout_duration).timeout
		return

	_stop_alarm_tween()
	_reset_cutscene_visuals(false)

	_alarm_active = false
	_begin_cutscene_visuals(0.0)
	var fade_to_black_duration := maxf(0.2, duration * 0.5)
	var reveal_duration := maxf(0.35, duration * 0.85)

	_show_key_layer(1.0, Color.WHITE)
	_show_glitch_layer(_get_key_glitch_source(), Color(1.0, 0.92, 0.92, 0.78), 0.78)
	_hide_key_layer()
	_apply_key_collapse_glitch_progress(0.0)

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
	_hide_key_layer()
	_show_glitch_layer(captured_texture, Color.WHITE, 1.0)
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

	_hide_glitch_layer()
	_hide_if_idle()

func play_null_spike_init_transition() -> void:
	if not is_inside_tree():
		return

	_stop_alarm_tween()
	_alarm_active = false
	var captured_texture := await _capture_viewport_texture()
	_begin_cutscene_visuals(1.0)
	_hide_key_layer()
	_show_glitch_layer(captured_texture, Color.WHITE, 1.0)
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

	_reset_cutscene_visuals()

func start_first_null_spike_sync(total_duration: float = 4.8) -> void:

	_begin_cutscene_visuals(0.0)
	_set_sync_overlay_visible(true)
	_set_sync_overlay_intensity(0.25)
	_set_sync_overlay_band_density(3.0)
	_set_sync_overlay_stretch(0.065)
	_set_sync_overlay_speed(0.8)
	_set_sync_overlay_glow(0.4)
	_set_sync_wash_alpha(0.01)
	for child in get_children():
		print(child, " ", child.visible)
	var total := maxf(5.0, total_duration)
	var phase_1 := 1.05
	var pulse_1 := 0.4
	var phase_2 := 1.2
	var pulse_2 := 0.45
	var phase_3 := 0.75
	var pulse_3 := 0.35
	var phase_4 := maxf(0.8, total - (phase_1 + pulse_1 + phase_2 + pulse_2 + phase_3 + pulse_3))

	_null_spike_sync_tween = create_tween()
	_null_spike_sync_tween.finished.connect(_finish_first_null_spike_sync)
	
	_null_spike_sync_tween.set_parallel(true)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_intensity, 0.25, 0.29, phase_1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_speed, 1.8, 4.0, phase_1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_stretch, 0.065, 0.11, phase_1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_glow, 0.4, 0.62, phase_1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_band_density, 56.0, 92.0, phase_1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	_null_spike_sync_tween.chain()
	_null_spike_sync_tween.tween_method(_set_sync_overlay_intensity, 0.29, 0.32, pulse_1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_speed, 4.0, 5.6, pulse_1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_stretch, 0.11, 0.145, pulse_1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_glow, 0.62, 0.82, pulse_1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_band_density, 92.0, 118.0, pulse_1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_null_spike_sync_tween.chain()
	_null_spike_sync_tween.tween_method(_set_sync_overlay_intensity, 0.32, 0.36, phase_2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_speed, 5.6, 7.8, phase_2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_stretch, 0.145, 0.185, phase_2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_glow, 0.82, 1.02, phase_2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_band_density, 118.0, 156.0, phase_2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_null_spike_sync_tween.chain()
	_null_spike_sync_tween.tween_method(_set_sync_overlay_intensity, 0.36, 0.4, pulse_2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_speed, 7.8, 10.5, pulse_2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_stretch, 0.185, 0.23, pulse_2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_glow, 1.02, 1.25, pulse_2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_band_density, 156.0, 196.0, pulse_2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_null_spike_sync_tween.chain()
	_null_spike_sync_tween.tween_method(_set_sync_overlay_intensity, 0.4, 0.39, phase_3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_speed, 10.5, 14.0, phase_3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_stretch, 0.23, 0.25, phase_3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_glow, 1.25, 1.45, phase_3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_band_density, 196.0, 228.0, phase_3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_null_spike_sync_tween.chain()
	_null_spike_sync_tween.tween_method(_set_sync_overlay_intensity, 0.39, 0.33, pulse_3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_speed, 14.0, 8.0, pulse_3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_stretch, 0.25, 0.12, pulse_3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_glow, 1.45, 0.7, pulse_3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_band_density, 228.0, 144.0, pulse_3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_null_spike_sync_tween.chain()
	_null_spike_sync_tween.tween_method(_set_sync_overlay_intensity, 0.33, 0.0, phase_4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_speed, 8.0, 1.2, phase_4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_stretch, 0.12, 0.0, phase_4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_glow, 0.7, 0.0, phase_4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_null_spike_sync_tween.tween_method(_set_sync_overlay_band_density, 144.0, 52.0, phase_4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func stop_first_null_spike_sync() -> void:
	_stop_null_spike_sync_tween()
	_finish_first_null_spike_sync()

func start_null_spike_active_effect(duration: float = 0.5) -> void:
	_stop_null_spike_active_tween()
	_null_spike_active_visual_enabled = true
	_begin_cutscene_visuals(0.0)
	_set_black_fade_alpha(0.0)
	_set_sync_overlay_visible(true)
	_set_sync_wash_alpha(0.0)

	var tween_duration := maxf(0.05, duration)
	var active_tween := create_tween()
	_null_spike_active_tween = active_tween
	active_tween.set_parallel(true)
	active_tween.set_ignore_time_scale(true)
	active_tween.tween_method(_set_sync_overlay_intensity, _get_sync_overlay_intensity(), 0.1, tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_method(_set_sync_overlay_band_density, _get_sync_overlay_band_density(), 80.0, tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_method(_set_sync_overlay_stretch, _get_sync_overlay_stretch(), 0.50, tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_method(_set_sync_overlay_speed, _get_sync_overlay_speed(), 20.0, tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_method(_set_sync_overlay_glow, _get_sync_overlay_glow(), 0.03, tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.finished.connect(_on_null_spike_active_tween_finished.bind(active_tween))

func stop_null_spike_active_effect(duration: float = 0.5) -> void:
	if _null_spike_sync_tween != null and _null_spike_sync_tween.is_valid():
		return

	_stop_null_spike_active_tween()
	_null_spike_active_visual_enabled = false

	var tween_duration := maxf(0.05, duration)
	var active_tween := create_tween()
	_null_spike_active_tween = active_tween
	active_tween.set_parallel(true)
	active_tween.tween_method(_set_sync_overlay_intensity, _get_sync_overlay_intensity(), 0.0, tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_method(_set_sync_overlay_band_density, _get_sync_overlay_band_density(), 80.0, tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_method(_set_sync_overlay_stretch, _get_sync_overlay_stretch(), 0.0, tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_method(_set_sync_overlay_speed, _get_sync_overlay_speed(), 1.0, tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_method(_set_sync_overlay_glow, _get_sync_overlay_glow(), 0.0, tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.finished.connect(_on_null_spike_active_tween_finished.bind(active_tween))

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

func _setup_null_spike_sync_layers() -> void:
	if null_spike_sync_wash != null:
		null_spike_sync_wash.visible = false
		null_spike_sync_wash.color = Color(0.62, 1.0, 1.0, 0.0)
	if null_spike_sync_overlay != null:
		null_spike_sync_overlay.color = Color.WHITE
		null_spike_sync_overlay.z_index = 100
		var sync_material := null_spike_sync_overlay.material as ShaderMaterial
		if sync_material == null:
			sync_material = ShaderMaterial.new()
			sync_material.shader = NULL_SPIKE_SYNC_SHADER
			null_spike_sync_overlay.material = sync_material
		null_spike_sync_overlay.visible = false
		_reset_sync_overlay_visuals()

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

func _set_sync_overlay_visible(is_visible: bool) -> void:
	if null_spike_sync_overlay == null:
		return
	null_spike_sync_overlay.visible = is_visible

func _set_sync_overlay_intensity(intensity: float) -> void:
	var sync_material := _get_sync_overlay_material()
	if sync_material == null:
		return
	sync_material.set_shader_parameter("intensity", clampf(intensity, 0.0, 1.0))

func _get_sync_overlay_intensity() -> float:
	var sync_material := _get_sync_overlay_material()
	if sync_material == null:
		return 0.0
	return float(sync_material.get_shader_parameter("intensity"))

func _set_sync_overlay_band_density(value: float) -> void:
	var sync_material := _get_sync_overlay_material()
	if sync_material == null:
		return
	sync_material.set_shader_parameter("band_density", maxf(1.0, value))

func _get_sync_overlay_band_density() -> float:
	var sync_material := _get_sync_overlay_material()
	if sync_material == null:
		return 80.0
	return float(sync_material.get_shader_parameter("band_density"))

func _set_sync_overlay_stretch(value: float) -> void:
	var sync_material := _get_sync_overlay_material()
	if sync_material == null:
		return
	sync_material.set_shader_parameter("stretch_amount", maxf(0.0, value))

func _get_sync_overlay_stretch() -> float:
	var sync_material := _get_sync_overlay_material()
	if sync_material == null:
		return 0.0
	return float(sync_material.get_shader_parameter("stretch_amount"))

func _set_sync_overlay_speed(value: float) -> void:
	var sync_material := _get_sync_overlay_material()
	if sync_material == null:
		return
	sync_material.set_shader_parameter("jitter_speed", maxf(0.0, value))

func _get_sync_overlay_speed() -> float:
	var sync_material := _get_sync_overlay_material()
	if sync_material == null:
		return 1.0
	return float(sync_material.get_shader_parameter("jitter_speed"))

func _set_sync_overlay_glow(value: float) -> void:
	var sync_material := _get_sync_overlay_material()
	if sync_material == null:
		return
	sync_material.set_shader_parameter("glow_strength", maxf(0.0, value))

func _get_sync_overlay_glow() -> float:
	var sync_material := _get_sync_overlay_material()
	if sync_material == null:
		return 0.0
	return float(sync_material.get_shader_parameter("glow_strength"))

func _set_sync_wash_alpha(alpha: float) -> void:
	if null_spike_sync_wash == null:
		return
	null_spike_sync_wash.visible = alpha > 0.001
	var color = null_spike_sync_wash.color
	color.a = clampf(alpha, 0.0, 1.0)
	null_spike_sync_wash.color = color

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

func _stop_null_spike_sync_tween() -> void:
	if _null_spike_sync_tween != null and _null_spike_sync_tween.is_valid():
		_null_spike_sync_tween.kill()
	_null_spike_sync_tween = null

func _stop_null_spike_active_tween() -> void:
	if _null_spike_active_tween != null and _null_spike_active_tween.is_valid():
		_null_spike_active_tween.kill()
	_null_spike_active_tween = null

func _finish_first_null_spike_sync() -> void:
	_stop_null_spike_sync_tween()
	_set_sync_overlay_visible(false)
	_reset_sync_overlay_visuals()
	if null_spike_sync_wash != null:
		null_spike_sync_wash.visible = false
	_set_black_fade_alpha(0.0)
	_hide_if_idle()
	null_spike_sync_finished.emit()

func _on_activate_null_spike() -> void:
	start_null_spike_active_effect()

func _on_deactivate_null_spike() -> void:
	stop_null_spike_active_effect()

func _on_null_spike_active_tween_finished(finished_tween: Tween) -> void:
	if _null_spike_active_tween != finished_tween:
		return
	_null_spike_active_tween = null
	if _null_spike_active_visual_enabled:
		_set_sync_overlay_visible(true)
		return
	_set_sync_overlay_visible(false)
	_hide_if_idle()

func _get_sync_overlay_material() -> ShaderMaterial:
	if null_spike_sync_overlay == null:
		return null
	return null_spike_sync_overlay.material as ShaderMaterial

func _play_blackout_pulse(fade_duration: float, hold_duration: float = 0.0) -> void:
	var blackout_tween := create_tween()
	blackout_tween.tween_method(_set_black_fade_alpha, _get_black_fade_alpha(), 1.0, maxf(0.01, fade_duration))
	await blackout_tween.finished
	if hold_duration > 0.0:
		await get_tree().create_timer(hold_duration).timeout
	var reveal_tween := create_tween()
	reveal_tween.tween_method(_set_black_fade_alpha, 1.0, 0.0, maxf(0.01, fade_duration))
	await reveal_tween.finished

func _begin_cutscene_visuals(black_alpha: float) -> void:
	visible = true
	modulate = Color.WHITE
	_set_black_fade_alpha(black_alpha)

func _show_key_layer(alpha: float = 1.0, tint: Color = Color.WHITE, scale: Vector2 = Vector2.ONE, local_position: Vector2 = Vector2.ZERO) -> void:
	if key_texture == null:
		return
	key_texture.visible = true
	key_texture.modulate = tint
	key_texture.modulate.a = alpha
	key_texture.scale = scale
	key_texture.position = local_position

func _hide_key_layer() -> void:
	if key_texture == null:
		return
	key_texture.visible = false
	key_texture.modulate = Color.WHITE
	key_texture.scale = Vector2.ONE
	key_texture.position = Vector2.ZERO

func _show_glitch_layer(texture: Texture2D, tint: Color = Color.WHITE, alpha: float = 1.0) -> void:
	if glitch_texture == null:
		return
	glitch_texture.texture = texture if texture != null else _get_default_glitch_texture()
	glitch_texture.visible = true
	glitch_texture.modulate = tint
	glitch_texture.modulate.a = alpha

func _hide_glitch_layer(reset_texture: bool = true) -> void:
	if glitch_texture == null:
		return
	glitch_texture.visible = false
	glitch_texture.modulate = Color.WHITE
	glitch_texture.modulate.a = 1.0
	if reset_texture:
		glitch_texture.texture = null

func _get_default_glitch_texture() -> Texture2D:
	return _base_glitch_texture

func _get_key_glitch_source() -> Texture2D:
	if key_texture != null and key_texture.texture != null:
		return key_texture.texture
	return _get_default_glitch_texture()

func _reset_sync_overlay_visuals() -> void:
	_set_sync_overlay_intensity(0.0)
	_set_sync_overlay_band_density(80.0)
	_set_sync_overlay_stretch(0.0)
	_set_sync_overlay_speed(1.0)
	_set_sync_overlay_glow(0.0)
	_set_sync_wash_alpha(0.0)

func _hide_if_idle() -> void:
	if _alarm_active or _null_spike_active_visual_enabled:
		return
	visible = false

func _reset_cutscene_visuals(hide_controller: bool = true) -> void:
	_stop_alarm_tween()
	_stop_null_spike_sync_tween()
	_stop_null_spike_active_tween()
	_null_spike_active_visual_enabled = false
	_set_glitch_intensity(0.0)
	_hide_glitch_layer()
	_hide_key_layer()
	if black_fade != null:
		black_fade.visible = false
		black_fade.color = Color(0, 0, 0, 1)
	if strobe_rect != null:
		strobe_rect.visible = false
		strobe_rect.color = Color(0.95, 0.06, 0.06, 0.0)
	if flash_rect != null:
		flash_rect.visible = false
		flash_rect.color = Color(1.0, 0.96, 0.96, 0.0)
	_set_sync_overlay_visible(false)
	_reset_sync_overlay_visuals()
	if hide_controller and not _alarm_active:
		visible = false
