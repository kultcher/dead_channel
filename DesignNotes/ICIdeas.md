# Dead Channel IC Ideas

This file is a compiled direction list for Intrusion Countermeasures. It is meant to organize expansion space, not to lock every idea into the near-term plan.

## IC Design Rules

- IC should create decisions, not just downtime.
- IC should usually be telegraphed enough that players can form plans.
- IC should attack multiple domains, not only one.
- UI-disrupting IC is valid, but it must remain fair and readable.
- Prototype IC should favor a small set of distinct identities over a long pile of gimmicks.

## Main Disruption Domains

### Timing

Purpose:

- force urgency
- delay clean execution
- punish overcommitment

Examples:

- reboot after disablement
- delayed retaliation
- forced wait windows
- shortened safe windows

### Information

Purpose:

- make interpretation harder
- muddy what is true
- tax attention

Examples:

- fuzzy scans
- false readouts
- misleading subprocess names
- partial signal visibility

### Access

Purpose:

- gate entry to systems
- force prerequisites
- create routing or sequencing friction

Examples:

- captcha / checksum barriers
- faraday-style no-access states
- proximity restrictions
- linked systems that require earlier setup

### Punishment / traps

Purpose:

- punish brute force
- punish impatience
- raise cost for wrong reads

Examples:

- tripwires
- honeypots
- retaliatory heat spikes
- progress resets after obvious misuse

### Interface / perception

Purpose:

- interfere with the player's view or inputs
- make the UI itself part of the threat space

Examples:

- popup obstruction
- fake windows
- visual corruption
- temporary command confusion

## Named Idea Bank

### Reboot

Behavior:

- disabled or altered systems recover after a delay

Why it works:

- punishes "solve once and forget"
- keeps pressure alive

### Fuzzy

Behavior:

- scans or readouts become slow, low-confidence, or noisy

Why it works:

- taxes information quality instead of direct execution

### Captcha / Checksum

Behavior:

- access is blocked behind a verification step

Why it works:

- creates friction before high-value interactions

### Faraday

Behavior:

- access denied until the team or signal reaches a closer / valid state

Why it works:

- changes timing and routing decisions

### Tripwire

Behavior:

- specific actions trigger retaliation if performed carelessly

Why it works:

- creates risk around brute-force habits

### Honeypot

Behavior:

- the apparent best target is bait

Why it works:

- punishes shallow reading
- reinforces probe / inspect value

### White Hat Interference

Behavior:

- hostile defenders actively counter the player in real time

Why it works:

- can create strong presence and narrative pressure

Risk:

- becomes unfair fast if not well telegraphed

### UI Obstruction

Behavior:

- windows or overlays block parts of the timeline or other useful information

Why it works:

- matches the game's pressure model

Risk:

- instantly reads as cheap if not tightly controlled

## IC By Usefulness To Prototype

### Strong prototype candidates

- Reboot
- Fuzzy scan interference
- Captcha / checksum access friction
- Tripwire
- Honeypot

Why:

- each attacks a distinct domain
- each is legible
- each can be understood without huge content overhead

### Good later additions

- Faraday-style positional denial
- heavier UI obstruction
- more complex white-hat behavior
- multi-step retaliatory IC chains

Why:

- stronger flavor and system interaction
- higher implementation or readability risk

## Puzzle-Specific IC Hooks

### Sniff hooks

- false target signatures
- delayed clarity
- noisy grid state

### Decrypt hooks

- rekey
- noise injection
- linked keyspaces
- blocked autofill
- candidate obfuscation

### Fuzz hooks

- shrinking probe windows
- false positives
- instability after repeated failed pushes

## Red Flags

- IC that the player cannot meaningfully anticipate
- IC that removes play instead of redirecting it
- IC that is visually clever but strategically empty
- too many UI disruptors too early
- stacking multiple information-denial effects until the game becomes unreadable

## Short Version

IC should make the player's job harder in distinct, readable ways.

The best IC does not merely say "no." It changes the shape of the triage problem, forces reprioritization, and makes the player feel like they are contending with hostile systems rather than arbitrary punishments.
