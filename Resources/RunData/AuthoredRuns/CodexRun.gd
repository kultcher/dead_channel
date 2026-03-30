extends RunDefinition

func get_run_id() -> String:
	return "codex"

func get_display_name() -> String:
	return "codex"

# A mid-density sample run for feel-testing pacing outside the scripted tutorial.
func get_spawns() -> Array[Dictionary]:
	return [
		# Light opener: scan, door, then a simple timing camera.
		build_spawn(BASIC_CAMERA, 4.5, {
			"system_id": "cam_01",
			"lane": 1,
			"facing_deg": -8,
			"vision_angle_deg": 24,
			"vision_length_cells": 1.0,
		}),
		build_spawn(BASIC_DOOR, 7.5, {
			"system_id": "door_01",
			"lane": 2,
			"puzzle": make_sniff_puzzle(1),
		}),
		build_spawn(PANNING_CAMERA, 10.5, {
			"system_id": "cam_02",
			"lane": 4,
			"vision_angle_deg": 20,
			"vision_length_cells": 1.0,
			"detection_patrol_points": make_detection_sweep([1, 2.5], [180, 2.5]),
			"add_ic_modules": [make_reboot_module(10)],
		}),

		# First pressure bump: a drone with an obvious distraction option.
		build_spawn(BASIC_DRONE, 14.5, {
			"system_id": "drone_01",
			"lane": 1,
			"add_ic_modules": [make_reboot_module(3)],
			"patrol_points": make_patrol_route([0.0, 0, 2.0, 0], [4.0, 0, 2.0, 0]),
		}),
		build_spawn(BASIC_DISRUPTOR, 15.5, {
			"system_id": "coolant_vent_01",
			"lane": 0,
		}),
		build_spawn(BASIC_CAMERA, 18.5, {
			"system_id": "cam_03",
			"lane": 3,
			"vision_angle_deg": 24,
			"vision_length_cells": 1.0,
			"add_ic_modules": [make_reboot_module(10)],
		}),

		# Chill section: straightforward lock plus an optional decrypt terminal.
		build_spawn(BASIC_DOOR, 22.5, {
			"system_id": "door_02",
			"lane": 2,
			"puzzle": make_sniff_puzzle(1),
		}),
		build_spawn(BASIC_TERMINAL, 24.5, {
			"system_id": "archive_terminal_01",
			"lane": 0,
			"puzzle": make_decrypt_puzzle(1),
		}),
		build_spawn(BASIC_CAMERA, 27.5, {
			"system_id": "cam_04",
			"lane": 0,
			"facing_deg": -10,
			"vision_angle_deg": 20,
			"vision_length_cells": 1.0,
		}),

		# First intense cluster: layered cameras + drone + multiple tools.
		build_spawn(PANNING_CAMERA, 29.5, {
			"system_id": "cam_05",
			"lane": 4,
			"vision_angle_deg": 20,
			"vision_length_cells": 1.0,
			"detection_patrol_points": make_detection_sweep([1, 3.0], [180, 3.0]),
			"add_ic_modules": [make_reboot_module(3)],
		}),
		build_spawn(BASIC_DRONE, 31.5, {
			"system_id": "drone_02",
			"lane": 3,
			"add_ic_modules": [make_reboot_module(10)],
			"patrol_points": make_patrol_route([0.0, -2, 2.0, 0], [3.0, -2, 2.0, 0], [3.0, 0, 2.0, 0], [0.0, 0, 2.0, 0]),
		}),
		build_spawn(BASIC_DISRUPTOR, 32.5, {
			"system_id": "fabricator_01",
			"lane": 4,
		}),
		build_spawn(BASIC_DISRUPTOR, 33.5, {
			"system_id": "breaker_panel_01",
			"lane": 1,
		}),
		build_spawn(BASIC_CAMERA, 35.5, {
			"system_id": "cam_06",
			"lane": 2,
			"vision_angle_deg": 20,
			"vision_length_cells": 1.0,
			"add_ic_modules": [make_reboot_module(10)],
		}),

		# Short breather before the final push.
		build_spawn(BASIC_DOOR, 39.5, {
			"system_id": "door_03",
			"lane": 2,
			"puzzle": make_sniff_puzzle(1),
		}),

		# Final push: one armed drone, a support drone, moving vision, and nearby answers.
		build_spawn(BASIC_DISRUPTOR, 40.5, {
			"system_id": "coolant_vent_02",
			"lane": 1,
		}),
		build_spawn(COMBAT_DRONE, 42.5, {
			"system_id": "attack_drone_01",
			"lane": 3,
			"patrol_points": make_patrol_route([0.0, -2, 1.5, 0], [-4.0, -2, 1.5, 0]),
			"puzzle": make_sniff_puzzle(1, load("res://Resources/PuzzlePrefabs/killer_drone_puzzle.tres")),
			"add_ic_modules": [make_faraday_module(2)],
		}),
		build_spawn(PANNING_CAMERA, 44.5, {
			"system_id": "cam_07",
			"lane": 0,
			"vision_angle_deg": 20,
			"vision_length_cells": 1.0,
			"detection_patrol_points": make_detection_sweep([-1, 2.5], [180, 2.5]),
			"add_ic_modules": [make_reboot_module(3)],
		}),
		build_spawn(BASIC_DRONE, 47.5, {
			"system_id": "drone_03",
			"lane": 4,
			"patrol_points": make_patrol_route([0.0, 0, 1.0, 0], [-2.0, -1, 1.0, 0], [0.0, -2, 1.0, 0]),
		}),
		build_spawn(BASIC_DISRUPTOR, 48.5, {
			"system_id": "nano_fabricator_01",
			"lane": 2,
		}),
		build_spawn(BASIC_DOOR, 51.5, {
			"system_id": "exit_door",
			"lane": 2,
		}),
	]
