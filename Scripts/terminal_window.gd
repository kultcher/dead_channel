# terminal_window.gd
# Terminal window UI. Sends commands to CommandDispatch for processing and displays result

extends PanelContainer

@onready var command_line = $TerminalVBox/CmdLineHBox/CommandLine
@onready var history = $TerminalVBox/TerminalHistory
@onready var prefix = $TerminalVBox/CmdLineHBox/InputPrefix
@onready var title_bar = $TerminalVBox/TitleBar
@onready var linked_signal: Node2D = null

var active_signal: ActiveSignal		# assigned by window_manager

func _ready():
	set_context()
	command_line.grab_focus()
	CommandDispatch.terminal_window = self
	CommandDispatch.command_complete.connect(_on_command_complete)
	CommandDispatch.command_error.connect(_on_command_error)

func switch_session(new_sig: ActiveSignal):
	active_signal = new_sig
	prefix.text = "-" + new_sig.data.system_id + "-["
	title_bar.self_modulate = Color(1.0, 1.0, 0.0, 1.0)
	print_to_log("New session started with " + new_sig.data.system_id)
	

func _on_command_line_text_submitted(new_text: String) -> void:
	print_to_log("--[ " + new_text)
	CommandDispatch.process_command(new_text, active_signal)
	command_line.clear()

func _on_command_complete(cmd_context: CommandContext) -> void:
	if cmd_context.active_sig != active_signal:		# ensure command signaldata matches terminal signaldata
		return
	for str in cmd_context.log:
		print_to_log(str)

func _on_command_error(error_msg: String, signal_context: ActiveSignal = null) -> void:
	if signal_context != active_signal:
		return
	print_to_log("!! ERROR: " + error_msg)

func process_result(results: Array):
	print("There was a result.")
	
func print_to_log(text: String):
	history.append_text(text + "\n")

func print_error(text: String):
	pass

func clear():
	pass

func set_context():	# add args later
	history.text = "Connecting"
	for i in 3:
		await get_tree().create_timer(0.2).timeout
		history.text += "."
	history.text += "."
	print("Window setup...")
	await get_tree().create_timer(0.2).timeout
	if active_signal != null:
		history.text += "\nConnected to " + active_signal.data.system_id
	await get_tree().create_timer(0.2).timeout
	history.text += "\nEnter command.\n"
