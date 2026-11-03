# Project K – Progress

Read this first in every new session. Keep it short: replace "Current status" and
"Next step" each time; add new entries to the TOP of the session log.

## Current status

- Build step 1 done: dice module + combat prototype (`scenes/combat/combat.tscn`) + game-tester skill.
- Build step 2 done: character creation (`scenes/character/character_creation.tscn`, main scene).
  Rarity-rolled race and talent, 5 rerolls each, class pick, final stats. Data in
  `data/races.json`, `talents.json`, `classes.json`. Rules in `scripts/character/character_draft.gd`.
- Combat still uses the test hero; open combat.tscn and press F6 to play it.
- Run checks: `for f in tests/test_*.gd; do /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://$f; done`

## Next step

- Build step 3: a run of 5 fights with level-up choices; connect the created hero to combat
  (Mage attacks with Magic) and start making passives work.

## Open questions

- Defend still loses to always-attack (76% vs 95% wins in sims): needs a reason to defend
  (enemy wind-up attacks, or Defend restores Energy once skills exist). Kha to decide.
- Armor = 10 + Defense was chosen by Claude; Kha may change it.
- Hero wins ~95% vs Bandit; fine for a test fight.

## Session log (newest first)

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
