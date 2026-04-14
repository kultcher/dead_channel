class_name NecromancerModule extends ICModule

@export var pulse_interval_sec: float = 18.0

var timer: Timer = null

const DIFFICULTY_PULSE_INTERVALS := [10.0, 8.0, 6.0, 4.0]

func get_desc():
	return "Necromancer(%.1fs)" % pulse_interval_sec

func get_codex_id():
	return &"codex_necromancer"

func apply_difficulty(difficulty: int) -> void:
	pulse_interval_sec = float(_pick_difficulty_value(DIFFICULTY_PULSE_INTERVALS, difficulty))
	warning_msg = get_desc()

func apply_params(params: Dictionary) -> void:
	pulse_interval_sec = float(params.get("pulse_interval_sec", pulse_interval_sec))
	warning_msg = get_desc()

func on_initialized(active_sig: ActiveSignal) -> void:
	_start_pulse_loop(active_sig)

func on_enabled(active_sig: ActiveSignal):
	_start_pulse_loop(active_sig)

func on_disabled(_active_sig: ActiveSignal):
	_clear_timer()

func get_connection_flow_lines(_active_sig: ActiveSignal) -> Array[String]:
	return [
		"[b][color=red]NECROMANCER[/color][/b]: Dead nodes queued for forced recovery.",
		"GLOBAL REANIMATION CYCLE: %.1fs" % pulse_interval_sec
	]

func _start_pulse_loop(active_sig: ActiveSignal) -> void:
	if not _is_valid_host_signal(active_sig):
		_clear_timer()
		return
	if timer != null and is_instance_valid(timer):
		return

	timer = Timer.new()
	timer.one_shot = false
	timer.wait_time = pulse_interval_sec
	GlobalEvents.add_child(timer)
	timer.timeout.connect(_on_pulse_timeout.bind(active_sig))
	timer.start()

func _on_pulse_timeout(active_sig: ActiveSignal) -> void:
	if not _is_valid_host_signal(active_sig):
		_clear_timer()
		return

	if CommandDispatch.signal_manager == null:
		return

	for target_sig in CommandDispatch.signal_manager.signal_queue:
		if not _can_reanimate_signal(target_sig):
			continue

		var action := ActionContext.create_system_action(
			ActionContext.ActionType.ENABLE_SIGNAL,
			target_sig,
			ActionContext.SourceType.IC_MODULE
		)
		action.add_tag(&"ic")
		action.add_tag(&"necromancer")
		action.set_metadata(&"codex_id", get_codex_id())
		ActionResolver.enqueue_action(action)

func _can_reanimate_signal(target_sig: ActiveSignal) -> bool:
	if target_sig == null or target_sig.data == null:
		return false
	if not target_sig.is_disabled:
		return false
	if target_sig.instance_node == null:
		return false
	if target_sig.data.type == SignalData.Type.TERMINAL:
		return false
	if target_sig.data.type == SignalData.Type.DISRUPTOR:
		return false
	return true

func _is_valid_host_signal(active_sig: ActiveSignal) -> bool:
	if active_sig == null or active_sig.data == null:
		return false
	if active_sig.is_disabled:
		return false
	return active_sig.data.type == SignalData.Type.ESCALATION

func _clear_timer() -> void:
	if timer != null and is_instance_valid(timer):
		timer.queue_free()
	timer = null
