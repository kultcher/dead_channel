class_name RunDefinition extends RefCounted

const BASIC_CAMERA := preload("res://Resources/SignalPrefabs/basic_camera.tres")
const BASIC_DOOR := preload("res://Resources/SignalPrefabs/basic_door.tres")
const BASIC_GUARD := preload("res://Resources/SignalPrefabs/basic_guard.tres")
const BASIC_DISRUPTOR := preload("res://Resources/SignalPrefabs/basic_disruptor.tres")

func get_run_id() -> String:
	return ""

func get_display_name() -> String:
	return get_run_id()

func get_spawns() -> Array[Dictionary]:
	return []

func get_tutorial_events() -> Array[TutorialEvent]:
	return []

# Overrides: lane, display_name, spoof_id, puzzle, ic_modules, add_ic_modules,
# response, add_response_effects, mobility, patrol_points, disruptor
func build_spawn(signal_data: SignalData, cell_index: float, overrides: Dictionary = {}) -> Dictionary:
	var spawn := {
		"signal_data": signal_data,
		"cell_index": cell_index,
	}

	for key in overrides.keys():
		spawn[key] = overrides[key]

	return spawn

func build_runtime_signal(spawn: Dictionary) -> SignalData:
	var signal_data: SignalData = spawn["signal_data"]
	var runtime_signal := signal_data.duplicate(true) as SignalData

	if spawn.has("lane"):
		runtime_signal.lane = spawn["lane"]
	if spawn.has("system_id"):
		runtime_signal.system_id = spawn["system_id"]
	if spawn.has("display_name"):
		runtime_signal.display_name = spawn["display_name"]
	if spawn.has("spoof_id"):
		runtime_signal.spoof_id = spawn["spoof_id"]
	if spawn.has("puzzle"):
		runtime_signal.puzzle = spawn["puzzle"].duplicate(true)
	if spawn.has("ic_modules"):
		runtime_signal.ic_modules = spawn["ic_modules"].duplicate(true)
	if spawn.has("add_ic_modules"):
		_append_ic_modules(runtime_signal, spawn["add_ic_modules"])
	if spawn.has("response"):
		runtime_signal.response = spawn["response"].duplicate(true)
	if spawn.has("add_response_effects"):
		_append_response_effects(runtime_signal, spawn["add_response_effects"])
	if spawn.has("mobility"):
		runtime_signal.mobility = spawn["mobility"].duplicate(true)
	if spawn.has("patrol_points"):
		_override_patrol_points(runtime_signal, spawn["patrol_points"])
	if spawn.has("disruptor"):
		runtime_signal.disruptor = spawn["disruptor"].duplicate(true)

	return runtime_signal

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

func make_response(effects: Array[Resource] = []) -> ResponseComponent:
	var response := ResponseComponent.new()
	response.effects.assign(effects)
	return response

func make_response_effect(
	effect_type: ResponseEffect.EffectType,
	amount: float,
	cadence: ResponseEffect.Cadence = ResponseEffect.Cadence.CONTINUOUS,
	delay: float = 0.0,
	sends_alert: bool = false
) -> ResponseEffect:
	var effect := ResponseEffect.new()
	effect.effect_type = effect_type
	effect.amount = amount
	effect.cadence = cadence
	effect.delay = delay
	effect.sends_alert = sends_alert
	return effect

func make_patrol_point(
	cell_x: float,
	lane: int,
	dwell_sec: float = 0.0,
	facing_deg: float = 180.0
) -> MobilityPatrolPoint:
	var point := MobilityPatrolPoint.new()
	point.cell_x = cell_x
	point.lane = lane
	point.dwell_sec = dwell_sec
	point.facing_deg = facing_deg
	return point

func make_patrol_route(point1: Array[float], point2: Array[float], point3: Array[float] = [], point4: Array[float] = []) -> Array[MobilityPatrolPoint]:
	var route: Array[MobilityPatrolPoint]= []
	route.append(make_patrol_point(point1[0], int(point1[1]), point1[2], point1[3]))
	route.append(make_patrol_point(point2[0], int(point2[1]), point2[2], point2[3]))
	if not point3.is_empty():
		route.append(make_patrol_point(point3[0], int(point3[1]), point3[2], point3[3]))
	if not point4.is_empty():
		route.append(make_patrol_point(point4[0], int(point4[1]), point4[2], point4[3]))
	return route

func _override_patrol_points(runtime_signal: SignalData, patrol_points: Array[MobilityPatrolPoint]) -> void:
	if runtime_signal.mobility == null:
		runtime_signal.mobility = MobilityComponent.new()

#	print(patrol_points)

	runtime_signal.mobility.patrol_points.clear()
	for point in patrol_points:
		if point == null:
			continue
		runtime_signal.mobility.patrol_points.append(point.duplicate(true))

func make_mobility(
	patrol_points: Array[MobilityPatrolPoint] = [],
	move_speed_cells_per_sec: float = 0.15,
	patrol_mode: MobilityComponent.PatrolMode = MobilityComponent.PatrolMode.LOOP
) -> MobilityComponent:
	var mobility := MobilityComponent.new()
	mobility.move_speed_cells_per_sec = move_speed_cells_per_sec
	mobility.patrol_mode = patrol_mode
	mobility.patrol_points.assign(patrol_points)
	return mobility

func make_disruptor(
	investigate_duration_sec: float = -1.0,
	horizontal_range_cells: int = 0,
	severity: int = 10,
	ttl_sec: float = -1.0
) -> DisruptorComponent:
	var disruptor := DisruptorComponent.new()
	disruptor.investigate_duration_sec = investigate_duration_sec
	disruptor.horizontal_range_cells = horizontal_range_cells
	disruptor.severity = severity
	disruptor.ttl_sec = ttl_sec
	return disruptor

func _append_ic_modules(runtime_signal: SignalData, modules_to_add: Array) -> void:
	if runtime_signal.ic_modules == null:
		runtime_signal.ic_modules = ICComponent.new()

	for module in modules_to_add:
		if module == null:
			continue
		runtime_signal.ic_modules.add_module(module.duplicate(true))

func _append_response_effects(runtime_signal: SignalData, effects_to_add: Array) -> void:
	if runtime_signal.response == null:
		runtime_signal.response = ResponseComponent.new()

	for effect in effects_to_add:
		if effect == null:
			continue
		runtime_signal.response.effects.append(effect.duplicate(true))


func build_tutorial_event(
	event_id: String,
	event_trigger: TutorialEvent.Trigger,
	event_value: int,
	event_signal_index: int,
	event_text: Array[String],
	event_position: Vector2 = Vector2(),
	event_focus_rect: Rect2 = Rect2(),
	event_objective_text: String = ""
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
	event.objective_text = event_objective_text
	return event
