extends RunDefinition

func get_run_id() -> String:
	return "tutorial"

func get_display_name() -> String:
	return "tutorial"

# Overrides: lane, display_name, spoof_id, puzzle, ic_modules, add_ic_modules
# Common helpers from RunDefinition: make_decrypt_puzzle(), make_reboot_module(), make_reboot_ic()
func get_spawns() -> Array[Dictionary]:
	return [
		build_spawn(BASIC_CAMERA, 6.5, {"lane": 2}),
		build_spawn(BASIC_DOOR, 8.5, {
			"lane": 2,
			"puzzle": make_decrypt_puzzle(1),
		}),
		build_spawn(BASIC_CAMERA, 14.5, {"system_id": "cam_02", "lane": 2, "add_ic_modules": [make_reboot_module(15.0)]}),
		build_spawn(BASIC_CAMERA, 20.5, {"system_id": "cam_03", "lane": 4}),
		build_spawn(BASIC_GUARD, 21.5, {"system_id": "guard_01", "lane": 0,
			"patrol_points": make_patrol_route([21.5, 0, 4.0, 90.0], [21.5, 4, 4.0, 90.0])
		}),
		build_spawn(BASIC_DISRUPTOR, 22.5, {"system_id": "vend_01", "lane": 0}),
		
		# Gauntlet
		build_spawn(BASIC_CAMERA, 31.5, {"system_id": "cam_03", "lane": 2, "add_ic_modules": [make_reboot_module(15.0)]}),
		build_spawn(BASIC_DOOR, 32.5, {
			"system_id": "door_02",
			"lane": 2,
			"puzzle": make_decrypt_puzzle(1),
		}),		build_spawn(BASIC_CAMERA, 33.5, {"lane": 4}),
		build_spawn(BASIC_GUARD, 34.5, {"system_id": "guard_02", "lane": 0,
			"patrol_points": make_patrol_route([34.5, 0, 4.0, 90.0], [34.5, 4, 4.0, 90.0], [35.5, 4, 4.0, 90.0], [35.5, 0, 4.0, 90.0])
		}),
		build_spawn(BASIC_DISRUPTOR, 34.5, {"system_id": "vend_02", "lane": 4}),
		build_spawn(BASIC_CAMERA, 36.5, {"system_id": "cam_04", "lane": 1}),
		build_spawn(BASIC_CAMERA, 36.5, {"system_id": "cam_05r","lane": 3, "add_ic_modules": [make_reboot_module(15.0)]}),
	]

func get_tutorial_events() -> Array[TutorialEvent]:
	var events: Array[TutorialEvent] = []

	events.append(build_tutorial_event(
		"first_signal",
		TutorialEvent.Trigger.CELL_REACHED,
		1,
		0,
		[
			"This is a SIGNAL. Signals represent all the networked devices in the facility.",
			"The shape of the signal can tell you what of device it is, but you can learn more information by SCANNING the signal.",
			"To SCAN a signal, hold the mouse over it. Keep scanning this signal until all of its info is revealed."
		],
		Vector2(),
		Rect2(),
		"Mouseover the cam_01 signal to scan it."
	))

	events.append(build_tutorial_event(
		"first_scan",
		TutorialEvent.Trigger.SCAN_COMPLETE,
		-1,
		0,
		[
			"Scanning this Signal has revealed it's type, it's access parameters and any IC (Intrusion Countermeasures) on the Signal. You don't have to Scan a Signal to hack it, but it's worth it if you have the time.",
			"Since it's ACCESS type is open and there's no IC, hacking it will be a breeze. Click on the signal to connect to it."
		],
		Vector2(),
		Rect2(),
		"Left-click on the camera signal to connect to the camera."
	))

	events.append(build_tutorial_event(
		"terminal_intro",
		TutorialEvent.Trigger.SIGNAL_CONNECT,
		-1,
		-1,
		[
			"You're connected to the camera, now let's take it out. There are a few different ways to deal with obstacles like these, but for now, we're going to do it fast and loud: with KILL.",
			"Note that each signal has it's own terminal session. You can connect to multiple signals and use the tabs to switch between them.",
			"Since you're already connected to the signal, all you have to do is type KILL and hit enter.",
		],
		Vector2(),
		Rect2(),
		"Type KILL in the terminal (make sure you're in the cam_01 session!)"
	))

	events.append(build_tutorial_event(
		"heat_intro",
		TutorialEvent.Trigger.SIGNAL_KILLED,
		-1,
		-1,
		[
			"KILL is easy, but it's not subtle. See how your HEAT gauge spiked?",
			"Too much HEAT can cause you all kinds of problems down the line, so don't just KILL every signal.",
			"HEAT is also gained by any other action or consequence that causes unwanted attention on the team. If they get spotted by a camera, have to take out a guard or blow a door, that'll build heat too.",
			"Now that the camera's blind, scan the upcoming door signal and see what we need to crack it."
		],
		Vector2(200, 700),
		Rect2(16, 812, 128, 252),
		"Mouseover to scan the door_01 signal."
	))

	events.append(build_tutorial_event(
		"decrypt_intro",
		TutorialEvent.Trigger.SCAN_COMPLETE,
		-1,
		1,
		[
			"This door has an Encrypted lock, so we can't do anything with it until we decrypt it.",
			"Connect to the door and type RUN DECRYPT in the terminal to boot up your DECRYPT program."
		],
		Vector2(),
		Rect2(),
		"Left click the door_01 signal to connect to the door.\nType RUN DECRYPT to start the decryption program."
	))


	events.append(build_tutorial_event(
		"decrypt_continued",
		TutorialEvent.Trigger.PUZZLE_STARTED,
		int(PuzzleComponent.Type.DECRYPT),
		-1,
		[
			"Decrypt can break any encryption by itself eventually. But that takes time you probably won't have on a real run.",
			"Take a look at the KEYSPACE sections. They show all the possible characters that might fit the cipher. As DECRYPT does its work, it'll cull one or more possibilities from each KEYSPACE.",
			"You can also help it along by using deduction or just brute-force guessing. Guess right and you optimize the algorithm, making the next cull come faster.",
			"Lastly, if you click on a keyspace, it will focus the culling process on that keyspace. See if you can crack this one before the runners reach the door.",
			"Every cipher is based on a simple rule, so if you can intuit them, you can crack it quickly."
		],
		Vector2(300, 500),
		Rect2(),
		"Solve the DECRYPT puzzle before the runners reach the door."
	))

	events.append(build_tutorial_event(
		"decrypt_complete",
		TutorialEvent.Trigger.PUZZLE_SOLVED,
		-1,
		1,
		[
			"Now we have access. Let's unlock the door for the team. You can do that with the OP command.",
			"The OP command is contextual and behaves differently depending on the type of signal you're connected to. For doors it locks and unlocks them."
		],
		Vector2(),
		Rect2(),
		"Type OP in the terminal to open the door and continue deeper into the facility."
	))

	events.append(build_tutorial_event(
		"ic_intro",
		TutorialEvent.Trigger.CELL_REACHED,
		8,
		2,
		[
			"Another camera. This one is a bit trickier. If you scan it, you'll see it's OPEN to hacking like the first one, but there's also IC: Reboot.",
			"Reboot will re-enable the signal after a short delay if you KILL it. Take it down too soon, and it'll be up and running in time to spot the team. Let's wait a few seconds."
		],
		Vector2(),
		Rect2(),
		"Wait for the right moment to take down the rebooting camera."
	))

	events.append(build_tutorial_event(
		"ic_timing",
		TutorialEvent.Trigger.CELL_REACHED,
		12,
		2,
		[
			"All right, time to KILL. It should stay disabled long enough for the team to slip past.",
			"If you want to be sure, you can use the -> arrow key to prompt the team to hustle. It's a great way to slip past any time-sensitive obstacles."
		],
		Vector2(),
		Rect2(),
		"KILL the camera, then hustle the team through if needed."
	))

	events.append(build_tutorial_event(
		"guards_intro",
		TutorialEvent.Trigger.CELL_REACHED,
		14,
		3,
		[
			"This next camera is off the main path and isn't likely to be a problem for the team, but by connecting to it, you access it's feed and you can now see that there's a guard patrolling the area.",
			"Guards don't just generate HEAT if they spot you. They can injure your runners.",
			"Worse yet, most guards can't be disabled by hacking alone. But you still have options. The simplest one is to cause a distraction. Let's see what other signals are nearby."
		],
		Vector2(),
		Rect2(),
		"Connect to the cam_03 signal to reveal the patrolling guard."
	))

	events.append(build_tutorial_event(
		"distraction_intro",
		TutorialEvent.Trigger.CELL_REACHED,
		16,
		4,
		[
			"Perfect. Even something as simple as a rogue vending machine set to dispense endlessly can draw a guard's attention for a few seconds.",
			"Like with the Reboot camera, timing is key. The guard will eventually return to their patrol route, so the team needs to be ghosts by then.",
			"We can use the contextual command OP again here to trigger the distraction. Connect to the vending machine and type OP."
		],
		Vector2(),
		Rect2(),
		"Use the OP command on the vend_01 signal."
	))

	events.append(build_tutorial_event(
		"skill_test",
		TutorialEvent.Trigger.CELL_REACHED,
		23,
		-1,
		[
			"All right, you've learned the basics.",
			"The real test is what you do when you have to decrypt a door lock, distract a guard and disable multiple cameras in the span of a few seconds. Good luck!"
		],
		Vector2(),
		Rect2(),
		"Clear the upcoming gauntlet."
	))

	events.append(build_tutorial_event(
		"tactical_pause_intro",
		TutorialEvent.Trigger.CELL_REACHED,
		25,
		-1,
		[
			"If you get overwhelmed, hit tactical pause (the ` key) and catch your breath. If you need a refresher on terminal commands, use F1.",
			"You can't interact with Signals while paused, but you can look up terminal commands on the help sheet, review terminal logs and check scanned data. Think about the timing and sequencing to make a plan."
		],
		Vector2(),
		Rect2(),
		"Reach the end. Use tactical pause if you need time to think. And F1 for help on terminal commands."
	))

	events.append(build_tutorial_event(
		"run_end_intro",
		TutorialEvent.Trigger.CELL_REACHED,
		40,
		5,
		[
			"You did the hard part. All that's left is to collect your reward. Connect to the final terminal and claim it.",
			"Victory will earn you cash to upgrade your deck and experience to improve your runners."
		],
		Vector2(),
		Rect2(),
		"Connect to the final terminal and claim the reward."
	))

	return events
