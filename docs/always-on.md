# SIGNAL always-on install

Use this when you want every agent reply to default to SIGNAL-3 without typing `/signal3` on every prompt.

## Fast path

```bash
npx skills add mattbaconz/signal
```

Then add the always-on host rules for the agent you use:

| Host | Always-on file |
| --- | --- |
| Codex | `AGENTS.md` |
| Claude Code | `CLAUDE.md` |
| Gemini CLI | `GEMINI.md` |
| Cursor | `.cursor/rules/signal.mdc` |
| Windsurf | `.windsurf/rules/signal.md` |
| Cline | `.clinerules/signal.md` |
| Copilot | `.github/copilot-instructions.md` |

The shared source is `templates/host-always-on.body.md`. It says:

- SIGNAL-3 is the default reply style.
- No per-turn `/signal3` prefix is required.
- `signal3`, `SIGNAL-3`, and `/signal3` all reset the session to the same tier.
- Code blocks, file paths, line numbers, quoted errors, and technical terms are never compressed.
- Code edits still follow the Karpathy-style coding norms.

## Clone install

From a cloned repo:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-signal-all.ps1 -AlwaysOn -DryRun
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-signal-all.ps1 -AlwaysOn
```

`-DryRun` prints the target skill folders and always-on files without changing them.

## Project install

Copy or merge the relevant template into the project instruction file:

```text
templates/host-always-on.body.md
templates/claude-CLAUDE.min.md
templates/gemini-GEMINI.min.md
```

Prefer the minified templates when you care most about prompt overhead. Prefer the full template when a team needs readable rules.

## User-facing behavior

With always-on rules loaded, users can just prompt normally:

```text
fix the auth expiry bug and add the missing tests
```

The agent should answer in SIGNAL-3 style by default. Users can still type `signal3` or `/signal3` to reassert the tier mid-session.
