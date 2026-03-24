extends RunDefinition

func get_run_id() -> String:
	return "tutorial"

func get_display_name() -> String:
	return "tutorial"

# Overrides: lane, display_name, spoof_id, puzzle, ic_modules, add_ic_modules
# Common helpers from RunDefinition: make_decrypt_puzzle(), make_reboot_module(), make_reboot_ic()
func get_spawns() -> Array[Dictionary]:
	return [
		build_spawn(BASIC_CAMERA, 3.5, {"system_id": "cam_00", "lane": 0, "facing_deg": -10}),
		build_spawn(BASIC_CAMERA, 4.5, {"system_id": "cam_01", "lane": 2}),
		build_spawn(BASIC_DOOR, 6.5, {
			"lane": 2,
			"puzzle": make_sniff_puzzle(1),
		}),
		build_spawn(PANNING_CAMERA, 11.5, {
			"system_id": "cam_02",
			"lane": 3,
			"add_ic_modules": [make_reboot_module(10)]
		}),
		build_spawn(BASIC_DRONE, 14.5, {"system_id": "drone_01", "lane": 3,
		"add_ic_modules": [make_reboot_module(3)],
		"patrol_points": make_patrol_route([14.5, 1, 1, 0], [15.5, 1, 1, 0], [15.5, 3, 1, 0], [14.5, 3, 1, 0])}),
		build_spawn(BASIC_DISRUPTOR, 14.5, {"system_id": "coolant_vent_01", "lane": 4}),
		build_spawn(BASIC_DOOR, 19.5, {"system_id": "lab_door",
			"lane": 2,
			"puzzle": make_sniff_puzzle(1, load("res://Resources/PuzzlePrefabs/null_spike_door_puzzle.tres"))
		}),
		build_spawn(BASIC_DISRUPTOR, 22.5, {"system_id": "coolant_vent_02", "lane": 0}),
		build_spawn(BASIC_DISRUPTOR, 23.5, {"system_id": "nano_fabricator_01", "lane": 0}),
		build_spawn(BASIC_DISRUPTOR, 24.5, {"system_id": "coolant_vent_04", "lane": 0}),
		build_spawn(BASIC_DISRUPTOR, 22.5, {"system_id": "coolant_vent_05", "lane": 4}),
		build_spawn(BASIC_DISRUPTOR, 23.5, {"system_id": "nano_fabricator_02", "lane": 4}),
		build_spawn(BASIC_DISRUPTOR, 24.5, {"system_id": "coolant_vent_06", "lane": 4}),
		build_spawn(BASIC_TERMINAL, 25.5, {"system_id": "null_terminal", "puzzle": make_decrypt_puzzle(0)})
	]
