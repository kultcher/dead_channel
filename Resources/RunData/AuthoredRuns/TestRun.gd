extends RunDefinition

func get_run_id() -> String:
	return "test"

func get_display_name() -> String:
	return "test"

# Overrides: lane, display_name, spoof_id, puzzle, ic_modules, add_ic_modules
# Common helpers from RunDefinition: make_decrypt_puzzle(), make_reboot_module(), make_reboot_ic()
func get_spawns() -> Array[Dictionary]:
	return [
		build_spawn(PANNING_CAMERA, 4.5, {
			"system_id": "cam_02",
			"lane": 3,
			"add_ic_modules": [make_reboot_module(10)]
		}),

		build_spawn(BASIC_DOOR, 5.5, {
			"lane": 2,
			"puzzle": make_sniff_puzzle(1),
		}),
		build_spawn(BASIC_DRONE, 6.5, {"system_id": "drone_01", "lane": 3,
		"add_ic_modules": [make_reboot_module(3)],
		"patrol_points": make_patrol_route([8.0, -2, 1, 0], [9.0, -2, 1, 0], [9.0, 0, 1, 0], [8.0, 0, 1, 0])}),
		build_spawn(BASIC_DISRUPTOR, 14.5, {"system_id": "coolant_vent_01", "lane": 4}),
		#build_spawn(BASIC_DOOR, 19.5, {"system_id": "lab_door",
			#"lane": 2,
			#"puzzle": make_sniff_puzzle(1, load("res://Resources/PuzzlePrefabs/null_spike_door_puzzle.tres"))
		#}),
		#build_spawn(BASIC_DISRUPTOR, 22.5, {"system_id": "coolant_vent_02", "lane": 0}),
		#build_spawn(BASIC_DISRUPTOR, 23.5, {"system_id": "nano_fabricator_01", "lane": 0}),
		#build_spawn(BASIC_DISRUPTOR, 24.5, {"system_id": "coolant_vent_04", "lane": 0}),
		#build_spawn(BASIC_DISRUPTOR, 22.5, {"system_id": "coolant_vent_05", "lane": 4}),
		#build_spawn(BASIC_DISRUPTOR, 23.5, {"system_id": "nano_fabricator_02", "lane": 4}),
		#build_spawn(BASIC_DISRUPTOR, 24.5, {"system_id": "coolant_vent_06", "lane": 4}),
		#build_spawn(BASIC_TERMINAL, 25.5, {"system_id": "null_terminal", "puzzle": make_decrypt_puzzle(0)}),
		#build_spawn(BASIC_DOOR, 27.5, {"system_id": "lab_exit",
			#"lane": 2,
		#}),
		#build_spawn(BASIC_CAMERA, 34.5, {"system_id": "cam_05", "lane": 0, "facing_deg": -10}),
		#build_spawn(BASIC_CAMERA, 34.5, {"system_id": "cam_06", "lane": 4, "facing_deg": 10}),
#
		#build_spawn(COMBAT_DRONE, 36.5, {"system_id": "c_drone_01", "lane": 1,
			#"patrol_points": make_patrol_route([0.0, 1, 1, 0], [-9.0, 1, 1, 0]),
			#"puzzle": make_sniff_puzzle(1, load("res://Resources/PuzzlePrefabs/killer_drone_puzzle.tres")),
			#"add_ic_modules": [make_faraday_module(3)]
		#}),
		#build_spawn(BASIC_DISRUPTOR, 33.5, {"system_id": "coolant_vent_07", "lane": 3}),
		#
		#build_spawn(COMBAT_DRONE, 44.5, {"system_id": "c_drone_02", "lane": 1,
			#"patrol_points": make_patrol_route([0.0, -1, 3, 0], [0.0, 2, 3, 0]),
			#"add_ic_modules": [make_faraday_module(3)]}),
#
		#build_spawn(COMBAT_DRONE, 46.5, {"system_id": "c_drone_03", "lane": 2,
			#"patrol_points": make_patrol_route([0.0, -1, 3, 0], [0.0, 2, 3, 0]),
			#"puzzle": make_sniff_puzzle(1)}),
#
		#build_spawn(BASIC_DISRUPTOR, 47.5, {"system_id": "coolant_vent_08", "lane": 0}),
#
		#build_spawn(COMBAT_DRONE, 48.5, {"system_id": "c_drone_04", "lane": 3,
			#"patrol_points": make_patrol_route([0.0, -2, .5, 0], [0.0, 0, .5, 0]),
			#"add_ic_modules": [make_reboot_module(3)]
		#}),
#
		#build_spawn(BASIC_DISRUPTOR, 49.5, {"system_id": "nano_fabricator_03", "lane": 4}),
#
		## final obstacle before door
		#build_spawn(COMBAT_DRONE, 50.5, {
			#"system_id": "c_drone_05", "lane": 4,
			#"patrol_points": make_patrol_route([0.0, -4, 3, 0], [0.0, 0, 3, 0]),
			#"puzzle": make_sniff_puzzle(1)}),
		#
		## horizontal patroller
		#build_spawn(COMBAT_DRONE, 50.5, {"system_id": "c_drone_05", "lane": 2,
			#"patrol_points": make_patrol_route([0.0, 0, 1, 0], [-3.0, 0, 1, 0]),
			#"add_ic_modules": [make_reboot_module(10)],
		#}),
		#
		#build_spawn(BASIC_TERMINAL, 52.5, {"system_id": "override_terminal", "puzzle": make_decrypt_puzzle(1)}),
	]
