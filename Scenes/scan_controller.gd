extends Node2D

@onready var signal_manager = $"../SignalManager"

var currently_scanning_signal: ActiveSignal = null

func _process(delta):
	if currently_scanning_signal != null:
		_process_active_scan(delta)

func begin_hover(target_signal: ActiveSignal) -> void:
	if not GlobalEvents.is_tutorial_feature_enabled("scan"):
		return
	start_signal_scan(target_signal)

func end_hover(active_sig: ActiveSignal = null) -> void:
	cancel_scan(active_sig)

func toggle_lock(clicked_signal: ActiveSignal) -> void:
	if not GlobalEvents.is_tutorial_feature_enabled("scan"):
		return
	handle_lock_toggle(clicked_signal)

func notify_signal_despawned(active_sig: ActiveSignal) -> void:
	if active_sig == null:
		return
	if currently_scanning_signal == active_sig:
		_cleanup_scan_visuals(active_sig)
		currently_scanning_signal = null

func start_signal_scan(target_signal: ActiveSignal):
	if target_signal == null or target_signal.instance_node == null:
		return

	if currently_scanning_signal != null and currently_scanning_signal != target_signal:
		_cleanup_scan_visuals(currently_scanning_signal)

	currently_scanning_signal = target_signal
	target_signal.is_being_scanned = true

	target_signal.instance_node.bring_to_front()
	target_signal.instance_node.show_scanning_tooltip()
	target_signal.instance_node.show_tooltip()
	target_signal.instance_node.set_scan_highlight(true)

func handle_lock_toggle(clicked_signal: ActiveSignal):
	if clicked_signal == null:
		return

	clicked_signal.is_tooltip_collapsed = not clicked_signal.is_tooltip_collapsed
	if clicked_signal.instance_node != null:
		clicked_signal.instance_node.set_tooltip_collapsed(clicked_signal.is_tooltip_collapsed)
		clicked_signal.instance_node.bring_to_front()

func cancel_scan(active_sig: ActiveSignal = null):
	if currently_scanning_signal != active_sig:
		return

	active_sig.current_layer_progress = 0
	if active_sig.instance_node != null:
		active_sig.instance_node.scan_cleanup()

	_cleanup_scan_visuals(currently_scanning_signal)
	currently_scanning_signal = null

func _process_active_scan(delta):
	var sig = currently_scanning_signal
	if sig == null:
		return

	if sig.instance_node == null:
		_cleanup_scan_visuals(sig)
		currently_scanning_signal = null
		return

	if sig.current_scan_index >= sig.scan_layers.size():
		return

	var current_layer = sig.scan_layers[sig.current_scan_index]
	sig.current_layer_progress += delta

	sig.instance_node.update_scan_progress(sig.current_layer_progress, current_layer.duration)

	if sig.current_layer_progress >= current_layer.duration:
		_complete_scan_layer(sig, current_layer)

func _complete_scan_layer(sig: ActiveSignal, layer):
	layer.revealed = true
	sig.current_layer_progress = 0.0
	sig.current_scan_index += 1

	if sig.instance_node != null:
		sig.instance_node.append_tooltip(layer.description)
		sig.instance_node.update_scan_progress(0, 1.0)
		sig.instance_node.refresh_status_panels()

	GlobalEvents.signal_scanned.emit(sig.data, sig.current_scan_index)

	if sig.current_scan_index >= sig.scan_layers.size():
		if sig.instance_node != null:
			sig.instance_node.show_scan_complete()
		GlobalEvents.signal_scan_complete.emit(sig.data)

func _cleanup_scan_visuals(sig: ActiveSignal):
	sig.is_being_scanned = false
	if sig.instance_node != null:
		sig.instance_node.set_scan_highlight(false)
		sig.instance_node.refresh_scan_status()
		sig.instance_node.set_tooltip_collapsed(sig.is_tooltip_collapsed)
