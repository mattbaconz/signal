---
name: signal-pr
description: Push + open GH pull request.
---
# ⚡ signal-pr (v0.3.1)

§TRIG: /signal-pr | "open a PR" | "ship a PR" | "PR this"
§ACT: signal-push → gh pr create (∅conf)
§PR_BODY:
## Changes
- {imp_phrase} (max 80c, group by type)
## Type
{feat|fix|...}
Closes #{issue_if_in_branch}
§REP:
✓ {commit_msg}
✓ pushed → origin/{branch}
✓ PR opened → {url}
§FLAGS: --draft (∅act) | --pr-draft (gh --draft)
§ERR: ∅gh → ✗ | exists → ✗ | ∅git → ✗
