# Project K – Progress

Read this first in every new session. Keep it short: replace "Current status" and
"Next step" each time; add new entries to the TOP of the session log.

## Current status

- Build step 1 done: dice module (`scripts/core/dice.gd`) + combat prototype
  (`scenes/combat/combat.tscn`, main scene): Hero vs Bandit, Attack + Defend, roll math in the log.
- Game-tester skill (`.claude/skills/game-tester/`): gamer agent + dev tester agent, report then ask.
  Tools: `tests/play.gd` (text play tool, `--seed`, `--force`), `Dice.forced_rolls`, self-checks.
- First playtest done; all bugs fixed; crits roll damage twice, Defend +4 Armor.
- Run checks: `for f in tests/test_*.gd; do /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://$f; done`

## Next step

- Build step 2: character creation screen (race, talent, class, 5 shared rerolls).

## Open questions

- Defend still loses to always-attack (76% vs 95% wins in sims): needs a reason to defend
  (enemy wind-up attacks, or Defend restores Energy once skills exist). Kha to decide.
- Armor = 10 + Defense was chosen by Claude; Kha may change it.
- Hero wins ~95% vs Bandit; fine for a test fight.

## Session log (newest first)

### 2026-11-03 – Game tester and first playtest
- Built the game-tester skill, text play tool and dev tools (seed, forced rolls).
- First playtest: play tool hang + bad forced rolls, negative damage healing, missing roll math.
- Fixed all of them; log now shows every roll's math and Armor on labels.
- Balance: crits roll damage die twice; Defend +4 Armor. Defend still weak (open question).

### 2026-11-03 – Rules, dice module
- Merged setup/claude-md (PR #1) and setup/ask-first (PR #2).
- Added CLAUDE.md rules: ask instead of assuming; ideas need Kha's OK before building.
- Claude now pushes, opens and merges PRs with gh when Kha says to merge.
- Built the dice module + headless self-check; nat 20 always succeeds, nat 1 always fails.
- Idea parked: game-tester skill with two agents, after combat prototype.
- Built the combat prototype (hero vs bandit, Attack/Defend, JSON stats, Restart).

### 2026-11-03 – Planning and setup
- Brainstormed the game, inspired by Pixel Lineage (Roblox) + D&D d20 checks.
- Chose Godot 4 (GDScript) over Unity; PC first (Mac + Windows), mouse only.
- Locked the design: rarity-rolled races and talents, 5 shared rerolls, 4 classes with
  evolution at level 15, 3 lives with chapter restart. Full details in design.md.
- Kha installed Godot 4.7.2 on his Mac, created the project, connected GitHub via GitHub Desktop.
- Wrote CLAUDE.md, the add-race skill, the branch workflow and this memory system.
