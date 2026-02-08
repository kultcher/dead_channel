# ActiveSignal.gd
# Wrapper for currently on-screen Signals

class_name ActiveSignal extends RefCounted

var data: SignalData
var start_cell_index: float
var instance_node: Node2D = null # Visual

class ScanLayer:
	var name: String         # Internal ID (e.g. "TYPE", "IC_CLOAK")
	var duration: float      # How long to unlock this specific layer
	var revealed: bool = false
	var description: String  # Text for the UI later (e.g. "Hidden IC Module")

var scan_layers: Array[ScanLayer] = []
var current_scan_index: int = 0
var current_layer_progress: float = 0.0
var is_being_scanned: bool = false
var is_scan_locked: bool = false

var is_disabled: bool = false

var ic_modules = []

func setup():
	# Assign name based on possible obfuscations
	if data.spoof_id != "":
		data.display_name = data.spoof_id
	if !data.display_name:
		data.display_name = data.system_id

func disable_signal():
	is_disabled = true
	instance_node.detection_controller.disable_vision()
	data.ic_modules.notify_disabled(self)
	instance_node.update_visuals()

func enable_signal():
	is_disabled = false
	instance_node.detection_controller.enable_vision()
	data.ic_modules.notify_enabled(self)
	instance_node.update_visuals()

func generate_scan_layers():
	scan_layers.clear()
	build_id_layer()
	build_puzzle_layer()
	build_ic_layer()
		
func build_id_layer(difficulty_modifier: float = 1.0):
	var l0 = ScanLayer.new()
	l0.name = "IDENTITY"
	l0.duration = 1.0 * difficulty_modifier
	l0.description = "Type: " + data.identity_dict[data.type]
	# Check data.visual_state. If it's already REVEALED, mark this true immediately
	if data.visual_state == SignalData.VisualState.REVEALED:
		l0.revealed = true
		current_scan_index = 1 # Skip to next
	scan_layers.append(l0)

func build_puzzle_layer(difficulty_modifier: float = 1.0):
	pass

func build_ic_layer(difficulty_modifier: float = 1.0):
	var l4 = ScanLayer.new()
	l4.name = "IC"
	l4.duration = 0.5
	l4.description = "IC: " + data.ic_modules.get_desc()
	scan_layers.append(l4)
