# terminal_window.gd
# Terminal window UI. Sends commands to CommandDispatch for processing and displays result

# TODO: Add protection for session tabs of lost signals

extends PanelContainer

const GHOST_TERMINAL_SCENE := preload("res://Scenes/ghost_terminal.tscn")
const MAGNIFYING_GLASS_ICON := preload("res://Visuals/Icons/Simple/magnifying-glass.svg")
const CHECK_MARK_ICON := preload("res://Visuals/Icons/Simple/check-mark.svg")
const PADLOCK_ICON := preload("res://Visuals/Icons/Simple/padlock.svg")
const PADLOCK_OPEN_ICON := preload("res://Visuals/Icons/Simple/padlock-open.svg")
const CANCEL_ICON := preload("res://Visuals/Icons/Simple/cancel.svg")
const SHIELD_ICON := preload("res://Visuals/Icons/Simple/shield.svg")
const GHOST_SPAWN_THRESHOLDS := [0.15, 0.35, 0.45, 0.55, 0.6, 0.65]
const GHOST_MARGIN := 48.0
const GHOST_MIN_SEPARATION := 280.0
const GHOST_POSITION_ATTEMPTS := 10
const GHOST_START_OFFSET_MAX := 500
const NULL_SPIKE_DUMP_2_PATH := "res://Resources/RunData/AuthoredRuns/null_spike_dump2.md"
const NULL_SPIKE_DUMP_3_PATH := "res://Resources/RunData/AuthoredRuns/null_spike_dump3.md"
const BREAKDOWN_CHARSET := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789[]{}<>/\\|!?@#$%^&*()_+-=;:.,~`¢£¥¤§¶µßøÞþÐðΩΛΨΣЖЯФЫЮдёж漢字仮名アイウエオ░▒▓█"

const CONNECTION_FLOW_TOTAL_DURATION := 0.96
const CONNECTION_FLOW_MAX_STEP_DELAY := 0.08

enum SessionVisualState { NONE, INACTIVE, ACTIVE }

signal session_opened(active_sig: ActiveSignal)
signal session_activated(active_sig: ActiveSignal)
signal session_deactivated(active_sig: ActiveSignal)
signal session_closed(active_sig: ActiveSignal)
signal session_line_display_mode_changed()

@onready var command_line = $TerminalVBox/CmdLineHBox/CommandLine
@onready var history = $TerminalVBox/TerminalHistory
@onready var prefix = $TerminalVBox/CmdLineHBox/InputPrefix
@onready var title_bar = $TerminalVBox/TitleBar
@onready var title_text = $TerminalVBox/TitleBar/TitleHBox/TitleText
@onready var session_tabs = $TerminalVBox/TitleBar/TitleHBox/SessionTabs

@onready var scan_panel = $TerminalVBox/SignalDetailHBox/ScanPanel
@onready var scan_progress = $TerminalVBox/SignalDetailHBox/ScanPanel/ScanProgress
@onready var scan_icon = $TerminalVBox/SignalDetailHBox/ScanPanel/ScanProgress/ScanCenterBox/ScanHBox/ScanIcon
@onready var scan_label = $TerminalVBox/SignalDetailHBox/ScanPanel/ScanProgress/ScanCenterBox/ScanHBox/ScanLabel

@onready var lock_panel = $TerminalVBox/SignalDetailHBox/LockPanel
@onready var lock_icon = $TerminalVBox/SignalDetailHBox/LockPanel/CenterContainer/LockHBox/LockIcon
@onready var lock_label = $TerminalVBox/SignalDetailHBox/LockPanel/CenterContainer/LockHBox/LockLabel
@onready var toolbox_button = $TerminalVBox/SignalDetailHBox/LockPanel/LockPanelButton
@onready var toolbox_panel = $TerminalVBox/SignalDetailHBox/LockPanel/LockPanelButton/LockToolboxControl/ToolboxPanel

@onready var ic_panel = $TerminalVBox/SignalDetailHBox/ICPanel
@onready var ic_progress = $TerminalVBox/SignalDetailHBox/ICPanel/ICProgress
@onready var ic_icon = $TerminalVBox/SignalDetailHBox/ICPanel/ICCenterBox/ICHBox/ICIcon
@onready var ic_label = $TerminalVBox/SignalDetailHBox/ICPanel/ICCenterBox/ICHBox/ICLabel



@export var show_inactive_session_lines := true:
	set(value):
		if show_inactive_session_lines == value:
			return
		show_inactive_session_lines = value
		session_line_display_mode_changed.emit()

var active_signal: ActiveSignal		# assigned by window_manager
var active_session: TerminalSession
var root_signal: ActiveSignal
var root_session: TerminalSession

var _dump_in_progress := false
var _ghost_threshold_index := 0
var _active_ghosts: Array[Control] = []
var _last_ghost_quadrant := -1
var _breakdown_entered_count := 0
var _collapse_sequence_started := false
var _main_breakdown_active := false
var _connection_flow_serial := 0
var _connection_send_locked := false
var _buffered_command_text := ""
var _buffered_command_signal: ActiveSignal = null
var _buffered_command_flow_serial := -1
var _scan_panel_tint: Color = Color.TRANSPARENT
var _lock_panel_tint: Color = Color.TRANSPARENT
var _ic_panel_tint: Color = Color.TRANSPARENT

func _ready():
	set_context()
	command_line.grab_focus()
	CommandDispatch.terminal_window = self
	CommandDispatch.command_complete.connect(_on_command_complete)
	CommandDispatch.command_error.connect(_on_command_error)
	GlobalEvents.signal_scanned.connect(_on_signal_scanned)
	GlobalEvents.signal_scan_complete.connect(_on_signal_scan_complete)
	GlobalEvents.puzzle_solved.connect(_on_signal_state_changed)
	GlobalEvents.puzzle_failed.connect(_on_signal_state_changed)
	root_session = TerminalSession.new()
	# Dummy signal for root session
	root_signal = ActiveSignal.new()
	active_signal = root_signal
	active_session = root_session
	root_session.has_tab = true
	root_session.active_signal = root_signal
	root_signal.terminal_session = root_session
	session_tabs.add_tab("root")
	_set_tab_session(0, root_session)
	_refresh_signal_detail_panel()

func _process(_delta: float) -> void:
	if active_signal != null and active_signal != root_signal:
		_refresh_signal_detail_panel()

func switch_session(new_sig: ActiveSignal, show_connection_banner: bool = false):
	if new_sig == null:
		print("null signal")
		return
	if active_signal == new_sig and not show_connection_banner:
		print("Same signal")
		return

	# Create new session
	if new_sig.terminal_session == null:
		var new_session = TerminalSession.new()
		new_session.active_signal = new_sig
		new_session.has_tab = true
		new_sig.terminal_session = new_session
		ensure_tab_for_session(new_session)
		session_opened.emit(new_sig)
		_set_active_session(new_session)
		clear_log()
		if show_connection_banner:
			_play_connection_flow(new_sig)
		else:
			print_to_log("New session started with " + new_sig.data.system_id)
		print_to_root("<Session Log>: Connected to " + new_sig.data.system_id)
		prefix.text = "-" + new_sig.data.system_id + "-["
		prefix.add_theme_color_override("font_color", new_sig.data.visuals.fill_color)

	# Switch to existing session
	elif new_sig.terminal_session != null:
		var existing_session := new_sig.terminal_session
		if not existing_session.has_tab:
			ensure_tab_for_session(existing_session)
			session_opened.emit(new_sig)
		_set_active_session(existing_session)
		if not active_session.has_tab:
			ensure_tab_for_session(active_session)
		if show_connection_banner:
			clear_log()
			active_session.history.clear()
			_play_connection_flow(new_sig)
			prefix.text = "-" + active_session.active_signal.data.system_id + "-["
			return
		restore_session(active_session)

func failed_connection_feedback(active_sig):
	print_unlogged("<Session Log>: WARNING: " + active_sig.data.system_id + " out of range. Dropping to root.")
	if active_session != root_session:
		print_to_root("<Session Log>: WARNING: " + active_sig.data.system_id + " out of range. Dropping to root.")
	restore_session(root_session)

func access_signal_via_click(target_sig: ActiveSignal) -> void:
	if target_sig == null or target_sig.data == null:
		return
	var command_text := "ACC " + target_sig.data.system_id
	print_to_log("--[ " + command_text)
	CommandDispatch.process_command(command_text, active_signal)


func print_to_root(text: String):
	root_session.history.append(text)

func print_to_log(text: String):
	active_session.history.append(text)
	history.append_text(text + "\n")

func print_unlogged(text: String):
	history.append_text(text + "\n")

func play_system_dump(text: String, initial_cps: float = 100.0, max_cps: float = 500.0) -> void:
	if _dump_in_progress:
		return

	_dump_in_progress = true
	var previous_editable = command_line.editable
	var previous_title_modulate = title_bar.modulate
	var previous_title_text = title_text.text
	var previous_history_modulate = history.modulate
	var previous_position = position
	command_line.editable = false
	title_bar.modulate = Color(1.4, 0.35, 0.35, 1.0)
	title_text.text = "DC_OS | [SYSTEM OVERRIDE]"
	_clear_ghosts()
	_ghost_threshold_index = 0
	_last_ghost_quadrant = -1
	_breakdown_entered_count = 0
	_collapse_sequence_started = false
	_main_breakdown_active = false

	var base_text = history.text
	if not base_text.ends_with("\n"):
		base_text += "\n"
	base_text += "\n[SYSTEM ARCHIVE LINK ESTABLISHED]\n[STREAM ACQUIRED]\n\n"
	history.text = base_text

	var plain_text := text.replace("\r\n", "\n")
	var total_chars = plain_text.length()
	var chars_revealed: float = 0.0
	while chars_revealed < total_chars:
		var delta: float = get_process_delta_time()
		
		var progress: float = chars_revealed / float(total_chars)
		var current_cps: float = lerpf(initial_cps, max_cps, progress * progress)
		
		var current_idx = int(chars_revealed)
		var visible_slice := plain_text.substr(0, int(chars_revealed))
		_maybe_spawn_ghost(progress, text)
		
		if current_idx < total_chars and plain_text[current_idx] == "\n":
			chars_revealed += 1.0
			visible_slice = plain_text.substr(0, int(chars_revealed))
			history.text = base_text + _apply_spacing_distortion(visible_slice, progress)
			_apply_dump_instability(progress, previous_position, previous_title_modulate, previous_history_modulate)
			await get_tree().create_timer(0.04).timeout
		else:
			chars_revealed += current_cps * delta
			visible_slice = plain_text.substr(0, int(chars_revealed))
			history.text = base_text + _apply_spacing_distortion(visible_slice, progress)
			_apply_dump_instability(progress, previous_position, previous_title_modulate, previous_history_modulate)
			await get_tree().process_frame

	history.text = base_text + plain_text + "\n\n[STREAM END]\n"
	_main_breakdown_active = true
	_on_breakdown_started(self)
	await _play_breakdown(base_text + plain_text + "\n\n[STREAM END]\n", max_cps)
	
	command_line.editable = previous_editable
	title_bar.modulate = previous_title_modulate
	title_text.text = previous_title_text
	history.modulate = previous_history_modulate
	position = previous_position
	_dump_in_progress = false

func _maybe_spawn_ghost(progress: float, source_text: String) -> void:
	if _ghost_threshold_index >= GHOST_SPAWN_THRESHOLDS.size():
		return
	if progress < GHOST_SPAWN_THRESHOLDS[_ghost_threshold_index]:
		return
	_spawn_ghost(source_text, _ghost_threshold_index)
	_ghost_threshold_index += 1

func _spawn_ghost(source_text: String, ghost_index: int) -> void:
	if get_parent() == null:
		return
	var ghost := GHOST_TERMINAL_SCENE.instantiate()
	get_parent().add_child(ghost)
	var ghost_control := ghost as Control
	if ghost_control != null:
		_position_ghost(ghost_control, ghost_index)
		ghost_control.z_index = z_index + ghost_index + 1
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

func _position_ghost(ghost: Control, ghost_index: int) -> void:
	var viewport_size := get_viewport_rect().size
	var ghost_size := ghost.size
	if ghost_size.x <= 1.0 or ghost_size.y <= 1.0:
		ghost_size = size
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
	ghost.position = chosen_position
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
		nearest_distance = minf(nearest_distance, candidate.distance_to(ghost.position))
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
		history.text = working_text
		_apply_dump_instability(1.0, position, title_bar.modulate, history.modulate)
		var line_cps := maxf(60.0, max_cps)
		var line_delay := clampf(float(line.length()) / line_cps, 0.02, 0.12)
		await get_tree().create_timer(line_delay).timeout
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
		await get_tree().create_timer(0.5).timeout
		var ghost = _active_ghosts.pop_back()
		if ghost == null or not is_instance_valid(ghost):
			continue
		if ghost.has_method("stop_breakdown"):
			ghost.stop_breakdown()
		ghost.queue_free()
	await get_tree().create_timer(0.5).timeout
	_main_breakdown_active = false
	history.clear()
	for i in range(20):
		if i == 9: await type_text_with_delay(history, "\nOVERFLOW: INSUFFICIENT THROUGHPUT (host)", 0.02)
		elif i == 11: await type_text_with_delay(history, "\n[KNOWN ISSUE. NO FIX PLANNED.]", 0.02)
		elif i == 14: await type_text_with_delay(history, "\nWORKAROUND: PROCEED", 0.05)
		elif i == 19: type_text_with_delay(history, "\nSESSION TRANSFERRED", 0.1)
		else: history.append_text("\n")
		await get_tree().create_timer(0.2).timeout

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
		var delta := get_process_delta_time()
		var current_idx := int(chars_revealed)

		if current_idx < total_chars and full_text[current_idx] == "\n":
			chars_revealed += 1.0
			target.text = base_text + full_text.substr(0, int(chars_revealed))
			await get_tree().create_timer(minf(0.04, safe_delay * 2.0)).timeout
			continue

		chars_revealed += chars_per_second * delta
		target.text = base_text + full_text.substr(0, int(chars_revealed))
		await get_tree().process_frame

	target.text = base_text + full_text

func estimate_type_duration(text: String, delay: float) -> float:
	if text.is_empty():
		return 0.0
	var newline_bonus := text.count("\n") * delay * 1.5
	return (text.length() * delay) + newline_bonus

func play_null_spike_sync(text: String, delay: float = 0.01) -> void:
	var previous_editable = command_line.editable
	var previous_title_modulate = title_bar.modulate
	var previous_title_text = title_text.text
	var previous_history_modulate = history.modulate

	switch_session(root_signal)
	if active_session != null:
		active_session.history.clear()
	clear_log()

	command_line.editable = false
	command_line.text = "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"

	title_bar.modulate = Color(0.72, 1.28, 1.36, 1.0)
	title_text.text = "DC_OS | [NULL SPIKE SYNC]"
	history.modulate = Color(0.82, 1.18, 1.3, 1.0)

	var base_text := "[NULL SPIKE SYNC INITIALIZING]\n[LINK STATE: UNSTABLE]\n\n"
	history.text = base_text
	if active_session != null:
		active_session.history.append(base_text.strip_edges())

	await type_text_with_delay(history, text.replace("\r\n", "\n"), delay)

	command_line.text = ""
	command_line.editable = previous_editable
	title_bar.modulate = previous_title_modulate
	title_text.text = previous_title_text
	history.modulate = previous_history_modulate


func _apply_dump_instability(
	progress: float,
	base_position: Vector2,
	base_title_modulate: Color,
	base_history_modulate: Color
) -> void:
	var jitter_strength := lerpf(0.0, 9.0, progress * progress)
	var jitter_x := randf_range(-jitter_strength, jitter_strength)
	var jitter_y := randf_range(-jitter_strength * 0.6, jitter_strength * 0.6)
	position = base_position + Vector2(jitter_x, jitter_y)

	var flicker_gate := progress > 0.22 and randf() < lerpf(0.03, 0.28, progress)
	if flicker_gate:
		title_bar.modulate = Color(
			randf_range(1.1, 1.9),
			randf_range(0.22, 0.65),
			randf_range(0.22, 0.65),
			1.0
		)
	else:
		title_bar.modulate = base_title_modulate.lerp(Color(1.45, 0.35, 0.35, 1.0), minf(1.0, 0.35 + progress * 0.5))

	var tint_mix := clampf(progress * 0.65, 0.0, 0.65)
	var target_history_modulate := Color(
		randf_range(0.85, 1.15),
		randf_range(0.9, 1.25),
		randf_range(0.9, 1.25),
		1.0
	)
	history.modulate = base_history_modulate.lerp(target_history_modulate, tint_mix)

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

func clear_log():
	history.text = ""

func _print_connection_flow(target_sig: ActiveSignal) -> void:
	var lines := Jargonizer.build_connection_flow(target_sig)
	for line in lines:
		print_to_log(line)

func _play_connection_flow(target_sig: ActiveSignal) -> void:
	_connection_flow_serial += 1
	var flow_serial := _connection_flow_serial
	_connection_send_locked = true
	_clear_buffered_command()
	_stream_connection_flow_async(target_sig, flow_serial)

func _stream_connection_flow_async(target_sig: ActiveSignal, flow_serial: int) -> void:
	var lines := Jargonizer.build_connection_flow(target_sig)
	if lines.is_empty():
		_finish_connection_flow(flow_serial, target_sig)
		return

	var full_text := "\n".join(lines)
	var total_chars := full_text.length()
	if total_chars <= 0:
		_finish_connection_flow(flow_serial, target_sig)
		return

	var char_delay := CONNECTION_FLOW_TOTAL_DURATION / float(total_chars)
	char_delay = minf(char_delay, CONNECTION_FLOW_MAX_STEP_DELAY)
	var base_text = history.text
	var chars_revealed: float = 0.0

	while chars_revealed < total_chars:
		if flow_serial != _connection_flow_serial:
			return
		if active_session == null or active_session.active_signal != target_sig:
			_finish_connection_flow(flow_serial, target_sig)
			return

		var delta := get_process_delta_time()
		var current_idx := int(chars_revealed)
		if current_idx < total_chars and full_text[current_idx] == "\n":
			chars_revealed += 1.0
			history.text = base_text + full_text.substr(0, int(chars_revealed))
			await get_tree().create_timer(minf(0.02, maxf(0.001, char_delay * 2.0))).timeout
			continue

		chars_revealed += delta / maxf(0.001, char_delay)
		history.text = base_text + full_text.substr(0, int(chars_revealed))
		await get_tree().process_frame

	if flow_serial == _connection_flow_serial:
		history.text = base_text + full_text + "\n"
		active_session.history.append_array(lines)
	_finish_connection_flow(flow_serial, target_sig)

func _finish_connection_flow(flow_serial: int, target_sig: ActiveSignal) -> void:
	if flow_serial != _connection_flow_serial:
		return
	_connection_send_locked = false
	_flush_buffered_command(target_sig, flow_serial)
	if target_sig != null and target_sig.data != null and target_sig.data.ic_modules != null:
		target_sig.data.ic_modules.notify_connected(target_sig)

func _clear_buffered_command() -> void:
	_buffered_command_text = ""
	_buffered_command_signal = null
	_buffered_command_flow_serial = -1

func _buffer_command_submit(new_text: String) -> void:
	_buffered_command_text = new_text
	_buffered_command_signal = active_signal
	_buffered_command_flow_serial = _connection_flow_serial
	command_line.clear()

func _flush_buffered_command(target_sig: ActiveSignal, flow_serial: int) -> void:
	if _buffered_command_text.is_empty():
		return
	if _buffered_command_signal != target_sig:
		_clear_buffered_command()
		return
	if _buffered_command_flow_serial != flow_serial:
		_clear_buffered_command()
		return

	var buffered_text := _buffered_command_text
	_clear_buffered_command()
	print_to_log("--[ " + buffered_text)
	CommandDispatch.process_command(buffered_text, active_signal)

func restore_session(session: TerminalSession):
	if active_session == null: return
	_set_active_session(session)
	if active_session.has_tab == false:
		ensure_tab_for_session(active_session)
	var tab_index = _find_tab_for_session(active_session)
	if tab_index != -1:
		session_tabs.current_tab = tab_index
	clear_log()
	for s in session.history:
		history.text += s + "\n"
	print_unlogged("---Reconnecting---\n")
	if session == root_session:
		prefix.text = "- root -["
	else:
		prefix.text = "-" + active_session.active_signal.data.system_id + "-["
	_refresh_signal_detail_panel()

func set_context():	# add args later
	history.text = Jargonizer.get_handshake()
	for i in 3:
		await get_tree().create_timer(0.2).timeout
		history.text += "."
	history.text += "."
	await get_tree().create_timer(0.2).timeout
	history.text += "\nConnected."
	await get_tree().create_timer(0.2).timeout
	history.text += "\nEnter command.\n"

func _on_session_tabs_tab_clicked(tab: int) -> void:
	var session = _get_tab_session(tab)
	if session == active_session: return
	restore_session(session)

func _on_session_tabs_tab_close_pressed(tab: int) -> void:
	if tab == 0: return
	var session = _get_tab_session(tab)
	if session == null:
		return
	_close_session_tab(session, session.active_signal)

func hide_tab_for_signal(target_signal: ActiveSignal) -> void:
	if target_signal == null or target_signal.terminal_session == null:
		return
	var session := target_signal.terminal_session
	
	if not session.has_tab:
		return

	var tab_index := _find_tab_for_session(session)
	if tab_index == -1:
		_close_session_tab(session, target_signal)
		return

	if session == active_session:
		print_to_root("<Session Log>: WARNING: " + target_signal.data.system_id + " no longer in range. Dropping to root.")
	_close_session_tab(session, target_signal)
	return

func ensure_tab_for_session(session: TerminalSession):
	var existing_index = _find_tab_for_session(session)
	if existing_index != -1:
		session_tabs.current_tab = existing_index
		return
	var tab_label = "root"
	if session != root_session and session.active_signal != null:
		tab_label = session.active_signal.data.system_id
	session_tabs.add_tab(tab_label)
	var new_index = session_tabs.tab_count - 1
	_set_tab_session(new_index, session)
	session_tabs.current_tab = new_index
	session.has_tab = true

func _find_tab_for_session(session: TerminalSession) -> int:
	for i in range(session_tabs.tab_count):
		if _get_tab_session(i) == session:
			return i
	return -1

func _get_tab_session(tab_index: int) -> TerminalSession:
	return session_tabs.get_tab_metadata(tab_index)

func _set_tab_session(tab_index: int, session: TerminalSession):
	session_tabs.set_tab_metadata(tab_index, session)

func get_session_visual_state(active_sig: ActiveSignal) -> int:
	if active_sig == null or active_sig == root_signal:
		return SessionVisualState.NONE
	if active_sig.terminal_session == null:
		return SessionVisualState.NONE

	var session := active_sig.terminal_session
	if not session.has_tab:
		return SessionVisualState.NONE
	if session == active_session:
		return SessionVisualState.ACTIVE
	return SessionVisualState.INACTIVE

func get_tab_anchor_global_position(session: TerminalSession) -> Vector2:
	if session == null:
		return Vector2(INF, INF)
	var tab_index := _find_tab_for_session(session)
	if tab_index == -1:
		return Vector2(INF, INF)
	var tab_rect = session_tabs.get_tab_rect(tab_index)
	var local_anchor = tab_rect.position + Vector2(tab_rect.size.x * 0.5, 0.0)
	return session_tabs.get_global_transform_with_canvas() * local_anchor

func _set_active_session(session: TerminalSession) -> void:
	var previous_session := active_session
	if previous_session == session:
		active_session = session
		active_signal = session.active_signal if session != null else root_signal
		_refresh_signal_detail_panel()
		return

	active_session = session
	active_signal = session.active_signal if session != null else root_signal

	if previous_session != null and previous_session != root_session and previous_session.has_tab and previous_session.active_signal != null:
		session_deactivated.emit(previous_session.active_signal)

	if active_session != null and active_session != root_session and active_session.has_tab and active_session.active_signal != null:
		session_activated.emit(active_session.active_signal)
	_refresh_signal_detail_panel()

func force_disconnect_signal(target_signal: ActiveSignal, reason_lines: Array[String] = []) -> void:
	if target_signal == null or target_signal.terminal_session == null:
		return

	var session := target_signal.terminal_session
	for line in reason_lines:
		if line.is_empty():
			continue
		session.history.append(line)
		if session == active_session:
			print_unlogged(line)
		print_to_root(line)

	if target_signal.data != null:
		print_to_root("<Session Log>: " + target_signal.data.system_id + " connection terminated.")

	if target_signal.instance_node != null and target_signal.instance_node.has_method("play_forced_disconnect_feedback"):
		await target_signal.instance_node.play_forced_disconnect_feedback()

	_close_session_tab(session, target_signal)

func _close_session_tab(session: TerminalSession, target_signal: ActiveSignal) -> void:
	if session == null:
		return

	var tab_index := _find_tab_for_session(session)
	if active_session == session:
		restore_session(root_session)

	session.has_tab = false
	if target_signal != null and target_signal.data != null and target_signal.data.ic_modules != null:
		target_signal.data.ic_modules.notify_session_closed(target_signal)
	if target_signal != null:
		session_closed.emit(target_signal)
	if tab_index != -1:
		session_tabs.remove_tab(tab_index)
	_refresh_signal_detail_panel()

# Signal Detail Panels

func _refresh_signal_detail_panel() -> void:
	if active_signal == null or active_signal == root_signal or active_signal.data == null:
		_apply_default_detail_panel_state()
		return

	_refresh_scan_panel(active_signal)
	_refresh_lock_panel(active_signal)
	_refresh_ic_panel(active_signal)

func _apply_default_detail_panel_state() -> void:
	scan_progress.max_value = 1.0
	scan_progress.value = 0.0
	scan_progress.self_modulate = ActiveSignal.COLOR_STATUS_UNKNOWN
	scan_icon.texture = MAGNIFYING_GLASS_ICON
	scan_icon.self_modulate = ActiveSignal.COLOR_STATUS_UNKNOWN
	scan_label.text = "Scan: Unscanned"
	scan_label.self_modulate = ActiveSignal.COLOR_STATUS_UNKNOWN
	_apply_panel_tint(scan_panel, ActiveSignal.COLOR_STATUS_UNKNOWN, "_scan_panel_tint")

	lock_icon.texture = PADLOCK_ICON
	lock_icon.self_modulate = ActiveSignal.COLOR_STATUS_UNKNOWN
	lock_label.text = "Lock: Unverified"
	lock_label.self_modulate = ActiveSignal.COLOR_STATUS_UNKNOWN
	_apply_panel_tint(lock_panel, ActiveSignal.COLOR_STATUS_UNKNOWN, "_lock_panel_tint")

	ic_progress.max_value = 1.0
	ic_progress.value = 0.0
	ic_progress.self_modulate = ActiveSignal.COLOR_STATUS_UNKNOWN
	ic_icon.texture = SHIELD_ICON
	ic_icon.self_modulate = ActiveSignal.COLOR_STATUS_UNKNOWN
	ic_label.text = "IC: Unknown"
	ic_label.self_modulate = ActiveSignal.COLOR_STATUS_UNKNOWN
	_apply_panel_tint(ic_panel, ActiveSignal.COLOR_STATUS_UNKNOWN, "_ic_panel_tint")

func _refresh_scan_panel(target_sig: ActiveSignal) -> void:
	var total_layers = max(1, target_sig.get_total_scan_layer_count())
	var revealed_layers := target_sig.get_revealed_scan_layer_count()
	var display_value := float(revealed_layers)
	if target_sig.is_being_scanned and target_sig.current_scan_index < target_sig.scan_layers.size():
		var current_layer = target_sig.scan_layers[target_sig.current_scan_index]
		var current_fraction := 0.0
		if current_layer.duration > 0.0:
			current_fraction = clampf(target_sig.current_layer_progress / current_layer.duration, 0.0, 1.0)
		display_value = minf(float(total_layers), float(revealed_layers) + current_fraction)

	var scan_color := target_sig.get_scan_status_color()
	scan_progress.max_value = total_layers
	scan_progress.value = display_value
	scan_progress.self_modulate = scan_color
	scan_icon.texture = CHECK_MARK_ICON if target_sig.get_scan_status_icon_state() == ActiveSignal.TooltipIconState.COMPLETE else MAGNIFYING_GLASS_ICON
	scan_icon.self_modulate = scan_color
	scan_label.text = target_sig.get_scan_status_label_text()
	scan_label.self_modulate = scan_color
	_apply_panel_tint(scan_panel, scan_color, "_scan_panel_tint")

func _refresh_lock_panel(target_sig: ActiveSignal) -> void:
	var lock_state := target_sig.get_lock_status_icon_state()
	var lock_color := target_sig.get_lock_status_color()
	match lock_state:
		ActiveSignal.TooltipIconState.UNKNOWN_LOCK:
			toolbox_button.disabled = true
			return
		ActiveSignal.TooltipIconState.OPEN, ActiveSignal.TooltipIconState.HACKED:
			lock_icon.texture = PADLOCK_OPEN_ICON
			toolbox_button.disabled = true
		_:
			lock_icon.texture = PADLOCK_ICON
			toolbox_button.disabled = false
	lock_icon.self_modulate = lock_color
	lock_label.text = target_sig.get_lock_status_label_text()
	lock_label.self_modulate = lock_color
	_apply_panel_tint(lock_panel, lock_color, "_lock_panel_tint")

func _refresh_ic_panel(target_sig: ActiveSignal) -> void:
	var ic_state := target_sig.get_ic_status_icon_state()
	var ic_color := target_sig.get_ic_status_color()
	var ic_progress_color := target_sig.get_ic_progress_color()
	match ic_state:
		ActiveSignal.TooltipIconState.NO_IC:
			ic_icon.texture = CANCEL_ICON
		ActiveSignal.TooltipIconState.ACTIVE_IC:
			ic_icon.texture = SHIELD_ICON
		_:
			ic_icon.texture = SHIELD_ICON
	ic_progress.max_value = target_sig.get_ic_scan_progress_max()
	ic_progress.value = target_sig.get_ic_scan_progress_value()
	ic_progress.self_modulate = ic_progress_color
	ic_icon.self_modulate = ic_color
	ic_label.text = target_sig.get_ic_status_detail_text()
	ic_label.self_modulate = ic_color
	_apply_panel_tint(ic_panel, ic_color, "_ic_panel_tint")

func _apply_panel_tint(panel: PanelContainer, accent: Color, cache_field: String) -> void:
	if panel == null:
		return
	if get(cache_field) == accent:
		return
	var base_style := panel.get_theme_stylebox("panel")
	if not (base_style is StyleBoxFlat):
		return
	var style := (base_style as StyleBoxFlat).duplicate()
	style.bg_color = Color(
		clampf(accent.r * 0.18, 0.05, 1.0),
		clampf(accent.g * 0.18, 0.05, 1.0),
		clampf(accent.b * 0.18, 0.05, 1.0),
		1.0
	)
	style.border_color = accent
	panel.add_theme_stylebox_override("panel", style)
	set(cache_field, accent)

func _on_signal_scanned(signal_data: SignalData, _scan_depth) -> void:
	if active_signal == null or active_signal == root_signal or signal_data != active_signal.data:
		return
	_refresh_signal_detail_panel()

func _on_signal_scan_complete(signal_data: SignalData) -> void:
	if active_signal == null or active_signal == root_signal or signal_data != active_signal.data:
		return
	_refresh_signal_detail_panel()

func _on_signal_state_changed(signal_data) -> void:
	if active_signal == null or active_signal == root_signal or signal_data != active_signal.data:
		return
	_refresh_signal_detail_panel()

# SIGNALLED FUNCTIONS

func _on_command_line_text_submitted(new_text: String) -> void:
	if _connection_send_locked:
		_buffer_command_submit(new_text)
		return
	print_to_log("--[ " + new_text)
	CommandDispatch.process_command(new_text, active_signal)
	command_line.clear()

func _on_command_complete(cmd_context: CommandContext) -> void:
	if cmd_context.active_sig != active_signal:		# ensure command signaldata matches terminal signaldata
		return
	for s in cmd_context.log_text:
		print_to_log(s)

func _on_command_error(error_msg: String, signal_context: ActiveSignal = null) -> void:
	if signal_context != active_signal:
		return
	print_to_log("!! ERROR: " + error_msg)

var toolbox_open: bool = false

func _on_lock_center_box_pressed() -> void:
	_toggle_toolbox()

func _toggle_toolbox():
	if !toolbox_open:
		_open_toolbox()
	else:
		_close_toolbox()
	
func _open_toolbox():
	var panel_shift = toolbox_panel.position.y + toolbox_panel.size.y
	var tween = create_tween()
	toolbox_panel.z_index = 0
	toolbox_panel.show()
	toolbox_open = true
	tween.tween_property(toolbox_panel, "position:y", -panel_shift, .1)
	await tween.finished
	tween.kill()

func _close_toolbox():
	var panel_shift = toolbox_panel.position.y + toolbox_panel.size.y
	var tween = create_tween()
	toolbox_panel.z_index = 0
	tween.tween_property(toolbox_panel, "position:y", panel_shift, .1)
	await tween.finished
	tween.kill()
	toolbox_panel.z_index = -20
	toolbox_panel.hide()
	toolbox_open = false


func _on_sniff_button_pressed() -> void:
	_close_toolbox()
	print("sniff")


func _on_decrypt_button_pressed() -> void:
	_close_toolbox()
	print("decrypt")
