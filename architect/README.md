# Architecture notes

Study diagrams for System Design prep. Each topic is a self-contained HTML page: open it in any browser (no build step). Fonts load from Google Fonts when online and fall back to system fonts offline.

| Topic | File | Covers |
|-------|------|--------|
| Write-Ahead Logging (WAL) | [`wal-architecture.html`](wal-architecture.html) | Commit path and fsync, ARIES crash recovery (analysis / redo / undo), SQLite WAL mode, replicated logs (Raft, Kafka) |

## Adding a topic

- Name the file `<topic>-architecture.html` (kebab-case).
- Keep it standalone: inline CSS and SVG, no local assets.
- Add a row to the table above.
