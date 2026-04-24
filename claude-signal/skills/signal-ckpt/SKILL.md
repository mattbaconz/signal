---
name: signal-ckpt
description: >
  Manually triggers a checkpoint compression of the current session state.
  Collapses conversation history into a compact state atom (≤50 tokens). Use when
  user types /signal-ckpt, "checkpoint", "compress context", "summarize session",
  "save state", or when the context window is getting large. In SIGNAL-3 mode
  this fires automatically every 5 turns.
signal_bundle_version: "0.3.2"
---

# ⚡ signal-ckpt — Manual Checkpoint

Collapse the session into a ≤50 token state atom. Drop all prior history. Resume from the atom.

---

## Invocation Triggers

Activate when user says any of:
- `/signal-ckpt`
- `"checkpoint"`, `"compress context"`, `"summarize session"`
- `"save state"`, `"compress history"`, `"ckpt"`
- Auto-fires in SIGNAL-3 mode every 5 turns

---

## Output Format

```
CKPT[N]:
  §project={name} §stack={tech}
  progress=[{task}✓, {task}✗, {task}∅, {task}/]
  blockers=[{issue}⊥{component}]
  next={next_task}
  §decisions=[{decision}✓]
```

`N` = checkpoint sequence number, starting at 1. Increment on each checkpoint.

**Minimal valid checkpoint (when session is simple):**
```
CKPT[1]:
  §project=my-app
  progress=[auth✓, api/]
  next=finish api endpoints
```

**Full checkpoint (active blockers, decisions, aliases):**
```
CKPT[3]:
  §project=data-pipeline §stack=python+airflow
  [X1]=schema_validation_step [X2]=postgres_loader
  progress=[ingest✓, transform✓, X1✗, X2∅]
  blockers=[X1⊥schema_mismatch]
  next=fix schema_mismatch in X1
  §decisions=[use_upsert✓]
```

---

## Hard Rules

1. **≤50 tokens total.** Count ruthlessly. If over, compress further: merge related tasks, abbreviate names, drop resolved items.

2. **Checkpoint replaces conversation history.** After this fires, all prior turns can be dropped. The checkpoint IS the history.

3. **Only active blockers.** Resolved blockers are gone. They do not appear anywhere in the checkpoint.

4. **Only future-relevant decisions.** `§decisions` only includes decisions that affect work not yet complete. Past decisions with no forward implication are dropped.

5. **`next` is singular.** One task. The most immediate pending action. Not a backlog.

6. **Carry active aliases forward.** Any `[Xn]` aliases still in use must appear in the checkpoint. Aliases for resolved items are dropped.

---

## Collapse Algorithm

When generating a checkpoint:

1. **Identify all tasks** mentioned in the session. Assign each a status from its last known state (`✓` `✗` `∅` `/` `⊥`).

2. **Drop resolved blockers.** If a blocker was fixed, it's gone.

3. **Filter `§decisions`** to only those that affect future work.

4. **Set `next`** to the single most immediate pending or in-progress action.

5. **Count tokens.** If >50:
   - Merge related tasks (`auth-login✓ + auth-refresh✓` → `auth✓`)
   - Abbreviate task names (keep enough to be unambiguous)
   - Drop sev1/low-signal completed tasks
   - Omit `§stack` if obvious from project name

6. **Verify sufficiency.** Could someone read only this checkpoint and resume the work without prior context? If no, add the missing signal.

---

## Status Symbols

| Symbol | Meaning |
|---|---|
| `✓` | Complete |
| `✗` | Failed / broken |
| `∅` | Not started |
| `/` | In progress |
| `⊥` | Blocked |

---

## Resuming from a Checkpoint

When a session resumes after a checkpoint (new context window, continuation):

1. Paste the checkpoint as the **first thing** in the new context.
2. The checkpoint bootstraps full session state.
3. Resume from `next` without re-reading prior turns.
4. Aliases declared in the checkpoint are active immediately.

**Resume format:**
```
[Resuming from CKPT[2]]
CKPT[2]:
  §project=api-service §stack=node+express
  progress=[auth✓, routes/, tests∅]
  next=finish routes
```

---

## SIGNAL-3 Auto-Checkpoint

In SIGNAL-3 mode, checkpoints fire automatically every 5 turns (or the configured interval).

Auto-checkpoint behavior:
- Fires silently at the end of turn N (not announced before)
- Output appears as the last element of the turn N response
- Turn N+1 begins with the checkpoint already in context

**Configuring the interval:**
```
BOOT: CKPT:every 3 turns    ← more aggressive
BOOT: CKPT:every 10 turns   ← less aggressive
BOOT: CKPT:∅                ← disable auto-checkpoint (manual only)
```

---

## Examples

### Simple 5-turn debug session

```
CKPT[1]:
  §project=auth-api
  progress=[login-endpoint✓, refresh-endpoint/, logout∅]
  blockers=[refresh⊥redis_timeout]
  next=fix redis timeout in refresh endpoint
```
Token count: ~22 tokens. Under limit.

### Complex 15-turn architecture session

```
CKPT[3]:
  §project=platform-v2 §stack=nextjs+postgres+redis
  [X1]=auth_service [X2]=caching_layer [X3]=rate_limiter
  progress=[X1✓, X2/, X3∅, db-schema✓, api-routes/]
  blockers=[X2⊥session_store_conflict]
  next=resolve X2⊥session_store
  §decisions=[jwt_over_sessions✓, redis_for_X2✓]
```
Token count: ~38 tokens. Under limit.

---

## Eat Your Own Cooking

The checkpoint itself must be maximally compressed:
- No preamble ("Here is a checkpoint of our session:")
- No explanation after the checkpoint atom
- The checkpoint IS the output — nothing before, nothing after
- If something prevents checkpoint generation: one line, TMPL:bug format
