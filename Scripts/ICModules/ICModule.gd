# ICModule.gd
# Base class for IC modules

class_name ICModule extends Resource

# Virtual function to be overridden
func bind_to_context(signal_data: SignalData, terminal_ref: Control):
	pass
