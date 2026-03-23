# signal_manager.gd
# Manages Signals and tracks their position on the Timeline

extends Node2D

@onready var timeline_manager = $"../TimelineManager"
@onready var window_manager = $"../../WindowManager"
@onready var terminal_window = $"../../TerminalWindow"
@onready var scan_controller = $"../ScanController"
@onready var spawner = SignalSpawner.new()

var signal_scene = preload("res://Scenes/signal_entity.tscn")

var signal_queue: Array[ActiveSignal] = []

func _ready():
	CommandDispatch.signal_manager = self
	
#	spawn_signal_data(spawner.create_test_cam("05", 2), 3.5)
#	spawn_signal_data(spawner.create_test_cam("06", 3), 6.5)
#	spawn_signal_data(spawner.create_test_cam("07", 4), 4.5)
#	spawn_signal_data(spawner.create_test_cam("08", 0), 7.5)
#	spawn_signal_data(spawner.create_test_door("01", 2), 1.5)
#	spawn_signal_data(spawner.create_test_guard("01", 5.0, 1), 5.0)

func get_active_signal(display_name: String):
	print("Search queue for: ", display_name)
	for sig in signal_queue:
		if sig.data.display_name == display_name:
			return sig

func get_signal_by_system_id(system_id: String) -> ActiveSignal:
	for sig in signal_queue:
		if sig != null and sig.data != null and sig.data.system_id == system_id:
			return sig
	return null

func has_signal_in_network(system_id: String) -> bool:
	return get_signal_by_system_id(system_id) != null

func is_signal_in_range(system_id: String) -> bool:
	var sig := get_signal_by_system_id(system_id)
	return sig != null and sig.instance_node != null
	
func _process(delta):
	update_signal_position()

func spawn_signal_data(data: SignalData, cell_index: float):
	var new_signal = ActiveSignal.new()
	new_signal.data = data
	new_signal.start_cell_index = cell_index
	new_signal.setup()
	new_signal.generate_scan_layers()
	signal_queue.append(new_signal)
	print("Spawn signal: ", new_signal.data.display_name)

func update_signal_position():
	for active_sig in signal_queue:
		var signal_cell_index := active_sig.start_cell_index
		var signal_lane := float(active_sig.data.lane)
		if active_sig.runtime_position_initialized:
			signal_cell_index = active_sig.runtime_cell_x
			signal_lane = active_sig.runtime_lane_pos

		# Distance from Runner (who is at current_cell_pos)
		var dist_from_runner_cells = signal_cell_index - timeline_manager.current_cell_pos
		
		# Visual Position = Runner's Screen X + Distance * Pixels/Cell
		var runner_screen_x = timeline_manager.cells_to_pixels(timeline_manager.runner_screen_offset_cells)
		var visual_x = runner_screen_x + (dist_from_runner_cells * timeline_manager.cell_width_px)
		var is_on_screen = visual_x > -200 and visual_x < timeline_manager.screen_width + 200
		
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
			
			var visual_y = (signal_lane * timeline_manager.lane_height) + (timeline_manager.lane_height * 0.5)
			var render_offset := active_sig.runtime_render_offset
			active_sig.instance_node.position = Vector2(visual_x, visual_y) + render_offset
			
		else:
			if visual_x < -200 and active_sig.instance_node != null:
				if terminal_window != null:
					terminal_window.hide_tab_for_signal(active_sig)
				if scan_controller != null:
					scan_controller.notify_signal_despawned(active_sig)
				active_sig.instance_node.queue_free()
				active_sig.instance_node = null

func _on_signal_left_clicked(active_sig: ActiveSignal):
	if not GlobalEvents.is_tutorial_feature_enabled("connect"):
		return
	CommandDispatch.switch_terminal_session(active_sig)
	
func _on_signal_mouse_enter(signal_entered: ActiveSignal):
	if not GlobalEvents.is_tutorial_feature_enabled("scan"):
		return
	if scan_controller != null:
		scan_controller.begin_hover(signal_entered)

func _on_signal_right_clicked(signal_clicked: ActiveSignal):
	if not GlobalEvents.is_tutorial_feature_enabled("scan"):
		return
	if scan_controller != null:
		scan_controller.toggle_lock(signal_clicked)
	
func _on_signal_mouse_exit(signal_exited: ActiveSignal):
	if scan_controller != null:
		scan_controller.end_hover(signal_exited)
