# Autoload: GlobalEvents.gd
# Global signal distributor

extends Node

# TERMINAL EVENTS
signal terminal_command_entered(signal_data, command, success)
signal terminal_command_failed(signal_data, command)

# GAMEPLAY EVENTS
signal signal_scanned(signal_data: SignalData, scan_depth)
signal signal_hacked(data: SignalData, success: bool)
signal signal_killed(active_sig: ActiveSignal)
signal heat_increased(amount, source)
signal runners_damaged(amount: float)
signal runners_stopped()
signal runners_resumed()
signal ic_triggered(ice_type: String)

# PUZZLE EVENTS
signal puzzle_started(active_signal: ActiveSignal, puzzle_type: PuzzleComponent.Type)
signal puzzle_failed(signal_data)
signal puzzle_solved(signal_data)
