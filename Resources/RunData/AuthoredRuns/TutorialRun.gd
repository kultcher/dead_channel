extends RunDefinition

func get_run_id() -> String:
	return "tutorial"

func get_display_name() -> String:
	return "tutorial"

func get_spawns() -> Array[Dictionary]:
	return [
		spawn(BASIC_CAMERA, 3.5) \
			.id("cam_00") \
			.lane(0) \
			.facing(-10) \
			.build(),

		spawn(BASIC_CAMERA, 4.5) \
			.id("cam_01") \
			.lane(2) \
			.build(),

		spawn(BASIC_DOOR, 6.5) \
			.lane(2) \
			.add_puzzle("sniff", 1) \
			.build(),

		spawn(PANNING_CAMERA, 11.5) \
			.id("cam_02") \
			.lane(3) \
			.add_ic_custom("reboot", {"reboot_time": 10.0}) \
			.build(),

		spawn(BASIC_DRONE, 14.5) \
			.id("drone_01") \
			.lane(3) \
			.add_ic_custom("reboot", {"reboot_time": 3.0}) \
			.patrol([0.0, -2, 1, 0], [1.0, -2, 1, 0], [1.0, 0, 1, 0], [0.0, 0, 1, 0]) \
			.build(),

		spawn(BASIC_DISRUPTOR, 14.5) \
			.id("coolant_vent_01") \
			.lane(4) \
			.build(),
		
		# pre-lab gauntlet (38.5 - 59.5)
		# top-lane panning camera, dodgeable with timing
		spawn(PANNING_CAMERA, 20.5) \
			.id("cam_03") \
			.lane(0) \
			.vision(20.0, 1.0) \
			.detection_sweep([-1, 3], [180, 3]) \
			.add_ic_custom("reboot", {"reboot_time": 3.0}) \
			.build(),

		# bottom-lane panning camera, dodgeable with timing
		spawn(PANNING_CAMERA, 23.5) \
			.id("cam_04") \
			.lane(4) \
			.vision(20.0, 1.0) \
			.detection_sweep([1, 3.5], [180, 3.5]) \
			.add_ic_custom("reboot", {"reboot_time": 10.0}) \
			.build(),

		# long-distance patrol drone
		spawn(BASIC_DRONE, 25.0) \
			.id("drone_02") \
			.lane(1) \
			.add_ic_custom("reboot", {"reboot_time": 10.0}) \
			.patrol([0.0, 0, 3, 0], [6.0, 0, 3, 0]) \
			.build(),

		spawn(BASIC_CAMERA, 26.5) \
			.id("cam_05") \
			.lane(0) \
			.vision(20.0, 1.0) \
			.detection_sweep([-1, 3.5], [180, 3.5]) \
			.add_ic_custom("reboot", {"reboot_time": 15.0}) \
			.build(),

		spawn(PANNING_CAMERA, 29.5) \
			.id("cam_06") \
			.lane(4) \
			.vision(20.0, 1.0) \
			.detection_sweep([1, 3.5], [180, 3.5]) \
			.add_ic_custom("reboot", {"reboot_time": 3.0}) \
			.build(),

		# middle-lane front facing camera, can't be avoided without hacking
		spawn(BASIC_CAMERA, 35.5) \
			.id("cam_07") \
			.lane(2) \
			.vision(20.0, 1.0) \
			.add_ic_custom("reboot", {"reboot_time": 10.0}) \
			.add_ic_custom("bouncer", {"time_to_disconnect": 3.0}) \
			.build(),

		spawn(BASIC_DRONE, 31.0) \
			.id("drone_03") \
			.lane(3) \
			.patrol([0.0, 0, 3, 0], [-6, 0, 3, 0]) \
			.build(),

		spawn(BASIC_DISRUPTOR, 27.5) \
			.id("coolant_vent_00") \
			.lane(4) \
			.build(),

		spawn(BASIC_DISRUPTOR, 29.5) \
			.id("breaker_panel_02") \
			.lane(0) \
			.build(),

		spawn(BASIC_DISRUPTOR, 31.5) \
			.id("nano_fabricator_00") \
			.lane(4) \
			.build(),

		spawn(BASIC_DOOR, 40.5) \
			.id("lab_door") \
			.lane(2) \
			.add_puzzle_custom("sniff", {"difficulty": 1, "config": load("res://Resources/PuzzlePrefabs/null_spike_door_puzzle.tres")}) \
			.build(),

		spawn(BASIC_DISRUPTOR, 43.5) \
			.id("coolant_vent_02") \
			.lane(0) \
			.build(),

		spawn(BASIC_DISRUPTOR, 44.5) \
			.id("nano_fabricator_01") \
			.lane(0) \
			.build(),

		spawn(BASIC_DISRUPTOR, 45.5) \
			.id("coolant_vent_04") \
			.lane(0) \
			.build(),

		spawn(BASIC_DISRUPTOR, 43.5) \
			.id("coolant_vent_05") \
			.lane(4) \
			.build(),

		spawn(BASIC_DISRUPTOR, 44.5) \
			.id("nano_fabricator_02") \
			.lane(4) \
			.build(),

		spawn(BASIC_DISRUPTOR, 45.5) \
			.id("coolant_vent_06") \
			.lane(4) \
			.build(),

		spawn(BASIC_TERMINAL, 46.5) \
			.id("null_terminal") \
			.add_puzzle("decrypt", 0) \
			.build(),

		spawn(BASIC_DOOR, 48.5) \
			.id("lab_exit") \
			.lane(2) \
			.build(),

		spawn(BASIC_CAMERA, 55.5) \
			.id("cam_08") \
			.lane(0) \
			.facing(-10) \
			.build(),

		spawn(BASIC_CAMERA, 55.5) \
			.id("cam_09") \
			.lane(4) \
			.facing(10) \
			.build(),

		spawn(COMBAT_DRONE, 57.5) \
			.id("c_drone_01") \
			.lane(2) \
			.patrol([0.0, 0, 1, 0], [-9.0, 0, 1, 0]) \
			.add_puzzle_custom("sniff", {"difficulty": 1, "config": load("res://Resources/PuzzlePrefabs/killer_drone_puzzle.tres")}) \
			.add_ic_custom("faraday", {"max_runner_distance_cells": 2.0}) \
			.build(),

		spawn(BASIC_DISRUPTOR, 54.5) \
			.id("coolant_vent_07") \
			.lane(3) \
			.build(),
		
		# final gauntlet
		spawn(COMBAT_DRONE, 65.5) \
			.id("c_drone_02") \
			.lane(1) \
			.patrol([0.0, -1, 3, 0], [0.0, 2, 3, 0]) \
			.add_ic_custom("faraday", {"max_runner_distance_cells": 3.0}) \
			.build(),

		spawn(COMBAT_DRONE, 67.5) \
			.id("c_drone_03") \
			.lane(2) \
			.patrol([0.0, -1, 3, 0], [0.0, 2, 3, 0]) \
			.add_puzzle("sniff", 1) \
			.build(),

		spawn(BASIC_DISRUPTOR, 68.5) \
			.id("coolant_vent_08") \
			.lane(0) \
			.build(),

		spawn(COMBAT_DRONE, 69.5) \
			.id("c_drone_04") \
			.lane(3) \
			.patrol([0.0, -2, .5, 0], [0.0, 0, .5, 0]) \
			.add_ic_custom("reboot", {"reboot_time": 3.0}) \
			.build(),

		spawn(BASIC_DISRUPTOR, 70.5) \
			.id("nano_fabricator_03") \
			.lane(4) \
			.build(),

		# final obstacle before door
		spawn(COMBAT_DRONE, 71.5) \
			.id("c_drone_05") \
			.lane(4) \
			.patrol([0.0, -4, 3, 0], [0.0, 0, 3, 0]) \
			.add_puzzle("sniff", 1) \
			.build(),
		
		# horizontal patroller
		spawn(COMBAT_DRONE, 71.5) \
			.id("c_drone_06") \
			.lane(2) \
			.patrol([0.0, 0, 1, 0], [-3.0, 0, 1, 0]) \
			.add_ic_custom("reboot", {"reboot_time": 10.0}) \
			.build(),
		
		spawn(BASIC_TERMINAL, 73.5) \
			.id("override_terminal") \
			.build(),
	]
