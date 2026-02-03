# signal_manager.gd
# Manages Signals and tracks their position on the Timeline

extends Node2D

@onready var timeline_manager = $"../TimelineManager"
@onready var window_manager = $"../../WindowManager"

var signal_scene = preload("res://Scenes/signal_entity.tscn")

var signal_queue: Array[ActiveSignal] = []
var currently_scanning_signal: ActiveSignal = null

signal signal_clicked(data: SignalData)

func _ready():
	GlobalEvents.signal_killed.connect(kill_signal)
	CommandDispatch.signal_manager = self

	create_test_cam("05", 2.5, 2)
	create_test_cam("06", 6.5, 1)

func get_active_signal(display_name: String):
	print("Search queue for: ", display_name)
	for sig in signal_queue:
		if sig.data.display_name == display_name:
			return sig
	
func create_test_cam(id, distance, lane):
	var cam = SignalData.new()
	cam.type = SignalData.Type.CAMERA
	cam.lane = lane
	cam.system_id = "cam_" + id

	var vision = VisionComponent.new()
	vision.watch_offset_cells = -1.0
	vision.watch_width_cells = 1.0
	vision.heat_per_second = 1.0

	cam.vision = vision

	var killable = KillableComponent.new()
	
	cam.killable = killable

	spawn_signal_data(cam, distance)

func _process(delta):
	if currently_scanning_signal != null:
		_process_active_scan(delta)
	update_signal_position()
	_process_signal_behaviors(delta)

func _process_signal_behaviors(delta: float):
	for sig in signal_queue:
		if sig.data.vision:
			sig.data.vision.process_vision(sig, delta, timeline_manager)
		if sig.data.behavior:
			sig.data.behavior.process_behavior(sig, delta, timeline_manager)

func spawn_signal_data(data: SignalData, cell_index: float):
	var new_signal = ActiveSignal.new()
	new_signal.data = data
	new_signal.start_cell_index = cell_index
	new_signal.setup()
	new_signal.generate_scan_layers()
	signal_queue.append(new_signal)

func update_signal_position():
	var cleared_signals = []
	for active_sig in signal_queue:
		# Distance from Runner (who is at current_cell_pos)
		var dist_from_runner_cells = active_sig.start_cell_index - timeline_manager.current_cell_pos
		
		# Visual Position = Runner's Screen X + Distance * Pixels/Cell
		var runner_screen_x = timeline_manager.cells_to_pixels(timeline_manager.runner_screen_offset_cells)
		var visual_x = runner_screen_x + (dist_from_runner_cells * timeline_manager.cell_width_px)
		var is_on_screen = visual_x > -100 and visual_x < timeline_manager.screen_width + 100
		
		if is_on_screen:
			if active_sig.instance_node == null:
				var new_node = signal_scene.instantiate()
				add_child(new_node)
				new_node.setup(active_sig)
				new_node.signal_interaction.connect(_on_signal_left_clicked)
				new_node.scan_lock_requested.connect(_on_signal_right_clicked)
				new_node.scan_requested.connect(_on_signal_mouse_enter)
				new_node.scan_aborted.connect(_on_signal_mouse_exit)
				active_sig.instance_node = new_node
			
			var visual_y = (active_sig.data.lane * timeline_manager.lane_height) + (timeline_manager.lane_height * 0.5)
			active_sig.instance_node.position = Vector2(visual_x, visual_y)
			
		else:
			if active_sig.instance_node != null:
				active_sig.instance_node.queue_free()
				cleared_signals.append(active_sig)

	for active_sig in cleared_signals:
			active_sig.instance_node = null
			signal_queue.erase(active_sig)

# === KILL SIGNALS ===
func kill_signal(active_sig: ActiveSignal):
	if active_sig == currently_scanning_signal:
		cancel_scan(active_sig)
	signal_queue.erase(active_sig)
	active_sig.instance_node.queue_free()

# === SCAN & LOCK LOGIC ===

func _on_signal_left_clicked(active_signal: ActiveSignal):
	window_manager.route_signal_to_window(active_signal)
	
func _on_signal_mouse_enter(signal_entered: ActiveSignal):
	if currently_scanning_signal != null and currently_scanning_signal.is_scan_locked:
		return
	start_signal_scan(signal_entered)

func _on_signal_right_clicked(signal_clicked: ActiveSignal):
	handle_lock_toggle(signal_clicked)
	
func _on_signal_mouse_exit(signal_exited: ActiveSignal):
	cancel_scan(signal_exited)
	
func start_signal_scan(target_signal: ActiveSignal):
	if currently_scanning_signal != null and currently_scanning_signal != target_signal:
		_cleanup_scan_visuals(currently_scanning_signal)
			
	currently_scanning_signal = target_signal
	target_signal.is_being_scanned = true

	print("Start signal scan called")
	target_signal.instance_node.tooltip_active_scan.show()
	target_signal.instance_node.tooltip_main.show()
	
	if target_signal.instance_node:
		target_signal.instance_node.set_scan_highlight(true)
		
	print("STARTED SCANNING: " + target_signal.data.display_name)

func handle_lock_toggle(clicked_signal: ActiveSignal):
	# CASE 1: Right-clicking the signal we are ALREADY scanning
	if currently_scanning_signal == clicked_signal:
		clicked_signal.is_scan_locked = !clicked_signal.is_scan_locked
		print("Lock State Toggled: ", clicked_signal.is_scan_locked)
		return

	# CASE 2: Right-clicking a NEW signal while another is locked
	if currently_scanning_signal != null:
		currently_scanning_signal.is_scan_locked = false
		_cleanup_scan_visuals(currently_scanning_signal)
	
	# Start fresh scan on new target and force lock
	start_signal_scan(clicked_signal)
	clicked_signal.is_scan_locked = true
	print("Override Lock onto: ", clicked_signal.data.display_name)

func cancel_scan(active_sig: ActiveSignal = null):
	if currently_scanning_signal != active_sig:
		return
		
	if currently_scanning_signal.is_scan_locked:
		return
	
	active_sig.current_layer_progress = 0
	active_sig.instance_node.scan_cleanup()

	_cleanup_scan_visuals(currently_scanning_signal)
	
	currently_scanning_signal = null

func _process_active_scan(delta):
	var sig = currently_scanning_signal

	if sig.instance_node == null:
		_cleanup_scan_visuals(sig)
		currently_scanning_signal = null
		return
		
	if sig.current_scan_index >= sig.scan_layers.size():
		return
		
	# Advance Progress
	var current_layer = sig.scan_layers[sig.current_scan_index]
	sig.current_layer_progress += delta

	# VISUAL UPDATE: RADAR

	if sig.instance_node:
		sig.instance_node.update_scan_progress(sig.current_layer_progress, current_layer.duration)

	# Check Completion
	if sig.current_layer_progress >= current_layer.duration:
		print("Layer complete")
		_complete_scan_layer(sig, current_layer)

func _complete_scan_layer(sig: ActiveSignal, layer):
	layer.revealed = true
	sig.current_layer_progress = 0.0
	sig.current_scan_index += 1
	
	GlobalEvents.signal_scanned.emit(sig.data, sig.current_scan_index)
	
	if sig.instance_node:
		sig.instance_node.append_tooltip(layer.description)
		sig.instance_node.update_scan_progress(0, 1.0)

			
func _cleanup_scan_visuals(sig: ActiveSignal):
	sig.is_being_scanned = false
	sig.is_scan_locked = false # Ensure lock is cleared
	if sig.instance_node:
		sig.instance_node.set_scan_highlight(false)
