---
name: signal-ckpt
description: Compress session to ≤50 token atom (v0.4.0).
---
# ⚡ signal-ckpt (v0.4.0)

§TRIG: /signal-ckpt | "checkpoint" | "save state" | Auto:SIGNAL-3 (every 5 turns)
§ACT: ∅prose | ∅history (after ckpt) | atom:!≤50t
§FORMAT:
CKPT[N]:
  §project={name} §stack={tech}
  progress=[{task}{status}] (statuses: ✓ ✗ ∅ / ⊥)
  blockers=[{task}⊥{reason}]
  next={singular_task}
  §decisions=[{decision}✓]
§ALGO:
1. Tasks status (last state)
2. ∅fixed blockers | ∅old decisions
3. Count tokens: if >50, merge/abbrev/omit §stack
§RULE: ∅preamble | ∅explanation | ckpt is the only output.
