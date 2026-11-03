# Project K – Progress

Read this first in every new session. Keep it short: replace "Current status" and
"Next step" each time; add new entries to the TOP of the session log.

## Current status

- Built: dice, combat, game-tester skill, character creation, framed UI, EXP + saved stat points,
  path screen (3 doors: Elite/Rest/Shop/Event), Rest/Train, gold, 8 rooms + Bandit Chief boss.
- Shop and Event doors lead to a plain battle until steps 3 and 4. Gold has no use yet.
- Run state: `scripts/core/run.gd`. Path screen: `scripts/path/path_screen.gd`.
  Stat panel: `scripts/ui/character_panel.gd` (CHARACTER button, path screen only).
- Play tool: fight `attack`, `defend`, `1`; path `1/2/3`, `character`, `+stat`/`-stat`, `confirm`, `close`.
- Run checks: `for f in tests/test_*.gd; do /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://$f; done`

## Next step

Kha picks balance ideas (see Open questions), on an `update/` branch. Then:
3. Shop + potions + Item button in combat.
4. NPC events with d20 checks.

## Open questions

Balance ideas from the 2026-11-04 playtest, waiting for Kha to pick (my pick in brackets):
- 5 Attack too strong (hit + damage): A) hit only, damage +1 per 2 Attack; B) costs 2 points. [A]
- 6 Speed useless: A) every 3 Speed = +1 Armor; B) extra attack if 5+ faster; C) flee chance. [A]
- 7 Defend a trap: A) also heal 10%; B) enemy's next attack at disadvantage; C) stronger crit guard. [B]
- 8 Train weak (~+2 EXP): A) +1 stat point; B) 50% of EXP bar. [A]
- 9 Elite too easy: always toughest enemy for the room, x2 HP, card names the enemy.
- 10 Difficulty ramp: rats only rooms 1-2, new mid enemy (Orc Raider 26 HP d8) rooms 5-8, boss 40 HP.
- 11 Archer/Mage fragile: A) everyone heals 10% after a won fight; B) +4 HP for both. [A]
- Human +10% XP and Fast Learner not built yet.

## Session log (newest first)

### 2026-11-04 – Path choice (step 2) merged
- Path screen: 3 door cards, hero sidebar, CHARACTER button with saved points; Elite, Rest/Train, gold, boss after room 8.
- Game-tester run: no rule bugs. Fixed Rest double-click, boss defeat text, door/rest wording, Armor = 10 + Defense shown.
- Rebalanced boss (44 HP, Atk 4, d10) and Skeleton (24 HP); bot clears 51-58%.
- Balance ideas 5-11 proposed, waiting for Kha.

### 2026-11-04 – New room plan, UI sections, stat points
- Kha redesigned the run: 8 rooms + boss, 3 doors (Elite/Shop/NPC event/Rest), every room ends in a fight.
- Replaced upgrade cards with EXP + 3 stat points per level (level-up panel with +/-).
- Rebuilt the combat and creation screens in framed sections; picked class has a gold frame.
- Step 2 (feature/path-choice): path screen with door cards, hero sidebar, CHARACTER panel, gold, Elite and Rest rooms, 8 rooms + boss.
- Battle log colored and reworded (separate damage line, weapon names); window opens maximized.

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
