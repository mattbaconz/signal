---
name: signal-push
description: >
  Stage all changes, create a conventional commit, then push to remote.
  One command for the full local→remote cycle. Use when user types
  /signal-push, "commit and push", "push everything", "push my changes", or
  wants to send current changes to remote without manual steps.
signal_bundle_version: "0.2.1"
---

# ⚡ signal-push — Commit + Push

One command. Stages, commits, pushes. Done.

---

## Invocation Triggers

Activate when user says any of:
- `/signal-push`
- `"commit and push"`, `"push everything"`, `"push my changes"`
- `"push this"`, `"ship it"`, `"send to remote"`
- `/signal-commit --push`

## Slash command behavior

If the user's message is **only** `/signal-push` (optionally with flags like
`--dry`, `--draft`, or `--split`), treat that as **execute now**.

- Do **not** stop after acknowledging the skill.
- Do **not** ask for confirmation unless the user explicitly requested review mode.
- Immediately run the ordered steps below in the same turn.
- Respect `--dry` and `--draft` exactly as defined in this file.

---

## Behavior (Ordered Steps)

1. **Run signal-commit logic** — full diff analysis, message generation, staging, committing.
   See `signal-commit/SKILL.md` for complete commit behavior.

2. **Push to remote**
   ```bash
   git push
   ```
   If no upstream is set (new branch), auto-set it:
   ```bash
   git push --set-upstream origin {current-branch}
   ```
   No prompt. No confirmation. It pushes.

3. **Report**
   ```
   ✓ feat(auth): add JWT refresh token rotation [3 files, +47/-12]
   ✓ pushed → origin/feat/jwt-refresh
   ```

---

## Flags

All flags from signal-commit are inherited, plus:

| Flag | Behavior |
|---|---|
| `--draft` | Show generated commit message, **do not commit or push**. |
| `--dry` | Explain what would happen — touch nothing. |
| `--split` | Force atomic commits per logical change, then push all. |

**`--dry` output:**
```
Would stage: 3 files
Would commit: feat(auth): add JWT refresh token rotation
Would push → origin/feat/jwt-refresh
```

---

## Output Format

Single commit + push:
```
✓ feat(auth): add JWT refresh token rotation [3 files, +47/-12]
✓ pushed → origin/feat/jwt-refresh
```

Split commits + push:
```
✓ fix(api): handle null response from upstream [2 files, +8/-3]
✓ chore(deps): update axios to 1.6.2 [1 file, +2/-2]
✓ pushed → origin/main
```

---

## Edge Cases

| Situation | Behavior |
|---|---|
| Nothing to commit | `∅ nothing to commit` — stop, no push attempt |
| Push rejected (non-fast-forward) | `✗ push rejected — pull and rebase first` |
| No remote configured | `✗ no remote configured — add remote first` |
| Detached HEAD | Commit succeeds, then: `✗ cannot push in detached HEAD — checkout a branch first` |
| Merge conflicts | `✗ merge conflicts in {files} — resolve before committing` |
| No git repo | `✗ not a git repository` |

---

## Script

```bash
bash .agents/skills/signal-push/scripts/push.sh [--draft] [--split] [--dry] ["custom message"]
```
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.agents\skills\signal-push\scripts\push.ps1" [--draft] [--split] [--dry] ["custom message"]
```

The script wraps `commit` (`commit.sh` / `commit.ps1`) and adds the push step. Message generation is done by the agent before calling the script.

---

## Eat Your Own Cooking

Output must comply with SIGNAL compression rules if SIGNAL is active:
- No preamble before the commit/push lines
- One line per action
- If something goes wrong: one line, TMPL:bug format
