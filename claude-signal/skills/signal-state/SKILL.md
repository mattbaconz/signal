---
name: signal-state
description: Continuous disk-backed state engine for the SIGNAL protocol
keywords:
  - signal
  - state
  - memory
  - checkpoint
  - status
---

# ⚡ signal-state

This skill manages the **Continuous State Engine** for the SIGNAL protocol. It transitions the context window from an ephemeral chat history to a persistent `.signal_state.md` file on disk.

## When to use
- **Start of session**: Read `.signal_state.md` if it exists. It IS your context.
- **Significant actions**: Update state on sub-task completion, PR merge, or focus shift.
- **Trigger**: `/signal-state` → refresh file immediately.

## How it works
Use `write_file` or `replace` to modify `.signal_state.md` in project root. No scripts required.

### Format (`.signal_state.md`)
YAML frontmatter + 3 blocks: Context, Progress, Next.

```markdown
---
signal_version: 0.2
boot_mode: BOOT:arch
updated_at: 2026-04-15T15:00:00Z
---
## Context
project=move-validator
stack=node+ts
scope=knight-validation

## Progress
[x] parse files
[x] validate L-shape 
[x] validate off-board edge cases
[/] SAN to coord conversion boundary
[ ] write unit tests for SAN parse

## Next
turn_focus=implement SAN string parsing in src/move.ts
```

## Rules for Updating State

1. **Keep it atomic:** The entire file should rarely exceed 30 lines. 
2. **Never store code:** The state file tracks *pointers* to progress, not the code itself.
3. **Overwrite, don't append:** When updating progress, change `[ ]` to `[x]`. Do not just append completed items to an infinitely growing list.
4. **Pruning:** If the `Progress` list exceeds 10 items, collapse the completed items `[x]` into a single summary line: `[x] core knight validation (5 tasks)`.

## Bootstrapping a new state

If the user asks to start using continuous state and the file doesn't exist, create it immediately based on the current context of the chat.

```bash
# Example action
write_to_file ".signal_state.md" <formatted_state_content>
```
