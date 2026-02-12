class_name SignalSpawner extends Resource

var base_camera_heat: Resource = preload("res://Resources/ResponseEffects/base_camera_heat.tres")
var door_base: Resource = preload("res://Resources/ResponseEffects/door_base.tres")


func create_test_cam(id, lane):
	var cam = SignalData.new()
	cam.type = SignalData.Type.CAMERA
	cam.lane = lane
	cam.system_id = "cam_" + id

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

func create_test_door(id, lane):
	var door = SignalData.new()
	door.type = SignalData.Type.DOOR
	door.lane = lane
	door.system_id = "door_" + id

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

	var p0 := MobilityPatrolPoint.new()
	p0.cell_x = start_cell
	p0.lane = lane
	p0.dwell_sec = 2.0

	var p1 := MobilityPatrolPoint.new()
	p1.cell_x = start_cell + 1.5
	p1.lane = clampi(lane, 0, 4)
	p1.dwell_sec = 2.0

	var p2 := MobilityPatrolPoint.new()
	p2.cell_x = start_cell + 1.5
	p2.lane = clampi(lane + 1, 0, 4)
	p2.dwell_sec = 2.0

	var p3 := MobilityPatrolPoint.new()
	p3.cell_x = start_cell
	p3.lane = clampi(lane + 1, 0, 4)
	p3.dwell_sec = 2.0

	mobility.patrol_points = [p0, p1, p2, p3]
	guard.mobility = mobility

	return guard
