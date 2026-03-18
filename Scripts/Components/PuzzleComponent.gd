# PuzzleComponent.gd
# Component for adding puzzles to a Signal

class_name PuzzleComponent extends Resource

enum Type { NONE, SNIFF, FUZZ, DECRYPT }

@export var puzzle_type: Type = Type.NONE
@export var difficulty: int = 1
@export var encryption_key: String = "" # For decryption puzzles
@export var puzzle_locked: bool = false

var puzzle_dict = {
	Type.NONE: "Open",
	Type.SNIFF: "Locked",
	Type.DECRYPT: "Encrypted",
	Type.FUZZ: "Vulnerable"
}

func _init():
	pass

func ensure_initial_lock_state():
	if puzzle_type != Type.NONE:
		puzzle_locked = true

func process_solve(active_sig: ActiveSignal):
	print("Puzzle Component: Puzzle Solved!")
	puzzle_locked = false
	#TODO: Find a clean way to update tooltip text... store as an array to print on each line?
	#WARNING: temporary
	active_sig.instance_node.tooltip_active_scan_text.text = "HACKED"
	active_sig.instance_node.tooltip_active_scan.set_self_modulate(Color(255,0,0))

func is_locked() -> bool:
	return puzzle_type != Type.NONE and puzzle_locked

func get_desc():
	if puzzle_type == Type.NONE:
		return "This shouldn't happen probably?"
	elif !puzzle_locked:
		return "HACKED"
	return puzzle_dict[puzzle_type]
	
