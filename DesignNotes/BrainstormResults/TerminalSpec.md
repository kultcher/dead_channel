# Dead Channel Terminal Spec

This document expands the terminal section of `DesignBible.md` into a more implementation-facing design reference.

## Purpose

The terminal is not just a UI skin. It is one of the main ways the player expresses mastery in Dead Channel.

It should deliver four things at once:

- a strong "remote operator" fantasy
- a fast triage tool under pressure
- a readable command language the player can internalize
- a path from blunt interaction to precise system manipulation

If the terminal becomes too shallow, the hacker fantasy collapses. If it becomes too arcane, it stops being tense and starts being homework.

## Target Feel

The ideal feeling is:

- "I am under pressure, but I understand my tools."
- "I can act fast with rough commands, or slow down and get precise."
- "The system is learnable enough that I can become fluent."
- "When I fail, it is because I misread or reprioritized badly, not because syntax betrayed me."

The terminal should feel closer to practiced field fluency than to full shell simulation.

## Core Design Rules

### 1. The terminal is a primary mechanic

It should stay central to signal interaction and not degrade into pure flavor text.

### 2. Broad first, precise later

The command curve should begin with blunt, expensive verbs and only later unlock more surgical control.

### 3. Clarity beats realism

The player should feel smart for understanding systems, not for surviving arbitrary parser edge cases.

### 4. Typed interaction is the gold path

Quick aids can exist, but full fluency should still favor typed commands, especially for finer manipulation.

### 5. The terminal must stay snappy

A command interaction that stalls the wider attention economy for too long is usually the wrong shape.

## Terminal Role In The Run

The terminal sits at the intersection of:

- signal targeting
- information gathering
- broad disablement
- fine-grained manipulation
- context interpretation
- puzzle access

It should help the player answer:

- What is this signal?
- What parts of it matter?
- What is the fastest thing I can do?
- What is the safest thing I can do?
- What can I afford to do right now?

## Session Model

The terminal is session-based.

In practical terms:

- the player is usually connected to one signal at a time
- the current session determines command context
- switching targets should be easy
- tabbing or multi-session support can deepen play later

Session-based interaction matters because it keeps the command space legible under pressure. The player should usually know what object their command is acting on.

## Targeting Model

The current targeting model is hybrid:

- the terminal usually has a current session / implicit target
- explicit target text is always allowed
- early play should lean on contextual targeting to reduce typing burden

In practice, this means the player can often act on the selected or connected signal without retyping its full name every time, but the command language still supports explicit targeting when needed.

Examples:

```text
> ACCESS
```

Interpreted as:

- "access the currently selected signal"

```text
> ACCESS cam_01
```

Interpreted as:

- "access cam_01 explicitly, regardless of current session"

This model preserves speed while keeping the language expressive.

### Why hybrid is the right fit

Strongly contextual targeting is fast, but can become confusing if the player loses track of session state.

Strongly global targeting is explicit, but adds too much typing overhead for a game built around pressure and rapid triage.

Hybrid targeting gets the useful parts of both:

- fast default play
- explicit override when needed
- cleaner onboarding
- room for advanced play with multiple sessions or tabs later

## Command Dispatch Flow

The terminal should behave like a predictable dispatcher, not like a bag of one-off special cases.

At a high level, command execution should follow this order:

1. Read player input
2. Parse verb, target, and flags / arguments
3. Resolve terminal context
4. Validate whether the command is legal in that context
5. Route the command to the relevant signal or subsystem logic
6. Return a readable result message plus any side effects

That means the terminal layer is responsible for:

- understanding what the player asked for
- knowing what session or target it applies to
- rejecting malformed or invalid requests clearly
- passing a structured request into gameplay logic

The signal / subsystem layer is responsible for:

- deciding whether the action succeeds
- applying heat, state changes, IC responses, or puzzle launches
- producing feedback data for the terminal to display

### Dispatch philosophy

The parser should not own all gameplay logic.

It should translate player intent into a structured action, something conceptually like:

```text
verb=ACCESS
target=cam_01
flags=[]
context=current_terminal_session
```

Then a dispatch layer routes that action to signal-aware logic.

This separation matters because:

- terminal syntax can evolve without rewriting signal behavior
- signals can expose different responses to the same verb
- IC can intercept or modify command execution cleanly
- the same action can be triggered by typing or UI shortcuts without duplicating all downstream logic

### Context resolution order

When a command is entered, context should resolve in a stable order:

1. explicit target in the command
2. current terminal session target
3. selected / focused signal, if allowed by the current interface state
4. failure with a clear "no target" message

This makes targeting rules easy to learn.

### Command result shape

Every command should ideally return a result with a few consistent dimensions:

- status: success, failure, partial success, blocked
- message: what the player sees in the terminal
- heat change: if any
- state change: session change, signal change, puzzle launch, IC trigger
- follow-up hooks: whether more input, a minigame, or a warning is needed

This helps the terminal feel coherent even when many systems are involved.

### Example flow: ACCESS

```text
> ACCESS
```

Dispatch interpretation:

1. No explicit target given
2. Use current session / selected signal
3. Ask signal logic whether access is allowed
4. Possible outcomes:
   - access succeeds directly
   - access is denied and names the next obstacle
   - access is denied and requires `RUN` or other follow-up
   - access triggers IC or a warning state

### Example flow: RUN

```text
> RUN decrypt
```

Dispatch interpretation:

1. Parse `RUN` as program execution
2. Resolve whether the program is global, target-bound, or context-bound
3. Validate whether a legal target exists
4. Start the puzzle / program / tool effect
5. Return a clear initiation message

This is one reason `RUN` is worth keeping in the command language. It gives the game a clean conceptual hook for program initiation and IC interference.

### Example flow: PROBE

```text
> PROBE -sub
```

Dispatch interpretation:

1. Resolve current target
2. Route the request to the signal's inspection logic
3. Return a structured view of subprocesses, properties, vulnerabilities, or topology

The terminal should feel like it is querying a system, not just printing canned flavor.

## Parser Behavior Guidelines

The parser should be strict enough to keep the command language meaningful, but forgiving enough that it does not become the main source of frustration.

Near-term priorities:

- stable verbs
- predictable argument order
- explicit feedback for missing targets or bad flags
- room for shorthand later, but not required immediately

Good parser failures:

- "No active target. Specify a signal or select one first."
- "Unknown flag for PROBE: `-netx`"
- "RUN requires a program name."

Bad parser failures:

- silent no-ops
- vague "syntax error" responses
- rejecting obvious intent for tiny formatting mistakes

## Relationship To UI Shortcuts

Mouse or UI shortcuts should sit above the same dispatch path, not beside it.

That means:

- clicking a signal can set session context or open a terminal
- clicking a puzzle launcher can still conceptually map to `RUN`
- quick buttons should generate the same structured actions the typed parser would have generated

This keeps behavior consistent and makes IC interaction easier to reason about.

## Credentials And Clearance

Credentials are a bypass layer for access friction.

Current direction:

- credentials can bypass minigame puzzles on signals with that clearance level or lower
- credentials can be obtained from certain guards and certain data-terminal-like signals
- credentials should probably have limited uses or a time limit rather than being permanent all-mission authority

The current lean is toward limited uses, but that should be treated as a tuning decision to confirm in testing.

### Why credentials belong in the terminal layer

They change what `ACCESS` means.

Without credentials:

- `ACCESS` often leads to denial, friction, or puzzle initiation

With credentials:

- `ACCESS` can become a fast bypass tool that trades preparation for speed

That makes credentials a strategic extension of terminal fluency rather than a detached inventory gimmick.

### Design goals for credentials

- let the player skip some known friction if they planned ahead
- reward scanning or stealing from the right targets
- create a meaningful choice between immediate hacking and setup for later speed
- avoid becoming a permanent "solve all doors forever" button

### Near-term implementation stance

- keep the player-facing idea simple: "this clearance lets me bypass matching or lower locks"
- source credentials from readable places such as guards and special terminals
- test limited uses first
- keep time-limited credentials as a live fallback if use-count-based tuning feels flat

## LINK

`LINK` is the most explicitly creative command in the current roster.

Its role is to connect two signals such that one signal's behavior influences or overwrites the other.

Current conceptual syntax:

```text
LINK <read_target>[subprocess] <write_target>[subprocess]
```

Examples:

```text
LINK cam_01 feed.vid cam_02 feed.vid
```

Meaning:

- read the visual feed from `cam_01`
- write it to `cam_02`
- `cam_02` now mirrors `cam_01` instead of its own live view

```text
LINK sensor_01 alert.sys door_01 door_open.exe
```

Meaning:

- when the motion sensor's alert behavior fires
- it writes into the door's open behavior

### LINK fantasy

`LINK` should feel like illegal systems wiring.

It is not just "cast combo spell."

It should feel like:

- rerouting output
- hijacking dependencies
- making one machine lie on behalf of another
- forcing systems to talk in ways they were not meant to

### Design goals for LINK

- produce genuinely clever, non-linear solutions
- reward understanding what signals actually do
- create system-combo play that feels distinct from `SPOOF`
- remain legible enough that players can predict results

### Risk

If LINK becomes fully general too early, it can become:

- unreadable
- too fiddly to type under pressure
- impossible to teach cleanly
- hard to balance because every system can potentially touch every other system

### Current implementation lean

Treat full explicit linking syntax as the ideal high-expression version.

However, if that proves too fiddly, it is acceptable to move toward semi-implicit linking where certain signal pairings expose a narrower set of legal behaviors. For example:

- camera-to-camera linking defaults to feed mirroring
- sensor-to-door linking defaults to trigger redirection
- other pairings are rejected or not surfaced

This preserves the creative identity of `LINK` without requiring a fully freeform routing language from day one.

## Command Progression

The terminal should teach itself through progression.

### Phase 1: blunt verbs

The early game should emphasize broad actions that are easy to understand and costly to misuse.

Examples:

- `ACCESS`
- `KILL`
- `PROBE`

At this stage, the lesson is:

- signals can be targeted
- commands are contextual
- blunt actions cost more heat or carry more risk

### Phase 2: readable specificity

Once the player is comfortable with the basics, commands can surface subprocesses, properties, or signal internals in more structured ways.

The lesson becomes:

- systems are composed of parts
- precision can be cheaper or more efficient than brute force
- context matters more than memorizing a large command list

### Phase 3: fluent manipulation

Later play can lean into higher-precision control, including:

- specific subsystem targeting
- property modification
- layered responses to IC
- interactions between terminal decisions and active puzzles

At this stage, mastery should look like faster triage and better judgment, not denser syntax for its own sake.

## Command Categories

These are the main categories the terminal should support.

## Near-Term Command Roster

The current core command language is:

- `ACCESS`
- `KILL`
- `RUN`
- `PROBE`
- `SPOOF`
- `LINK`

Not all of these should appear at once. `LINK` is part of the intended command family, but it is a later addition rather than an early onboarding verb.

`RUN` stays in the command language even if some puzzle-launch interactions eventually gain mouse-driven shortcuts. It is still valuable as an explicit terminal concept because:

- it reinforces that programs are something the player executes
- it gives IC and other systems a clear hook for interfering with program initiation
- it preserves consistency between typed and clicked interaction

Support or utility verbs such as `SCAN`, `TRACE`, or `PING` can remain on file as secondary possibilities, but they are not part of the current must-have core roster.

## Onboarding Progression

The current intended onboarding curve is:

1. `ACCESS`
2. `KILL`
3. `RUN`
4. `PROBE`
5. `SPOOF`
6. `LINK`

This maps to a clear growth path:

- `ACCESS`: basic interaction and signal targeting
- `KILL`: blunt force, high-cost intervention
- `RUN`: explicit program and puzzle initiation
- `PROBE`: deeper reading and system understanding
- `SPOOF`: precision manipulation
- `LINK`: clever, non-linear system play

The progression matters because it teaches the player what the terminal is for in layers:

- first, "I can act on signals"
- then, "I can force outcomes"
- then, "I can invoke tools"
- then, "I can understand systems"
- then, "I can alter systems precisely"
- finally, "I can combine systems creatively"

### Access / targeting

Purpose:

- connect to a signal or switch terminal context quickly

Design requirement:

- should be easy and reliable

### Probe / inspect

Purpose:

- reveal more detail than passive scanning
- expose subprocesses, properties, risks, or system state

Design requirement:

- information should be useful enough to justify the time spent reading it

### Broad disablement

Purpose:

- let the player take a fast, blunt action when they cannot afford precision

Design requirement:

- strong enough to matter
- costly enough that precision remains attractive

### Precision control

Purpose:

- let the player alter system parts rather than only shutting whole signals down

Design requirement:

- should feel like understanding the machine, not entering puzzle-passwords

### Utility / support

Purpose:

- help the player manage information, sessions, or timing pressure

This can include:

- tabbing
- command history
- quick reference
- command helper affordances

### Program execution

Purpose:

- explicitly invoke a cracking tool, support program, or puzzle-starting action

Design requirement:

- should be simple and readable
- should preserve the feeling that puzzle access is still part of the terminal language of play

## Heat And Cost Logic

Heat is one of the cleanest balancing levers for terminal play.

Current direction:

- blunt actions should often cost more
- precise actions should often be more efficient but demand more understanding
- emergency options can exist if they create meaningful tradeoffs

The player should frequently face:

- "Do I spend heat to solve this fast?"
- "Do I spend attention to solve this cleanly?"

That trade is central to the terminal's feel.

## Syntax Philosophy

The terminal should not be a realism contest.

Preferred qualities:

- consistent verbs
- readable nouns / targets
- stable structure
- minimal punctuation overhead
- low chance of "I knew what I meant, but the parser rejected me"

Bad difficulty:

- invisible parser rules
- fragile argument order
- needless abbreviations
- one-character failure states that feel arbitrary

Good difficulty:

- deciding what to target
- deciding whether to go broad or precise
- reading system context under pressure
- remembering the right tool at the right moment

## Accessibility And Support

Support tools are allowed, but they must not displace the terminal's core identity.

Good support:

- command reminder overlays
- available-command hints in early play
- quick target shortcuts
- readable session indicators

Risky support:

- one-click precision that bypasses command understanding
- automations that make typed interaction feel optional

The rule of thumb is:

If the aid helps the player remember or execute what they already understand, it is good.

If it removes the need to understand the system at all, it is probably too much.

## Planning Mode

A planning mode is compatible with the current design, as long as it does not let the player smuggle in active execution without time pressure.

Useful planning-mode functions:

- reviewing already revealed information
- comparing signal state
- checking reference material
- inspecting current sessions

Functions that should stay time-bound:

- committing commands
- progressing puzzles
- active manipulation that should cost run-time attention

## Relationship To Puzzles

The terminal should coexist with puzzle windows, not be sealed off from them.

Desired relationship:

- the terminal can unlock, contextualize, or accelerate puzzles
- puzzles can reinforce the fiction that the terminal is interacting with hostile systems
- the player should feel that all these interactions belong to one coherent hacking layer

The terminal itself also functions as a recurring micro-puzzle through interpretation and context.

## Failure Modes To Avoid

- The terminal becomes flavor text with no meaningful mastery.
- The terminal becomes so strict that syntax is harder than decision-making.
- The command list becomes too wide too early.
- Quick-access UI makes typing feel unnecessary.
- Information density gets so high that the player cannot extract meaning quickly.

## Near-Term Implementation Guidance

- Keep the base command set small.
- Make session targeting obvious.
- Keep parser rules stable and forgiving where possible.
- Use heat as the main balancing lever for blunt options.
- Make precision visibly more elegant or efficient, not just "more typing."
- Reserve advanced subprocess / property depth for after the broad loop feels good.

## Short Version

The terminal should feel like a practiced operational instrument.

The player should start with a few strong verbs, learn that precision beats brute force when they can afford it, and gradually internalize the system until typing a command feels like making a tactical decision, not solving a parser puzzle.
