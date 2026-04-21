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

From the repository root, this repo includes [`.claude-plugin/marketplace.json`](../.claude-plugin/marketplace.json). In **Claude Code** (not the generic claude.ai chat app), add the marketplace and install:

```text
/plugin marketplace add mattbaconz/signal
/plugin install signal@signal-suite
/reload-plugins
```

Use the marketplace **`name`** field (`signal-suite`) as shown by `/plugin marketplace list` after adding.

### If `/plugin` is not recognized

That usually means you are **not in Claude Code**, or Claude Code is **out of date**. See [Discover plugins — troubleshooting](https://code.claude.com/docs/en/discover-plugins#plugin-command-not-recognized). [Update](https://code.claude.com/docs/en/setup), restart, and try again.

**Fallback (no plugin):** copy skills into `~/.claude/skills/` from [`claude-signal/skills/`](../claude-signal/skills/) or run [`scripts/install-signal-all.ps1`](../scripts/install-signal-all.ps1) from the repo root. Then use short slash commands (`/signal`, `/signal-commit`, …) without the `signal:` prefix — **do not** also enable the plugin (duplicate skills).

See the main [README.md](../README.md#install) for SIGNAL behavior, tiers, and Claude Code install paths.
