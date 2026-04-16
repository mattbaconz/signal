---
name: signal-commit
description: >
  Stage all changes and create a conventional commit from the diff.
  Zero prompts, zero confirmation by default. Use when user types
  /signal-commit, "commit everything", "just commit", "signal commit", or asks
  to commit current changes without specifying a message. Supports --draft
  (show message without committing) and --split (atomic commits per logical
  change).
signal_bundle_version: "0.1.1"
---

# ⚡ signal-commit — Instant Commit

Zero-confirmation commit. Reads the diff, generates a conventional commit message, stages everything, commits. One command. Done.

---

## Invocation Triggers

Activate when user says any of:
- `/signal-commit`
- `"commit everything"`, `"just commit"`, `"signal commit"`
- `"commit my changes"`, `"commit this"`, `"commit and push"`
- Asks to commit without providing a message

## Slash command behavior

If the user's message is **only** `/signal-commit` (optionally with flags like
`--dry`, `--draft`, or `--split`), treat that as **execute now**.

- Do **not** stop after acknowledging the skill.
- Do **not** ask for confirmation unless the user explicitly requested review mode.
- Immediately follow the ordered steps below in the same turn.
- Respect `--dry` and `--draft` exactly as defined in this file.

### Host notes (Gemini CLI, Antigravity, and similar)

- **Activation is not a commit.** The UI may show that this skill loaded (e.g. “Skill signal-commit activated”). That only brings this file into context. A real commit happens only when **you** run the workflow: either follow the git steps below or invoke `scripts/commit.ps1` / `scripts/commit.sh` with **current working directory = the git repository root** and the generated message (see **Script**).
- **Same turn as `/signal-commit`.** When the user’s message is only `/signal-commit` (plus flags), perform those steps **in that response**, using whatever terminal or git integration the host allows. Do not treat “skill activated” as completion.
- **Later messages are new turns.** A follow-up like `hi` does **not** mean “run signal-commit now”; answer that message. If the user wants a commit after chatting, they must invoke `/signal-commit` again or ask explicitly to commit.

---

## Behavior (Ordered Steps)

1. **Get the full diff**
   ```bash
   git diff --staged && git diff
   ```
   Both staged and unstaged. Work with the combined picture.

2. **Analyze the diff — detect type and scope**

   | Type | When to use |
   |---|---|
   | `feat` | New capability, new endpoint, new component |
   | `fix` | Bug fix, error handling, crash prevention |
   | `refactor` | Same behavior, restructured code |
   | `chore` | Config, deps, tooling, build, CI |
   | `docs` | Comments, README, documentation only |
   | `test` | Adding or fixing tests only |
   | `style` | Formatting, whitespace, no logic change |
   | `perf` | Performance improvement |

   **Scope** = the primary directory or module affected. Derive from file paths:
   - `src/auth/*` → `(auth)`
   - `src/api/*` → `(api)`
   - `components/ui/*` → `(ui)`
   - `*.config.*`, `package.json` → `(config)`
   - Mix of unrelated paths → omit scope

3. **Detect if multiple logical changes exist**

   Logical change = unrelated type+scope pair. Examples:
   - `fix(auth)` changes + `chore(deps)` changes = 2 logical changes → split
   - `feat(api)` across 3 files = 1 logical change → single commit

   If multiple logical changes detected:
   - Without `--split` flag: warn once, then split anyway
   - With `--split` flag: split silently

   **Agent invocation for split:** When splitting, the agent generates one conventional commit
   message per logical change and passes them as a single newline-delimited string. The script
   uses the `(scope)` in each message to selectively stage matching files for that commit.

4. **Generate commit message**

   Format: `type(scope): description`
   - Max 72 chars total
   - Imperative mood: `add` not `added`, `fix` not `fixes`, `remove` not `removed`
   - No period at end
   - No emoji
   - No ticket numbers unless branch name contains one (e.g. `feat/PROJ-123-thing` → `feat(scope): description PROJ-123`)

5. **Execute** (unless `--draft` or `--dry`)
   ```bash
   git add -A
   git commit -m "{generated_message}"
   ```

6. **Report**
   ```
   ✓ feat(auth): add JWT refresh token rotation [3 files, +47/-12]
   ```

---

## Flags

| Flag | Behavior |
|---|---|
| `--draft` | Show generated message, **do not commit**. User can approve or edit. |
| `--split` | Force atomic commits per logical change. No warning. |
| `--push` | Commit then immediately push (equivalent to running signal-push). |
| `--dry` | Explain what would happen — touch nothing, change nothing. |

**`--draft` output format:**
```
Draft commit message:
  feat(auth): add JWT refresh token rotation

Run /signal-commit to confirm, or edit and pass as: /signal-commit "your message"
```

**`--dry` output format:**
```
Would stage: 3 files
Would commit: feat(auth): add JWT refresh token rotation
Would not push (use --push to push)
```

---

## Commit Message Rules (Non-Negotiable)

These do not change. There is no config for them.

1. **Conventional Commits format always:** `type(scope): description`
2. **Types:** `feat` `fix` `refactor` `chore` `docs` `test` `style` `perf`
3. **Max 72 chars** — truncate description if needed, never truncate type or scope
4. **Imperative mood:** `add` not `added`, `fix` not `fixes`
5. **No period at end**
6. **No emoji**
7. **No "WIP"** — if genuinely incomplete, user should use `--draft` first

**Why no config:** Having *a* standard is more valuable than having the *right* standard. Conventional Commits works with semantic-release and most CI systems. Config options lead to bikeshedding.

---

## Output Format

Single commit:
```
✓ feat(auth): add JWT refresh token rotation [3 files, +47/-12]
```

Split commits:
```
✓ fix(api): handle null response from upstream [2 files, +8/-3]
✓ chore(deps): update axios to 1.6.2 [1 file, +2/-2]
```

With `--push`:
```
✓ feat(auth): add JWT refresh token rotation [3 files, +47/-12]
✓ pushed → origin/main
```

---

## Edge Cases

| Situation | Behavior |
|---|---|
| Nothing to commit | `∅ nothing to commit` — stop, no error |
| Untracked files only | Stage them, include in commit |
| Merge conflict markers present | `✗ merge conflicts in {files} — resolve before committing` |
| Detached HEAD | Commit succeeds, warn: `? detached HEAD — push will require explicit ref` |
| No git repo | `✗ not a git repository` |
| User passes a message | Use it as-is, skip generation. Still enforce max 72 chars. |

---

## Script

The mechanical git operations are handled by `scripts/commit.sh` (Unix) or `scripts/commit.ps1` (Windows PowerShell).

**Single commit:**
```bash
bash .agents/skills/signal-commit/scripts/commit.sh [--draft] [--push] [--dry] "feat(auth): add JWT refresh token rotation"
```
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.agents\skills\signal-commit\scripts\commit.ps1" [--draft] [--push] [--dry] "feat(auth): add JWT refresh token rotation"
```

**Split commits (agent passes newline-delimited messages):**
```bash
bash .agents/skills/signal-commit/scripts/commit.sh --split "fix(auth): handle null token\nchore(deps): update axios to 1.6.2"
```
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.agents\skills\signal-commit\scripts\commit.ps1" --split "fix(auth): handle null token`nchore(deps): update axios to 1.6.2"
```

The script handles: selective staging per scope, git add, git commit, stat reporting. Message generation is done by the agent (this skill) before calling the script.

---

## Eat Your Own Cooking

This skill's own output must comply with SIGNAL compression rules if SIGNAL is active:

- No preamble before the commit line
- No explanation after the commit line
- One line per commit
- If something goes wrong: one line, TMPL:bug format
