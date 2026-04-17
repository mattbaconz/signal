# SIGNAL Git Shared Logic

### Invocation Rules
- **Slash commands (`/signal-commit`, `/signal-push`, `/signal-pr`)**: If the user's message is only the command (plus flags), **execute immediately**.
- **No confirmation**: Do not stop to acknowledge the skill or ask "Are you sure?".
- **Turn 1**: Perform all steps (diff, analysis, generation, execution) in the same turn.

### Conventional Commits (CC)
- **Format**: `type(scope): description`
- **Types**: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `style`, `perf`
- **Scope**: Derived from path (e.g. `src/auth/*` → `auth`). Omit if mixed.
- **Description**: Imperative mood (`add` not `added`), max 72 chars, no period, no emoji.

### Shared Flags
- `--draft`: Show generated message/body, **do not commit/push/PR**.
- `--dry`: Explain intent, **touch nothing**.
- `--split`: Atomic commits per logical change.

### Edge Cases
- **Nothing to commit**: `∅ nothing to commit`.
- **Merge conflicts**: `✗ merge conflicts in {files}`.
- **No repo**: `✗ not a git repository`.
- **Detached HEAD**: Warn or fail depending on push/PR requirement.

### Scripts (Repo Root)
- **Commit**: `bin/run-commit.sh` / `.ps1`
- **Push**: `bin/run-push.sh` / `.ps1`
- **PR**: `signal-pr/scripts/pr.sh` / `.ps1` (requires `gh` CLI)
