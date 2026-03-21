# Brainstorm Synthesis Workflow

This workflow is for turning long-form brainstorm chats into a durable design reference without flattening disagreements or losing edge-case detail.

## Goal

Use the filesystem as the agent's memory:

- `BrainstormInbox/`: immutable raw source material
- `BrainstormWorking/`: per-source extraction notes
- `BrainstormResults/`: home for results of synthesized notes, even if WIP, including DesignBible.md
- `SourceIndex.md`: processing ledger
- `Contradictions.md`: unresolved conflicts and judgment calls
- `DesignBible.md`: current canon

## Rules Of Use

1. Treat files in `BrainstormInbox/` as source records. Do not edit them after import.
2. Extract before merging. Every source should get a working note in `BrainstormWorking/`.
3. Do not silently resolve conflicts. Put them in `Contradictions.md`.
4. Only move material into `DesignBible.md` when it is:
   - clearly supported by one or more sources, or
   - explicitly approved by you after a contradiction review.
5. Keep provenance. Every meaningful section in the bible should cite the source files that informed it.

## Recommended Agent Prompt

Use this when you want the extension to continue the process with minimal micromanagement:

```text
Process every queued source in DesignNotes/BrainstormInbox.
For each source:
- read the raw file
- update or complete its matching note in DesignNotes/BrainstormWorking
- extract decisions, speculative ideas, unresolved questions, terminology, mechanics, narrative details, and implementation constraints
- ignore specific technical implementation details and discussion about code, focus only on game design and brainstorming
- register any conflicts or ambiguities in DesignNotes/Contradictions.md instead of guessing
- merge only resolved material into DesignNotes/DesignBible.md with source references
- update DesignNotes/SourceIndex.md to reflect progress
Pause and ask me only when a contradiction needs a design judgment.
```

## Suggested Review Cadence

1. Drop new chats into `BrainstormInbox/`.
2. Run `Scripts/Tools/brainstorm_ingest.ps1` to register them.
3. Ask the agent to process `queued` or `extracting` entries.
4. Review `Contradictions.md`.
5. Resolve items and have the agent fold the answers into `DesignBible.md`.

## Status Meanings

- `queued`: source exists but has not been extracted
- `extracting`: working note exists and is being distilled
- `needs_review`: contradictions or ambiguities block canon merge
- `merged`: extracted and reflected in the bible
- `archived`: source remains for provenance but is not active
