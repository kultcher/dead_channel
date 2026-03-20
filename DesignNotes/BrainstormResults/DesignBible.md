# Dead Channel Design Bible

This file is the maintained canonical design reference for Dead Channel. It is the intended long-term source of truth for design decisions.

Legacy reference docs:

- `PROJECT Dead Channel.txt`
- `RunLevelSystemsDetail.txt`
- `DevProgress.txt`

`PROJECT Dead Channel.txt` remains the foundational seed doc and historical snapshot, but canon should now be updated here first. When new brainstorm material conflicts with this file, log the conflict in `Contradictions.md` instead of overwriting canon by default.

Companion synthesis docs:

- `TerminalSpec.md`
- `TerminalOpenQuestions.md`
- `MinigameDirections.md`
- `ICIdeas.md`

## Canon Status

- Last synthesis pass: 2026-03-14
- Canon owner: `DesignBible.md`

## Product Summary

Dead Channel is a cyberpunk matrix-overwatch game about supporting a runner team under pressure as the remote hacker and problem-solver behind the action. Its identity centers on run-level triage, terminal fluency, puzzle-gated hacks, escalating heat, and a later management layer built around runners and cyberdeck growth.

## Design Pillars

### Pressure And Triage

The player should frequently face more problems than they can fully solve, forcing prioritization under time pressure.

### Remote Support Fantasy

The player influences the run indirectly through software, signal manipulation, information, and limited command authority rather than direct character control.

### Systems With Readable Consequences

Signals, heat, IC, puzzles, and terminal commands should interact in ways the player can learn, predict, and exploit.

### Core Loop

Runs ask the player to watch an abstract signal timeline, scan and interpret upcoming threats, connect to signals through a terminal, and decide what to disable, alter, delay, or simply accept. The player is not expected to solve everything perfectly; the intended loop is constant reprioritization under pressure.

The management layer remains part of the long-term plan: money from runs supports hiring, development, and cyberdeck upgrades. For now, the run layer is the primary design and implementation focus.

### Run Layer

The run layer is built around attention as a scarce resource. The player tracks threats on the timeline while juggling movable windows, puzzles, the terminal, and heat pressure. Difficulty should usually come from concurrent demands and changing context rather than from pure execution difficulty in one isolated subsystem.

### Management Layer

The management layer is planned to support runner hiring, development, quirks, and cyberdeck upgrades. Story missions surrounded by proc-gen contracts are a plausible long-term campaign shape, but the exact campaign motivation and structure remain open.

### Timeline And Signals

The timeline is an abstract measure of time and travel rather than a literal map. The center lane is the runners' critical path. Side lanes represent adjacent spaces that can still threaten the team or offer optional routes, boons, and paydata. Signals are the primary interaction units and can represent obstacles, objectives, or opportunities.

Mission arcs can alter timeline behavior between infiltration, objective, and extraction phases. Timeline speed is an important pressure dial and can change by mission context.

Split-track scenarios remain a long-term set-piece concept, not a near-term design priority.

### Terminal And Commands

The terminal is a core pillar, not auxiliary flavor. It is the main gateway for high-value interaction with signals and a major expression of player fluency. The command language should stabilize into muscle memory, reward mastery, and avoid edge-case syntax traps that feel unfair under pressure.

The command set should teach itself through progression from broad, costly verbs toward more precise manipulation of subprocesses and properties. Accessibility aids such as quick buttons or command hints are acceptable if they support fluency rather than replacing it.

### Puzzles

The prototype puzzle roster is intentionally narrow and built around distinct temporal roles:

- Terminal as the recurring command / interpretation layer
- Sniff as a fast attention check
- Decrypt as a slower background process that rewards periodic check-ins and deduction
- Fuzz as an additional prototype candidate to test whether a timing / probing / stacking-success puzzle adds something meaningfully distinct

Additional variety should usually be introduced through modifiers, IC, and context rather than by endlessly adding new engines. Other puzzle concepts remain exploratory until the starting roster is proven.

The terminal itself also functions as a recurring micro-puzzle layer through command interpretation, context, and process targeting.

### Heat And Difficulty Escalation

Heat is a multi-vector escalation system rather than a simple fail timer. It should influence spawning, signal behavior, puzzle difficulty, visibility, or other contextual pressures so that high heat changes the character of a run rather than only making it faster to lose.

Runs should generally tip into degraded or death-spiral states before hard failure. Heat maxing out or major mistakes should usually make the situation worse, not instantly end the run, unless a specific mission structure calls for it.

### IC And Counterplay

IC should attack several domains: timing, information, access, resources, and interface clarity. Good IC creates new triage decisions rather than only forcing dead time. Telegraphing and counterplay matter; the player should usually understand why the system became harder.

Interface-targeting IC is compatible with the game's design, but it must remain readable and fair.

### Runner Team

The runners are people, not direct-control units. They should feel competent enough that the player is supporting coworkers rather than puppeteering disposable pawns, but vulnerable enough that intervention matters.

Near-term canon favors meaningful but moderate consequences over constant brutal loss. Injury, stress, setbacks, and degraded mission outcomes should be common enough to matter. True permanent runner loss, if it exists, should be rare and significant rather than a routine punishment for interface pressure.

### World, Tone, And Fiction

The base canon remains gritty independent-contractor cyberpunk with strong corporate identities. Each corporation should eventually feel like a cultural and mechanical tileset that changes obstacle mix, IC style, terminal language, and mission tone.

Post-corporate or brand-cult decay can appear as secondary flavor where it enriches corp identity, terminal voice, or environmental storytelling, but it is not the primary premise of the setting. The core fantasy should stay centered on the pressured hacker-support role first.

### UI And Presentation

Moveable windows are part of the game's intended pressure, not just utility UI. The signal timeline must remain readable in motion, window dragging must feel crisp, and heat / cyberdeck information should stay visible in peripheral vision. If window behavior feels sticky or unclear, the design will read as unfair instead of tense.

### Technical Constraints

The main scope multipliers to guard against are:

- too many standalone puzzle engines
- split-track baseline support
- overly elaborate command syntax
- UI systems that obscure information without reliable control

Prototype guidance is simple: favor a small number of strong interacting systems, reserve multiplicative mechanics for special cases, and prioritize readability in windowing, timeline motion, and command handling.

Split tracks specifically should be treated as a future special-case expansion rather than something that drives current architecture.

## Open Canon Questions

- None currently logged.
