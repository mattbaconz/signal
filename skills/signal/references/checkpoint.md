# SIGNAL Checkpoint Format

The checkpoint is the single highest-leverage compression technique for long sessions. It replaces 3,000+ tokens of conversation history with ~40 tokens of structured state.

---

## When Checkpoints Fire

- **SIGNAL-3 (auto):** Every 5 turns. Configurable: `CKPT:every N turns`
- **Manual:** User types `/signal-ckpt` or "checkpoint" or "compress context"
- **On demand:** When context window pressure is detected

---

## Format Spec

```
CKPT[N]:
  §project={name} §stack={tech}
  progress=[{task}✓, {task}✗, {task}∅, {task}/]
  blockers=[{issue}⊥{component}]
  next={next_task}
  §decisions=[{decision}✓]
```

### Field reference

| Field | Required | Meaning |
|---|---|---|
| `[N]` | yes | Checkpoint sequence number, starts at 1 |
| `§project` | yes | Project name or identifier |
| `§stack` | if relevant | Tech stack (omit if obvious from project) |
| `progress` | yes | Task list with status symbols |
| `blockers` | only if active | Current blockers only — resolved blockers are dropped |
| `next` | yes | The single next action |
| `§decisions` | only if future-relevant | Decisions that affect work not yet done |

### Status symbols

| Symbol | Meaning |
|---|---|
| `✓` | Complete |
| `✗` | Failed / broken |
| `∅` | Not started |
| `/` | In progress |
| `⊥` | Blocked |

---

## Hard Rules

1. **≤50 tokens total.** If the checkpoint exceeds 50 tokens, compress further. Drop resolved items, merge related items, abbreviate task names.

2. **Checkpoint replaces, not appends.** After a checkpoint fires, all prior conversation history can be dropped. The checkpoint IS the history.

3. **Only active blockers.** If a blocker was resolved, it does not appear in the checkpoint. Resolved state belongs to `progress`, not `blockers`.

4. **Only future-relevant decisions.** `§decisions` only includes decisions that will affect work not yet done. Past decisions that have no forward implication are dropped.

5. **`next` is singular.** One task. The checkpoint is not a backlog — it is a handoff to the next turn.

6. **Inject at top of context.** When resuming after a checkpoint, paste the checkpoint as the first thing in the new context window. It bootstraps the session.

---

## Worked Example

### Before (10-turn session, ~2,400 tokens of history)

```
Turn 1: User asked to add JWT auth to Express API. We discussed strategy.
Turn 2: Decided to use jsonwebtoken library, store refresh tokens in Redis.
Turn 3: Implemented /auth/login endpoint. Tests failing.
Turn 4: Fixed tests — issue was bcrypt async not being awaited.
Turn 5: Started /auth/refresh endpoint. Hit a Redis connection issue.
Turn 6: Resolved Redis issue — was wrong env var name.
Turn 7: /auth/refresh endpoint complete. Moving to /auth/logout.
Turn 8: /auth/logout done. Now need to add middleware to protected routes.
Turn 9: Middleware added. Found issue — token expiry not being checked.
Turn 10: [current turn — expiry fix in progress]
```

### After (CKPT[2], ~35 tokens)

```
CKPT[2]:
  §project=express-api §stack=node+jwt+redis
  progress=[login✓, refresh✓, logout✓, middleware/, expiry-check∅]
  next=fix token expiry check in middleware
```

Note: Redis issue is gone (resolved). Bcrypt bug is gone (resolved). Decisions about jsonwebtoken and Redis are gone (already implemented — no longer future-relevant). What remains is exactly what the next turn needs.

---

## Multi-Blocker Example

```
CKPT[4]:
  §project=data-pipeline §stack=python+airflow+postgres
  progress=[ingestion✓, transform✓, validation✗, load∅, report∅]
  blockers=[validation⊥schema_mismatch, load⊥validation_incomplete]
  next=fix schema_mismatch in validation step
  §decisions=[use_upsert_not_insert✓]
```

`§decisions` includes `use_upsert_not_insert` because the load step (not yet started) depends on it.

---

## Checkpoint with Aliases

If the session established aliases (`[X1]`, `[X2]`, etc.), carry them forward in the checkpoint:

```
CKPT[3]:
  §project=auth-service
  [X1]=refresh_token_rotation [X2]=redis_connection_pool
  progress=[X1✓, X2/, login✓]
  blockers=[X2⊥env_config]
  next=fix X2 env var name
```

Aliases declared in the checkpoint are valid for the remainder of the session.

---

## Collapse Algorithm

When collapsing a session into a checkpoint:

1. **Extract all tasks mentioned.** Assign status from last known state.
2. **Drop all resolved blockers.** If it was fixed, it's gone.
3. **Identify forward-relevant decisions only.** "We chose Redis" is only in `§decisions` if future work still depends on it.
4. **Set `next` to the single most immediate pending action.**
5. **Count tokens.** If >50, merge related tasks, abbreviate names, drop low-signal items.
6. **Verify the checkpoint is sufficient to resume.** Could someone read only the checkpoint and continue the work? If no, add the missing signal.
