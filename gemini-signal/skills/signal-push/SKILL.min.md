---
name: signal-push
description: Commit + push to remote.
---
# ⚡ signal-push (v0.3.0)

§TRIG: /signal-push | "push [everything|this|changes]" | "ship it" | /signal-commit --push
§ACT: signal-commit → git push (∅conf)
§UPSTREAM: ∅upstream → `git push --set-upstream origin {branch}` (silent)
§REP:
✓ {commit_msg} [{files}, +/-]
✓ pushed → origin/{branch}
§ERR: nothing → ∅push | rejected → ✗pull/rebase | ∅git → ✗
§RULE: follow signal-commit logic for message generation.
