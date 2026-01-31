# Autoload: GlobalEvents.gd
# Global signal distributor

extends Node

# TERMINAL EVENTS
signal terminal_command_entered(signal_data, command, success)
signal terminal_command_failed(signal_data, command)

# GAMEPLAY EVENTS
signal signal_scanned(signal_data: SignalData, scan_depth)
signal signal_hacked(data: SignalData, success: bool)
signal runner_in_vision(active_sig: ActiveSignal)
signal heat_generated(source_name, amount)
signal runner_damaged(amount: float)
signal ic_triggered(ice_type: String)

# PUZZLE EVENTS
signal puzzle_started(signal_data, puzzle_type)
signal puzzle_failed(signal_data)
signal puzzle_solved(signal_data)
