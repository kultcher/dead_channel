# terminal_window.gd
# Terminal window UI. Sends commands to CommandDispatch for processing and displays result

# TODO: Add protection for session tabs of lost signals

extends PanelContainer

@onready var command_line = $TerminalVBox/CmdLineHBox/CommandLine
@onready var history = $TerminalVBox/TerminalHistory
@onready var prefix = $TerminalVBox/CmdLineHBox/InputPrefix
@onready var title_bar = $TerminalVBox/TitleBar
@onready var session_tabs = $TerminalVBox/TitleBar/TitleHBox/SessionTabs

var active_signal: ActiveSignal		# assigned by window_manager
var active_session: TerminalSession
var root_signal: ActiveSignal
var root_session: TerminalSession

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
		prefix.text = "-" + new_sig.data.system_id + "-["

	# Switch to existing session
	elif active_signal.terminal_session != null:
		active_session = active_signal.terminal_session
		restore_session(active_session)

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

func print_to_log(text: String):
	active_session.history.append(text)
	history.append_text(text + "\n")

func print_unlogged(text: String):
	history.append_text(text + "\n")

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
	history.text = "Connecting"
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
