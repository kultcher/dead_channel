# Autoload: GlobalEvents.gd
# Global signal distributor

extends Node

@warning_ignore("unused_signal")

# TERMINAL EVENTS
signal terminal_command_entered(signal_data, command, success)
signal terminal_command_failed(signal_data, command)

# GAMEPLAY EVENTS
signal cell_reached(cell: int)
signal signal_scanned(signal_data: SignalData, scan_depth)
signal signal_scan_complete(signal_data: SignalData)
signal signal_hacked(data: SignalData, success: bool)
signal signal_killed(active_sig: ActiveSignal)
signal heat_increased(amount, source)
signal runners_damaged(amount: float)
signal runners_stopped()
signal runners_resumed()
signal ic_triggered(ice_type: String)
signal guard_alert_raised(alert: GuardAlertData)
signal guard_comms_ping_started(active_sig: ActiveSignal)
signal guard_comms_ping_ended(active_sig: ActiveSignal)
signal tactical_pause()
signal tactical_unpause()
signal tutorial_locked()

# PUZZLE EVENTS
signal puzzle_started(active_signal: ActiveSignal, puzzle_type: PuzzleComponent.Type)
signal puzzle_failed(signal_data)
signal puzzle_solved(signal_data)
