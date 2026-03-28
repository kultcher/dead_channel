class_name BouncerModule extends ICModule

@export var time_to_disconnect: float = 3.0

var timer: Timer = null

func get_desc():
	return "Bouncer(%.1fs)" % time_to_disconnect

func get_codex_id():
	return &"codex_bouncer"

func on_connect(active_sig: ActiveSignal):
	_clear_timer()
	if active_sig == null or active_sig.terminal_session == null:
		return

	timer = Timer.new()
	timer.one_shot = true
	GlobalEvents.add_child(timer)
	timer.timeout.connect(_on_disconnect_timer_timeout.bind(active_sig), CONNECT_ONE_SHOT)
	timer.start(time_to_disconnect)

func on_session_closed(_active_sig: ActiveSignal):
	_clear_timer()

func on_disabled(_active_sig: ActiveSignal):
	_clear_timer()

func get_connection_flow_lines(_active_sig: ActiveSignal) -> Array[String]:
	return [
		"[b][color=red]BOUNCER[/color][/b]: Session integrity challenge armed.",
		"SESSION TTL: %.1fs" % time_to_disconnect
	]

func _on_disconnect_timer_timeout(active_sig: ActiveSignal) -> void:
	_clear_timer()
	if active_sig == null or active_sig.terminal_session == null:
		return
	if not active_sig.terminal_session.has_tab:
		return
	if CommandDispatch.terminal_window == null:
		return

	var reason_lines: Array[String] = [
		"[b][color=red]BOUNCER[/color][/b]: Session timer expired.",
		"Connection forcibly terminated."
	]
	CommandDispatch.terminal_window.force_disconnect_signal(
		active_sig,
		reason_lines
	)

func _clear_timer() -> void:
	if timer != null and is_instance_valid(timer):
		timer.queue_free()
	timer = null
