extends PanelContainer

signal breakdown_started(source)
signal dump_finished

const BREAKDOWN_CHARSET := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789[]{}<>/\\|!?@#$%^&*()_+-=;:.,~`¢£¥¤§¶µßøÞþÐðΩΛΨΣЖЯФЫЮдёж漢字仮名アイウエオ░▒▓█"

@onready var history = $TerminalVBox/TerminalHistory
@onready var title_bar = $TerminalVBox/TitleBar
@onready var title_text = $TerminalVBox/TitleBar/TitleHBox/TitleText

var _dump_in_progress := false
var _breakdown_active := false

func _ready():
	pass

func play_system_dump(
	text: String,
	initial_cps: float = 100.0,
	max_cps: float = 500.0,
	start_char_offset: int = 0
) -> void:

	if _dump_in_progress:
		return

	_dump_in_progress = true
	var previous_title_modulate = title_bar.modulate
	var previous_title_text = title_text.text
	var previous_history_modulate = history.modulate
	var previous_position = position
	title_bar.modulate = Color(1.4, 0.35, 0.35, 1.0)
	title_text.text = "DC_OS | [SYSTEM OVERRIDE]"

	var base_text = history.text
	if not base_text.ends_with("\n"):
		base_text += "\n"

	var plain_text := text.replace("\r\n", "\n")
	var total_chars = plain_text.length()

	var reveal_start := clampi(start_char_offset, 0, max(0, total_chars - 1))
	var chars_revealed: float = 0.0

	var revealed_text := plain_text.substr(reveal_start)
	total_chars = revealed_text.length()

	while chars_revealed < total_chars:
		var delta: float = get_process_delta_time()
		
		var progress: float = chars_revealed / float(total_chars)
		var current_cps: float = lerpf(initial_cps, max_cps, progress * progress)
		
		var current_idx = int(chars_revealed)
		var visible_slice := revealed_text.substr(0, int(chars_revealed))
		if current_idx < total_chars and revealed_text[current_idx] == "\n":
			chars_revealed += 1.0
			visible_slice = revealed_text.substr(0, int(chars_revealed))
			history.text = base_text + _apply_spacing_distortion(visible_slice, progress)
			_apply_dump_instability(progress, previous_position, previous_title_modulate, previous_history_modulate)
			await get_tree().create_timer(0.04).timeout
		else:
			chars_revealed += current_cps * delta
			visible_slice = revealed_text.substr(0, int(chars_revealed))
			history.text = base_text + _apply_spacing_distortion(visible_slice, progress)
			_apply_dump_instability(progress, previous_position, previous_title_modulate, previous_history_modulate)
			await get_tree().process_frame

	history.text = base_text + revealed_text + "\n\n[STREAM END]\n"
	_breakdown_active = true
	breakdown_started.emit(self)
	await _play_breakdown(base_text + revealed_text + "\n\n[STREAM END]\n", max_cps)
	
	title_bar.modulate = previous_title_modulate
	title_text.text = previous_title_text
	history.modulate = previous_history_modulate
	position = previous_position
	_dump_in_progress = false
	dump_finished.emit()

func stop_breakdown() -> void:
	_breakdown_active = false

func _apply_dump_instability(
	progress: float,
	base_position: Vector2,
	base_title_modulate: Color,
	base_history_modulate: Color
) -> void:
	var jitter_strength := lerpf(0.0, 9.0, progress * progress)
	var jitter_x := randf_range(-jitter_strength, jitter_strength)
	var jitter_y := randf_range(-jitter_strength * 0.6, jitter_strength * 0.6)
	position = base_position + Vector2(jitter_x, jitter_y)

	var flicker_gate := progress > 0.22 and randf() < lerpf(0.03, 0.28, progress)
	if flicker_gate:
		title_bar.modulate = Color(
			randf_range(1.1, 1.9),
			randf_range(0.22, 0.65),
			randf_range(0.22, 0.65),
			1.0
		)
	else:
		title_bar.modulate = base_title_modulate.lerp(Color(1.45, 0.35, 0.35, 1.0), minf(1.0, 0.35 + progress * 0.5))

	var tint_mix := clampf(progress * 0.65, 0.0, 0.65)
	var target_history_modulate := Color(
		randf_range(0.85, 1.15),
		randf_range(0.9, 1.25),
		randf_range(0.9, 1.25),
		1.0
	)
	history.modulate = base_history_modulate.lerp(target_history_modulate, tint_mix)

func _apply_spacing_distortion(text: String, progress: float) -> String:
	if progress < 0.3 or text.is_empty():
		return text

	var distortion_strength := clampf((progress - 0.3) / 0.7, 0.0, 1.0)
	var step := maxi(3, int(round(10.0 - distortion_strength * 6.0)))
	var out := ""
	var visible_index := 0
	for i in range(text.length()):
		var ch := text[i]
		out += ch
		if ch == " " or ch == "\n" or ch == "\t":
			continue
		visible_index += 1
		if visible_index % step != 0:
			continue
		out += " " if distortion_strength < 0.6 else "\u200A"
		if distortion_strength > 0.8 and visible_index % (step * 2) == 0:
			out += "\u200A"
	return out

func _play_breakdown(base_text: String, max_cps: float) -> void:
	var working_text := base_text
	while _breakdown_active:
		var line := _generate_breakdown_line()
		working_text += line + "\n"
		history.text = working_text
		_apply_dump_instability(1.0, position, title_bar.modulate, history.modulate)
		var line_cps := maxf(80.0, max_cps)
		var line_delay := clampf(float(line.length()) / line_cps, 0.015, 0.09)
		await get_tree().create_timer(line_delay).timeout

func _generate_breakdown_line() -> String:
	var line_length := randi_range(10, 30)
	var out := ""
	for _i in range(line_length):
		out += BREAKDOWN_CHARSET[randi() % BREAKDOWN_CHARSET.length()]
	return out
