# ICModule.gd
# Base class for IC modules

class_name ICModule extends Resource

# Virtual function to be overridden
func get_desc():
	return ""

func bind_to_context(signal_data: SignalData, terminal_ref: Control):
	pass

func interrupts_commands(command: String):
	pass

func on_disabled(active_sig: ActiveSignal):
	pass

func on_enabled(active_sig: ActiveSignal):
	pass
