# Project K – Progress

Read this first in every new session. Keep it short: replace "Current status" and
"Next step" each time; add new entries to the TOP of the session log.

## Current status

- Build steps 1-3 done: dice, combat, game-tester skill, character creation, 5-fight run.
- Flow: character creation -> Start run -> 5 fights (`scenes/combat/combat.tscn`) with a
  level-up after each win -> back to creation on loss or full clear.
- Run state: `scripts/core/run.gd` (static `Run`). Enemies `data/enemies.json`, upgrades `data/upgrades.json`.
- Passives working: Elf, Mossfolk, Glass Cannon, Bloodlust, Lucky, Keen Eye, Second Wind, Chosen One
  (via "effects" in races/talents JSON). Not yet: Emberkin burn, poison, XP, talk/check bonuses.
- Balance sim (`tests/test_run.gd`, always-attack bot, random upgrades): classes clear ~40-48% of runs.
- Every passive logs when it helps. Upgrades include "Heal 50% of max HP".
- Play tool: `tests/play.gd -- [--seed N] [--race x] [--talent y] [--class z] attack defend 1 2 3`

## Next step

- Build step 4: chapter map (shop, rest, events, boss).

## Open questions

- Defend is still weaker than attacking; needs a reason (enemy wind-ups, or Energy once skills exist).
- No healing between fights except the Heal 50% upgrade; rest spots come with the chapter map.
- Heal card is still offered at full HP ("+0 HP"); Kha to decide.

## Session log (newest first)

### 2026-11-04 – Second playtest fixes
- Game-tester run on the 5-fight run: no game bugs; 3 play-tool argument bugs fixed.
- Level-up title shows the new level; double upgrade click guarded.
- Passives now log when they help; upgrade texts clearer; Heal 50% card added, Speed removed.
- Game-tester skill prompts refreshed (play tool options, per-agent temp folders).

### 2026-11-03 – 5-fight run
- Built the run: created hero fights 5 enemies, picks 1 of 3 upgrades after each win.
- Made 8 combat passives work through "effects" in data; Mage attacks with Magic.
- First enemy set was almost unwinnable; softened enemies and tuned classes (sim ~30-34% each).
- Play tool can now play a whole run and choose the hero.

### 2026-11-03 – Character creation
- Built the character creation screen (rarity rolls, rerolls, class buttons from data).
- Added stat numbers for classes and races (Claude's proposal, approved).
- Added Legendary talent Chosen One (advantage on every check).
- Changed rerolls: 5 each for race and talent instead of 5 shared.

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
