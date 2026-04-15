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

- **At the start of a session:** If `.signal_state.md` exists in the workspace, you MUST read it before taking any other action. It holds your context.
- **After significant actions:** When you complete a sub-task, merge a PR, or shift focus, you MUST update the state file.
- **When the user says `/signal-state`**: Immediately refresh the state file based on the current reality of the workspace.

## How it works

You do not need a special bash script to interact with state. You just use your native file-editing tools (e.g., `write_to_file`, `replace_file_content`) to modify `.signal_state.md` in the project root.

### The State Format (`.signal_state.md`)

The file MUST strictly adhere to this format: YAML frontmatter for machine-readable context, separating into 3 functional blocks.

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
