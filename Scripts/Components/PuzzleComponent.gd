# PuzzleComponent.gd
# Component for adding puzzles to a Signal

class_name PuzzleComponent extends Resource

enum Type { NONE, SNIFF, FUZZ, DECRYPT }

@export var puzzle_type: Type = Type.NONE
@export var difficulty: int = 1
@export var encryption_key: String = "" # For decryption puzzles
@export var solved: bool = false

func is_locked() -> bool:
	return puzzle_type != Type.NONE and not solved


func get_desc():
	if not is_locked():
		return "Open"
	else:
		return "Restricted"
