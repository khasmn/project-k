# Project K – Progress

Read this first in every new session. Keep it short: replace "Current status" and
"Next step" each time; add new entries to the TOP of the session log.

## Current status

- Project set up: Godot 4.7 project at ~/Dev/project-k, GitHub repo khasmn/project-k.
- CLAUDE.md, git branch workflow, project memory (docs/memory/) and skills
  (add-race, project-memory) are written on branch `setup/claude-md`.
- No game code yet.

## Next step

1. Kha publishes `setup/claude-md` in GitHub Desktop, opens a pull request and merges it.
2. Then: switch to `main`, pull, create `feature/dice-module`.
3. Build step 1 of the build order: dice module (`scripts/core/dice.gd`) + combat prototype.

## Open questions

- None right now.

## Session log (newest first)

### 2026-11-03 – Planning and setup
- Brainstormed the game, inspired by Pixel Lineage (Roblox) + D&D d20 checks.
- Chose Godot 4 (GDScript) over Unity; PC first (Mac + Windows), mouse only.
- Locked the design: rarity-rolled races and talents, 5 shared rerolls, 4 classes with
  evolution at level 15, 3 lives with chapter restart. Full details in design.md.
- Kha installed Godot 4.7.2 on his Mac, created the project, connected GitHub via GitHub Desktop.
- Wrote CLAUDE.md, the add-race skill, the branch workflow and this memory system.
