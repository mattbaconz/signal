# Contributing to SIGNAL

Thanks for helping improve the skill bundle. This repo is **documentation-heavy** and **multi-target** (`skills/` source + mirrored host packages). Following these rules avoids drift between canonical specs and minified skills.

## Where to edit

| Path | Role |
| --- | --- |
| [`skills/<name>.md`](skills/) | **Canonical** readable spec for each skill (source of truth for behavior and prose). |
| [`skills/<name>.min.md`](skills/) | **Dense** Symbol-Grammar surface the agent loads. Must stay **paired** with the same `<name>.md`. |
| [`references/`](references/) | Shared references (symbols, Karpathy norms, benchmarks, checkpoint notes). |
| [`templates/`](templates/) | Snippets users merge into project `GEMINI.md` / `CLAUDE.md`. |

**Do not** edit mirrored copies under [`gemini-signal/skills/`](gemini-signal/skills/), [`claude-signal/skills/`](claude-signal/skills/), or [`kiro-signal/skills/`](kiro-signal/skills/) by hand. Those trees are **generated** from `skills/` by [`scripts/sync-integration-packages.ps1`](scripts/sync-integration-packages.ps1). The `kiro-signal/` tree also gets a bundled copy of [`references/`](references/) with rewritten paths — also generated, not hand-edited.

## Minified skills (`.min.md`) — important

[`scripts/shrink.ps1`](scripts/shrink.ps1) does **not** auto-generate `.min.md` files. It **compares** each canonical `skills/*.md` with its paired `*.min.md` and prints shrink ratios (and warns if a `.min.md` is missing).

When you change behavior or wording that matters for the compressed surface:

1. Edit the canonical `skills/<skill>.md` as needed.
2. Update the paired `skills/<skill>.min.md` using the Symbol Grammar conventions (see [`skills/signal-core.min.md`](skills/signal-core.min.md)).
3. Run:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\shrink.ps1 -All
   ```

4. Commit **both** files in the same PR when both exist for that skill.

**Do not** submit PRs that only change `.min.md` unless the change is intentionally min-only (rare); reviewers will ask for the canonical `.md` to match.

## Sync and verify before you push

After changing anything under [`skills/`](skills/) that should appear in Gemini or Claude packages:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\sync-integration-packages.ps1
```

That refreshes [`gemini-signal/skills/`](gemini-signal/skills/), [`claude-signal/skills/`](claude-signal/skills/), root [`GEMINI.md`](GEMINI.md), and [`gemini-extension.json`](gemini-extension.json) per the script.

**CI** runs [`scripts/verify.ps1`](scripts/verify.ps1) on pull requests; it invokes `sync-integration-packages.ps1` and checks repo layout, `bin/run-commit.ps1 --dry`, and relative markdown links. Run verify locally when you can:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1
```

## Versioning

- Bump **`signal_bundle_version`** in skill frontmatter when you cut a release (see [CHANGELOG.md](CHANGELOG.md)).
- Align [`gemini-extension.json`](gemini-extension.json), [`gemini-signal/gemini-extension.json`](gemini-signal/gemini-extension.json), [`claude-signal/.claude-plugin/plugin.json`](claude-signal/.claude-plugin/plugin.json), and [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json) with the same semver when maintainers ship a versioned release.
- Tag releases as `v0.x.y` and optionally publish a **GitHub Release** (see [Maintainer: GitHub topics and releases](#maintainer-github-topics-and-releases) below).

## Pull request checklist

- [ ] Edits are under `skills/`, `references/`, `templates/`, `scripts/`, or docs—not hand-edited mirrors in `gemini-signal/skills/` / `claude-signal/skills/` without running sync.
- [ ] Paired `.md` + `.min.md` updated together where the min skill is part of the install surface.
- [ ] `shrink.ps1 -All` run; ratios make sense.
- [ ] `sync-integration-packages.ps1` run after skill changes affecting host packages.
- [ ] `verify.ps1` passes locally (or you note why CI-only).

## Maintainer: GitHub topics and releases

**GitHub Release:** Publish a release from tag **`v0.3.1`** (or the current `v0.x.y`) so the sidebar shows a current release; changelog text can match [CHANGELOG.md](CHANGELOG.md). With [GitHub CLI](https://cli.github.com/):

`gh release create v0.3.1 --title "SIGNAL v0.3.1" --notes-file CHANGELOG.md`

(edit the title or paste only the section for that version if you prefer).

**GitHub Topics:** Repo → **Settings → General → Topics**. Suggested tags:  
`agent-skills`, `token-compression`, `cursor`, `llm`, `developer-tools`, `gemini-cli`, `claude-code`, `opensource`, `ai-agents`, `prompt-engineering`.
