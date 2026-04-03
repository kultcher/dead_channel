# Architecture Review: Dead Channel

## Overview
The architecture of **Dead Channel** is built on a modular, component-based system designed for a Godot 4.x environment. It leverages Autoloads (Singletons) for global state management and a robust "Action-Command" pattern for decoupling terminal input from gameplay effects. The system is well-positioned for procedural generation but faces some scalability bottlenecks as it expands toward a full campaign and management layer.

---

## 1. Core Pattern Critiques & Scalability Bottlenecks

### A. The Action-Command Pattern (`CommandDispatch` & `ActionResolver`)
- **Current State:** `CommandDispatch` parses text into a `CommandContext`, which `ActionResolver` then translates into an `ActionContext` to apply effects.
- **Critique:** The translation logic in `ActionResolver.build_action_from_command()` uses a large `match` statement. As the number of commands increases, this will become a maintenance burden.
- **Bottleneck:** The system is "hardcoded-heavy." For example, `OP` behavior is determined by checking `SignalData.Type.DOOR` or `SignalData.Type.DISRUPTOR` explicitly inside `ActionResolver`.
- **Recommendation:** Move command logic into the components themselves (e.g., `HackableComponent` or specific `Action` resources). Instead of `ActionResolver` knowing how to "Kill" a signal, it should ask the signal's `HackableComponent` to generate the appropriate `ActionContext`.

### B. Global Event Bus (`GlobalEvents`)
- **Current State:** A single Autoload managing everything from runner health and heat to tutorial locks and program RAM.
- **Critique:** While effective for decoupling, it is becoming a "God Object." Debugging signal flow is difficult when 20+ scripts are listening to the same hub.
- **Bottleneck:** The "Runner Hold" system (used to stop movement) is centralized here. If multiple systems (puzzles, tutorials, IC) request holds simultaneously, tracking down a "leaked" hold (where movement never resumes) will be challenging.
- **Recommendation:** Split `GlobalEvents` into domain-specific buses (e.g., `SignalEvents`, `RunnerEvents`, `UIEvents`). Implement a more robust "Hold" debugger that tracks which object/system currently owns each hold token.

### C. Resource-Based Composition (`SignalData`)
- **Current State:** Signals are composed of multiple `Resource` components (`DetectionComponent`, `ICComponent`, etc.).
- **Critique:** This is a very strong pattern for Godot and supports the goal of Procedural Generation perfectly.
- **Bottleneck:** The components sometimes have "circular" knowledge. `DetectionComponent` calls `GlobalEvents.runner_detected`, but `DetectionController` (the Node) also handles some of this logic. The boundary between the Data (Resource) and the Controller (Node) is slightly blurred.

---

## 2. Load-Bearing System Evaluation

### A. Terminal Flow (`CommandDispatch` -> `ActionResolver`)
- The use of `ActionContext` as a "transaction" object is excellent. It allows for pre-processing (IC interception) and post-processing (logging/consequences) without the core logic needing to know about those systems.
- **Risk:** The `ActionResolver` is currently a synchronous "drain" of a queue. If any action requires a true async wait (e.g., waiting for an animation to finish before resolving), the current `while` loop in `_drain_action_queue` will block.

### B. Signal Interaction & Scanning
- Scanning is handled in `ActiveSignal` and `ScanController`. The layer-based approach is clean and easily extensible.
- **Risk:** `ActiveSignal` holds a reference to `instance_node`. If a signal is despawned while a process (like a long-running IC effect) is still referencing the `ActiveSignal`, it might attempt to access a null `instance_node`.

### C. IC Module System
- The `ICModule` pre/post-processing hook is the most flexible part of the architecture. It allows "Bouncer" or "Reboot" modules to inject themselves into any action.
- **Risk:** The `RebootModule` and `BouncerModule` use `GlobalEvents.add_child(timer)`. This is a "code smell" where non-Node objects are injecting children into a global singleton to gain access to the SceneTree.
- **Recommendation:** Create a dedicated `TimeManager` or use a `Tween` on a dummy object to handle these timers without polluting the global event bus.

---

## 3. Friction Points for Future Features

- **SPOOF/LINK:** The current `ActionResolver` is built for "Single Target" operations. `LINK` (connecting two signals) will require an update to how `ActionContext` handles `secondary_targets`.
- **Subprocesses:** To support killing a *specific* process (e.g., `<stream_video.exe>`), the `HackableComponent` needs to move from a "placeholder" to a collection of `Process` resources.
- **Heat Consequences:** `HeatTracker` is currently a passive sink. Making it an active "Director" that influences ProcGen/Spawning will require it to have a reference to the `RunManager` or a `DifficultyManager`.

---

## 4. ProcGen & Management Layer Readiness

- **ProcGen:** **High Readiness.** The `RunDefinition` and `SpawnBuilder` are very well-designed. A ProcGen script can simply inherit from `RunDefinition` and override `get_spawns()` to generate a level on the fly.
- **Management Layer:** **Medium Readiness.** The current `run_main.tscn` is the "center of the world." To support a management layer (Base Building / Squad Mgt), the game needs a higher-level `Main` scene that swaps between the "Management" and "Run" scenes.
- **Critical Risk:** Many scripts use `get_tree().root` or direct `$` paths that assume they are inside `run_main.tscn`. Moving to a multi-scene architecture will break these references.

---

## Summary of Recommendations
1. **Decentralize Action Logic:** Let components define their own actions rather than hardcoding them in `ActionResolver`.
2. **Domain-Specific Event Buses:** Prevent `GlobalEvents` from becoming a bottleneck.
3. **Timer Management:** Replace `add_child(timer)` on Singletons with a dedicated timer/tween-based utility.
4. **Scene Hierarchy Refactor:** Prepare for a "Master Scene" that can host the `RunManager` without it being the root of the entire application.
