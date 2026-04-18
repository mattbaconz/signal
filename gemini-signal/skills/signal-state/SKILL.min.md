---
name: signal-state
description: Continuous disk-backed state engine.
---
# ⚡ signal-state (v0.3.0)

§TRIG: /signal-state | Start:session | End:sub-task
§ACT: ephemeral → persistent (.signal_state.md)
§FORMAT:
YAML frontmatter (version|boot|updated_at)
## Context
project={name} | stack={tech} | scope={focus}
## Progress
[x] done | [/] wip | [ ] todo (max 10 items)
## Next
turn_focus={immediate_task}
§RULES:
1. Atomic: ≤30 lines total.
2. Pointers: ∅code | ∅long_prose.
3. Overwrite: ∅append.
4. Prune: >10 items → collapse [x] into "∑ {N} core tasks".
§BOOT: If ∅file, create from current context.
