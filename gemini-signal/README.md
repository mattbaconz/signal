# SIGNAL — Gemini CLI extension

This directory is a **Gemini CLI extension** (manifest: `gemini-extension.json`). Skill sources are copied from the repo root by `scripts/sync-integration-packages.ps1`.

## Install (local path / dev)

From the repository root:

```bash
gemini extensions link ./gemini-signal
```

Or:

```bash
gemini extensions install ./gemini-signal --consent
```

Restart the CLI after install. Remote `gemini extensions install <github-url>` expects `gemini-extension.json` at the **repository root**; this repo nests the extension here, so prefer `link` or install from a **local clone path** as above.

## Bundled pieces

- `skills/` — six SIGNAL skills (synced copies).
- `GEMINI.md` — short session defaults (merged into extension context).
- `commands/signal/*.toml` — slash commands such as `/signal:commit` (git context + instructions).
- `bin/run-commit.*`, `bin/run-push.*` — forward to bundled `commit.ps1` / `push.ps1`; run with **current directory = git repository root**.

See the main [README.md](../README.md) for the full protocol and tier table.
