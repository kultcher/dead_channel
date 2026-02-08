# SignalData.gd
# Modular base signal class, add components for specific functionality

class_name SignalData extends Resource

enum Type { DOOR, CAMERA, TRAP, DRONE, GUARD, INFO, DISRUPTOR, OBJECTIVE, MISC }
enum VisualState { HIDDEN, UNKNOWN, SPOOFED, REVEALED }

var identity_dict = {
	Type.DOOR: "Door | Mech",
	Type.CAMERA: "Camera | Mech",
 }

# IDENTIFIERS
@export var type: Type = Type.MISC
@export var lane: int = 2 # 0=Top, 4=Bottom
@export var system_id: String = "unknown"
@export var display_name: String = ""
@export var spoof_id: String = ""

# STATE
@export var visual_state: VisualState = VisualState.REVEALED
@export var scan_depth: int = 0
@export var scans_to_reveal: int = 1

# COMPONENTS
@export var hackable: HackableComponent
@export var detection: DetectionComponent
@export var response: ResponseComponent
@export var effect_area: EffectAreaComponent
@export var puzzle: PuzzleComponent
@export var ic_protection: Array[ICComponent]
