# Brainstorm Inbox

Drop raw brainstorm chats here as `.md`, `.txt`, or `.json` files.

Guidelines:

- Keep one conversation or coherent dump per file.
- Prefer descriptive names such as `2026-03-13-terminal-ideas.md`.
- Treat imported files as immutable source records.
- If a file contains several unrelated topics, split it before import if practical.

After adding files, run:

```powershell
./Scripts/Tools/brainstorm_ingest.ps1
```

Then have the agent process any `queued` entries from `DesignNotes/SourceIndex.md`.
