---
name: signal-review
description: >
  Review code in SIGNAL's one-line format with required severity per issue.
  Output is typed, structured, and chainable — not prose paragraphs. Use when
  user types /signal-review, "review this", "review my code", "check this PR",
  "review this file", or asks for a code review on any file, diff, or PR.
  Works standalone or as part of a SIGNAL session.
signal_bundle_version: "0.3.2"
---

# ⚡ signal-review — Templated Code Review

One line per issue. Severity required. Summary at the end. No prose.

---

## Invocation Triggers

Activate when user says any of:
- `/signal-review`
- `"review this"`, `"review my code"`, `"review this file"`
- `"check this PR"`, `"code review"`, `"look at this diff"`
- `"what's wrong with this"`, `"any issues with this code"`

Target can be: a file, a diff, a PR URL, a code block, or the current working directory.

## Slash command behavior

If the user's message is **only** `/signal-review`, treat that as **review now**.

- Do **not** stop after acknowledging the skill.
- Do **not** ask for confirmation unless the user explicitly asked for draft / dry behavior.
- Immediately inspect the provided target (or current working context) and output the review
  in the format below in the same turn.

---

## Output Format

**One line per issue:**
```
{file}:{line}|{issue}|{severity:1-5}|{fix}
```

**Full example:**
```
auth.js:47|nullref on empty arr|4|add guard clause before map
api.js:103|missing await on async call|5|add await
utils.js:12|unused import lodash|1|remove import
∑ 3 issues [1×sev5, 1×sev4, 1×sev1]  critical→api.js:103
```

**Rules:**
- Severity is **required** on every line. No exceptions.
- Issue description: max ~60 chars, imperative noun phrase ("nullref on empty arr", not "there is a null reference error")
- Fix: max ~50 chars, imperative ("add guard clause before map", not "you should add a guard clause")
- Order by severity descending (sev5 first)
- One summary line at the end, always

---

## Summary Line Format

```
∑ {N} issues [{breakdown}]  critical→{highest-sev-location}
```

Examples:
```
∑ 5 issues [2×sev5, 1×sev3, 2×sev1]  critical→auth.js:47
∑ 1 issue [1×sev2]
∑ 0 issues ✓
```

If zero issues: output only `∑ 0 issues ✓`. No explanation, no praise.

---

## Severity Scale

Full definitions in `references/severity.md`. Quick reference:

| Level | Meaning |
|---|---|
| `5` | Breaks in production, security vulnerability, data loss |
| `4` | Likely runtime error, will crash under normal use |
| `3` | Wrong behavior under specific conditions, logic error |
| `2` | Code smell, maintainability issue, confusing pattern |
| `1` | Style, minor cleanup, nitpick |

**Severity assignment rule:** Assign based on *impact when triggered*, not *probability of triggering*. A SQL injection that only fires on a specific input is still sev5.

---

## What to Review

In order of priority:

1. **Security** — injection, auth bypass, exposed secrets, insecure defaults
2. **Correctness** — logic errors, missing error handling, race conditions, off-by-one
3. **Runtime safety** — null dereferences, unhandled promises, type mismatches
4. **Performance** — N+1 queries, unnecessary re-renders, missing indexes, sync-in-loop
5. **Maintainability** — dead code, magic numbers, unclear naming, deep nesting
6. **Style** — only if it affects readability, never as a primary finding

---

## Scope Inference

If the user doesn't specify what to review:
- **File open in editor** → review that file
- **Recent diff** → review the diff (`git diff HEAD`)
- **PR URL provided** → fetch with `gh pr diff {url}` and review
- **Code block in message** → review exactly what was shared

---

## Flags

| Flag | Behavior |
|---|---|
| `--quick` | Sev3+ only. Skip style and nitpicks. |
| `--security` | Security-focused pass only. |
| `--sev {N}` | Only report issues at severity N or above. |
| `--fix` | After listing issues, output the corrected code block. |

**`--fix` output:**
List all issues first, then output the corrected file or function in a single code block. Do not mix issue lines with code.

---

## Multi-File Reviews

When reviewing multiple files, group by file:

```
auth.js:
  auth.js:47|nullref on empty arr|4|add guard clause before map
  auth.js:89|hardcoded secret|5|move to env var

api.js:
  api.js:103|missing await|5|add await

∑ 3 issues [2×sev5, 1×sev4]  critical→api.js:103
```

The summary line covers all files combined.

---

## BOOT Integration

If `BOOT:review` is active (see [`references/boot-presets.md`](../references/boot-presets.md)):
- Output format is already set to `TMPL:rev`
- Severity is already required by `severity_required`
- No preamble, no summary prose — just the lines and the `∑` line
- If the active template cannot be satisfied, emit `SIGNAL_DRIFT: <one-line reason>` instead of falling back to prose

If SIGNAL is not active, still use this format. The template is the default for this skill regardless of SIGNAL mode.

---

## Eat Your Own Cooking

This skill's own output must comply with SIGNAL compression rules if SIGNAL is active:
- No "Here are the issues I found:" preamble
- No "Overall, the code looks pretty good except..." summary
- First line is an issue line or `∑ 0 issues ✓`
- Last line is always the `∑` summary
