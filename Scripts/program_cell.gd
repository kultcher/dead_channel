extends VBoxContainer

signal left_clicked(program_id: StringName)
signal right_clicked(program_id: StringName)

const COLOR_LOADING := Color(0.35, 1.0, 0.45, 1.0)
const COLOR_RUNNING := Color(1.0, 0.86, 0.2, 1.0)
const COLOR_CLEANUP := Color(0.84, 0.52, 0.16, 1.0)
const COLOR_IDLE := Color(0.55, 0.55, 0.55, 0.6)

@onready var active_progress: ProgressBar = $ActiveProgramProgress
@onready var active_button: TextureButton = $ActiveProgramButton
@onready var docked_button: TextureButton = $DockedProgramButton

var empty_icon: Texture2D = preload("res://Visuals/Icons/Simple/square.svg")

var program_instance: ProgramInstance = null
var _default_active_icon: Texture2D = null
var _default_docked_icon: Texture2D = null
var _pulse_time := 0.0

func _ready() -> void:
	_default_active_icon = active_button.texture_normal
	_default_docked_icon = docked_button.texture_normal
	active_button.pressed.connect(_on_active_button_pressed)
	docked_button.pressed.connect(_on_docked_button_pressed)
	active_button.gui_input.connect(_on_active_button_gui_input)
	docked_button.gui_input.connect(_on_docked_button_gui_input)

func bind_program(target_program: ProgramInstance) -> void:
	program_instance = target_program
	var display_name := ""
	var description := ""
	var icon: Texture2D = null
	if program_instance != null and program_instance.definition != null:
		display_name = program_instance.get_display_name()
		description = program_instance.get_description()
		icon = program_instance.definition.icon
	#NOTE: Need to rework RAM cost display (or custom tooltip)
	docked_button.tooltip_text = display_name + "\nRAM Cost: " + str(program_instance.definition.get_phase_ram_cost(1)) + "\n" + description
	active_button.tooltip_text = display_name +"\n" + description
	docked_button.texture_normal = icon if icon != null else _default_docked_icon
	active_button.texture_normal = icon if icon != null else _default_active_icon
	set_visual_state(program_instance, _get_total_phase_time(program_instance), 0.0)

func set_visual_state(target_program: ProgramInstance, total_phase_time: float, pulse_time: float) -> void:
	program_instance = target_program
	_pulse_time = pulse_time
	if program_instance == null:
		hide()
		return

	show()
	var state := program_instance.state
	match state:
		ProgramInstance.State.DOCKED:
			_apply_docked_state()
		ProgramInstance.State.LOADING:
			_apply_loading_state(total_phase_time)
		ProgramInstance.State.RUNNING:
			_apply_running_state()
		ProgramInstance.State.CLEANUP:
			_apply_cleanup_state(total_phase_time)

func _apply_docked_state() -> void:
	docked_button.disabled = false
	docked_button.modulate = Color.WHITE
	active_button.disabled = true
	active_button.texture_normal = empty_icon
	active_button.modulate = Color.WHITE
	active_progress.value = 0.0
	active_progress.self_modulate = COLOR_IDLE

func _apply_loading_state(total_phase_time: float) -> void:
	docked_button.visible = true
	docked_button.disabled = true
	docked_button.modulate = Color(1.0, 1.0, 1.0, 0.2)
	active_button.visible = true
	active_button.disabled = true
	active_button.texture_normal = program_instance.definition.icon
	active_button.modulate = Color.WHITE
	active_progress.value = _get_fill_value(total_phase_time)
	active_progress.self_modulate = COLOR_LOADING

func _apply_running_state() -> void:
	docked_button.visible = true
	docked_button.disabled = true
	docked_button.modulate = Color(1.0, 1.0, 1.0, 0.2)
	active_button.visible = true
	active_button.disabled = false
	active_button.modulate = Color.WHITE
	active_progress.value = active_progress.max_value
	var pulse_strength := 0.8 + 0.2 * (0.5 + 0.5 * sin(_pulse_time * 4.0))
	active_progress.self_modulate = Color(
		COLOR_RUNNING.r * pulse_strength,
		COLOR_RUNNING.g * pulse_strength,
		COLOR_RUNNING.b * pulse_strength,
		1.0
	)

func _apply_cleanup_state(total_phase_time: float) -> void:
	docked_button.visible = true
	docked_button.disabled = true
	docked_button.modulate = Color(1.0, 1.0, 1.0, 0.2)
	active_button.visible = true
	active_button.disabled = true
	active_button.modulate = Color.WHITE
	active_progress.value = _get_drain_value(total_phase_time)
	active_progress.self_modulate = COLOR_CLEANUP

func _get_total_phase_time(target_program: ProgramInstance) -> float:
	if target_program == null or target_program.definition == null:
		return 0.0
	match target_program.state:
		ProgramInstance.State.LOADING:
			return target_program.definition.load_time_sec
		ProgramInstance.State.CLEANUP:
			return target_program.definition.cleanup_time_sec if target_program.was_used else target_program.definition.get_cancel_cleanup_time_sec()
		_:
			return 0.0

func _get_fill_value(total_phase_time: float) -> float:
	if total_phase_time <= 0.0 or program_instance == null:
		return active_progress.max_value
	var elapsed := total_phase_time - program_instance.time_remaining_sec
	return clampf((elapsed / total_phase_time) * active_progress.max_value, 0.0, active_progress.max_value)

func _get_drain_value(total_phase_time: float) -> float:
	if total_phase_time <= 0.0 or program_instance == null:
		return 0.0
	return clampf((program_instance.time_remaining_sec / total_phase_time) * active_progress.max_value, 0.0, active_progress.max_value)

func _emit_right_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and program_instance != null:
		right_clicked.emit(program_instance.get_program_id())

func _on_docked_button_pressed() -> void:
	if program_instance != null:
		left_clicked.emit(program_instance.get_program_id())

func _on_active_button_pressed() -> void:
	if program_instance != null:
		left_clicked.emit(program_instance.get_program_id())

func _on_docked_button_gui_input(event: InputEvent) -> void:
	_emit_right_click(event)

func _on_active_button_gui_input(event: InputEvent) -> void:
	_emit_right_click(event)
