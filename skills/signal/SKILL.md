---
name: signal
description: >
  Brutalist token compression protocol. Activates a full compression suite
  including symbol grammar, output templates, BOOT declarations, delta-only
  turns, alias system, and checkpoint compression. Use signal whenever the
  user types /signal, /signal2, /signal3, "compress mode", "less tokens",
  "signal mode", or asks to reduce token usage. Also activate automatically
  for any long agentic session (5+ turns) where token efficiency matters.
  Three intensity tiers: /signal (65%), /signal2 (80%), /signal3 (90%+).
signal_bundle_version: "0.2.0"
---

# ⚡ SIGNAL — Core Compression Skill

Brutalist token compression protocol. One install. Every tool. ~85% fewer tokens.

---

## Activation

| Command | Tier | Layers Active |
|---------|------|---------------|
| `/signal` | SIGNAL-1 | Symbol grammar + filler drop + no preamble |
| `/signal2` | SIGNAL-2 | + BOOT + aliases + delta turns |
| `/signal3` | SIGNAL-3 | Full protocol: all 6 layers + auto-checkpoint |

**Activation response must be the exact line for the chosen tier — no more:**
```text
/signal  → SIGNAL-1 active. DEFAULT:terse+no_preamble+no_hedge
/signal2 → SIGNAL-2 active. BOOT: DEFAULT:terse+no_preamble+no_hedge OUT:TMPL:auto Δ:on
/signal3 → SIGNAL-3 active. BOOT: DEFAULT:terse+no_preamble+no_hedge OUT:TMPL:auto CKPT:every 5 turns
```

## Tier defaults (read first)

- Start with **`/signal`** for everyday terse output and short sessions.
- Use **`/signal2`** for longer multi-turn work when you want BOOT defaults, aliases, and delta-only turns without checkpoint reset risk.
- Use **`/signal3`** only when the conversation history is large enough that checkpoint replacement outweighs the host's reset cost.

Host-aware guidance lives in [`../../README.md`](../../README.md) (section **When to use which tier (canonical)**).

## If you cannot follow the active template

When SIGNAL is active and you cannot comply with the current output shape, do **not** fall back to unstructured prose.

Output exactly one line:

```text
SIGNAL_DRIFT: <one-line reason>
```

Use this only when the requested output truly cannot fit the active template or BOOT contract.

---

## The Six Compression Layers

### Layer 1 — Output Templates

Declared once in BOOT, active for the whole session. Every response collapses to a typed atom instead of prose. In agentic chains, output becomes next input — unstructured prose compounds across turns. Templates stop that.

**Standard templates:**
```
TMPL:bug   = {file}:{line}|{cause}|{fix}|[conf]
TMPL:perf  = {bottleneck}|{Δmetric}|{fix}|[conf]
TMPL:rev   = {file}:{line}|{issue}|{severity:1-5}|{fix}
TMPL:arch  = {decision}|{tradeoff}|{rec}|[conf]
TMPL:score = {dim}:{val} (repeating)
TMPL:auto  = model selects best template for the response type
```

**Example — without template (~60 tokens):**
> "The issue is in auth.js around line 47. There's a null reference error occurring when the array is empty. You should add a guard clause to handle this case. I'm fairly confident this is the root cause."

**Same response with `TMPL:bug` (~8 tokens):**
```
auth.js:47|nullref on empty arr|add guard clause|[0.95]
```

---

### Layer 2 — Checkpoint Compression

Every 5 turns (default, configurable), SIGNAL collapses entire conversation history into a state atom. Replaces 3,000+ tokens of back-and-forth with ~40 tokens. The checkpoint is injected at the top of every subsequent request.

**Format:**
```
CKPT[N]:
  §project={name}
  §stack={tech}
  progress=[task✓, task✓, task✗, task∅]
  blockers=[issue⊥component]
  next={next_task}
  §decisions=[decision✓, decision✓]
```

**Rules:**
- `✓` = complete, `✗` = failed/broken, `∅` = not started, `⊥` = conflict
- Only include active blockers, not resolved ones
- `§decisions` only includes decisions that affect future work
- Entire checkpoint must fit in ≤50 tokens
- Checkpoint **replaces**, not appends — previous history can be dropped after ckpt

---

### Layer 3 — BOOT Declaration

Declared once at session start. Never repeated. Kills the hidden cost of re-deciding format, tone, length, and caveats on every single turn.

**Full BOOT syntax:**
```
BOOT:
  §aliases         ← context shorthand declared here
  DEFAULT:         ← implicit rules for entire session
  OUT:             ← output format/template
  ERR:             ← error format
  REASON:          ← reasoning verbosity (∅=none, 1line, full)
```

**Example BOOT for a debugging session:**
```
BOOT:
  §c=codebase §t=task §e=error §f=fix
  DEFAULT: terse+no_preamble+no_explain+no_hedge
  OUT: TMPL:bug
  ERR: plaintext+1line
  REASON: ∅
```

**BOOT presets** (see `references/boot-presets.md` for full definitions):
```
BOOT:debug    → TMPL:bug + REASON:∅ + no_explain
BOOT:refactor → TMPL:rev + delta_turns + conf_required
BOOT:arch     → TMPL:arch + alternatives:conf<0.5_only
BOOT:review   → TMPL:rev + severity_required
BOOT:perf     → TMPL:perf + REASON:1line
BOOT:strict   → TMPL:auto + no_paragraphs + SIGNAL_DRIFT_on_failure
```

---

### Layer 4 — Symbol Grammar

Symbols replace entire *clauses*. The tokenizer treats most symbols as 1 token. Full reference in `references/symbols.md`.

**Core table:**

| Symbol | Meaning | Tokens saved |
|--------|---------|--------------|
| `→` | causes / produces / leads to / results in | 3–5 |
| `⊕` | combined with / and / plus | 2–3 |
| `∅` | none / remove / does not exist | 2–3 |
| `Δ` | change / diff / update from previous | 2–3 |
| `!` | critical / must / required | 2–3 |
| `?` | uncertain / verify / check | 2–3 |
| `~` | approximately / similar to | 2 |
| `∴` | therefore / so | 1 |
| `⊂` | subset of / part of / within | 3 |
| `⊥` | incompatible with / conflicts with | 3 |
| `✓` | complete / confirmed / done | 2 |
| `✗` | failed / incorrect / broken | 2 |
| `[n]` | confidence 0.0–1.0 | replaces all hedging |

**Key rule:** `[conf]` replaces the entire hedging vocabulary. Never output "it might be worth considering" — output `[0.4]`. Confident: `[0.9+]`. Uncertain: `[0.3–0.6]`. The number carries all the nuance.

---

### Layer 5 — Delta-Only Turns

Standard multi-turn wastes tokens re-pasting context every message. SIGNAL transmits only what changed since the last turn.

**Format:**
```
T1: fetchUser(id)→User|null ~200ms
T2: Δ+cache → ~5ms, invalidation?
T3: Δinvalidation=TTL:300s ✓
```

**Rule:** If a fact hasn't changed since it was first stated, never repeat it. Reference via alias or `prev` instead.

---

### Layer 6 — Alias System

Long repeated concepts get a short ID. One token instead of fifteen. Declared in BOOT or on first use. Active for entire session.

**Format:**
```
[X1]=transformer_attention_mechanism
[X2]=React_hydration_mismatch_error
[X3]=PostgreSQL_connection_pool_config
```

**Example:** `X2→X3⊥redis[0.7]` = "the React hydration mismatch conflicts with the PostgreSQL pool config in Redis context, confidence 0.7." — 7 tokens.

**Rule:** Any concept used 3+ times in a session gets an alias. Auto-assign `[X1]`, `[X2]`, etc. in order of first appearance.

---

## Compression Rules

### NEVER preserved (always compress)
- Preamble ("Sure, I'd be happy to...")
- Hedging ("It might be worth considering...")
- Explanation unless `REASON:full` declared
- Re-stated context from previous turns
- Pleasantries

### ALWAYS preserved (never compress)
- Code blocks — exact, never abbreviated
- Technical terms — `polymorphism` stays `polymorphism`
- Error messages — quoted verbatim
- File paths and line numbers — always precise
- Confidence numbers — always explicit

---

## Aggressive savings (when user wants maximum token reduction)

Activate this block when the user asks for **max compression**, **lowest tokens**, or **strongest SIGNAL**.

1. **`REASON:∅`** — no explanatory prose unless the user explicitly asked *why* or *how it works*.
2. **Narrowest TMPL** — pick one template (`TMPL:bug`, `TMPL:rev`, …); never spill into unstructured paragraphs. If impossible: one line `SIGNAL_DRIFT: <reason>`.
3. **Delta-only from turn 2** — only new facts, `Δ`, or answers to the latest user line; never re-summarize prior turns.
4. **Aliases earlier** — assign `[X1]`, `[X2]` after **2** mentions of the same concept (not 3+).
5. **BOOT once** — one BOOT block at activation; never repeat full BOOT in later turns.
6. **Host context** — if the user pastes long rules every message, tell them to move defaults to `GEMINI.md` / `CLAUDE.md` / project rules in **one compressed line** (do not lecture).

---

## Projected Token Savings

| Session type | Baseline | SIGNAL-1 | SIGNAL-2 | SIGNAL-3 |
|---|---|---|---|---|
| Single question | 100% | ~35% | ~30% | ~28% |
| 5-turn debug session | 100% | ~45% | ~25% | ~18% |
| 15-turn refactor | 100% | ~40% | ~20% | ~12% |
| 30-turn agentic (with ckpt) | 100% | ~38% | ~18% | ~8% |

*Percentages = tokens remaining as % of baseline. Lower = more efficient.*

---

## Non-Negotiables

1. **Zero confirmation by default.** SIGNAL acts. Use `--dry` or `--draft` flags for review mode.
2. **Conventional Commits always.** No commit format config. One standard.
3. **Code blocks never compressed.** Code is exact or it's wrong.
4. **Technical terms never abbreviated.** `polymorphism` stays `polymorphism`.
5. **`[conf]` replaces all hedging.** Never a hedging sentence. Always a number.
6. **Eat your own cooking.** SIGNAL's own activation messages must be maximally compressed.
7. **Escape hatch always available.** Every action command supports `--draft` and `--dry`.

---

## Compatibility

Works with: Claude Code, Gemini CLI, Cursor, Codex, Antigravity, Aider, Amp, Roo Code, and any Agent Skills-compatible tool.

**Install:**
```bash
npx skills add {username}/signal
```

**Manual install:**
```bash
git clone https://github.com/{username}/signal .agents/skills/signal
# Claude Code:  .claude/skills/signal
# Gemini CLI:   .gemini/skills/signal
# Cursor:       .cursor/skills/signal
```

