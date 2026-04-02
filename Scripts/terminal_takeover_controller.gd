class_name TerminalTakeoverController
extends RefCounted

const GHOST_TERMINAL_SCENE := preload("res://Scenes/ghost_terminal.tscn")
const GHOST_SPAWN_THRESHOLDS := [0.15, 0.35, 0.45, 0.55, 0.6, 0.65]
const GHOST_MARGIN := 48.0
const GHOST_MIN_SEPARATION := 280.0
const GHOST_POSITION_ATTEMPTS := 10
const GHOST_START_OFFSET_MAX := 500
const NULL_SPIKE_DUMP_2_PATH := "res://Resources/RunData/AuthoredRuns/null_spike_dump2.md"
const NULL_SPIKE_DUMP_3_PATH := "res://Resources/RunData/AuthoredRuns/null_spike_dump3.md"
const BREAKDOWN_CHARSET := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789[]{}<>/\\|!?@#$%^&*()_+-=;:.,~`Â¢Â£Â¥Â¤Â§Â¶ÂµÃŸÃ¸ÃžÃ¾ÃÃ°Î©Î›Î¨Î£Ð–Ð¯Ð¤Ð«Ð®Ð´Ñ‘Ð¶æ¼¢å­—ä»®åã‚¢ã‚¤ã‚¦ã‚¨ã‚ªâ–‘â–’â–“â–ˆ"

var _host: Control
var _command_line: LineEdit
var _history: RichTextLabel
var _title_bar: CanvasItem
var _title_text: RichTextLabel

var _active_session: TerminalSession
var _root_signal: ActiveSignal

var _dump_in_progress := false
var _ghost_threshold_index := 0
var _active_ghosts: Array[Control] = []
var _last_ghost_quadrant := -1
var _breakdown_entered_count := 0
var _collapse_sequence_started := false
var _main_breakdown_active := false

func _init(
	host: Control,
	command_line: LineEdit,
	history: RichTextLabel,
	title_bar: CanvasItem,
	title_text: RichTextLabel
) -> void:
	_host = host
	_command_line = command_line
	_history = history
	_title_bar = title_bar
	_title_text = title_text

func set_session_context(active_session: TerminalSession, root_signal: ActiveSignal) -> void:
	_active_session = active_session
	_root_signal = root_signal

func play_system_dump(text: String, initial_cps: float = 100.0, max_cps: float = 500.0) -> void:
	if _dump_in_progress:
		return

	_dump_in_progress = true
	var previous_editable := _command_line.editable
	var previous_title_modulate := _title_bar.modulate
	var previous_title_text := _title_text.text
	var previous_history_modulate := _history.modulate
	var previous_position := _host.position

	_command_line.editable = false
	_title_bar.modulate = Color(1.4, 0.35, 0.35, 1.0)
	_title_text.text = "DC_OS | [SYSTEM OVERRIDE]"
	_clear_ghosts()
	_ghost_threshold_index = 0
	_last_ghost_quadrant = -1
	_breakdown_entered_count = 0
	_collapse_sequence_started = false
	_main_breakdown_active = false

	var base_text := _history.text
	if not base_text.ends_with("\n"):
		base_text += "\n"
	base_text += "\n[SYSTEM ARCHIVE LINK ESTABLISHED]\n[STREAM ACQUIRED]\n\n"
	_history.text = base_text

	var plain_text := text.replace("\r\n", "\n")
	var total_chars := plain_text.length()
	var chars_revealed: float = 0.0
	while chars_revealed < total_chars:
		var delta := _host.get_process_delta_time()
		var progress := chars_revealed / float(total_chars)
		var current_cps := lerpf(initial_cps, max_cps, progress * progress)
		var current_idx := int(chars_revealed)
		var visible_slice := plain_text.substr(0, int(chars_revealed))
		_maybe_spawn_ghost(progress, text)

		if current_idx < total_chars and plain_text[current_idx] == "\n":
			chars_revealed += 1.0
			visible_slice = plain_text.substr(0, int(chars_revealed))
			_history.text = base_text + _apply_spacing_distortion(visible_slice, progress)
			_apply_dump_instability(progress, previous_position, previous_title_modulate, previous_history_modulate)
			await _host.get_tree().create_timer(0.04).timeout
		else:
			chars_revealed += current_cps * delta
			visible_slice = plain_text.substr(0, int(chars_revealed))
			_history.text = base_text + _apply_spacing_distortion(visible_slice, progress)
			_apply_dump_instability(progress, previous_position, previous_title_modulate, previous_history_modulate)
			await _host.get_tree().process_frame

	_history.text = base_text + plain_text + "\n\n[STREAM END]\n"
	_main_breakdown_active = true
	_on_breakdown_started(_host)
	await _play_breakdown(base_text + plain_text + "\n\n[STREAM END]\n", max_cps)

	_command_line.editable = previous_editable
	_title_bar.modulate = previous_title_modulate
	_title_text.text = previous_title_text
	_history.modulate = previous_history_modulate
	_host.position = previous_position
	_dump_in_progress = false

func estimate_type_duration(text: String, delay: float) -> float:
	if text.is_empty():
		return 0.0
	var newline_bonus := text.count("\n") * delay * 1.5
	return (text.length() * delay) + newline_bonus

func play_null_spike_sync(text: String, delay: float = 0.01) -> void:
	var previous_editable := _command_line.editable
	var previous_title_modulate := _title_bar.modulate
	var previous_title_text := _title_text.text
	var previous_history_modulate := _history.modulate

	if _root_signal != null:
		_host.switch_session(_root_signal)
	if _active_session != null:
		_active_session.history.clear()
	_host.clear_log()

	_command_line.editable = false
	_command_line.text = "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"

	_title_bar.modulate = Color(0.72, 1.28, 1.36, 1.0)
	_title_text.text = "DC_OS | [NULL SPIKE SYNC]"
	_history.modulate = Color(0.82, 1.18, 1.3, 1.0)

	var base_text := "[NULL SPIKE SYNC INITIALIZING]\n[LINK STATE: UNSTABLE]\n\n"
	_history.text = base_text
	if _active_session != null:
		_active_session.history.append(base_text.strip_edges())

	await type_text_with_delay(_history, text.replace("\r\n", "\n"), delay)

	_command_line.text = ""
	_command_line.editable = previous_editable
	_title_bar.modulate = previous_title_modulate
	_title_text.text = previous_title_text
	_history.modulate = previous_history_modulate

func type_text_with_delay(target: RichTextLabel, text: String, delay: float) -> void:
	if target == null or text.is_empty():
		return

	var safe_delay := maxf(0.001, delay)
	var chars_per_second := 1.0 / safe_delay
	var full_text := text.replace("\r\n", "\n")
	var total_chars := full_text.length()
	var chars_revealed: float = 0.0
	var base_text := target.text

	while chars_revealed < total_chars:
		var delta := _host.get_process_delta_time()
		var current_idx := int(chars_revealed)

		if current_idx < total_chars and full_text[current_idx] == "\n":
			chars_revealed += 1.0
			target.text = base_text + full_text.substr(0, int(chars_revealed))
			await _host.get_tree().create_timer(minf(0.04, safe_delay * 2.0)).timeout
			continue

		chars_revealed += chars_per_second * delta
		target.text = base_text + full_text.substr(0, int(chars_revealed))
		await _host.get_tree().process_frame

	target.text = base_text + full_text

func _maybe_spawn_ghost(progress: float, source_text: String) -> void:
	if _ghost_threshold_index >= GHOST_SPAWN_THRESHOLDS.size():
		return
	if progress < GHOST_SPAWN_THRESHOLDS[_ghost_threshold_index]:
		return
	_spawn_ghost(source_text, _ghost_threshold_index)
	_ghost_threshold_index += 1

func _spawn_ghost(source_text: String, ghost_index: int) -> void:
	var ghost_parent := _host.get_tree().current_scene
	if ghost_parent == null:
		return
	var ghost := GHOST_TERMINAL_SCENE.instantiate()
	ghost_parent.add_child(ghost)
	var ghost_control := ghost as Control
	if ghost_control != null:
		ghost_control.top_level = true
		_position_ghost(ghost_control, ghost_index)
		ghost_control.z_index = _host.z_index + ghost_index + 1
		_active_ghosts.append(ghost_control)
	if ghost.has_signal("breakdown_started"):
		ghost.breakdown_started.connect(_on_breakdown_started, CONNECT_ONE_SHOT)
	if ghost.has_signal("dump_finished"):
		ghost.dump_finished.connect(_on_ghost_dump_finished.bind(ghost), CONNECT_ONE_SHOT)
	var ghost_initial_cps := 160.0 + ghost_index * 35.0
	var ghost_max_cps := 650.0 + ghost_index * 120.0
	var ghost_start_offset := randi_range(0, GHOST_START_OFFSET_MAX)
	ghost.play_system_dump(
		_get_ghost_dump_text(source_text, ghost_index),
		ghost_initial_cps,
		ghost_max_cps,
		ghost_start_offset
	)

func _position_ghost(ghost: Control, _ghost_index: int) -> void:
	var viewport_size := _host.get_viewport_rect().size
	var ghost_size := ghost.size
	if ghost_size.x <= 1.0 or ghost_size.y <= 1.0:
		ghost_size = _host.size
	if ghost_size.x <= 1.0 or ghost_size.y <= 1.0:
		ghost_size = Vector2(800, 600)
	var max_x := maxf(GHOST_MARGIN, viewport_size.x - ghost_size.x - GHOST_MARGIN)
	var max_y := maxf(GHOST_MARGIN, viewport_size.y - ghost_size.y - GHOST_MARGIN)
	var quadrant := _pick_ghost_quadrant()
	var half_x := maxf(GHOST_MARGIN, max_x * 0.5)
	var half_y := maxf(GHOST_MARGIN, max_y * 0.5)
	var x_range := Vector2(GHOST_MARGIN, max_x)
	var y_range := Vector2(GHOST_MARGIN, max_y)
	match quadrant:
		0:
			x_range = Vector2(GHOST_MARGIN, half_x)
			y_range = Vector2(GHOST_MARGIN, half_y)
		1:
			x_range = Vector2(half_x, max_x)
			y_range = Vector2(GHOST_MARGIN, half_y)
		2:
			x_range = Vector2(GHOST_MARGIN, half_x)
			y_range = Vector2(half_y, max_y)
		3:
			x_range = Vector2(half_x, max_x)
			y_range = Vector2(half_y, max_y)
	var chosen_position := Vector2(x_range.x, y_range.x)
	var best_distance := -1.0
	for _attempt in range(GHOST_POSITION_ATTEMPTS):
		var pos_x := randf_range(x_range.x, maxf(x_range.x, x_range.y))
		var pos_y := randf_range(y_range.x, maxf(y_range.x, y_range.y))
		var candidate := Vector2(pos_x, pos_y)
		var nearest_distance := _get_nearest_ghost_distance(candidate)
		if nearest_distance >= GHOST_MIN_SEPARATION:
			chosen_position = candidate
			break
		if nearest_distance > best_distance:
			best_distance = nearest_distance
			chosen_position = candidate
	ghost.global_position = chosen_position
	ghost.modulate.a = 1.0
	ghost.self_modulate = Color(
		randf_range(0.92, 1.08),
		randf_range(0.92, 1.08),
		randf_range(0.92, 1.08),
		1.0
	)

func _pick_ghost_quadrant() -> int:
	var options := [0, 1, 2, 3]
	if _last_ghost_quadrant in options:
		options.erase(_last_ghost_quadrant)
	var chosen = options[randi() % options.size()]
	_last_ghost_quadrant = chosen
	return chosen

func _get_ghost_dump_text(default_text: String, ghost_index: int) -> String:
	var path := NULL_SPIKE_DUMP_2_PATH if ghost_index < 2 else NULL_SPIKE_DUMP_3_PATH
	var loaded_text := FileAccess.get_file_as_string(path)
	if loaded_text.is_empty():
		return default_text
	return loaded_text

func _get_nearest_ghost_distance(candidate: Vector2) -> float:
	if _active_ghosts.is_empty():
		return INF
	var nearest_distance := INF
	for ghost in _active_ghosts:
		if ghost == null or not is_instance_valid(ghost):
			continue
		nearest_distance = minf(nearest_distance, candidate.distance_to(ghost.global_position))
	return nearest_distance

func _on_ghost_dump_finished(ghost: Node) -> void:
	if ghost is Control:
		_active_ghosts.erase(ghost)

func _clear_ghosts() -> void:
	for ghost in _active_ghosts:
		if ghost != null and is_instance_valid(ghost):
			if ghost.has_method("stop_breakdown"):
				ghost.stop_breakdown()
			ghost.queue_free()
	_active_ghosts.clear()

func _play_breakdown(base_text: String, max_cps: float) -> void:
	var working_text := base_text
	while _main_breakdown_active:
		var line := _generate_breakdown_line()
		working_text += line + "\n"
		_history.text = working_text
		_apply_dump_instability(1.0, _host.position, _title_bar.modulate, _history.modulate)
		var line_cps := maxf(60.0, max_cps)
		var line_delay := clampf(float(line.length()) / line_cps, 0.02, 0.12)
		await _host.get_tree().create_timer(line_delay).timeout
	_main_breakdown_active = false

func _generate_breakdown_line() -> String:
	var line_length := randi_range(10, 30)
	var out := ""
	for _i in range(line_length):
		out += BREAKDOWN_CHARSET[randi() % BREAKDOWN_CHARSET.length()]
	return out

func _on_breakdown_started(_source: Node) -> void:
	_breakdown_entered_count += 1
	var total_terminals := 1 + GHOST_SPAWN_THRESHOLDS.size()
	if _collapse_sequence_started:
		return
	if _breakdown_entered_count < total_terminals:
		return
	_collapse_sequence_started = true
	_run_ghost_collapse_sequence()

func _run_ghost_collapse_sequence() -> void:
	while not _active_ghosts.is_empty():
		await _host.get_tree().create_timer(0.5).timeout
		var ghost = _active_ghosts.pop_back()
		if ghost == null or not is_instance_valid(ghost):
			continue
		if ghost.has_method("stop_breakdown"):
			ghost.stop_breakdown()
		ghost.queue_free()
	await _host.get_tree().create_timer(0.5).timeout
	_main_breakdown_active = false
	_history.clear()
	for i in range(20):
		if i == 9:
			await type_text_with_delay(_history, "\nOVERFLOW: INSUFFICIENT THROUGHPUT (host)", 0.02)
		elif i == 11:
			await type_text_with_delay(_history, "\n[KNOWN ISSUE. NO FIX PLANNED.]", 0.02)
		elif i == 14:
			await type_text_with_delay(_history, "\nWORKAROUND: PROCEED", 0.05)
		elif i == 19:
			await type_text_with_delay(_history, "\nSESSION TRANSFERRED", 0.1)
		else:
			_history.append_text("\n")
		await _host.get_tree().create_timer(0.2).timeout

func _apply_dump_instability(
	progress: float,
	base_position: Vector2,
	base_title_modulate: Color,
	base_history_modulate: Color
) -> void:
	var jitter_strength := lerpf(0.0, 9.0, progress * progress)
	var jitter_x := randf_range(-jitter_strength, jitter_strength)
	var jitter_y := randf_range(-jitter_strength * 0.6, jitter_strength * 0.6)
	_host.position = base_position + Vector2(jitter_x, jitter_y)

	var flicker_gate := progress > 0.22 and randf() < lerpf(0.03, 0.28, progress)
	if flicker_gate:
		_title_bar.modulate = Color(
			randf_range(1.1, 1.9),
			randf_range(0.22, 0.65),
			randf_range(0.22, 0.65),
			1.0
		)
	else:
		_title_bar.modulate = base_title_modulate.lerp(Color(1.45, 0.35, 0.35, 1.0), minf(1.0, 0.35 + progress * 0.5))

	var tint_mix := clampf(progress * 0.65, 0.0, 0.65)
	var target_history_modulate := Color(
		randf_range(0.85, 1.15),
		randf_range(0.9, 1.25),
		randf_range(0.9, 1.25),
		1.0
	)
	_history.modulate = base_history_modulate.lerp(target_history_modulate, tint_mix)

func _apply_spacing_distortion(text: String, progress: float) -> String:
	if progress < 0.3 or text.is_empty():
		return text

	var distortion_strength := clampf((progress - 0.3) / 0.7, 0.0, 1.0)
	var step := maxi(3, int(round(10.0 - distortion_strength * 6.0)))
	var out := ""
	var visible_index := 0
	for i in range(text.length()):
		var ch := text[i]
		out += ch
		if ch == " " or ch == "\n" or ch == "\t":
			continue
		visible_index += 1
		if visible_index % step != 0:
			continue
		out += " " if distortion_strength < 0.6 else "\u200A"
		if distortion_strength > 0.8 and visible_index % (step * 2) == 0:
			out += "\u200A"
	return out
