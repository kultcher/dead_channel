# Code Hygiene & Architecture Review: Dead Channel

This review focuses on redundancy, overengineering, and general code hygiene within the **Dead Channel** codebase.

---

## 1. Redundancy & Duplicated Logic

### A. Signal State Initialization
- **Issue:** Both `signal_entity.gd` (`setup`) and `MobilityController.gd` (`initialize`) manually initialize runtime state (cell position, lane, facing).
- **Redundancy:** `signal_entity.gd` contains a block that mirrors exactly what `MobilityController` does, but only if the controller hasn't run yet.
- **Recommendation:** Centralize runtime state initialization in `ActiveSignal.setup()`. Let the visual and logic controllers read from the already-initialized `ActiveSignal` rather than trying to "fix" it on their own.

### B. UI Update Loops
- **Issue:** `terminal_window.gd` calls `_refresh_signal_detail_panel()` in `_process(delta)`.
- **Redundancy:** This means the entire detail panel (Scan, Lock, IC) is recalculated and redrawn 60+ times per second, even when nothing has changed.
- **Recommendation:** Move to a signal-driven update pattern. Only refresh the panels when `GlobalEvents.signal_scanned` or `GlobalEvents.puzzle_solved` is emitted.

### C. Signal Interaction Logic
- **Issue:** `SignalManager.gd` and `signal_entity.gd` share responsibility for click/hover logic.
- **Redundancy:** `SignalManager` connects to four different signals from `signal_entity` just to pass them back to a `ScanController`.
- **Recommendation:** Let `signal_entity` talk to a localized "InteractionHandler" or directly to the `ScanController` to reduce the "pass-through" noise in `SignalManager`.

---

## 2. Overengineering

### A. The "Takeover Controller" in Terminal
- **Issue:** `terminal_window.gd` uses a `TerminalTakeoverController` to handle printing and animations.
- **Critique:** While cool for "Null Spike" effects, it adds a layer of abstraction that makes standard `print_to_log` calls more complex than necessary.
- **Recommendation:** Evaluate if the "Takeover" logic can be simplified into a few helper functions or a dedicated `RichTextLabel` wrapper instead of a full controller that "takes over" the terminal's UI elements.

### B. Puzzle Window Tracking
- **Issue:** `window_manager.gd` has a complex `_active_puzzle_windows` dictionary and multiple "unregister" and "tree_exiting" cleanup functions.
- **Critique:** Even the author noted this as "Overengineered maybe?" in the comments.
- **Recommendation:** Use Godot's built-in `owner` and `group` systems to manage open windows. If a signal is destroyed, simply `get_tree().call_group("puzzles_for_" + sig_id, "close")`.

---

## 3. Hygiene & Maintenance Issues

### A. Hardcoded UI Paths
- **Issue:** Many managers (like `RunManager` or `SignalManager`) use `$"../..."` relative paths to find each other.
- **Hygiene Risk:** This makes the scenes very fragile. Moving a node in the scene tree breaks the entire game.
- **Recommendation:** Use **Access as Unique Name** (%) in Godot or rely strictly on the Autoload references (which you already have for `CommandDispatch`).

### B. Component "Placeholder" Classes
- **Issue:** `HackableComponent.gd` is essentially an empty class.
- **Hygiene Risk:** It exists only for type-checking, but it doesn't provide any actual API.
- **Recommendation:** Either implement the core API (like the `registered_commands` suggestion from the Architecture Review) or use a more generic `Component` base class to avoid a proliferation of empty files.

### C. Resource Lifecycle ("Dummy Children")
- **Issue:** `ICModules` (Reboot, Bouncer) injecting `Timer` nodes into `GlobalEvents`.
- **Hygiene Risk:** This is a major hygiene issue as it pollutes the global event bus with temporary timers and makes the scene tree unpredictable during runtime.
- **Recommendation:** (As noted in the Architecture Review) Use a dedicated `TimerManager` or `Tween` utility that doesn't require "orphaning" nodes into other managers.

---

## 4. Summary of Suggested Refactors

| Priority | Issue | Solution |
| --- | --- | --- |
| **High** | Terminal Process Update | Move `_refresh_signal_detail_panel` from `_process` to signal-based events. |
| **High** | Timer Injection | Stop using `GlobalEvents.add_child(timer)` for IC modules. |
| **Medium** | Path Fragility | Replace `$"../"` paths with Unique Names or Autoloads. |
| **Medium** | Redundant Init | Move all runtime state initialization to `ActiveSignal.setup()`. |
| **Low** | Empty Components | Flesh out `HackableComponent` or merge into a generic base. |
