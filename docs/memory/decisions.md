# Project K – Decisions

Every important decision, newest first, with a short "why". Never delete old entries;
if a decision changes, add a new entry that says what it replaces.

| Date | Decision | Why |
| --- | --- | --- |
| 2026-11-04 | Shop sells gear + potions (10g), sells gear back at half; start gold 30; GEAR window with bag | Kha's choices |
| 2026-11-04 | Copper Ring is +1 Speed instead of +1 Luck | Luck has no effect in fights yet |
| 2026-11-04 | Skill cooldown = cost + 2 turns (monsters 2); Meditate moved to COMMAND; Info button removed, hover only | Kha's choices |
| 2026-11-04 | Farm is for animals that can become companions, not food (replaces "farm = food") | Kha's choice |
| 2026-11-04 | Town: warm sunset, built step by step (Inn first, others "coming soon"); menu art animated too | Kha's choices |
| 2026-11-04 | Energy max 7 (was 3), start 1, Mage starts at 3 Mana; Meditate/Concentrate gives +1 for your turn; Flee moved into the skill list | Kha asked: Energy builds up over a fight |
| 2026-11-04 | Mage's Energy is called Mana (same rules); HP bars over monsters; Energy/Mana bar in HERO box | Kha asked |
| 2026-11-04 | Skill button opens a list of skills; each class gets a 2nd skill (Iron Guard, Aimed Shot, Frost Bolt, Uppercut) | Kha's choice: Attack stays one click; more choice per class |
| 2026-11-04 | Attack animations: full hero frames per class and skill, monster attack strips with a lunge, effect strips named in data; an "Attack animation" Settings switch | Kha asked for sword, bow and skill animations; switch for motion comfort |
| 2026-11-04 | Skills: 1 per class now; Energy max 3, full each fight, +1 a turn; monsters use their skill on a d6 5-6 (that d6 isn't animated); status effects poison, burn, stun, shield with saves vs 10 + Attack (full list in design.md) | Kha's choices; makes classes feel different |
| 2026-11-04 | Rat King is skinny and starving (arched spine, ribs, long thin legs) but still scary (scars, fangs, red eye); the Orc Warlord is the fat one (big gut, iron collar). Replaces the fat Rat King | Kha changed their mind |
| 2026-11-04 | Rat King redrawn as one big, fat, scary rat (no crown): round hump, sagging belly, wide maw of fangs, drool, spiky matted fur, many scars, torn ear, glowing red eye, yellow fangs, claws; Giant Rat colors. Replaces the three-rat knot | Kha's request |
| 2026-11-04 | Dire Wolf redrawn: slate blue-grey, big spiky mane, bushy tail, prowling with a paw raised, calm amber eye (inspired by a Fear & Hunger wolf, made less scary); normal Wolf unchanged | Kha's reference |
| 2026-11-04 | Boss art: elites on 48x48, the Bandit Chief on 64x64, shown at the same pixel scale and standing on the same floor; each boss is a very different design from its normal monster (Rat King = three of Kha's rats knotted by the tails) | Kha's choices; .pxo stays as the Pixelorama source, the game reads the exported PNG strip |
| 2026-11-04 | Wolf and Skeleton sprites; wolves wear a collar when a Bandit or Bandit Captain is in the same fight (enemies.json "sprite_with": {monster id: sprite}) | Kha's idea: the bandits' tamed wolves |
| 2026-11-04 | Dice animation: every roll (attacks, damage, initiative, flee) tumbles as a pixel die (~1.5 s) before the log line; same dice land together (advantage); your dice pale green, monster dice dark red; nat 20 gold, nat 1 red; Settings switch to turn it off. Display only: rolls are decided first (Dice.history) | Kha's choices |
| 2026-11-04 | Bandit has two looks (hooded rogue, rough brigand); enemies.json "sprite" can be a list, one picked per monster via Dice. Target is marked by a bobbing gold arrow above it (2 FPS), replacing the yellow frame | Kha's choices |
| 2026-11-04 | Hero customization on the creation screen (LOOK box): name, skin tone per race, hair style and color, 3 outfits; class changes only the weapon; layered tinted sprites | Kha's choices |
| 2026-11-04 | Main menu (New Game, Continue greyed out, Settings, Quit) over grim title art; Settings = background animation + fullscreen | Kha's choices; animation toggle for motion sickness |
| 2026-11-04 | Character creation: battle-screen style, Back button, cosmetic slot-machine spin (real roll still from the dice module) | Kha's choice |
| 2026-11-04 | Chapter 1 is a deep jungle-like forest: bright with a little grim, day, a giant old tree, pointed leaves (no cloud-like blobs), many trunks, vines, ferns; 5-frame breeze loop stored as a strip of 384x128 frames, played at 2 FPS (6 FPS gave Kha motion sickness); backgrounds are 384x128 PNGs in assets/backgrounds/ shown 3x | Kha's choice; make-background skill (JRPG style inspiration only, never copied) |
| 2026-11-05 | Battle log floats top-left inside a frameless battle area (no box, outlined text, hidden scrollbar) | Kha's reference picture; replaces the BATTLE LOG box |
| 2026-11-05 | Art in Pixelorama: 32x32, exported as a strip of square frames (assets/sprites/enemies/<id>_idle.png), 6 FPS; enemies.json "sprite" field; nearest filter project-wide | First sprite: Kha's Giant Rat with a 5-frame breathing idle |
| 2026-11-05 | When sprites exist: battle area is art only; monster info by mouse hover tooltip or an Info command that shows it in the HERO box (tab renamed to the monster) | Kha's plan for later; see design.md "Battle screen once art exists" |
| 2026-11-05 | Combat screen in classic RPG layout: BATTLE area (monster cards + hero), BATTLE LOG, bottom bar ENEMIES / COMMAND / HERO; dark fantasy boxes with gold title tabs, hover cursor on commands | Kha's reference picture; replaces the log/actions half-half row |
| 2026-11-05 | Combat bottom row: battle log and actions side by side (half/half); Item button | Kha's layout request |
| 2026-11-05 | Every run starts with 2 Healing Potions (heal 30% Max HP, uses your turn); items in data/items.json | Kha picked potions now instead of waiting for the shop |
| 2026-11-05 | Fights have 1-4 random monsters from the start (data "rooms": [first, last]); click a card to target | Kha's choice; monsters made much weaker one by one so groups stay fair |
| 2026-11-05 | Elites are their own entries (Rat King, Bandit Captain, Dire Wolf, Bone Knight, Orc Warlord); elite room = elite + 0-2 helpers; boss = Bandit Chief + 2 Bandits | Kha picked 9 + groups; replaces the 1.5x HP "Elite X" formula |
| 2026-11-05 | Damage = weapon die + half Attack (Attack still fully adds to hit) | Attack was the only good stat pick (5A) |
| 2026-11-05 | Speed: initiative and Flee (d20 + Speed vs 10 + fastest monster's Speed; escape = no rewards, fail = lose turn; no flee from boss) | 6C |
| 2026-11-05 | Defend: +4 Armor and attacks on you roll with disadvantage until your next turn | 7B |
| 2026-11-05 | Train gives +1 stat point (replaces +10% EXP); Archer 34 HP, Mage 30 HP; Orc Raider added rooms 5-8, rats rooms 1-2 | 8A, 11B, 10 |
| 2026-11-04 | Run = 8 rooms + Bandit Chief boss; after each fight pick 1 of 3 different doors (Elite, Rest, Shop, Event) | Kha wants choices between fights; replaces the fixed 5-fight list |
| 2026-11-04 | Stat points are saved; spend them any time with the CHARACTER button on the path screen (replaces the level-up popup) | Kha's reference layout |
| 2026-11-04 | Shop and Event doors show as cards but lead to a plain battle until steps 3 and 4 | Kha's choice |
| 2026-11-04 | Elite = 1.5x HP, +1 Attack/Defense, double gold and EXP; Rest = +30% HP or +10% EXP bar; boss 44 HP, Atk 4, d10 | Bot clears 51-58% after rebalance |
| 2026-11-04 | Game window opens maximized; UI scales up (canvas_items stretch) | Kha wants the game to fill the screen |
| 2026-11-04 | Battle log in plain words with colors: attack line + separate damage line with weapon names | Kha found the dice math hard to read |
| 2026-11-04 | UI in framed sections (top bar, hero, enemy, battle log, actions, level-up) with HP/EXP bars | Kha found the interface confusing |
| 2026-11-04 | EXP bar (8, 12, 16...) and 3 stat points per level, spent with +/- (replaces upgrade cards) | Kha wants to build the hero himself |
| 2026-11-04 | Plan: 8 rooms + boss; 3 different doors from Elite/Shop/NPC event/Rest; every room ends with a fight; Rest = +30% HP or +10% EXP bar | Kha's design; built in 4 small steps |
| 2026-11-04 | Every passive writes a log line when it helps (e.g. "Chosen One: rolled 7 and 15") | Playtest: passives felt invisible |
| 2026-11-04 | Upgrade pool: +5 Max HP, +1 Attack/Magic, +1 Defense, +1 damage, Heal 50% HP; +1 Speed removed | Playtest: boss wall and useless Speed; sim now 40-48% |
| 2026-11-03 | Classes tuned (Warrior Def 2; Archer 30 HP, Def 2; Mage 26 HP, Def 1; Brawler 30 HP, Atk 3, d8) | Sim: all classes clear ~30-34% of runs |
| 2026-11-03 | Softer enemies (Rat 10, Bandit 16, Wolf 18, Skeleton 22, Chief 32 HP) | First set was nearly unwinnable (0-3%) |
| 2026-11-03 | Initiative ties go to the enemy unless the hero is an Elf (replaces "hero wins ties") | Gives Elf's passive a purpose |
| 2026-11-03 | Passive numbers: Mossfolk +1 HP/turn, Glass Cannon +2 dmg -6 HP, Bloodlust +4 HP on win, Lucky rerolls first nat 1/fight, Keen Eye crit 19-20, Second Wind once per run, Chosen One advantage on attacks + initiative | Simple combat passives first |
| 2026-11-03 | 5-fight run: Rat, Bandit, Wolf, Skeleton, Bandit Chief; no healing between fights; level up after every win (1 of 3 upgrades); lose or win = back to creation | Build step 3, lives come in step 5 |
| 2026-11-03 | 5 rerolls each for race and talent (replaces "5 rerolls shared") | Kha wants more control over both rolls |
| 2026-11-03 | Legendary talent: Chosen One (advantage on every check) | Kha picked it from Claude's ideas; strongest option, watch balance |
| 2026-11-03 | Passives and check bonuses are text only for now; built later | Keeps character creation small |
| 2026-11-03 | Hero stats = class base + race changes; Mage attacks with Magic | Numbers proposed by Claude, approved by Kha |
| 2026-11-03 | Character creation is its own screen for now; connect to combat in build step 3 | Small steps |
| 2026-11-03 | Defend gives +4 Armor (replaces +2) | +2 was never worth picking (playtest) |
| 2026-11-03 | Crit rolls the damage die twice, then adds Attack (replaces "doubles total damage") | Doubling made crits near one-shots (playtest) |
| 2026-11-03 | A hit always does at least 1 damage | Negative Attack must not heal |
| 2026-11-03 | Armor = 10 + Defense; Defend gives +2 Armor until your next turn | D&D-style, simple; easy to change |
| 2026-11-03 | Crit (nat 20) doubles total damage; damage = weapon die + Attack | Matches design "double damage" |
| 2026-11-03 | Combat prototype: Attack + Defend only, stats from JSON, Restart button | Small but a real choice; data-driven from the start |
| 2026-11-03 | Game-tester skill (gamer + dev tester agents) waits until combat prototype runs | Nothing to test yet |
| 2026-11-03 | Dice is a static `class_name Dice` script, not an autoload | Simplest; callable anywhere |
| 2026-11-03 | Nat 20 always succeeds, nat 1 always fails, for every check | Every roll keeps hope and risk |
| 2026-11-03 | Claude merges PRs with gh when Kha says merge (replaces "Kha merges PRs") | Faster workflow |
| 2026-11-03 | Claude asks when unclear and asks before building its own ideas | Kha stays in control |
| 2026-11-03 | Project memory lives in docs/memory/ (design, progress, decisions) | New chats and Claude Code can pick up where we left off |
| 2026-11-03 | Every feature/fix/update on its own branch; Kha merges PRs into main | Keep main stable and reviewable |
| 2026-11-03 | Working title "Project K" | No name yet |
| 2026-11-03 | Death: back to main menu, restart chapter, keep level and gear | Forgiving but still has stakes |
| 2026-11-03 | 3 lives per character; third death ends the run | Gives runs tension without instant loss |
| 2026-11-03 | Class evolution event at level 15 (choose 1 of 2 paths) | Mid-run power spike and choice |
| 2026-11-03 | Classes: Warrior, Archer, Mage, Brawler | Clear, distinct starting roles |
| 2026-11-03 | Added common races Elf, Orc, Dwarf, Undead; keep current race names | More familiar fantasy options |
| 2026-11-03 | 5 rerolls shared between race and talent | Adds a strategic choice |
| 2026-11-03 | Races and talents rolled by rarity (50/25/15/8/2%) | Pixel Lineage-style excitement |
| 2026-11-03 | Mouse-only controls first | Simplest for a turn-based PC game |
| 2026-11-03 | PC first (macOS + Windows), iPhone later | Develop and test on the Mac directly |
| 2026-11-03 | D&D-style d20 checks for combat, talk, exploration | Tension and meaningful race/talent bonuses |
| 2026-11-03 | Godot 4 with GDScript (not Unity, not C#) | Lightweight, strong 2D, beginner-friendly |
