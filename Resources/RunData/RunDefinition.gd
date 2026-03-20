class_name RunDefinition extends RefCounted

const BASIC_CAMERA := preload("res://Resources/SignalPrefabs/basic_camera.tres")
const BASIC_DOOR := preload("res://Resources/SignalPrefabs/basic_door.tres")
const BASIC_GUARD := preload("res://Resources/SignalPrefabs/basic_guard.tres")

func get_run_id() -> String:
	return ""

func get_display_name() -> String:
	return get_run_id()

func get_spawns() -> Array[Dictionary]:
	return []

func get_tutorial_events() -> Array[TutorialEvent]:
	return []

# Overrides: lane, display_name, spoof_id, puzzle, ic_modules, add_ic_modules
func build_spawn(signal_data: SignalData, cell_index: float, overrides: Dictionary = {}) -> Dictionary:
	var spawn := {
		"signal_data": signal_data,
		"cell_index": cell_index,
	}

	for key in overrides.keys():
		spawn[key] = overrides[key]

	return spawn

func make_puzzle(
	puzzle_type: PuzzleComponent.Type,
	difficulty: int = 1,
	encryption_key: String = ""
) -> PuzzleComponent:
	var puzzle := PuzzleComponent.new()
	puzzle.puzzle_type = puzzle_type
	puzzle.difficulty = difficulty
	puzzle.encryption_key = encryption_key
	puzzle.ensure_initial_lock_state()
	return puzzle

func make_sniff_puzzle(difficulty: int = 1) -> PuzzleComponent:
	return make_puzzle(PuzzleComponent.Type.SNIFF, difficulty)

func make_fuzz_puzzle(difficulty: int = 1) -> PuzzleComponent:
	return make_puzzle(PuzzleComponent.Type.FUZZ, difficulty)

func make_decrypt_puzzle(difficulty: int = 1, encryption_key: String = "") -> PuzzleComponent:
	return make_puzzle(PuzzleComponent.Type.DECRYPT, difficulty, encryption_key)

func make_ic(modules: Array[Resource] = []) -> ICComponent:
	var ic := ICComponent.new()
	ic.modules.assign(modules)
	return ic

func make_reboot_module(reboot_time: float = 5.0) -> RebootModule:
	var module := RebootModule.new()
	module.reboot_time = reboot_time
	return module

func make_reboot_ic(reboot_time: float = 5.0) -> ICComponent:
	return make_ic([make_reboot_module(reboot_time)])

func build_tutorial_event(
	event_id: String,
	event_trigger: TutorialEvent.Trigger,
	event_value: int,
	event_signal_index: int,
	event_text: Array[String],
	event_position: Vector2 = Vector2(),
	event_focus_rect: Rect2 = Rect2()
) -> TutorialEvent:
	var event := TutorialEvent.new()
	event.id = event_id
	event.trigger = event_trigger
	event.value = event_value
	event.signal_index = event_signal_index
	event.text.assign(event_text)
	event.default_position = event_position
	event.has_custom_position = event_position != Vector2()
	event.focus_rect = event_focus_rect
	return event
