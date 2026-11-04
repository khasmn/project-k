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

Branch update/balance-and-groups is ready for Kha to test (monster groups, targeting, Flee, new Defend,
half-Attack damage, elites, Train point, log/actions side by side, Item button with 2 potions). After merge:
- setup/code-style from main: add CLAUDE.md rule (shortest code, no useless comments, no emoji,
  delete unused code) and clean up all scripts/tests to match (Kha said yes, 2026-11-05).
3. Shop + potions + Item button in combat.
4. NPC events with d20 checks.

## Open questions

- Bot sim clears 42-52% with groups (never defends or flees); real play should be easier. Retune after Kha plays.
- Monsters are now small (4-9 HP) so a hero often kills one per hit; elites and the boss are the real threats.
- Human +10% XP and Fast Learner not built yet.
- Later (with art): art-only battle area, hover info and Info command (design.md).

## Session log (newest first)

### 2026-11-04 – Background skill and chapter 1 woods
- make-background skill (setup/background-skill, not merged yet).
- assets/backgrounds/woods.png drawn (feature/background-woods, on top of the skill branch). Not shown in the game yet: needs code, waiting for Kha's OK.

### 2026-11-05 – Art pipeline, Giant Rat sprite, battle screen
- Code-style rule in CLAUDE.md + cleanup; Continue-button fix; add-enemy skill.
- Pixelorama chosen for art. Kha drew the Giant Rat (32x32) with a 5-frame idle at 6 FPS.
- Monsters with a "sprite" show art only; hover tooltip and Info command show their info.
- Battle log floats top-left in a frameless battle area (Kha's reference picture).
- Next art: Bandit, Rat King, hero sprite. Export as a 1-row spritesheet to assets/sprites/enemies/<id>_idle.png.

### 2026-11-05 – Balance and monster groups (update/balance-and-groups)
- Kha picked 5A, 6C (Flee), 7B, 8A, 9 (own elite entries + groups of 1-4), 10, 11B.
- Combat screen: monster cards in a 2x2 grid, click to target, Flee button (not in boss fight).
- Enemies data: "rooms" range, "elite" partner, boss "guards"; Orc Raider + 5 elites added.
- Play tool: t1-t4 to target, flee. Sim retuned to 42-52% for the always-attack bot.

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
