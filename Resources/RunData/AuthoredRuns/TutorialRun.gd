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
		build_spawn(BASIC_CAMERA, 14.5, {"display_name": "cam_02", "lane": 2, "add_ic_modules": [make_reboot_module(15.0)]}),
		build_spawn(BASIC_CAMERA, 20.5, {"display_name": "cam_03", "lane": 4}),
		build_spawn(BASIC_GUARD, 21.5, {"lane": 4}),
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
			"To SCAN a signal, hold the mouse over it. Keep scanning this signal until all it's info is revealed."
		]
	))

	events.append(build_tutorial_event(
		"first_scan",
		TutorialEvent.Trigger.SCAN_COMPLETE,
		-1,
		0,
		[
			"Scanning this Signal has revealed it's type, it's access parameters and any IC (Intrusion Countermeasures) on the Signal. You don't have to Scan a Signal to hack it, but it's worth it if you have the time.",
			"Since it's ACCESS type is open and there's no IC, hacking it will be a breeze. Click on the signal to connect to it."
		]
	))

	events.append(build_tutorial_event(
		"terminal_intro",
		TutorialEvent.Trigger.SIGNAL_CONNECT,
		-1,
		-1,
		[
			"You're connected to the camera, now let's take it out. There are a few different ways to deal with obstacles like these, but for now, we're going to do it fast and loud: with KILL.",
			"Since you're already connected to the signal, all you have to do is type KILL and hit enter."
		]
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
		Rect2(16, 812, 128, 252)
	))

	events.append(build_tutorial_event(
		"decrypt_intro",
		TutorialEvent.Trigger.SCAN_COMPLETE,
		-1,
		1,
		[
			"This door has an Encrypted lock, so we can't do anything with it until we decrypt it.",
			"Connect to the door and type RUN DECRYPT in the terminal to boot up your DECRYPT program."
		]
	))


	events.append(build_tutorial_event(
		"decrypt_continued",
		TutorialEvent.Trigger.PUZZLE_STARTED,
		int(PuzzleComponent.Type.DECRYPT),
		-1,
		[
			"Decrypt can break any encryption by itself eventually. But that takes time you probably won't have on a real run.",
			"Take a look at the KEYSPACE sections. They show all the possible characters that might fit the cipher. As DECRYPT does its work, it'll cull one or more possibilities from each KEYSPACE.",
			"You can also help it along by using deduction or just brute-force guessing. Guess right and you optimize the algorithm, making the next cull come faster. See if you can crack this one before the runners reach the door."
		],
		Vector2(300, 500)
	))

	events.append(build_tutorial_event(
		"decrypt_complete",
		TutorialEvent.Trigger.PUZZLE_SOLVED,
		-1,
		1,
		[
			"Now we have access.",
			"The exact interaction for opening or toggling this door is still a placeholder in the tutorial flow for now."
		]
	))

	events.append(build_tutorial_event(
		"ic_intro",
		TutorialEvent.Trigger.CELL_REACHED,
		8,
		2,
		[
			"Another camera. This one is a bit trickier. It's OPEN to hacking like the first one, but there's also IC: Reboot.",
			"Reboot will re-enable the signal after a short delay if you KILL it. Take it down too soon, and it'll be up and running in time to spot the team. Let's wait a few seconds."
		]
	))

	events.append(build_tutorial_event(
		"ic_timing",
		TutorialEvent.Trigger.CELL_REACHED,
		12,
		2,
		[
			"All right, time to KILL. It should stay disabled long enough for the team to slip past.",
			"If you want to be sure, you can use the -> key to prompt the team to hustle. It's a great way to slip past any time-sensitive obstacles."
		]
	))

	events.append(build_tutorial_event(
		"guards_intro",
		TutorialEvent.Trigger.CELL_REACHED,
		14,
		3,
		[
			"This next camera isn't likely to be a problem for the team, but by accessing its feed, you can now see that there's a guard patrolling the area.",
			"Guards don't just generate HEAT if they spot you. They can injure your runners.",
			"Worse yet, most guards can't be disabled by hacking alone. But you still have options. The simplest one is to cause a distraction. Let's see what other signals are nearby."
		]
	))

	events.append(build_tutorial_event(
		"distraction_intro",
		TutorialEvent.Trigger.CELL_REACHED,
		28,
		4,
		[
			"Perfect. Even something as simple as a rogue vending machine set to dispense endlessly can draw a guard's attention for a few seconds.",
			"Like with the Reboot camera, timing is key. The guard will eventually return to their patrol route, so the team needs to be ghosts by then."
		]
	))

	events.append(build_tutorial_event(
		"skill_test",
		TutorialEvent.Trigger.CELL_REACHED,
		34,
		-1,
		[
			"All right, you've learned the basics.",
			"The real test is what you do when you have to decrypt a door lock, distract a guard and disable multiple cameras in the span of a few seconds. Good luck!"
		]
	))

	events.append(build_tutorial_event(
		"tactical_pause_intro",
		TutorialEvent.Trigger.CELL_REACHED,
		38,
		-1,
		[
			"If you get overwhelmed, hit tactical pause and catch your breath.",
			"You can't interact with Signals while paused, but you can look up terminal commands on the help sheet, review terminal logs and check scanned data."
		]
	))

	events.append(build_tutorial_event(
		"run_end_intro",
		TutorialEvent.Trigger.CELL_REACHED,
		44,
		5,
		[
			"You did the hard part. All that's left is to collect your reward. Connect to the final terminal and claim it.",
			"Victory will earn you cash to upgrade your deck and experience to improve your runners."
		]
	))

	return events
