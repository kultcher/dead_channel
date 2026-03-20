# Dead Channel Terminal Open Questions

This file tracks terminal-design uncertainties that are not contradictions in canon, but still need sharper decisions before the system is fully specified.

Use it as a working queue for focused design decisions.

## How To Use This File

- Resolved items should be moved into `TerminalSpec.md` or `DesignBible.md` as appropriate.
- If a question creates a true canon conflict, also log it in `Contradictions.md`.
- Keep questions concrete enough that they can be answered decisively.

## Current Queue

### T-001 Command Surface

Question:

What is the exact near-term command roster the player can actually type in the first substantial versions of the game?

Why it matters:

- determines parser complexity
- determines onboarding burden
- defines what "terminal fluency" means in practice

Current canon:

- broad-to-precise progression
- typed interaction remains the gold path
- prototype puzzle roster includes terminal, Sniff, Decrypt, and Fuzz

Current candidates repeatedly discussed:

- `ACCESS`
- `KILL`
- `RUN`
- `PROBE`
- `SPOOF`
- `LINK`
- utility or meta commands such as `RUN`, `SCAN`, `TRACE`, or `PING`

Things to nail down:

- which support / utility commands deserve real implementation
- which are direct player verbs vs helper / utility verbs

Current resolution:

- Core command family to keep in active design: `ACCESS`, `KILL`, `RUN`, `PROBE`, `SPOOF`, `LINK`
- Rough onboarding sequence: `ACCESS -> KILL -> RUN -> PROBE -> SPOOF -> LINK`
- `LINK` is explicitly later-game
- `RUN` remains part of the command language even if some puzzle-launch actions also get mouse-driven shortcuts

Remaining uncertainty:

- whether any utility verbs such as `SCAN`, `TRACE`, or `PING` deserve promotion into the near-term implemented roster

### T-002 Targeting Model

Question:

How contextual should the terminal be by default?

Main options:

- strongly contextual: last-clicked / selected signal is the default target
- hybrid: implicit current target, but explicit target text is always allowed
- strongly global: every meaningful command should name a target explicitly

Why it matters:

- affects speed under pressure
- affects readability of command examples
- changes how much the player must type

Current lean:

- hybrid, with strong session context and explicit override support

Current resolution:

- hybrid model confirmed
- implicit session target should handle most early-game use
- explicit target text remains legal and important
- terminal dispatch should resolve explicit target first, then session context, then selected signal if appropriate

Remaining uncertainty:

- how much the player should see of current session state at all times
- whether multiple simultaneous terminal windows should share or isolate targeting context in the near term

### T-003 Syntax Strictness

Question:

How forgiving should the parser be with typos, abbreviations, spacing, and synonyms?

Why it matters:

- heavily shapes terminal feel
- determines whether failure feels fair

Current lean:

- readable and forgiving enough that parser friction is not the main difficulty
- not so loose that command identity becomes muddy

### T-004 Information Density

Question:

How much junk output should the terminal surface before it starts damaging fast play?

Sub-questions:

- how often should the player read full boot blurbs
- when should the game summarize vs dump raw detail
- how much noise belongs in early signals vs advanced ones

Why it matters:

- terminal feel depends on flavorful output
- triage play depends on readable output

### T-005 Quick Aids

Question:

What helper affordances are allowed without undermining typed fluency?

Candidate aids:

- command suggestions
- target buttons
- tab completion
- command history
- quick-reference overlays

Why it matters:

- accessibility and feel both live here

Current lean:

- use aids for recall and speed, not for bypassing understanding

### T-006 Process / Property Depth

Question:

How deep should subprocess and property manipulation go in the near term?

Why it matters:

- determines whether the terminal feels broad or truly surgical
- heavily impacts implementation scope

Current lean:

- broad interaction first
- defer deeper property systems unless the game clearly needs them

### T-007 Credentials And Access Escalation

Question:

How important is the clearance / credentials layer to the terminal fantasy in early implementation?

Current direction:

- credentials bypass minigame puzzles on signals with matching or lower clearance
- credentials are obtained from certain guards and certain data terminals
- credentials likely have limited uses or a time limit
- limited uses are the current lean

Why it matters:

- changes what `ACCESS` means
- creates a strategic layer between scanning, hacking, and bypassing

Current lean:

- credentials are important enough to treat as part of the intended terminal design space

Remaining uncertainty:

- use-count based vs time-limited expiration
- whether credentials apply automatically or can sometimes require explicit invocation
- how much IC should be allowed to burn, corrupt, or consume credentials

### T-008 LINK Identity

Question:

What should `LINK` actually be in play, and what kinds of relationships should it be allowed to create?

Possible identities:

- reroute one signal's output into another
- share / mirror detection feeds
- redirect consequences
- create temporary functional pairings between systems

Why it matters:

- `LINK` is one of the most distinctive commands discussed
- it can either become a signature creative tool or a complexity sink

What needs deciding:

- how explicit the final syntax should be
- what classes of pairings are legal in the near term
- whether the first implementation should be freeform or semi-implicit by signal type
- whether the player chooses subprocesses directly or picks from surfaced legal options

Current resolution:

- `LINK` is late in the onboarding curve and should not shape early-game terminal teaching
- `LINK` is conceptually a read-target to write-target routing command
- its intended use is making one signal's behavior influence or overwrite another

### T-009 Terminal-Puzzle Handshake

Question:

How exactly should the terminal hand off into other puzzles?

Examples:

- `ACCESS` fails and launches a puzzle directly
- `PROBE` reveals what puzzle is needed
- `RUN` explicitly invokes a tool or cracking program

Why it matters:

- determines whether the terminal feels like the language of play or just a gateway screen

### T-010 Corp Voice vs Mechanical Clarity

Question:

How far should corp-specific terminal voice drift without hurting readability?

Why it matters:

- flavor is valuable
- readability is more valuable during active triage

Current lean:

- structure stays stable
- wording and tone drift by corp
- corp voice should not rewrite the rules of parsing
