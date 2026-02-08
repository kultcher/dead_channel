class_name SignalSpawner extends Resource

var base_camera_heat: Resource = preload("res://Resources/ResponseEffects/base_camera_heat.tres")

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

	var puzzle = PuzzleComponent.new()
	cam.puzzle = puzzle
	puzzle.puzzle_type = PuzzleComponent.Type.SNIFF


	var ic = ICComponent.new()
	var reboot = RebootModule.new()
	ic.add_module(reboot)
	cam.ic_modules = ic

	return cam
