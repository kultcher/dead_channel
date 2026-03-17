# Working Note: DesignNotes\BrainstormInbox\Claude_Chat_Minigames.json

## Source Metadata

- UserMessages: 4
- SourceType: json
- Preview: Attached file: PROJECT- Dead Channel.pdf
- ConversationFormat: orpg.3.0
- UpdatedAt: 2026-02-07T21:30:58.256Z
- StartedAt: 2026-02-07T20:55:24.863Z
- AssistantMessages: 3
- Source: `DesignNotes\BrainstormInbox\Claude_Chat_Minigames.json`
- Participants: Claude Opus 4.6
- Status: extracting
- MessageCount: 7
- SourceTitle: Design Dive: Minigames

## High-Fidelity Summary

Focused deep dive on puzzle roles within the run layer, especially how puzzles should create pressure without turning the game into isolated minigame soup.

## Transcript Snapshot

- User: Attached file: PROJECT- Dead Channel.pdf
- User: So I've been working on this hacking themed minigame. See attached design doc. I've got working prototypes of several of the core systems, and want to do a deep design dive before I start finalizing things. Let's tackle these one at a time....
- Assistant: # Sniff Minigame: Deep Design Dive ## Strengths & Weaknesses Analysis ### What's Working - **Speed-appropriate complexity.** A visual search task in a shifting grid is almost pure attention cost, which is exactly what you want. It taxes the...
- User: I think that's about as much as we can get from Sniff, so let's look at Decrypt as it's the other locked-in and prototyped minigame. Here's how it currently works: - A variable-length (default 3 or 4 characters) cipher is at the top of the ...
- Assistant: # Decrypt Minigame: Deep Design Dive ## Strengths & Weaknesses Analysis ### What's Working - **Natural "process delay" cadence.** This is the puzzle type you called out in the doc as incentivizing the player to deal with other things while ...
- User: One more to dig into. This is one I just came up with and haven't prototyped or fleshed out. I like the spaces of timing windows, probing weaknesses and "stacking small successes," inspired by real hackers paradigms like fuzzing. Here's the...

## Concrete Decisions

- Sniff should remain a fast attention check whose difficulty mostly comes from surrounding run pressure, not from raw puzzle complexity.
- Decrypt should occupy the opposite temporal role: a longer-running background process that rewards periodic check-ins and deduction.
- Puzzle difficulty should come more from modifiers, IC disruption, and context than from endlessly adding new standalone puzzle engines.

## Speculative Ideas

- A third puzzle space built around timing windows, probing weaknesses, or "stacking small successes" could complement Sniff and Decrypt if it has a distinct time profile.
- Decrypt could support manual culling, partial deduction rewards, or focus decay to create more mid-puzzle decision points.
- IC variants for puzzles can target information clarity, pace, autofill behavior, and player attention rather than just making puzzles numerically harder.

## Unresolved Questions

- Which third core puzzle type, if any, deserves prototype priority after Sniff and Decrypt.
- How much passive completion is acceptable in Decrypt before it stops feeling like "cracking" and starts feeling like waiting.

## Terminology And Definitions

- Sniff: fast visual search / attention check puzzle.
- Decrypt: slower deduction-and-wait puzzle that can run in the background.
- Focus: player-directed acceleration or emphasis on part of a puzzle state.

## Mechanics And Systems Details

- Sniff is strongest when it stays short, readable, and pressure-sensitive.
- Decrypt works well as a plate the player keeps spinning while handling other threats on the timeline.
- Correct-answer momentum and partial knowledge should feel mechanically rewarding, not purely cosmetic.
- Puzzle-side IC concepts include rekeying, noise injection, masking solved states, linked keyspaces, and encoded candidate displays.

## Narrative Or Tone Details

- Puzzle behavior should reinforce the fantasy of working through hostile systems rather than feeling like abstract arcade tests.

## Implementation Constraints

- Keep the prototype puzzle set narrow and get variety from modifiers.
- Avoid puzzle rules that require heavy tutorial overhead or too much standalone screen time.

## Contradictions To Log

- No direct contradiction with canon, but this source reinforces a narrower prototype puzzle roster than the broad brainstorm lists elsewhere.

## Merge Recommendations

- Merge Sniff and Decrypt into the bible as the current core puzzle pillars.
- Record any third puzzle type as exploratory until a prototype direction is chosen.
