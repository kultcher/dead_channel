extends RunDefinition

func get_run_id() -> String:
	return "codex"

func get_display_name() -> String:
	return "codex"

# A mid-density sample run for feel-testing pacing outside the scripted tutorial.
func get_spawns() -> Array[Dictionary]:
	return [
		spawn(BASIC_CAMERA, 4.5) \
			.id("cam_01") \
			.lane(1) \
			.facing(-8) \
			.vision(24.0, 1.0) \
			.build(),

		spawn(BASIC_TERMINAL, 7.5) \
			.id("archive_terminal_01") \
			.lane(0) \
			.add_puzzle("decrypt", 1) \
			.build(),

		spawn(BASIC_DOOR, 7.5) \
			.id("door_01") \
			.lane(2) \
			.add_puzzle("sniff", 1) \
			.build(),

		spawn(PANNING_CAMERA, 10.5) \
			.id("cam_02") \
			.lane(4) \
			.vision(20.0, 1.0) \
			.detection_sweep([1, 2.5], [180, 2.5]) \
			.add_ic_custom("reboot", {"reboot_time": 10.0}) \
			.build(),

		# First pressure bump: a drone with an obvious distraction option.
		spawn(BASIC_DRONE, 14.5) \
			.id("drone_01") \
			.lane(1) \
			.add_ic_custom("reboot", {"reboot_time": 3.0}) \
			.patrol([0.0, 0, 2.0, 0], [4.0, 0, 2.0, 0]) \
			.build(),

		spawn(BASIC_DISRUPTOR, 15.5) \
			.id("coolant_vent_01") \
			.lane(0) \
			.build(),

		spawn(BASIC_CAMERA, 18.5) \
			.id("cam_03") \
			.lane(3) \
			.vision(24.0, 1.0) \
			.add_ic_custom("reboot", {"reboot_time": 10.0}) \
			.build(),

		# Chill section: straightforward lock plus an optional decrypt terminal.
		spawn(BASIC_DOOR, 22.5) \
			.id("door_02") \
			.lane(2) \
			.add_puzzle("sniff", 1) \
			.build(),

		spawn(BASIC_TERMINAL, 24.5) \
			.id("archive_terminal_02") \
			.lane(0) \
			.add_puzzle("decrypt", 1) \
			.build(),

		spawn(BASIC_CAMERA, 27.5) \
			.id("cam_04") \
			.lane(0) \
			.facing(-10) \
			.vision(20.0, 1.0) \
			.build(),

		# First intense cluster: layered cameras + drone + multiple tools.
		spawn(PANNING_CAMERA, 29.5) \
			.id("cam_05") \
			.lane(4) \
			.vision(20.0, 1.0) \
			.detection_sweep([1, 3.0], [180, 3.0]) \
			.add_ic_custom("reboot", {"reboot_time": 3.0}) \
			.build(),

		spawn(BASIC_DRONE, 31.5) \
			.id("drone_02") \
			.lane(3) \
			.add_ic_custom("reboot", {"reboot_time": 10.0}) \
			.patrol([0.0, -2, 2.0, 0], [3.0, -2, 2.0, 0], [3.0, 0, 2.0, 0], [0.0, 0, 2.0, 0]) \
			.build(),

		spawn(BASIC_DISRUPTOR, 32.5) \
			.id("fabricator_01") \
			.lane(4) \
			.build(),

		spawn(BASIC_DISRUPTOR, 33.5) \
			.id("breaker_panel_01") \
			.lane(1) \
			.build(),

		spawn(BASIC_CAMERA, 35.5) \
			.id("cam_06") \
			.lane(2) \
			.vision(20.0, 1.0) \
			.add_ic_custom("reboot", {"reboot_time": 10.0}) \
			.build(),

		# Short breather before the final push.
		spawn(BASIC_DOOR, 39.5) \
			.id("door_03") \
			.lane(2) \
			.add_puzzle("sniff", 1) \
			.build(),

		# Final push: one armed drone, a support drone, moving vision, and nearby answers.
		spawn(BASIC_DISRUPTOR, 40.5) \
			.id("coolant_vent_02") \
			.lane(1) \
			.build(),

		spawn(COMBAT_DRONE, 42.5) \
			.id("attack_drone_01") \
			.lane(3) \
			.patrol([0.0, -2, 1.5, 0], [-4.0, -2, 1.5, 0]) \
			.add_puzzle_custom("sniff", {"difficulty": 1, "config": load("res://Resources/PuzzlePrefabs/killer_drone_puzzle.tres")}) \
			.add_ic_custom("faraday", {"max_runner_distance_cells": 2.0}) \
			.build(),

		spawn(PANNING_CAMERA, 44.5) \
			.id("cam_07") \
			.lane(0) \
			.vision(20.0, 1.0) \
			.detection_sweep([-1, 2.5], [180, 2.5]) \
			.add_ic_custom("reboot", {"reboot_time": 3.0}) \
			.build(),

		spawn(BASIC_DRONE, 47.5) \
			.id("drone_03") \
			.lane(4) \
			.patrol([0.0, 0, 1.0, 0], [-2.0, -1, 1.0, 0], [0.0, -2, 1.0, 0]) \
			.build(),

		spawn(BASIC_DISRUPTOR, 48.5) \
			.id("nano_fabricator_01") \
			.lane(2) \
			.build(),

		spawn(BASIC_DOOR, 51.5) \
			.id("exit_door") \
			.lane(2) \
			.build(),
	]
