class_name CallbackModule extends ICModule

const CHARSET_BASIC := "abcdefghijklmnopqrstuvwxyz123456789"
const CHARSET_UPPER := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const CHARSET_SPECIAL := "!@#$%^&*+=?"
const DIFFICULTY_SET_COUNTS := {
	1: Vector3i(4, 0, 0),
	2: Vector3i(4, 1, 0),
	3: Vector3i(4, 2, 0),
	4: Vector3i(4, 2, 1),
	5: Vector3i(4, 2, 2),
}

@export var callback_sequence: String = ""

var _armed: bool = false
var _resolved: bool = false
var _rng := RandomNumberGenerator.new()

func _init():
	warning_msg = get_desc()
	_rng.randomize()

func get_desc():
	var sequence_length := callback_sequence.length()
	if sequence_length <= 0:
		sequence_length = _get_sequence_counts().x + _get_sequence_counts().y + _get_sequence_counts().z
	return "Callback(%dc)" % sequence_length

func get_codex_id():
	return &"codex_callback"

func apply_difficulty(difficulty: int) -> void:
	var counts := _get_sequence_counts(difficulty)
	callback_sequence = _build_callback_sequence(counts)
	warning_msg = get_desc()

func apply_params(params: Dictionary) -> void:
	if params.has("callback_sequence"):
		callback_sequence = String(params.get("callback_sequence", ""))
	else:
		var difficulty := int(params.get("difficulty", base_difficulty if base_difficulty > 0 else 1))
		callback_sequence = _build_callback_sequence(_get_sequence_counts(difficulty))
	warning_msg = get_desc()

func on_connect(_active_sig: ActiveSignal):
	if _resolved:
		_armed = false
		return
	if callback_sequence.is_empty():
		callback_sequence = _build_callback_sequence(_get_sequence_counts())
	_armed = true

func on_session_closed(_active_sig: ActiveSignal):
	_armed = false

func on_disabled(_active_sig: ActiveSignal):
	_armed = false

func on_enabled(_active_sig: ActiveSignal):
	_resolved = false
	_armed = false
	if uses_escalation_difficulty:
		callback_sequence = _build_callback_sequence(_get_sequence_counts())

func process_action(action_context: ActionContext) -> void:
	if action_context == null or action_context.primary_target == null:
		return
	if not _armed:
		return
	match action_context.action_type:
		ActionContext.ActionType.SHOW_HELP:
			return
		ActionContext.ActionType.CALLBACK_INPUT:
			_process_callback_input(action_context)
		_:
			action_context.block(
				&"callback",
				"[b][color=orange]CALLBACK[/color][/b] lock active. Enter return sequence to resume command channel."
			)

func get_connection_flow_lines(_active_sig: ActiveSignal) -> Array[String]:
	return [
		"[b][color=red]CALLBACK[/color][/b]: Return-sequence challenge armed.",
		"Use [color=cyan]$<sequence>[/color] to clear the channel."
	]

func _process_callback_input(action_context: ActionContext) -> void:
	var submitted := String(action_context.get_metadata(&"callback_input", "")).strip_edges()
	if submitted == callback_sequence:
		_armed = false
		_resolved = true
		action_context.succeed("[b][color=green]CALLBACK[/color][/b] accepted. Command channel restored.")
		return
	action_context.fail("[b][color=orange]CALLBACK[/color][/b] rejected.")

func _get_sequence_counts(difficulty: int = -1) -> Vector3i:
	var effective_difficulty := difficulty
	if effective_difficulty <= 0:
		effective_difficulty = max(1, base_difficulty)
	if DIFFICULTY_SET_COUNTS.has(effective_difficulty):
		return DIFFICULTY_SET_COUNTS[effective_difficulty]
	var clamped := clampi(effective_difficulty, 1, 5)
	return DIFFICULTY_SET_COUNTS[clamped]

func _build_callback_sequence(counts: Vector3i) -> String:
	var chars: Array[String] = []
	_append_random_chars(chars, CHARSET_BASIC, counts.x)
	_append_random_chars(chars, CHARSET_UPPER, counts.y)
	_append_random_chars(chars, CHARSET_SPECIAL, counts.z)
	_shuffle_chars(chars)
	return "".join(chars)

func _append_random_chars(result: Array[String], charset: String, count: int) -> void:
	for _i in range(maxi(0, count)):
		var char_idx := _rng.randi_range(0, charset.length() - 1)
		result.append(charset.substr(char_idx, 1))

func _shuffle_chars(chars: Array[String]) -> void:
	for i in range(chars.size() - 1, 0, -1):
		var swap_idx := _rng.randi_range(0, i)
		var temp := chars[i]
		chars[i] = chars[swap_idx]
		chars[swap_idx] = temp
