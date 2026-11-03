# Project K – Progress

Read this first in every new session. Keep it short: replace "Current status" and
"Next step" each time; add new entries to the TOP of the session log.

## Current status

- Built: dice, combat, game-tester skill, character creation, 5-fight run with passives.
- Step 1 of the new room plan done (branch feature/ui-and-stat-points): framed UI sections,
  HP/EXP bars, EXP and levels, 3 stat points per level via the level-up panel.
- Run state: `scripts/core/run.gd` (fight, level, EXP). Level-up panel: `scripts/combat/level_up_panel.gd`.
- Play tool actions: attack, defend, 1/2/3 choices, +hp/+attack/+defense/+speed, -stat, confirm.
- Run checks: `for f in tests/test_*.gd; do /Applications/Godot.app/Contents/MacOS/Godot --headless --script res://$f; done`

## Next step

New room plan (see design.md "Chapter rooms"), one branch each:
2. Doors after each fight (3 different of Elite/Shop/NPC event/Rest) with Elite and Rest working,
   gold, 8 rooms + boss; rebalance EXP and enemies for 8 rooms.
3. Shop + potions + Item button in combat.
4. NPC events with d20 checks.

## Open questions

- Defend is still weaker than attacking; needs a reason (enemy wind-ups, or Energy once skills exist).
- Balance is temporary until step 2 (sim: 52-59% clears with 5 fights and stat points).
- Human +10% XP and Fast Learner can work now that EXP exists; not built yet.

## Session log (newest first)

### 2026-11-04 – New room plan, UI sections, stat points
- Kha redesigned the run: 8 rooms + boss, 3 doors (Elite/Shop/NPC event/Rest), every room ends in a fight.
- Replaced upgrade cards with EXP + 3 stat points per level (level-up panel with +/-).
- Rebuilt the combat and creation screens in framed sections; picked class has a gold frame.
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
