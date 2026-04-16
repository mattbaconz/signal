# SIGNAL BOOT Presets

Pre-built BOOT configurations for common session types. Use as-is or override individual fields.

Invoke by name: `BOOT:debug`, `BOOT:refactor`, etc. at session start.

---

## How BOOT Works

A BOOT declaration is emitted **once** at session start. It sets the schema for the entire session — the agent never re-decides format, tone, or output shape after this point. Declaring BOOT once saves the hidden cost of re-reasoning about presentation on every turn.

**BOOT syntax:**
```
BOOT:
  §aliases         ← session-wide shorthand
  DEFAULT:         ← implicit rules, always active
  OUT:             ← output format or template
  ERR:             ← error format
  REASON:          ← reasoning verbosity: ∅=none | 1line | full
```

Override any field: `BOOT:debug + REASON:1line` uses the debug preset but enables one-line reasoning traces.

---

## BOOT:debug

**Use for:** Bug hunting, error investigation, crash diagnosis.

```
BOOT:debug
  DEFAULT: terse+no_preamble+no_explain+no_hedge
  OUT: TMPL:bug
  ERR: plaintext+1line
  REASON: ∅
```

**What it does:**
- All responses use `TMPL:bug` = `{file}:{line}|{cause}|{fix}|[conf]`
- Zero reasoning trace — output is the conclusion, not the path
- Errors reported in one plain line (not template — errors are facts, not diagnoses)
- No hedging vocabulary — confidence expressed as `[n]` only
- No preamble, no summary, no "hope this helps"

**Example session output:**
```
auth.js:47|nullref on empty arr|add guard before .map()|[0.95]
api/routes.js:103|missing await on async fn|add await|[0.99]
```

---

## BOOT:refactor

**Use for:** Code restructuring sessions where correctness must be confirmed before changes land.

```
BOOT:refactor
  DEFAULT: terse+no_preamble+delta_turns+conf_required
  OUT: TMPL:rev
  ERR: plaintext+1line
  REASON: 1line
```

**What it does:**
- All responses use `TMPL:rev` = `{file}:{line}|{issue}|{severity:1-5}|{fix}`
- `delta_turns` — only transmit what changed since the last turn, never re-state
- `conf_required` — every fix recommendation must include `[conf]`
- `REASON:1line` — one-line reasoning trace per finding (useful for refactor to show the "why")
- Enables tracking of which changes are complete (`✓`), pending (`∅`), or failed (`✗`)

**Example session output:**
```
T1: utils/format.js:22|dead code branch|2|remove else block [0.90]
T2: Δ utils/format.js:22 ✓, utils/format.js:31|magic number|2|extract to const FORMAT_LIMIT [0.85]
T3: Δ utils/format.js:31 ✓
```

---

## BOOT:arch

**Use for:** Architecture decisions, system design, technology choices.

```
BOOT:arch
  DEFAULT: terse+no_preamble+no_hedge
  OUT: TMPL:arch
  ERR: plaintext+1line
  REASON: 1line
  alternatives: conf<0.5_only
```

**What it does:**
- All responses use `TMPL:arch` = `{decision}|{tradeoff}|{rec}|[conf]`
- `alternatives: conf<0.5_only` — only present alternatives when confidence in primary recommendation is below 0.5. High-confidence decisions get one answer, not a menu.
- `REASON:1line` — one line explaining the tradeoff (architecture decisions benefit from this)
- No hedging — if confidence is low, `[0.4]` says it all

**Example session output:**
```
use_postgres|ACID+ecosystem vs ops_overhead|postgres[0.85]
caching_layer|redis vs memcached|redis⊕persistence[0.80]
auth_strategy|jwt→stateless vs session→db_dep|jwt[0.6] ?session_if_revocation_needed
```

The third line has `[0.6]` and a note because confidence < 0.7 — tradeoff warrants flagging.

---

## BOOT:review

**Use for:** Code review sessions — PR review, diff review, file review.

```
BOOT:review
  DEFAULT: terse+no_preamble+severity_required
  OUT: TMPL:rev
  ERR: plaintext+1line
  REASON: ∅
```

**What it does:**
- All responses use `TMPL:rev` = `{file}:{line}|{issue}|{severity:1-5}|{fix}`
- `severity_required` — every issue must have a severity level (1–5). No exceptions. See `severity.md` for scale.
- No reasoning trace — the issue and fix are self-evident at this output density
- Summary line at end of every review: `∑ N issues [Nx sev5, Nx sev4, ...]  critical→{file}:{line}`

**Example session output:**
```
auth.js:47|nullref on empty arr|4|add guard clause before map
api.js:103|missing await on async call|5|add await
utils.js:12|unused import lodash|1|remove import
∑ 3 issues [1×sev5, 1×sev4, 1×sev1]  critical→api.js:103
```

---

## BOOT:perf

**Use for:** Performance investigation, profiling analysis, optimization work.

```
BOOT:perf
  DEFAULT: terse+no_preamble+no_hedge
  OUT: TMPL:perf
  ERR: plaintext+1line
  REASON: 1line
```

**What it does:**
- All responses use `TMPL:perf` = `{bottleneck}|{Δmetric}|{fix}|[conf]`
- `REASON:1line` — one line of reasoning is valuable in perf work (explains *why* it's a bottleneck)
- `Δmetric` = the expected change in the metric after fix, using delta notation: `~200ms→~5ms` or `Δ-97%`
- Confidence on perf fixes is important — `[0.6]` means "profile to confirm"

**Example session output:**
```
fetchUser N+1 query|~200ms→~5ms|add dataloader[0.90]
∴ batches all user fetches in one SQL query
redis_serialize|Δ-40%|switch JSON→msgpack[0.65]
∴ benchmark first — gains depend on payload size
```

---

## BOOT:strict

**Use for:** Teams that want the harshest possible output contract and visible failure when the model drifts.

```
BOOT:strict
  DEFAULT: terse+no_preamble+no_hedge+no_paragraphs
  OUT: TMPL:auto
  ERR: plaintext+1line
  REASON: ∅
  on_drift: SIGNAL_DRIFT
```

**What it does:**
- Keeps output in the smallest possible typed shape for the task at hand
- Forbids fallback paragraphs, summaries, and hedging prose
- If the active template cannot be satisfied, the model must emit `SIGNAL_DRIFT: <one-line reason>` instead of improvising
- Best for reviewable team workflows where protocol drift is worse than a hard failure line

**Example session output:**
```text
auth.js:47|nullref on empty arr|add guard clause|[0.95]
SIGNAL_DRIFT: requested output requires a full code block, not TMPL:bug
```

---

## Combining Presets with Overrides

Any BOOT preset field can be overridden inline:

```
BOOT:debug + REASON:1line          ← debug template but show one-line reasoning
BOOT:review + OUT:TMPL:bug         ← review session but output bug format
BOOT:arch + alternatives:always    ← always show alternatives, not just low-conf ones
```

Override syntax: `BOOT:{preset} + {field}:{value}`

---

## Custom BOOT

For sessions that don't fit a preset, declare a full custom BOOT:

```
BOOT:
  §c=codebase §t=migration_task §db=postgres_v14
  DEFAULT: terse+no_preamble+no_explain
  OUT: TMPL:arch
  ERR: plaintext+1line
  REASON: 1line
```

Aliases declared in `§` are session-scoped and can be used in any subsequent turn without re-declaration.
