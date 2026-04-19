# Team rollout: Gemini CLI + SIGNAL

This playbook is for **engineering leads** rolling SIGNAL out to a whole team. It combines **per-machine skills**, a **committed project `GEMINI.md`** (always-on defaults), and **team process** so SIGNAL is a standard—not an optional slash command.

**Upstream bundle:** [github.com/mattbaconz/signal](https://github.com/mattbaconz/signal)

---

## Prerequisites

- **Gemini CLI** is installed and in use for agentic work.
- The team agrees SIGNAL is an **engineering / review standard** (consistent agent output, lower token burn), not a one-off model tweak.
- Someone owns **merging** `GEMINI.md` into application repos and **documenting** install steps in onboarding.

---

## Per developer: install skills

Skills give the model the full **SIGNAL** protocol on demand (`/signal`, `/signal2`, `/signal3`, workflow skills). Every developer who uses Gemini with this repo should install the bundle once.

**Recommended (global, non-interactive):**

```bash
npx skills add mattbaconz/signal -y -g
```

See [Agent Skills](https://agentskills.io/) and the bundle [README](../README.md#install) for `owner/repo` requirements.

**When to use a clone instead:**

- You need a **pinned checkout** or fork, or you run `gemini skills install /path/to/clone/signal --consent` from an internal mirror.
- **Windows:** [scripts/install-signal-all.ps1](../scripts/install-signal-all.ps1) copies the six core skills into standard user folders (including `~/.agents/skills/`).

---

## Per repo: committed `GEMINI.md` (always-on)

**Skills alone do not set session tone.** To make terse SIGNAL-style defaults apply **without** typing `/signal` every thread, add a **project** `GEMINI.md` at the **repository root** (or agree a single root file for a monorepo).

Gemini loads instructions in a **cascade** (project file, parents, user defaults). Official behavior: [GEMINI.md cascade](https://geminicli.com/docs/cli/gemini-md).

**What to merge**

| Goal | Source in this bundle |
| --- | --- |
| **Fewest prompt tokens** (default for most teams) | [templates/gemini-GEMINI.min.md](../templates/gemini-GEMINI.min.md) |
| **Richer defaults** (Karpathy norms + workflow reminders) | [templates/gemini-GEMINI.md](../templates/gemini-GEMINI.md) |

Copy the chosen file’s body into your app repo’s `GEMINI.md` (or merge carefully with existing project rules). Keep the block **short**; duplicating the entire skill wastes tokens—see [docs/token-metrics.md](token-metrics.md).

**Monorepos:** Pick one canonical root `GEMINI.md` or document which package roots include a fragment so every dev gets the same behavior.

---

## Extension vs skills-only

| Approach | When it helps |
| --- | --- |
| **`npx skills add mattbaconz/signal`** | Skills in user discovery paths; works across projects. |
| **`gemini extensions install https://github.com/mattbaconz/signal --consent`** | Bundled extension + skills aligned with releases; good for “install once” ergonomics ([releasing](https://geminicli.com/docs/extensions/releasing)). |

**Do not load the same skill twice.** If you use the extension **and** a manual copy under another discovery path, Gemini may warn about conflicts. Pick **one** install path per machine. Install commands: [README — Install](../README.md#install); mirrored host trees (`gemini-signal/`, `claude-signal/`): [README — Repo map](../README.md#repo-map).

---

## Making SIGNAL a “need” (process)

Technical setup is not enough; **norms** make adoption stick.

- **Onboarding:** Add two steps: (1) run the global `npx skills add` line above, (2) confirm the repo’s `GEMINI.md` is present after `git clone`.
- **Code review:** Treat edits to `GEMINI.md` like lint or CI config—reviewers check that agent defaults are not removed casually.
- **PR checklist:** Paste the fragment from [templates/team-pr-checklist.md](../templates/team-pr-checklist.md) into your org’s PR template (optional checkbox for agent-facing changes).
- **Leadership / cost story:** Point stakeholders at [docs/token-metrics.md](token-metrics.md) for prompt vs output vs history—useful when justifying a thin `GEMINI.md` vs verbose policy docs.

---

## Output drift (“it went back to normal prose”)

Models often switch to tutorial tone on **how-to** or setup questions even when SIGNAL is active.

**Mitigations:**

- Re-issue **`/signal2`** or **`/signal3`** when you need BOOT + structure on long threads.
- Say explicitly: **follow SIGNAL strictly** or **stay in TMPL** for one turn.
- Tier choice is host- and session-dependent: [README — Tiers](../README.md#tiers).

There is no guarantee of perfect symbol grammar on every turn; persistent `GEMINI.md` + occasional tier activation is the practical combination.

---

## See also

- [README — Install](../README.md#install)
- [README — Repo map](../README.md#repo-map) (`gemini-signal/`, `claude-signal/`, `skills/`)
- [skills/signal.md](../skills/signal.md) (activation lines, `SIGNAL_DRIFT`)
