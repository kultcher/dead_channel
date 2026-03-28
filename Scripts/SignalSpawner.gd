class_name SignalSpawner extends Resource

var base_camera_heat: Resource = preload("res://Resources/ResponseEffects/base_camera_heat.tres")
var door_base: Resource = preload("res://Resources/ResponseEffects/door_base.tres")
var camera_visuals: SignalVisuals = preload("res://Resources/SignalVisuals/camera_visuals.tres")
var door_visuals: SignalVisuals = preload("res://Resources/SignalVisuals/door_visuals.tres")
var door_unlocked_visuals: SignalVisuals = preload("res://Resources/SignalVisuals/door_unlocked_visuals.tres")
var guard_visuals: SignalVisuals = preload("res://Resources/SignalVisuals/guard_visuals.tres")
var disruptor_visuals: SignalVisuals = preload("res://Resources/SignalVisuals/disruptor_visuals.tres")

func create_test_cam(id, lane):
	var cam = SignalData.new()
	cam.type = SignalData.Type.CAMERA
	cam.lane = lane
	cam.system_id = "cam_" + id
	cam.visuals = camera_visuals

	var detection = DetectionComponent.new()
	detection.watch_offset_cells = 0.0
	detection.vision_length_cells = 1.0
	detection.vision_angle_deg = 30.0
	detection.shape_type = DetectionComponent.ShapeType.CONE
	cam.detection = detection

	var hackable = HackableComponent.new()
	cam.hackable = hackable

	var response = ResponseComponent.new()
	cam.response = response
	response.effects.append(base_camera_heat)

	var ic = ICComponent.new()
	var reboot = RebootModule.new()
	ic.add_module(reboot)
	cam.ic_modules = ic

	return cam

func create_test_drone(id: String, start_cell: float, lane: int) -> SignalData:
	var drone := SignalData.new()
	drone.type = SignalData.Type.DRONE
	drone.lane = lane
	drone.system_id = "drone_" + id
	drone.visuals = camera_visuals

	var detection := DetectionComponent.new()
	detection.watch_offset_cells = 0.0
	detection.vision_length_cells = 0.9
	detection.vision_angle_deg = 20.0
	detection.shape_type = DetectionComponent.ShapeType.CONE
	drone.detection = detection

	var hackable := HackableComponent.new()
	drone.hackable = hackable

	var response := ResponseComponent.new()
	drone.response = response
	response.effects.append(base_camera_heat)

	var ic := ICComponent.new()
	drone.ic_modules = ic

	var mobility := MobilityComponent.new()
	mobility.move_speed_cells_per_sec = 0.15

	var p0 := _make_absolute_patrol_point(start_cell, lane, 0.0, 0, 2.0)
	var p1 := _make_absolute_patrol_point(start_cell, lane, 1.5, 0, 2.0)

	mobility.patrol_points = [p0, p1]
	drone.mobility = mobility

	return drone

func create_test_door(id, lane):
	var door = SignalData.new()
	door.type = SignalData.Type.DOOR
	door.lane = lane
	door.system_id = "door_" + id
	door.visuals = door_visuals
	door.alternate_visuals = door_unlocked_visuals
	door.door_locked = true

	var detection = DetectionComponent.new()
	detection.watch_offset_cells = 0.0
	detection.vision_length_cells = 0.2
	detection.delay	= 3.0
	detection.shape_type = DetectionComponent.ShapeType.CIRCLE
	door.detection = detection

	var hackable = HackableComponent.new()
	door.hackable = hackable

	var puzzle = PuzzleComponent.new()
	door.puzzle = puzzle
	puzzle.puzzle_type = PuzzleComponent.Type.DECRYPT

	var response = ResponseComponent.new()
	door.response = response
	response.effects.append(door_base)

	return door

func create_test_guard(id: String, start_cell: float, lane: int) -> SignalData:
	var guard := SignalData.new()
	guard.type = SignalData.Type.GUARD
	guard.lane = lane
	guard.system_id = "guard_" + id
	guard.visual_state = SignalData.VisualState.HIDDEN
	guard.visuals = guard_visuals

	var detection := DetectionComponent.new()
	detection.shape_type = DetectionComponent.ShapeType.ARC
	detection.watch_offset_cells = 0.0
	detection.vision_length_cells = .5
	detection.vision_angle_deg = 00.0
	detection.vision_segments = 16
	guard.detection = detection

	var response := ResponseComponent.new()
	guard.response = response
	response.effects.append(base_camera_heat)

	var hackable := HackableComponent.new()
	guard.hackable = hackable

	var mobility := MobilityComponent.new()
	mobility.move_speed_cells_per_sec = 0.15

	var p0 := _make_absolute_patrol_point(start_cell, lane, 0.0, 0, 2.0)
	var p1 := _make_absolute_patrol_point(start_cell, lane, 1.5, 0, 2.0)
	var p2 := _make_absolute_patrol_point(start_cell, lane, 1.5, 1, 2.0)
	var p3 := _make_absolute_patrol_point(start_cell, lane, 0.0, 1, 2.0)

	mobility.patrol_points = [p0, p1, p2, p3]
	guard.mobility = mobility

	return guard

func create_test_disruptor(id: String, lane: int) -> SignalData:
	var disruptor := SignalData.new()
	disruptor.type = SignalData.Type.DISRUPTOR
	disruptor.lane = lane
	disruptor.system_id = "disruptor_" + id
	disruptor.visuals = disruptor_visuals

	var hackable := HackableComponent.new()
	disruptor.hackable = hackable

	var disruptor_component := DisruptorComponent.new()
	disruptor.disruptor = disruptor_component

	return disruptor

func _make_absolute_patrol_point(
	base_cell_x: float,
	base_lane: int,
	cell_offset: float,
	lane_offset: int,
	dwell_sec: float = 0.0,
	facing_deg: float = 180.0
) -> MobilityPatrolPoint:
	# These test helpers author patrols with offsets, then immediately resolve them.
	var point := MobilityPatrolPoint.new()
	point.cell_x = base_cell_x + cell_offset
	point.lane = clampi(base_lane + lane_offset, 0, 4)
	point.dwell_sec = dwell_sec
	point.facing_deg = facing_deg
	return point
