# SIGNAL — Claude Code plugin

This directory is a **Claude Code plugin** (manifest: `.claude-plugin/plugin.json`). Skills are copied from the repository root by `scripts/sync-integration-packages.ps1`.

## Try locally

```bash
claude --plugin-dir ./claude-signal
```

## Slash commands (namespaced)

Plugin skills are invoked as **`/signal:<skill-folder>`** — for example:

- `/signal:signal` — core protocol
- `/signal:signal-commit` — instant commit
- `/signal:signal-push` — commit + push
- `/signal:signal-pr` — PR via `gh`
- `/signal:signal-review` — structured review
- `/signal:signal-ckpt` — checkpoint

Exact names match the **folder names** under `skills/`. See [Claude Code plugins](https://code.claude.com/docs/en/plugins).

To keep short commands like `/signal-commit` without the prefix, install skills standalone under `~/.claude/skills/` (e.g. `scripts/install-signal-all.ps1`) **or** use the plugin — not both, to avoid duplicate definitions.

## Marketplace (team install)

From the repository root, this repo includes [`.claude-plugin/marketplace.json`](../.claude-plugin/marketplace.json). Users can add the marketplace and install the plugin:

```text
/plugin marketplace add <git-url-or-path-to-this-repo>
/plugin install signal@signal-suite
```

Use the marketplace **`name`** field (`signal-suite`) as shown by `/plugin marketplace list` after adding.

See the main [README.md](../README.md) for SIGNAL behavior and tiers.
