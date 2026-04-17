# SIGNAL — Gemini CLI extension

This directory is a **Gemini CLI extension** (manifest: `gemini-extension.json`). Skill sources are copied from the repo root by `scripts/sync-integration-packages.ps1`.

## Gallery / remote install (`gemini-extension.json` at repo root)

For **`gemini extensions install https://github.com/...`** and the [extension gallery](https://geminicli.com/extensions/browse/), use the **standalone** repository (manifest at repository root, not nested):

**[github.com/mattbaconz/gemini-signal](https://github.com/mattbaconz/gemini-signal)**

```bash
gemini extensions install https://github.com/mattbaconz/gemini-signal --consent
```

Sync from this monorepo: `scripts/sync-integration-packages.ps1` then `scripts/sync-gemini-standalone-repo.ps1` (see [`templates/gemini-standalone-PUBLISHING.md`](../templates/gemini-standalone-PUBLISHING.md)).

## Install (local path / dev from this monorepo)

From the repository root:

```bash
gemini extensions link ./gemini-signal
```

Or:

```bash
gemini extensions install ./gemini-signal --consent
```

Restart the CLI after install. Remote URL install from **this** repo is awkward because the manifest is not at the Git root; prefer the standalone repo above or `link` with a local clone.

## Bundled pieces

- `skills/` — six SIGNAL skills (synced copies).
- `GEMINI.md` — short session defaults (merged into extension context).
- `commands/signal/*.toml` — slash commands such as `/signal:commit` (git context + instructions).
- `bin/run-commit.*`, `bin/run-push.*` — forward to bundled `commit.ps1` / `push.ps1`; run with **current directory = git repository root**.

See the main [README.md](../README.md) for the full protocol and tier table.
