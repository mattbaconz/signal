# Draft: Agent Skills Discord — #skills-showcase

**Title:** SIGNAL — compression + git workflows (inspired by Caveman, went a different direction)

**Tags:** Coding · Productivity

**Body:**

I’ve been using **[Caveman](https://github.com/JuliusBrussee/caveman)** for a while — the whole “why use many token when few token do trick” thing actually works, and it made me think harder about *how* we shrink assistant output without turning answers into mush.

**SIGNAL** is my take on that problem, but it’s not trying to be Caveman 2.0. Same *kind* of goal (less noise, keep the technical stuff intact), different shape: **tiers** (`/signal`, `/signal2`, `/signal3`), **templates / symbols / optional checkpoints** for long sessions, plus **workflow skills** so “just ship it” can mean **stage → commit → push → PR → review** without me writing five paragraphs first.

Repo: **https://github.com/mattbaconz/signal**  
Install: `npx skills add mattbaconz/signal` (global / no prompts: `-y -g`)

If you’re already on Caveman, you might use both, or neither — totally fine. I’m not here to win a % fight on a spreadsheet; I just wanted something that fits how *I* work and figured I’d put it out there. Metrics nuance: see **`docs/token-metrics.md`** in the repo (prompt vs output vs history).

Feedback welcome, especially if something’s confusing or broken on your stack.
