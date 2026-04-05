class_name HazeModule extends ICModule

@export var scan_time_multiplier: float = 2.0

const DIFFICULTY_SCAN_MULTIPLIERS := [2.0, 2.5, 3.0, 4.0]

func get_desc():
	return "Haze(x%.1f)" % scan_time_multiplier

func get_codex_id():
	return &"codex_haze"

func apply_difficulty(difficulty: int) -> void:
	scan_time_multiplier = float(_pick_difficulty_value(DIFFICULTY_SCAN_MULTIPLIERS, difficulty))

func apply_params(params: Dictionary) -> void:
	scan_time_multiplier = float(params.get("scan_time_multiplier", scan_time_multiplier))

func process_action(action_context: ActionContext) -> void:
	if action_context == null or action_context.primary_target == null:
		return
	if action_context.action_type != ActionContext.ActionType.START_SCAN_SIGNAL:
		return

	var current_multiplier := float(action_context.get_metadata(&"scan_time_multiplier", 1.0))
	action_context.set_metadata(
		&"scan_time_multiplier",
		maxf(0.01, current_multiplier * scan_time_multiplier)
	)
