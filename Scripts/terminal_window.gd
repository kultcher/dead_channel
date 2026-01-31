# terminal_window.gd
# Terminal window UI. Sends commands to CommandDispatch for processing and displays result

extends PanelContainer

@onready var command_line = $TerminalVBox/CmdLineHBox/CommandLine
@onready var history = $TerminalVBox/TerminalHistory
@onready var linked_signal: Node2D

var signal_data: SignalData		# assigned by window_manager

func _ready():
	set_context()
	command_line.grab_focus()
	CommandDispatch.command_success.connect(_on_command_success)
	CommandDispatch.command_error.connect(_on_command_error)

func _on_command_line_text_submitted(new_text: String) -> void:
	print_to_log("--[ " + new_text)
	CommandDispatch.process_command(new_text, signal_data)
	command_line.clear()

func _on_command_success(command: String, arg: String, flags: Array, context: SignalData) -> void:
	if context != signal_data:		# ensure command signaldata matches terminal signaldata
		return

	match command:
		"ACCESS":
			print_to_log("--[ ACCESS granted to " + arg)
			print_to_log("--[ Awaiting next command... ")
		"SCAN":
			print_to_log("--[ Scanning " + arg + "...")

func _on_command_error(error_msg: String, context: SignalData) -> void:
	if context != signal_data:
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
	if signal_data != null:
		history.text += "\nConnected to " + signal_data.system_id
	await get_tree().create_timer(0.2).timeout
	history.text += "\nEnter command.\n"

func lock_input(duration: float):
	pass

func inject_text(text: String, delay := 0.0):
	pass
