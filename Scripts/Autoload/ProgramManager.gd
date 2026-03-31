extends Node

signal total_ram_changed(total_ram: int)
signal ram_usage_changed(used_ram: int, total_ram: int)
signal program_installed(program_instance: ProgramInstance)
signal program_removed(program_instance: ProgramInstance)
signal program_state_changed(program_instance: ProgramInstance, old_state: int, new_state: int)

@export var total_ram: int = 3:
	set(value):
		total_ram = maxi(0, value)
		total_ram_changed.emit(total_ram)
		_emit_ram_usage_changed()

var _programs: Array[ProgramInstance] = []

func _ready() -> void:
	if not total_ram_changed.is_connected(GlobalEvents.program_total_ram_changed.emit):
		total_ram_changed.connect(GlobalEvents.program_total_ram_changed.emit)
	if not ram_usage_changed.is_connected(GlobalEvents.program_ram_changed.emit):
		ram_usage_changed.connect(GlobalEvents.program_ram_changed.emit)
	if not program_installed.is_connected(GlobalEvents.program_installed.emit):
		program_installed.connect(GlobalEvents.program_installed.emit)
	if not program_removed.is_connected(GlobalEvents.program_removed.emit):
		program_removed.connect(GlobalEvents.program_removed.emit)
	if not program_state_changed.is_connected(GlobalEvents.program_state_changed.emit):
		program_state_changed.connect(GlobalEvents.program_state_changed.emit)

	total_ram_changed.emit(total_ram)
	_emit_ram_usage_changed()

func _process(delta: float) -> void:
	for program in _programs:
		if program == null:
			continue
		var old_state := program.state
		if program.tick(delta):
			program_state_changed.emit(program, old_state, program.state)
			_emit_ram_usage_changed()

func install_program(definition: ProgramDefinition) -> ProgramInstance:
	if definition == null:
		return null
	var instance := ProgramInstance.new(definition)
	_programs.append(instance)
	program_installed.emit(instance)
	return instance

func remove_program(program_id: StringName) -> bool:
	var instance := get_program(program_id)
	if instance == null:
		return false
	_programs.erase(instance)
	program_removed.emit(instance)
	_emit_ram_usage_changed()
	return true

func get_program(program_id: StringName) -> ProgramInstance:
	for program in _programs:
		if program != null and program.get_program_id() == program_id:
			return program
	return null

func get_programs() -> Array[ProgramInstance]:
	return _programs.duplicate()

func request_load(program_id: StringName) -> bool:
	var program := get_program(program_id)
	if program == null or program.state != ProgramInstance.State.DOCKED:
		return false
	if not _can_afford_state_transition(program, ProgramInstance.State.LOADING):
		return false

	var old_state := program.state
	program.begin_loading()
	program_state_changed.emit(program, old_state, program.state)
	_emit_ram_usage_changed()
	return true

func request_unload(program_id: StringName) -> bool:
	var program := get_program(program_id)
	if program == null:
		return false
	match program.state:
		ProgramInstance.State.LOADING, ProgramInstance.State.RUNNING:
			var old_state := program.state
			program.begin_cleanup(program.was_used)
			program_state_changed.emit(program, old_state, program.state)
			_emit_ram_usage_changed()
			return true
		_:
			return false

func mark_program_used(program_id: StringName) -> bool:
	var program := get_program(program_id)
	if program == null or program.state != ProgramInstance.State.RUNNING:
		return false

	program.mark_used()
	var old_state := program.state
	program.begin_cleanup(true)
	program_state_changed.emit(program, old_state, program.state)
	_emit_ram_usage_changed()
	return true

func get_used_ram() -> int:
	var used_ram := 0
	for program in _programs:
		if program == null:
			continue
		used_ram += program.get_current_ram_cost()
	return used_ram

func get_available_ram() -> int:
	return maxi(0, total_ram - get_used_ram())

func preprocess_action(action_context: ActionContext) -> void:
	for program in _programs:
		if program == null:
			continue
		program.preprocess_action(action_context)

func postprocess_action(action_context: ActionContext) -> void:
	for program in _programs:
		if program == null:
			continue
		program.postprocess_action(action_context)

func _can_afford_state_transition(program: ProgramInstance, target_state: int) -> bool:
	if program == null or program.definition == null:
		return false
	var target_cost := program.definition.get_phase_ram_cost(target_state)
	var projected_ram := get_used_ram() - program.get_current_ram_cost() + target_cost
	return projected_ram <= total_ram

func _emit_ram_usage_changed() -> void:
	ram_usage_changed.emit(get_used_ram(), total_ram)
