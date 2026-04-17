# SIGNAL Symbol Grammar

Full reference for all symbols in the SIGNAL compression protocol.

> **Key principle:** Symbols replace entire *clauses*, not just words. The tokenizer treats most of these as 1 token. Using a symbol instead of a clause saves 2–5 tokens per use. Across a 30-turn session, this compounds to hundreds of tokens.

---

## Core Symbol Table


| Symbol | Meaning                                     | Example usage             | Tokens saved         |
| ------ | ------------------------------------------- | ------------------------- | -------------------- |
| `→`    | causes / produces / leads to / results in   | `nullref→crash`           | 3–5                  |
| `⊕`    | combined with / and / plus                  | `auth⊕rate-limit`         | 2–3                  |
| `∅`    | none / remove / does not exist / empty      | `cache=∅`                 | 2–3                  |
| `Δ`    | change / diff / update from previous        | `Δ+cache→~5ms`            | 2–3                  |
| `!`    | critical / must / required / urgent         | `!fix before deploy`      | 2–3                  |
| `?`    | uncertain / verify / check / unknown        | `race condition?`         | 2–3                  |
| `~`    | approximately / similar to / roughly        | `~200ms`                  | 2                    |
| `∴`    | therefore / so / thus                       | `∴ add guard clause`      | 1                    |
| `⊂`    | subset of / part of / within / scoped to    | `auth⊂middleware`         | 3                    |
| `⊥`    | incompatible with / conflicts with / blocks | `X2⊥X3`                   | 3                    |
| `✓`    | complete / confirmed / done / resolved      | `cache✓`                  | 2                    |
| `✗`    | failed / incorrect / broken / rejected      | `test✗ nullref`           | 2                    |
| `∑`    | summary / total / aggregate                 | `∑ 3 issues`              | 2                    |
| `§`    | alias declaration / named concept           | `§c=codebase`             | —                    |
| `[n]`  | confidence score 0.0–1.0                    | `add guard clause [0.95]` | replaces all hedging |


---

## Confidence Score `[n]` — The Hedging Replacement

`[conf]` is the most important symbol in SIGNAL. It replaces the entire hedging vocabulary that LLMs are trained to produce.

**Never output:**

- "It might be worth considering..."
- "One possible approach could be..."
- "I'm fairly confident that..."
- "You may want to think about..."
- "I think this might..."

**Always output:**

```
[0.95]  ← high confidence, near-certain
[0.80]  ← confident, minor uncertainty
[0.60]  ← moderate confidence, verify
[0.40]  ← uncertain, check before applying
[0.20]  ← low confidence, exploratory only
```

**Decision threshold:** If `[conf] < 0.5`, include a one-line reason for the uncertainty. If `[conf] ≥ 0.5`, the number carries all the nuance — no explanation needed.

---

## Alias System `§` and `[Xn]`

Two kinds of aliases:

### Session aliases (`§`) — declared in BOOT

Short-form for frequently referenced project concepts. Declared once in BOOT, valid for the session.

```
BOOT:
  §c=codebase
  §t=current_task
  §e=the_error_being_debugged
  §f=proposed_fix
```

Usage: `§c has §e in auth.js:47` instead of "The codebase has the error being debugged in auth.js:47"

### Auto-aliases (`[Xn]`) — assigned on third use

Any concept mentioned 3+ times in a session gets an auto-alias. Assign in order of first appearance.

```
[X1]=transformer_attention_mechanism
[X2]=React_hydration_mismatch_error
[X3]=PostgreSQL_connection_pool_config
```

**Compound example:**
`X2→X3⊥redis[0.7]`
= "The React hydration mismatch causes a conflict with the PostgreSQL connection pool config in the Redis context, confidence 0.7"
= 7 tokens vs ~25 tokens

---

## Progress Status Symbols

Used in checkpoints and task lists:


| Symbol | Meaning            |
| ------ | ------------------ |
| `✓`    | Complete / done    |
| `✗`    | Failed / broken    |
| `∅`    | Not started        |
| `⊥`    | Blocked / conflict |
| `/`    | In progress        |


**Checkpoint example:**

```
progress=[auth✓, cache✓, tests✗, deploy∅]
blockers=[tests⊥ci-runner]
```

---

## Delta Notation `Δ`

`Δ` marks what has changed since the previous turn. Combined with `+` and `-` for additions and removals:


| Notation           | Meaning                    |
| ------------------ | -------------------------- |
| `Δ+{thing}`        | added {thing}              |
| `Δ-{thing}`        | removed {thing}            |
| `Δ{thing}={value}` | {thing} changed to {value} |
| `Δ∅`               | no change since last turn  |


**Multi-turn example:**

```
T1: fetchUser(id)→User|null  ~200ms
T2: Δ+cache → ~5ms, invalidation?
T3: Δinvalidation=TTL:300s ✓
```

T2 and T3 only transmit what changed — the original fetch behavior is never re-stated.

---

## Relationship Operators


| Symbol | Relationship        | Example                         |
| ------ | ------------------- | ------------------------------- |
| `→`    | A causes/produces B | `uncaught_exception→retry_loop` |
| `⊕`    | A and B together    | `auth⊕session_store`            |
| `⊥`    | A conflicts with B  | `v1_api⊥v2_schema`              |
| `⊂`    | A is part of B      | `rate_limiter⊂middleware`       |
| `∴`    | A therefore B       | `cache_miss∴db_query`           |


---

## Rules for Using Symbols

1. **Symbols replace clauses, not words.** Don't write `auth→` when you mean "the auth module". Write `auth→crash` when you mean "the auth module causes a crash."
2. **Never use symbols inside code blocks.** Code is exact. `→` inside a code block means an arrow, not "causes."
3. **Never use symbols in technical terms.** `→` inside `Promise<User|null>` is the TypeScript generic separator, not SIGNAL.
4. **Use `[conf]` on every non-trivial claim.** If you're asserting a root cause, recommending a fix, or making a judgment call — add `[conf]`. Omit it only for pure facts (line numbers, file paths, error quotes).
5. **Combine symbols freely.** `X1⊕X2→X3[0.8]` is valid. "Combined with" + "causes" + confidence in 5 tokens.

