class_name RunDefinition extends RefCounted

const BASIC_CAMERA := preload("res://Resources/SignalPrefabs/basic_camera.tres")
const BASIC_DRONE := preload("res://Resources/SignalPrefabs/basic_drone.tres")
const BASIC_DOOR := preload("res://Resources/SignalPrefabs/basic_door.tres")
const BASIC_GUARD := preload("res://Resources/SignalPrefabs/basic_guard.tres")
const BASIC_DISRUPTOR := preload("res://Resources/SignalPrefabs/basic_disruptor.tres")
const BASIC_TERMINAL := preload("res://Resources/SignalPrefabs/basic_terminal.tres")
const PANNING_CAMERA := preload("res://Resources/SignalPrefabs/panning_camera.tres")
const COMBAT_DRONE := preload("res://Resources/SignalPrefabs/combat_drone.tres")


func get_run_id() -> String:
	return ""

func get_display_name() -> String:
	return get_run_id()

func get_spawns() -> Array[Dictionary]:
	return []

# Overrides: lane, display_name, spoof_id, facing_deg, puzzle, ic_modules, add_ic_modules,
# response, add_response_effects, mobility, patrol_points, detection, detection_patrol_points, disruptor
# `patrol_points` are authored as offsets relative to this spawn's base cell_index and resolved lane.
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
	if spawn.has("facing_deg"):
		runtime_signal.facing_deg = float(spawn["facing_deg"])
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
	if spawn.has("detection"):
		runtime_signal.detection = spawn["detection"].duplicate(true)
	if runtime_signal.detection != null and spawn.has("vision_angle_deg"):
		runtime_signal.detection.vision_angle_deg = float(spawn["vision_angle_deg"])
	if runtime_signal.detection != null and spawn.has("vision_length_cells"):
		runtime_signal.detection.vision_length_cells = float(spawn["vision_length_cells"])
	if runtime_signal.detection != null and spawn.has("watch_offset_cells"):
		runtime_signal.detection.watch_offset_cells = float(spawn["watch_offset_cells"])
	if runtime_signal.detection != null and spawn.has("detection_threat_state"):
		runtime_signal.detection.threat_state = int(spawn["detection_threat_state"])
	if spawn.has("detection_patrol_points"):
		_override_detection_patrol_points(runtime_signal, spawn["detection_patrol_points"])
	if spawn.has("mobility"):
		runtime_signal.mobility = spawn["mobility"].duplicate(true)
	if spawn.has("patrol_points"):
		_override_patrol_points(runtime_signal, spawn, spawn["patrol_points"])
	if spawn.has("disruptor"):
		runtime_signal.disruptor = spawn["disruptor"].duplicate(true)

	return runtime_signal

func make_puzzle(
	puzzle_type: PuzzleComponent.Type,
	difficulty: int = 1,
	encryption_key: String = "",
	puzzle_config: Resource = null
) -> PuzzleComponent:
	var puzzle := PuzzleComponent.new()
	puzzle.puzzle_type = puzzle_type
	puzzle.difficulty = difficulty
	puzzle.encryption_key = encryption_key
	if puzzle_config != null:
		puzzle.puzzle_config = puzzle_config.duplicate(true)
	puzzle.ensure_initial_lock_state()
	return puzzle

func make_sniff_puzzle(difficulty: int = 1, sniff_config: SniffPuzzleConfig = null) -> PuzzleComponent:
	return make_puzzle(PuzzleComponent.Type.SNIFF, difficulty, "", sniff_config)

func make_fuzz_puzzle(difficulty: int = 1) -> PuzzleComponent:
	return make_puzzle(PuzzleComponent.Type.FUZZ, difficulty)

func make_decrypt_puzzle(difficulty: int = 1, encryption_key: String = "", decrypt_config: DecryptPuzzleConfig = null) -> PuzzleComponent:
	return make_puzzle(PuzzleComponent.Type.DECRYPT, difficulty, encryption_key, decrypt_config)

func make_ic(modules: Array[Resource] = []) -> ICComponent:
	var ic := ICComponent.new()
	ic.modules.assign(modules)
	return ic

func make_reboot_module(reboot_time: float = 5.0) -> RebootModule:
	var module := RebootModule.new()
	module.reboot_time = reboot_time
	return module

func make_faraday_module(max_runner_distance_cells: float = 2.0) -> FaradayModule:
	var module := FaradayModule.new()
	module.max_runner_distance_cells = max_runner_distance_cells
	return module

func make_reboot_ic(reboot_time: float = 5.0) -> ICComponent:
	return make_ic([make_reboot_module(reboot_time)])

func make_faraday_ic(max_runner_distance_cells: float = 2.0) -> ICComponent:
	return make_ic([make_faraday_module(max_runner_distance_cells)])

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
	cell_offset: float,
	lane_offset: int,
	dwell_sec: float = 0.0,
	facing_deg: float = 180.0
) -> MobilityPatrolPoint:
	var point := MobilityPatrolPoint.new()
	point.cell_x = cell_offset
	point.lane = lane_offset
	point.dwell_sec = dwell_sec
	point.facing_deg = facing_deg
	return point

func make_detection_patrol_point(facing_deg: float, dwell_sec: float = 0.0) -> DetectionPatrolPoint:
	var point := DetectionPatrolPoint.new()
	point.facing_deg = facing_deg
	point.dwell_sec = dwell_sec
	return point

func make_detection_sweep(point1: Array[float], point2: Array[float], point3: Array[float] = [], point4: Array[float] = []) -> Array[DetectionPatrolPoint]:
	var route: Array[DetectionPatrolPoint] = []
	route.append(make_detection_patrol_point(point1[0], point1[1]))
	route.append(make_detection_patrol_point(point2[0], point2[1]))
	if not point3.is_empty():
		route.append(make_detection_patrol_point(point3[0], point3[1]))
	if not point4.is_empty():
		route.append(make_detection_patrol_point(point4[0], point4[1]))
	return route

# Patrol route points are authored as [cell_offset, lane_offset, dwell_sec, facing_deg].
func make_patrol_route(point1: Array[float], point2: Array[float], point3: Array[float] = [], point4: Array[float] = []) -> Array[MobilityPatrolPoint]:
	var route: Array[MobilityPatrolPoint]= []
	route.append(make_patrol_point(point1[0], int(point1[1]), point1[2], point1[3]))
	route.append(make_patrol_point(point2[0], int(point2[1]), point2[2], point2[3]))
	if not point3.is_empty():
		route.append(make_patrol_point(point3[0], int(point3[1]), point3[2], point3[3]))
	if not point4.is_empty():
		route.append(make_patrol_point(point4[0], int(point4[1]), point4[2], point4[3]))
	return route

func _override_patrol_points(runtime_signal: SignalData, spawn: Dictionary, patrol_points: Array[MobilityPatrolPoint]) -> void:
	if runtime_signal.mobility == null:
		runtime_signal.mobility = MobilityComponent.new()

	var base_cell_x := float(spawn["cell_index"])
	var base_lane := runtime_signal.lane
	runtime_signal.mobility.patrol_points.clear()
	for point in patrol_points:
		if point == null:
			continue
		var resolved_point := point.duplicate(true) as MobilityPatrolPoint
		resolved_point.cell_x = base_cell_x + point.cell_x
		resolved_point.lane = base_lane + point.lane
		runtime_signal.mobility.patrol_points.append(resolved_point)

func _override_detection_patrol_points(runtime_signal: SignalData, patrol_points: Array[DetectionPatrolPoint]) -> void:
	if runtime_signal.detection == null:
		runtime_signal.detection = DetectionComponent.new()

	runtime_signal.detection.patrol_points.clear()
	runtime_signal.detection.follow_movement_facing = false
	for point in patrol_points:
		if point == null:
			continue
		runtime_signal.detection.patrol_points.append(point.duplicate(true))

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
