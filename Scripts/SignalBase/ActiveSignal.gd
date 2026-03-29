# ActiveSignal.gd
# Wrapper for currently on-screen Signals

class_name ActiveSignal extends RefCounted

var data: SignalData
var start_cell_index: float
var instance_node: Node2D = null # Visual

enum TooltipIconState {
	UNKNOWN_SCAN,
	UNKNOWN_LOCK,
	SCANNING,
	PARTIAL,
	COMPLETE,
	OPEN,
	LOCKED,
	HACKED,
	NO_IC,
	ACTIVE_IC
}

class ScanLayer:
	var name: String         # Internal ID (e.g. "TYPE", "IC_CLOAK")
	var duration: float      # How long to unlock this specific layer
	var revealed: bool = false
	var description: String  # Text for the UI later (e.g. "Hidden IC Module")

var scan_layers: Array[ScanLayer] = []
var current_scan_index: int = 0
var current_layer_progress: float = 0.0
var is_being_scanned: bool = false
var is_tooltip_collapsed: bool = true

var is_disabled: bool = false

var terminal_session: TerminalSession = null

# Runtime movement state for mobile signals. These are timeline-space
# coordinates; screen-space conversion stays in SignalManager.
var runtime_position_initialized: bool = false
var runtime_cell_x: float = 0.0
var runtime_lane: int = 2
var runtime_lane_pos: float = 2.0
var runtime_body_facing_deg: float = 180.0
var runtime_detection_facing_deg: float = 180.0
var runtime_detection_paused: bool = false
var runtime_render_offset: Vector2 = Vector2.ZERO

func setup():
	# Assign name based on possible obfuscations
	if data.spoof_id != "":
		data.display_name = data.spoof_id
	if !data.display_name:
		data.display_name = data.system_id
	if data.puzzle:
		data.puzzle.ensure_initial_lock_state()
	if data.type == SignalData.Type.DOOR:
		set_door_locked(data.door_locked)

func disable_signal():
	is_disabled = true
	if CommandDispatch.window_manager != null:
		CommandDispatch.window_manager.close_puzzles_for_signal(self)
	if instance_node != null:
		instance_node.detection_controller.disable_vision()
		instance_node.update_visuals()
	if data.ic_modules:
		data.ic_modules.notify_disabled(self)

func enable_signal():
	is_disabled = false
	if instance_node != null:
		instance_node.detection_controller.enable_vision()
		instance_node.update_visuals()
	if data.ic_modules:
		data.ic_modules.notify_enabled(self)

func generate_scan_layers():
	scan_layers.clear()
	build_id_layer()
	build_puzzle_layer()
	build_ic_layer()

func set_door_locked(locked: bool) -> void:
	if data == null or data.type != SignalData.Type.DOOR:
		return

	data.door_locked = locked
	data.use_alternate_visuals = not locked
	if data.detection != null:
		if locked:
			data.detection.enable_detection()
		else:
			data.detection.disable_detection()
	if data.response != null:
		data.response.reset_delay_state(self, not locked)
	if instance_node != null:
		instance_node.update_visuals()
		
func build_id_layer(difficulty_modifier: float = 1.0):
	var l0 = ScanLayer.new()
	l0.name = "IDENTITY"
	l0.duration = 0.25 * difficulty_modifier
	l0.description = "Type: " + data.identity_dict[data.type]
	# Check data.visual_state. If it's already REVEALED, mark this true immediately
	#if data.visual_state == SignalData.VisualState.REVEALED:
	#	l0.revealed = true
	#	current_scan_index = 1 # Skip to next
	scan_layers.append(l0)

func build_puzzle_layer(difficulty_modifier: float = 1.0):
	var l3 = ScanLayer.new()
	l3.name = "ACCESS"
	l3.duration = 0.5
	if data.puzzle: l3.description = "Access: " + data.puzzle.get_desc()
	else: l3.description = "Access: Open"
	scan_layers.append(l3)

func build_ic_layer(difficulty_modifier: float = 1.0):
	if data.ic_modules == null: return
	var l4 = ScanLayer.new()
	l4.name = "IC"
	l4.duration = 0.5
	l4.description = "IC: " + data.ic_modules.get_desc()
	scan_layers.append(l4)

func get_revealed_scan_descriptions() -> Array[String]:
	var revealed_lines: Array[String] = []
	for layer in scan_layers:
		if layer.revealed:
			revealed_lines.append(layer.description)
	return revealed_lines

func is_scan_layer_revealed(layer_name: String) -> bool:
	for layer in scan_layers:
		if layer.name == layer_name:
			return layer.revealed
	return false

func get_scan_status_icon_state() -> int:
	if is_being_scanned and current_scan_index < scan_layers.size():
		return TooltipIconState.SCANNING
	if scan_layers.is_empty() or current_scan_index >= scan_layers.size():
		return TooltipIconState.COMPLETE
	if current_scan_index > 0:
		return TooltipIconState.PARTIAL
	return TooltipIconState.UNKNOWN_SCAN

func get_lock_status_icon_state() -> int:
	if not is_scan_layer_revealed("ACCESS"):
		return TooltipIconState.UNKNOWN_LOCK
	if data == null or data.puzzle == null:
		return TooltipIconState.OPEN
	if data.puzzle.puzzle_locked:
		return TooltipIconState.LOCKED
	return TooltipIconState.HACKED

func get_ic_status_icon_state() -> int:
	if not is_scan_layer_revealed("IC"):
		return TooltipIconState.UNKNOWN_SCAN
	if data == null or data.ic_modules == null or data.ic_modules.modules.size() <= 0:
		return TooltipIconState.NO_IC
	return TooltipIconState.ACTIVE_IC
