# Architecture notes

Study diagrams for System Design prep. Each topic is a self-contained HTML page: open it in any browser (no build step). Fonts load from Google Fonts when online and fall back to system fonts offline.

| Topic | File | Covers |
|-------|------|--------|
| Write-Ahead Logging (WAL) | [`wal-architecture.html`](wal-architecture.html) | Commit path and fsync, ARIES crash recovery (analysis / redo / undo), SQLite WAL mode, replicated logs (Raft, Kafka) |
| Colibri MoE inference (to study) | [`colibri-architecture.html`](colibri-architecture.html) | Running a 744B MoE on 25 GB RAM: expert streaming from NVMe, sigmoid top-k router, per-layer LRU + prefetch (live simulation), MLA, MTP speculation, study checklist |
| Speculative decoding | [`speculative-decoding-architecture.html`](speculative-decoding-architecture.html) | Draft-then-verify, why one verify pass is almost free (memory-bound + causal mask, 70B worked numbers), (1−α^(k+1))/(1−α) acceptance formula, live α/k/cost simulation, self-check |

## Adding a topic

- Name the file `<topic>-architecture.html` (kebab-case).
- Keep it standalone: inline CSS and SVG, no local assets.
- Add a row to the table above.
