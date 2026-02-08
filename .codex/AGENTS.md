Project: Dead Channel
Engine: Godot(2D)
Language: GDScript

- Read to /DesignNotes/PROJECT Dead Channel.txt for the design doc to understand the project context.
- Key structural elements:
    - timeline_manager.gd: core source of truth for the distance from the runner team the player is supporting to the various obstacles and objectives in their path
    - SignalData.gd, ActiveSignal.gd, signal_entity.gd: SignalData is the core template, ActiveSignal is for Signals that are on-screen and interactable, signal_entity is the underlying scene and visual component
    - CommandDispatch.gd: Receives commands from the terminal window, packages results, and delivers them where they need to go.

- Specific mechanics:
    - terminal_wndow