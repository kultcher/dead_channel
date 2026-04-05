extends PanelContainer

const PROGRAM_CELL_SCENE := preload("res://Scenes/program_cell.tscn")
const RAM_AVAILABLE_MODULATE := Color.WHITE
const RAM_UNAVAILABLE_MODULATE := Color(0.35, 0.35, 0.35, 1.0)

@onready var dock_hbox: HBoxContainer = $DockHBox
@onready var ram_panel: PanelContainer = $DockHBox/RAMPanel
@onready var ram_vbox: VBoxContainer = $DockHBox/RAMPanel/VBoxContainer
@onready var ram_light_template: TextureRect = $DockHBox/RAMPanel/VBoxContainer/RAMLight
@onready var cell_template: Control = $DockHBox/ProgramCell

var _ram_lights: Array[TextureRect] = []
var _program_cells: Dictionary = {}
var _pulse_time := 0.0

func _ready() -> void:
	_prepare_templates()
	_connect_managers()
	_rebuild_ram_lights(RAMManager.total_ram)
	_refresh_ram_lights(RAMManager.get_used_ram(), RAMManager.total_ram)
	_rebuild_cells()
	set_process(true)

func _process(delta: float) -> void:
	_pulse_time += delta
	_refresh_all_cells()

func _prepare_templates() -> void:
	cell_template.hide()
	ram_light_template.hide()

func _connect_managers() -> void:
	if not RAMManager.total_ram_changed.is_connected(_on_total_ram_changed):
		RAMManager.total_ram_changed.connect(_on_total_ram_changed)
	if not RAMManager.ram_usage_changed.is_connected(_on_ram_usage_changed):
		RAMManager.ram_usage_changed.connect(_on_ram_usage_changed)
	if not ProgramManager.program_installed.is_connected(_on_program_structure_changed):
		ProgramManager.program_installed.connect(_on_program_structure_changed)
	if not ProgramManager.program_removed.is_connected(_on_program_removed):
		ProgramManager.program_removed.connect(_on_program_removed)
	if not ProgramManager.program_state_changed.is_connected(_on_program_state_changed):
		ProgramManager.program_state_changed.connect(_on_program_state_changed)

func _rebuild_ram_lights(total_ram: int) -> void:
	for light in _ram_lights:
		if light != null and is_instance_valid(light):
			light.queue_free()
	_ram_lights.clear()

	for i in range(total_ram):
		var light: TextureRect
		if i == 0:
			light = ram_light_template
		else:
			light = ram_light_template.duplicate() as TextureRect
			ram_vbox.add_child(light)
		light.show()
		light.self_modulate = RAM_AVAILABLE_MODULATE
		_ram_lights.append(light)

func _refresh_ram_lights(used_ram: int, total_ram: int) -> void:
	if _ram_lights.size() != total_ram:
		_rebuild_ram_lights(total_ram)
	for i in range(_ram_lights.size()):
		var light := _ram_lights[i]
		if light == null:
			continue
		light.self_modulate = RAM_UNAVAILABLE_MODULATE if i < used_ram else RAM_AVAILABLE_MODULATE

func _rebuild_cells() -> void:
	for cell in _program_cells.values():
		if cell != null and is_instance_valid(cell):
			cell.queue_free()
	_program_cells.clear()

	for program in ProgramManager.get_programs():
		_create_cell(program)
	_refresh_all_cells()

func _create_cell(program: ProgramInstance) -> void:
	if program == null:
		return
	var cell := PROGRAM_CELL_SCENE.instantiate()
	dock_hbox.add_child(cell)
	dock_hbox.move_child(cell, max(0, dock_hbox.get_child_count() - 2))
	cell.left_clicked.connect(_on_program_left_clicked)
	cell.right_clicked.connect(_on_program_right_clicked)
	cell.bind_program(program)
	_program_cells[program.get_program_id()] = cell

func _remove_cell(program_id: StringName) -> void:
	if not _program_cells.has(program_id):
		return
	var cell: Node = _program_cells[program_id]
	_program_cells.erase(program_id)
	if cell != null and is_instance_valid(cell):
		cell.queue_free()

func _refresh_all_cells() -> void:
	for program in ProgramManager.get_programs():
		_refresh_cell(program)

func _refresh_cell(program: ProgramInstance) -> void:
	if program == null:
		return
	var program_id := program.get_program_id()
	if not _program_cells.has(program_id):
		_create_cell(program)
	var cell = _program_cells.get(program_id)
	if cell == null:
		return
	var total_phase_time := _get_total_phase_time(program)
	cell.set_visual_state(program, total_phase_time, _pulse_time)

func _get_total_phase_time(program: ProgramInstance) -> float:
	if program == null or program.definition == null:
		return 0.0
	match program.state:
		ProgramInstance.State.LOADING:
			return program.definition.load_time_sec
		ProgramInstance.State.CLEANUP:
			return program.definition.cleanup_time_sec if program.was_used else program.definition.get_cancel_cleanup_time_sec()
		_:
			return 0.0

func _on_total_ram_changed(total_ram: int) -> void:
	_rebuild_ram_lights(total_ram)
	_refresh_ram_lights(RAMManager.get_used_ram(), total_ram)

func _on_ram_usage_changed(used_ram: int, total_ram: int) -> void:
	_refresh_ram_lights(used_ram, total_ram)

func _on_program_structure_changed(_program: ProgramInstance) -> void:
	_rebuild_cells()

func _on_program_removed(program: ProgramInstance) -> void:
	if program != null:
		_remove_cell(program.get_program_id())
	_refresh_all_cells()

func _on_program_state_changed(program: ProgramInstance, _old_state: int, _new_state: int) -> void:
	_refresh_cell(program)

func _on_program_left_clicked(program_id: StringName) -> void:
	var program := ProgramManager.get_program(program_id)
	if program == null:
		return
	match program.state:
		ProgramInstance.State.DOCKED:
			ProgramManager.request_load(program_id)
		ProgramInstance.State.RUNNING:
			if program.definition != null and program.definition.kind == ProgramDefinition.ProgramKind.ACTIVE and program.definition.is_manual_activation():
				ProgramManager.request_use(program_id)

func _on_program_right_clicked(program_id: StringName) -> void:
	ProgramManager.request_unload(program_id)
