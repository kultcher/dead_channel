# terminal_window.gd
# Terminal window UI. Sends commands to CommandDispatch for processing and displays result

# TODO: Add protection for session tabs of lost signals

extends PanelContainer

@onready var command_line = $TerminalVBox/CmdLineHBox/CommandLine
@onready var history = $TerminalVBox/TerminalHistory
@onready var prefix = $TerminalVBox/CmdLineHBox/InputPrefix
@onready var title_bar = $TerminalVBox/TitleBar
@onready var title_text = $TerminalVBox/TitleBar/TitleHBox/TitleText
@onready var session_tabs = $TerminalVBox/TitleBar/TitleHBox/SessionTabs

var active_signal: ActiveSignal		# assigned by window_manager
var active_session: TerminalSession
var root_signal: ActiveSignal
var root_session: TerminalSession
var _dump_in_progress := false

func _ready():
	set_context()
	command_line.grab_focus()
	CommandDispatch.terminal_window = self
	CommandDispatch.command_complete.connect(_on_command_complete)
	CommandDispatch.command_error.connect(_on_command_error)
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

func switch_session(new_sig: ActiveSignal):
	if new_sig == null:
		print("null signal")
		return
	if active_signal == new_sig:
		print("Same signal")
		return

	active_signal = new_sig

	# Create new session
	if new_sig.terminal_session == null:
		var new_session = TerminalSession.new()
		new_session.active_signal = new_sig
		new_session.has_tab = true
		new_sig.terminal_session = new_session
		active_session = new_session
		ensure_tab_for_session(new_session)
		clear_log()
		print_to_log("New session started with " + new_sig.data.system_id)
		print_to_root("<Session Log>: Connected to " + new_sig.data.system_id)
		prefix.text = "-" + new_sig.data.system_id + "-["

	# Switch to existing session
	elif active_signal.terminal_session != null:
		active_session = active_signal.terminal_session
		restore_session(active_session)

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
	
	command_line.editable = previous_editable
	title_bar.modulate = previous_title_modulate
	title_text.text = previous_title_text
	history.modulate = previous_history_modulate
	position = previous_position
	_dump_in_progress = false

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

func restore_session(session: TerminalSession):
	if active_session == null: return
	active_session = session
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
	if session == active_session:
		restore_session(root_session)
	if session != null:
		session.has_tab = false
	session_tabs.remove_tab(tab)

func hide_tab_for_signal(target_signal: ActiveSignal) -> void:
	if target_signal == null or target_signal.terminal_session == null:
		return
	var session := target_signal.terminal_session
	
	if not session.has_tab:
		return

	var tab_index := _find_tab_for_session(session)
	if tab_index == -1:
		session.has_tab = false
		if active_session == session:
			restore_session(root_session)
		return

	if session == active_session:
		print_to_root("<Session Log>: WARNING: " + target_signal.data.system_id + " no longer in range. Dropping to root.")
		restore_session(root_session)

	session.has_tab = false
	session_tabs.remove_tab(tab_index)

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

# SIGNALLED FUNCTIONS

func _on_command_line_text_submitted(new_text: String) -> void:
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

	
