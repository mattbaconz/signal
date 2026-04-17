# SIGNAL — Gemini CLI extension (packaged copy)

This directory mirrors the **Gemini CLI extension** layout (`gemini-extension.json`, `skills/`, `commands/`, `bin/`, `GEMINI.md`). Canonical skill sources are the six folders at the repo root (`signal/`, …); `scripts/sync-integration-packages.ps1` copies them here and **also mirrors the same extension tree to the repository root** so the [gallery indexer](https://geminicli.com/docs/extensions/releasing) sees `gemini-extension.json` at the **Git root**.

## Remote install (GitHub URL)

From any machine:

```bash
gemini extensions install https://github.com/mattbaconz/signal --consent
```

The CLI clones the repo and uses the root-level `gemini-extension.json` (same layout as [extension reference](https://geminicli.com/docs/extensions/reference/)).

## Local dev (this monorepo)

From the repository root:

```bash
gemini extensions link ./gemini-signal
```

Or install the folder path:

```bash
gemini extensions install ./gemini-signal --consent
```

Restart the CLI after install.

## Bundled pieces

- `skills/` — six SIGNAL skills (synced copies).
- `GEMINI.md` — short session defaults (merged into extension context).
- `commands/signal/*.toml` — slash commands such as `/signal:commit`.
- `bin/run-commit.*`, `bin/run-push.*` — forward to bundled scripts; run with **current directory = git repository root**.

See the main [README.md](../README.md) for the full protocol and tier table.
