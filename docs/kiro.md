# SIGNAL for Kiro

SIGNAL skills follow the open [Agent Skills](https://agentskills.io) standard, which Kiro supports natively. This means you can import any SIGNAL skill directly from GitHub using Kiro's built-in import flow.

## How Kiro skills work

Kiro loads skills with **progressive disclosure**:

1. At startup, only the skill `name` and `description` are read (metadata phase).
2. When your request matches a skill's description, the full `SKILL.md` is loaded.
3. Reference files under `references/` are loaded only when the skill instructions ask for them.

This keeps context focused: you pay the full token cost of a skill only when it is actually relevant.

## Scope: workspace vs global

| Scope | Location | When to use |
| --- | --- | --- |
| Workspace | `.kiro/skills/` | Project-specific skills, or per-repo overrides |
| Global | `~/.kiro/skills/` | Personal habits across all projects |

Workspace skills take priority when names conflict.

## Importing from GitHub

SIGNAL ships a dedicated [`kiro-signal/`](../kiro-signal/) tree with bundled protocol references so links in skill files resolve correctly after import.

**In Kiro IDE:**

1. Open **Agent Steering & Skills** in the Kiro panel.
2. Click **+** → **Import a skill** → **GitHub**.
3. Paste the URL for the skill folder you want. Use the `kiro-signal/skills/<name>` path, not the repo root.

Import URL format:

```
https://github.com/mattbaconz/signal/tree/main/kiro-signal/skills/<skill-name>
```

### Available skills

| Skill | Import URL |
| --- | --- |
| `signal` (core compression) | `…/kiro-signal/skills/signal` |
| `signal-ckpt` (checkpoint) | `…/kiro-signal/skills/signal-ckpt` |
| `signal-commit` | `…/kiro-signal/skills/signal-commit` |
| `signal-push` | `…/kiro-signal/skills/signal-push` |
| `signal-pr` | `…/kiro-signal/skills/signal-pr` |
| `signal-review` | `…/kiro-signal/skills/signal-review` |
| `signal-state` | `…/kiro-signal/skills/signal-state` |

Replace `…` with `https://github.com/mattbaconz/signal/tree/main`.

Import only the skills you need. Start with `signal` to get the core compression protocol.

## Why `kiro-signal/` instead of `skills/` directly

The canonical [`skills/`](../skills/) source files contain relative links like `../references/layers.md` that point to the repo-root `references/` directory. When a single skill folder is copied into `.kiro/skills/`, that parent path no longer exists.

The `kiro-signal/` tree solves this by:

- Mirroring all skills under `kiro-signal/skills/<name>/SKILL.md`.
- Copying `references/` to `kiro-signal/references/`.
- Rewriting links from `(../references/` → `(../../references/` so they resolve from the skill folder depth.

This layout is generated automatically by [`scripts/sync-integration-packages.ps1`](../scripts/sync-integration-packages.ps1) — do not hand-edit `kiro-signal/`.

## Workflow skills (signal-commit, signal-push, signal-pr)

These skills describe git operations and reference shell scripts. The scripts live in [`skills/signal-commit/scripts/`](../skills/signal-commit/scripts/) etc. in the source repo but are not bundled in the imported skill folder.

After importing, the skill instructions tell Kiro how to form the git commands. If you want the shell scripts locally, copy them from the repo into your project alongside the imported skill folder.

## Slash commands

After importing, invoke skills via `/` in the Kiro chat:

| Slash command | What it does |
| --- | --- |
| `/signal` | Activate SIGNAL-1 (terse, symbols, no preamble) |
| `/signal2` | SIGNAL-2 (+ BOOT, aliases, delta turns) |
| `/signal3` | SIGNAL-3 (+ auto-checkpoint every 5 turns) |
| `/signal-commit` | Stage + conventional commit from diff |
| `/signal-push` | Commit + push |
| `/signal-pr` | Push + open PR |
| `/signal-review` | One-line code review with required severity |
| `/signal-ckpt` | Manual checkpoint compression |
| `/signal-state` | Disk-backed session state |

## Frontmatter compatibility note

SIGNAL skill files include a `signal_bundle_version` key in frontmatter alongside the standard `name` and `description`. This is extra metadata unknown to the Agent Skills spec validator. Kiro loads the file without rejecting extra keys; if you run `skills-ref validate` you can move `signal_bundle_version` under `metadata:` to pass strict validation.
