Project Snapshot
- Project: Dead Channel
- Engine: Godot (2D)
- Language: GDScript
- Pitch: A Shadowrun-inspired cyberpunk hacking overwatch game about supporting a runner team under pressure.

Source Docs (Required Reading)
- DesignNotes/PROJECT Dead Channel.txt is the canonical design reference.

Core Systems (Code Map)
- Timeline/Signals: Scripts/timeline_manager.gd, Scripts/signal_manager.gd, Scripts/SignalBase/SignalData.gd, Scripts/SignalBase/ActiveSignal.gd, Scripts/SignalBase/signal_entity.gd
- Commands/Terminal: Scripts/terminal_window.gd, Scripts/window_manager.gd, Scripts/Autoload/CommandDispatch.gd, Scripts/Helpers/CommandContext.gd
- Components: Scripts/Components/* (detection, hacking, IC, puzzle, response)
- IC Modules: Scripts/ICModules/*
- Puzzle implementations: Scripts/Puzzles/decrypt_puzzle.gd, Scripts/Puzzles/sniff_puzzle.gd
- Heat tracking: Scripts/heat_tracker.gd
- Signal spawning: Scripts/SignalSpawner.gd
- Grid layer: Scripts/grid_layer.gd
- Autoloads: Scripts/Autoload/*

Gameplay Glossary (Short)
- Signal: Any obstacle, objective, or interactable on the timeline.
- ActiveSignal: A Signal currently on-screen and interactable.
- IC/ICE: Intrusion countermeasures that disrupt the player or modify obstacles.
- Heat: Global difficulty pressure that rises with time and actions.
- Timeline: The horizontal track showing runner progress and approaching Signals.
- Runner team: The crew moving along the timeline, influenced but not directly commanded.

Workflow Defaults
- Refactor-friendly when it improves clarity or cohesion.
- Match existing file style and typing usage.
- Read relevant scripts before proposing changes.
- Ask before running heavy tools.

Editing Guardrails
- Prefer minimal diffs unless a refactor improves clarity.
- Avoid expanding scope outside the user request.
- Default to ASCII-only edits unless the file already uses Unicode.

Known Gaps
- Run command: not defined yet.
- Testing workflow: not defined yet.
