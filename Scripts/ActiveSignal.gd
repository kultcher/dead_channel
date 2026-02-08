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
	instance_node.vision_controller.disable_vision()
	instance_node.update_visuals()

func generate_scan_layers():
	scan_layers.clear()
	build_id_layer()
	build_response_layer()
	build_puzzle_layer()
	build_component_layers()
		
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

func build_response_layer(difficulty_modifier: float = 1.0):
	var l1 = ScanLayer.new()
	var response_desc
	var effect_desc
	l1.name = "MODE"
	l1.duration = 0.5
	if data.response:
		response_desc = data.response.get_desc()
	else: response_desc = "Static"
	if data.effect_area:
		effect_desc = data.effect_area.get_desc()
	else: effect_desc = ""
	l1.description = "Mode: " + response_desc
	scan_layers.append(l1)

func build_puzzle_layer(difficulty_modifier: float = 1.0):
	pass

func build_component_layers(difficulty_modifier: float = 1.0):
	pass
