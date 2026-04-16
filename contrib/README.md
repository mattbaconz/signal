# Contrib patches

## One-click fork (GitHub)

Create your fork first: **[Fork VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills/fork)**.

From the SIGNAL repo root (PowerShell):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\prepare-awesome-agent-skills-pr.ps1
```

Then follow the printed `git remote` / `git push` steps using **your** fork URL.

## `awesome-agent-skills-add-signal.patch`

Adds **[mattbaconz/signal](https://github.com/mattbaconz/signal)** to [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) under **Community Skills → Productivity and Collaboration**.

**Apply (after forking awesome-agent-skills):**

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/awesome-agent-skills.git
cd awesome-agent-skills
git checkout -b add-signal-skill
git apply /path/to/signal/contrib/awesome-agent-skills-add-signal.patch
git add README.md
git commit -m "docs: add mattbaconz/signal to community skills"
git push -u origin add-signal-skill
```

Then open a PR against `VoltAgent/awesome-agent-skills` **main**.

**skills.sh:** There is no manual listing. The public directory reflects `npx skills` usage over time. Your repo already works with:

```bash
npx skills add mattbaconz/signal --list
```

Installs (`npx skills add mattbaconz/signal -y -g`) help visibility on [skills.sh](https://skills.sh).
