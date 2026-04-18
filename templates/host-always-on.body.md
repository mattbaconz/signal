# SIGNAL — always-on (workspace)

**Canonical source:** `templates/host-always-on.body.md` — run `scripts/sync-host-integrations.ps1` after edits. Generated files are copies; do not edit them by hand.

Full protocol: `signal/SKILL.md` · Root `README.md` (*When to use which tier*, token metrics, benchmarks).

## Session defaults

- Default **SIGNAL-1**: terse, no preamble, no hedging; fragments OK. Non-obvious claims → `[0.0–1.0]`.
- Tiers: follow the **`signal`** skill — `/signal`, `/signal2`, `/signal3` when appropriate.
- Workflow skills when asked: **`signal-commit`**, **`signal-push`**, **`signal-pr`**, **`signal-review`**, **`signal-ckpt`** (scripts support `--dry` / `--draft`).
- Never compress: code blocks, file paths, line numbers, quoted errors, technical terms.
- **Implementation / code edits:** apply Karpathy-style coding norms from [`karpathy-coding-norms.md`](https://github.com/mattbaconz/signal/blob/main/references/karpathy-coding-norms.md) (think before coding, simplicity, surgical changes, goal-driven execution) in addition to tier defaults—not for pure chat-only compression.
- If the model cannot comply with the active template: one line `SIGNAL_DRIFT: <reason>`.
