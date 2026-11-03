# Project K – Progress

Read this first in every new session. Keep it short: replace "Current status" and
"Next step" each time; add new entries to the TOP of the session log.

## Current status

- Setup merged (PR #1, PR #2: ask-first rule, .DS_Store ignored, Claude merges via gh).
- Dice module done: `scripts/core/dice.gd` (roll, roll_d20 with advantage/disadvantage,
  check vs DC) + self-check `tests/test_dice.gd` (passes). Merged via feature/dice-module.
- Run the check: `/Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_dice.gd`

## Next step

1. Combat prototype on `feature/combat-prototype`: one hero vs one enemy, simple shapes,
   clickable actions, roll log using Dice.

## Open questions

- Game-tester skill (gamer agent + dev tester agent): build after the combat prototype runs.

## Session log (newest first)

### 2026-11-03 – Rules, dice module
- Merged setup/claude-md (PR #1) and setup/ask-first (PR #2).
- Added CLAUDE.md rules: ask instead of assuming; ideas need Kha's OK before building.
- Claude now pushes, opens and merges PRs with gh when Kha says to merge.
- Built the dice module + headless self-check; nat 20 always succeeds, nat 1 always fails.
- Idea parked: game-tester skill with two agents, after combat prototype.

### 2026-11-03 – Planning and setup
- Brainstormed the game, inspired by Pixel Lineage (Roblox) + D&D d20 checks.
- Chose Godot 4 (GDScript) over Unity; PC first (Mac + Windows), mouse only.
- Locked the design: rarity-rolled races and talents, 5 shared rerolls, 4 classes with
  evolution at level 15, 3 lives with chapter restart. Full details in design.md.
- Kha installed Godot 4.7.2 on his Mac, created the project, connected GitHub via GitHub Desktop.
- Wrote CLAUDE.md, the add-race skill, the branch workflow and this memory system.
