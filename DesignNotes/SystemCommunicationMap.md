# Dead Channel System Communication Map

This is a textual system map of the current runtime architecture.

The goal is not to list every file. The goal is to answer:

- Which systems own state?
- Which systems talk to each other?
- How do they communicate?
- What are the main gameplay flows?

## Communication Styles

There are three main communication patterns in the project:

1. Direct scene references
   - Example: `RunManager` talks directly to `SignalManager`.
   - Used when systems are tightly coupled in `Scenes/run_main.tscn`.

2. Autoload-mediated references
   - `CommandDispatch` stores references to `TimelineManager`, `SignalManager`, `TerminalWindow`, and `WindowManager`.
   - Other systems then reach those managers through `CommandDispatch`.

3. Global event bus
   - `GlobalEvents` is the main broadcast hub for cross-system notifications.
   - Used for pause state, scan completion, puzzles, heat, guards, and tutorial triggers.

## Top-Level Runtime Topology

`Scenes/run_main.tscn` is the composition root.

- `RunManager`
  - Loads the authored run script.
  - Builds runtime `SignalData` instances.
  - Pushes spawn data into `SignalManager`.

- `TutorialManager`
  - Pulls tutorial events from `RunManager`.
  - Listens to `GlobalEvents`.
  - Tells `WindowManager` what tutorial UI and focus state to show.

- `SignalTimeline/TimelineManager`
  - Owns runner progress through the level.
  - Emits `cell_reached`.
  - Owns tactical pause state and runner speed.

- `SignalTimeline/SignalManager`
  - Owns the runtime list of active signals.
  - Spawns and despawns signal scene instances.
  - Handles hover scan logic and click-to-connect logic.

- `WindowManager`
  - Owns non-terminal overlay windows.
  - Spawns puzzle windows and tutorial dialogue.
  - Controls help overlay, objective tracker, and focus overlay.

- `TerminalWindow`
  - Owns terminal UI and per-signal terminal sessions.
  - Sends commands to `CommandDispatch`.
  - Displays command results and errors.

- `HeatTracker`
  - Passive UI sink for `heat_increased`.

## Core Data Layers

### Authored run layer

- `Resources/RunData/RunDefinition.gd`
  - Base API for authored runs.
  - Defines helpers for building spawn dictionaries, puzzles, IC, responses, patrol routes, and disruptors.

- `Resources/RunData/AuthoredRuns/TutorialRun.gd`
  - Concrete authored run.
  - Defines signal spawns and tutorial event definitions.

- `Resources/RunData/TutorialEvent.gd`
  - Data container for tutorial triggers, pages, focus rects, and objective text.

### Runtime signal layer

- `SignalData`
  - Resource that describes one signal's capabilities and state.
  - Aggregates components like `hackable`, `detection`, `response`, `puzzle`, `ic_modules`, `mobility`, and `disruptor`.

- `ActiveSignal`
  - Runtime wrapper around `SignalData`.
  - Adds scan progress, instance node reference, disabled state, session reference, and runtime movement state.

- `signal_entity.gd`
  - Scene-side visual/input controller for an `ActiveSignal`.
  - Bridges player input to `SignalManager`.
  - Hosts `DetectionController` and optional `MobilityController`.

## System Ownership and Dependencies

### Run bootstrap

Flow:

`TutorialRun` -> `RunManager` -> `SignalManager` -> `ActiveSignal` -> `signal_entity`

Details:

- `RunManager.start_run()` loads the authored run script selected by `level_script_path`.
- `RunManager.propagate()` iterates the run's spawn list.
- Each spawn dictionary is converted into a duplicated runtime `SignalData`.
- `SignalManager.spawn_signal_data()` wraps that data in `ActiveSignal`, initializes scan layers, and stores it in `signal_queue`.
- When a signal comes on screen, `SignalManager` instantiates `Scenes/signal_entity.tscn`.

### Timeline and spatial truth

`TimelineManager` is the primary time/progression authority.

- Owns `current_cell_pos`.
- Emits `GlobalEvents.cell_reached` when the runner crosses into a new cell.
- `SignalManager` uses `TimelineManager.current_cell_pos` to convert logical cell distance into screen position.
- Guard movement also depends on `TimelineManager` metrics through `MobilityController`.

### Signal presentation and scan flow

Flow:

Player hover/right-click -> `signal_entity` -> `SignalManager` -> `GlobalEvents.signal_scanned` -> `signal_entity` -> `GlobalEvents.signal_scan_complete`

Details:

- `signal_entity` emits:
  - `scan_requested`
  - `scan_aborted`
  - `scan_lock_requested`
  - `signal_interaction`
- `SignalManager` owns the actual scan state:
  - current scanned target
  - layer timing
  - lock/unlock behavior
- Each completed scan layer emits `GlobalEvents.signal_scanned`.
- The matching `signal_entity` listens for that and emits `GlobalEvents.signal_scan_complete` when all layers are revealed.

### Terminal command flow

Flow:

Player types command -> `TerminalWindow` -> `CommandDispatch` -> `HackableComponent` / `ICComponent` -> `CommandDispatch` -> `TerminalWindow`

Details:

- `TerminalWindow` sends submitted text plus the active terminal session signal into `CommandDispatch.process_command()`.
- `CommandDispatch` parses command text, resolves target signal via `SignalManager`, validates session context, and builds a `CommandContext`.
- `ACCESS` is handled directly by `CommandDispatch` and switches the terminal session.
- Other commands go through `_try_command()`:
  - IC modules get first chance via `ICComponent.command_intercept()`.
  - If not interrupted, the signal's `HackableComponent` executes the command.
- `CommandDispatch` emits:
  - `command_complete`
  - `command_error`
- `TerminalWindow` listens and appends the resulting text to the active session log.

### Puzzle flow

Flow:

`HackableComponent.RUN` -> `GlobalEvents.puzzle_started` -> `WindowManager` -> puzzle window -> `WindowManager` -> `PuzzleComponent` -> `GlobalEvents.puzzle_solved` / `puzzle_failed`

Details:

- `HackableComponent` decides whether `RUN SNIFF`, `RUN FUZZ`, or `RUN DECRYPT` matches the signal's `PuzzleComponent`.
- On match, it emits `GlobalEvents.puzzle_started`.
- `WindowManager` listens and spawns the corresponding puzzle scene.
- On solve:
  - `WindowManager` calls `active_sig.data.puzzle.process_solve(active_sig)`.
  - `PuzzleComponent` clears `puzzle_locked`.
  - `WindowManager` emits `GlobalEvents.puzzle_solved`.
- On failure:
  - `WindowManager` emits `GlobalEvents.puzzle_failed`.

### Signal disable / heat / IC flow

Flow:

`KILL` -> `HackableComponent._kill()` -> `ActiveSignal.disable_signal()` -> `GlobalEvents.signal_killed` + `GlobalEvents.heat_increased`

Optional follow-up:

`ActiveSignal.disable_signal()` -> `ICComponent.notify_disabled()` -> `RebootModule.on_disabled()` -> timer -> `ActiveSignal.enable_signal()`

Details:

- `KILL` is currently the main direct disable command.
- Disabling a signal updates visuals and disables its vision controller.
- Reboot IC is implemented as a timer-based re-enable behavior hosted by `RebootModule`.
- Pause/unpause also affects reboot timers because the module listens to tactical pause events.

### Detection / response / runner consequence flow

Flow:

Runner enters detection area -> `DetectionController` -> `DetectionComponent.apply_detection()` -> `ResponseComponent.on_detection()` -> `GlobalEvents`

Outputs currently include:

- `heat_increased`
- `runners_damaged`
- `runners_stopped`
- `runners_resumed`

Details:

- `DetectionController` owns overlap sensing and alert flash visuals.
- `DetectionComponent` decides whether detection should apply.
- `ResponseComponent` translates ongoing detection into consequences.
- Delayed responses can temporarily stop runner movement before applying effects.
- `TimelineManager` listens to stop/resume events and changes runner speed accordingly.
- `HeatTracker` listens to heat events and updates the heat UI.

### Guard distraction / alert flow

Flow:

`OP` on disruptor -> `HackableComponent._op_disruptor()` -> `GlobalEvents.guard_alert_raised` -> each guard `MobilityController`

Details:

- Disruptor signals emit a `GuardAlertData` event for guards in horizontal range.
- Each guard's `MobilityController` subscribes to `guard_alert_raised`.
- Matching guards leave patrol, move toward the alert, investigate for a duration, then return to patrol.
- Guard visibility to the player is also managed in `MobilityController`:
  - near the runner, or
  - near an active camera that currently has a terminal session and is not puzzle-locked.

### Tutorial flow

Flow:

Gameplay emits `GlobalEvents` -> `TutorialManager` -> `WindowManager` -> tutorial dialogue / focus overlay / objective tracker

Details:

- `TutorialManager` pulls authored `TutorialEvent` data from `RunManager`.
- It listens for:
  - `cell_reached`
  - `signal_scan_complete`
  - `signal_connect`
  - `signal_killed`
  - `puzzle_started`
  - `puzzle_solved`
- When a tutorial trigger matches:
  - `TutorialManager` emits `tutorial_lock_changed(true)`
  - `TutorialManager` emits `tactical_pause`
  - `WindowManager` shows tutorial dialogue
  - `WindowManager` updates objective text
  - `WindowManager` highlights a control or signal via `FocusOverlay`
- When the dialogue is dismissed:
  - `WindowManager` clears focus
  - emits `tutorial_lock_changed(false)`
  - emits `tactical_unpause`

## GlobalEvents Cheat Sheet

`GlobalEvents` is the main decoupling layer between gameplay systems.

- Progress/state:
  - `cell_reached`
  - `tutorial_lock_changed`
  - `tactical_pause`
  - `tactical_unpause`

- Signal interaction:
  - `signal_scanned`
  - `signal_scan_complete`
  - `signal_connect`
  - `signal_hacked`
  - `signal_killed`

- Consequences:
  - `heat_increased`
  - `runners_damaged`
  - `runners_stopped`
  - `runners_resumed`

- Puzzles:
  - `puzzle_started`
  - `puzzle_failed`
  - `puzzle_solved`

- Guards/IC:
  - `guard_alert_raised`
  - `guard_comms_ping_started`
  - `guard_comms_ping_ended`
  - `ic_triggered`

## Practical "Who Talks To Who" Summary

- `RunManager` talks to `SignalManager`.
- `TutorialManager` talks to `RunManager`, `SignalManager`, `WindowManager`, and `GlobalEvents`.
- `TimelineManager` talks mainly through `GlobalEvents`; `SignalManager` and guard movement read its state directly.
- `SignalManager` talks to `TimelineManager`, `CommandDispatch`, and `signal_entity` instances.
- `signal_entity` talks to `SignalManager`, `DetectionController`, `MobilityController`, and `GlobalEvents`.
- `TerminalWindow` talks to `CommandDispatch`.
- `CommandDispatch` talks to `TerminalWindow`, `SignalManager`, `WindowManager`, `ICComponent`, and `HackableComponent`.
- `HackableComponent` talks to `ActiveSignal`, `PuzzleComponent`, `SignalManager`, and `GlobalEvents`.
- `DetectionComponent` talks to `ResponseComponent` through the owning `SignalData`.
- `ResponseComponent` talks to `TimelineManager` and UI indirectly through `GlobalEvents`.
- `WindowManager` talks to puzzle windows, tutorial dialogue, focus/objective UI, and `GlobalEvents`.
- `HeatTracker` is a passive listener.

## Current Architectural Center of Gravity

If you need the shortest possible mental model, it is this:

- `TimelineManager` owns time and runner progress.
- `SignalManager` owns the live signal roster and scan state.
- `CommandDispatch` owns terminal command routing.
- `WindowManager` owns auxiliary UI windows.
- `GlobalEvents` is the broadcast glue between subsystems.
- `SignalData` + components own per-signal behavior.

## Likely Follow-Up References

If you want to extend or refactor the project, these are the highest-value starting points:

- `Scenes/run_main.tscn`
- `Scripts/Autoload/GlobalEvents.gd`
- `Scripts/Autoload/CommandDispatch.gd`
- `Scripts/signal_manager.gd`
- `Scripts/timeline_manager.gd`
- `Scripts/window_manager.gd`
- `Scripts/SignalBase/signal_entity.gd`
- `Scripts/SignalBase/MobilityController.gd`
- `Scripts/Components/HackableComponent.gd`
- `Resources/RunData/RunDefinition.gd`
