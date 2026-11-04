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

### 2026-11-05 – Events (feature/events)
- Lives PR #46 and the design-class-evolution skill PR #47 merged.
- Event door works: 4 events with check choices, dice roll, outcomes, next-fight effects.
- Allies in battle: the Farm companion plus an event helper (Bram the Sellsword, borrowed bandit art for now).
- Next: run design-class-evolution (Warrior -> Knight -> Holy Knight, Mage -> Dark Mage -> Necromancer);
  their special events will be event-door scenes.

### 2026-11-05 – 3 lives (feature/three-lives)
- Eggs PR #45 merged.
- A death with lives left: lose a life and half your gold, heal, Back to town, chapter restarts. 3rd death ends the run.
- Hearts in the battle HERO box; lives check in tests/test_run.gd.

### 2026-11-05 – Farm step 2: eggs (feature/farm-eggs)
- Farm PR #44 merged.
- Owl, Raven and Drake eggs drop from wolves/skeletons, bandits and the Bandit Chief; they hatch at the Farm.
- New skills Keen Sight, Snatch, Fire Breath; Release button in the barn; owl, raven, drake art.

### 2026-11-05 – Farm step 1 (feature/farm)
- Boss background PR #43 merged.
- Farm window (farmer Marta Hayes): buy Puppy, Chick, Piglet; name them; pick one to bring.
- Companion fights with its own AI turn, can be attacked, runs off at 0 HP, grows Baby -> Young -> Adult.
- New: data/animals.json, scripts/core/farm.gd, tests/test_farm.gd, animal and farmer art.
- Next: Farm step 2, eggs from loot.

### 2026-11-05 – Boss background (feature/background-bandit-fortress)
- Peddler's Cart PR #42 merged.
- Bandit fortress at night with a blood moon for the boss fight (darker, more epic).

### 2026-11-05 – Peddler's Cart (feature/peddler-cart)
- Gear upgrades PR #41 merged (blacksmith named Ladis Washrum).
- Peddler's Cart: Pip Wanderwick, 4 random offers, haggling with Charisma, 3 new potions usable in fights.
- Play tool: "leave" closes the cart. New check tests/test_peddler.gd.
- Next: the Farm (animal companions), 3 lives, events.

### 2026-11-05 – Gear upgrades (feature/gear-upgrades)
- Blacksmith PR #40 merged. Upgrades +1 to +3 with d20 + Luck, fail / -1 on nat 1 / +2 on beating the DC by 10.
- Ladis Washrum (dwarf NPC portrait, talk lines), Forge new / Upgrade tabs, anvil cutscene + Settings switch.
- Next: the Peddler's Cart with its own random stock.

### 2026-11-04 – Blacksmith (feature/blacksmith)
- Materials and blueprint drops from monsters; Starmetal Shard from the boss; Blacksmith forging with Luck grades.
- BACK TO TOWN button (chapter restarts, hero keeps everything); after the boss: Back to town / Next chapter (soon).
- 25 item pictures, 9 new gear layers on the hero. Shop PR #39 merged before this.
- Next: gear upgrades (+1 to +3), then the Peddler's Cart with its own random stock.

### 2026-11-04 – Shop and gear (feature/shop-gear)
- 11 gear pieces in data/gear.json, 5 new sprite layers (cap, helm, leather armor, chainmail, shield).
- Town Shop: buy potions and gear, sell gear for half. GEAR window in town and on the path screen.
- Start gold 30. Copper Ring gives +1 Speed (not Luck: Luck does nothing in fights yet).
- New check tests/test_gear.gd.
- Item pictures (16x16) on Shop lines; GEAR page has framed slot boxes in two columns beside the hero (Kha's pick).

### 2026-11-04 – Commands and cooldowns (update/commands-cooldowns)
- Info button removed (hover shows monster info); Meditate/Concentrate is a COMMAND button; Flee stays in the skill list.
- Skill cooldowns: cost + 2 turns for heroes, 2 for monsters; the list shows "wait N".
### 2026-11-04 – Town, step 1 (feature/city)
- Town screen after character creation: animated sunset art, clickable Farm, Blacksmith, Inn, Shop; Leave town starts the run.
- Every fight waits 1 second on the fight screen before the initiative dice (skipped when dice animation is off).
- Inn heals to full; the other buildings are "coming soon". Menu and creation pictures now animate gently.
- Next town steps: Shop (buy potions), Blacksmith + gear slots, Farm, lives (town after 1st/2nd death).

### 2026-11-04 – HP and Energy bars (update/hp-energy-bars)
- Red HP bar over each monster on the battlefield; gold Energy bar (blue Mana for the Mage) in the HERO box.
- Mage's Energy is named Mana ("energy_name" in classes.json); skill costs show in Energy or Mana.
- Energy max 7 in boxes, start 1 (Mage 3, "start_energy"); Meditate/Concentrate (+1, skips attack) and Flee moved into the skill list.

### 2026-11-04 – Skill list and second class skills (feature/skill-menu)
- Skill button opens a list in the COMMAND box (shared with Item); unaffordable skills are greyed out.
- New skills with own poses and effects: Iron Guard, Aimed Shot, Frost Bolt, Uppercut. Classes list "skills" in classes.json.
- Merged: attack animations (#32), enemies stand closer (#33).

### 2026-11-04 – Attack animations (feature/attack-animations)
- Hero attack and skill strips for all 4 classes, attack strips for all 13 monsters, 20 effect strips in assets/sprites/fx/.
- scripts/combat/fight_fx.gd plays effects, projectiles, hit flash and damage numbers; combat_screen._animate wires every attack and all 15 skills.
- Animation names live in classes.json and skills.json. New Settings switch "Attack animation" (off in the play tool).
- Next: Kha tests in game; then the make-attack-animation Claude skill; then the city and gear.

### 2026-11-04 – Skills, Energy and status effects
- data/skills.json; classes and monsters name their skill. Skill button in COMMAND, Energy in the HERO box, statuses on rows and in Info.
- Combatant: energy, shield, statuses, afflict (saves), use_skill; monsters tick poison/burn and can be stunned.
- tests/test_skills.gd added. The balance bot in test_run still plays without skills.

### 2026-11-04 – Game test and item-menu fix
- Gamer + dev tester run. Confirmed open bugs: New hero resets rerolls, shop door/log name mismatch, elite "pack" text when alone, Lucky not on Flee, Bandit Chief arrow over the log; play tool: Bandit look uses a die (shifts --force), doesn't stop at New hero.
- Balance notes: elites pay less than 4-monster rooms, no difficulty curve, classes feel the same, Defend/Speed weak.
- "Item menu freeze" was the play tool clicking hidden buttons; fixed in tests/play.gd (game was fine).
- Next: hero and monster skills with Energy and status effects (list approved 2026-11-04).

### 2026-11-04 – Boss sprites
- Rat King, Bandit Captain, Dire Wolf, Bone Knight, Orc Warlord (48x48) and Bandit Chief (64x64) drawn; every monster now has art.
- Monster cards size the picture from the strip height, so bigger canvases just work.

### 2026-11-04 – Orc Raider sprite
- Orc Raider drawn (green skin, tusks, topknot, fur pad, cleaver). All normal monsters now have art.
- Still text cards: the 5 elites and the Bandit Chief boss.

### 2026-11-04 – Wolf and Skeleton sprites
- Wolf (plus collared version with bandits) and Skeleton drawn; test_run checks the collar rule.
- Still text cards: Orc Raider, the elites and the boss.

### 2026-11-04 – Dice roll animation
- DiceTray shows recorded rolls as tumbling dice in the battle area; Settings > Dice animation.
- Buttons stay locked until the first turn is decided.

### 2026-11-04 – Bandit sprites and target arrow
- Two Bandit looks drawn (rogue, brigand); each Bandit picks one at random.
- Target arrow above the chosen monster replaces the gold frame.

### 2026-11-04 – Hero sprite and customization
- LOOK box in character creation with live preview, name + Random, skin/hair/color/outfit arrows.
- Layered hero sprite (HeroSprite) shown in battle; the log uses the hero's name.
- Art is a first draft for Kha to polish in Pixelorama.

### 2026-11-04 – Main menu and character creation restyle
- Title art (assets/backgrounds/title.png, 384x216, grim dawn, cloaked hero on a cliff).
- Main menu: New Game, Continue (greyed out until saving), Settings (background animation, fullscreen; saved in user://settings.cfg), Quit.
- Character creation restyled with gold-tab boxes, Back button, slot-machine spin on race/talent rolls.
- Shared styles in scenes/ui/ (gold_box, gold_tab, flat_button) and UI.menu_button for all menus.

### 2026-11-04 – Background skill and chapter 1 woods
- make-background skill (setup/background-skill, not merged yet).
- assets/backgrounds/woods.png: deep jungle, 5-frame leaf sway, shown behind every fight (Run.BACKGROUND, one per chapter later).
- Art monsters stand on the background with no card box; the target gets a gold frame. Turn text and hero name have outlines.

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
