# Project K – Game Design

Source of truth for the game design. (A copy also lives on claude.ai:
https://claude.ai/artifact/4UKyd7RnGBHQ5ZpMwuFAQo — if they differ, THIS file wins.)

## Overview

A 2D pixel-art, turn-based roguelike RPG where every action that matters is decided by a d20 roll.
You create a hero by rolling a race and a talent and picking a class, then fight, talk and sneak
through chapters of rooms until you beat the boss or lose all your lives.

- Genre: turn-based roguelike RPG with tabletop-style dice checks
- Platform: PC first (Windows and macOS), built in Godot 4; mouse-only controls; iPhone maybe later
- Inspiration: Pixel Lineage on Roblox (races and talents) and D&D (d20 checks)
- Audience: just me for now
- Working title: Project K (placeholder)

## Character creation

### Hero look (Kha 2026-11-04)
- Name: typed, or a Random button (names in data/looks.json) so it works mouse-only.
- Each race has its own look and 3 skin tones (races.json "skins"): Human normal tones, Elf pointed ears,
  Orc green with tusks, Dwarf beard, Ironhide grey with rivets, Undead pale with sunken eyes,
  Mossfolk bark skin with leaves, Emberkin red-orange with glowing eyes, Glimmerfae lilac with wings.
- Player picks: skin tone, hair style (short, long, ponytail, mohawk, bald), hair color, outfit
  (Peasant, Adventurer, Noble; looks only). The class only changes the weapon.
- Art: 32x32 layered 5-frame strips in assets/sprites/hero/ (race, face, outfit, hair, weapon);
  grey layers are tinted with the skin or hair color. Drafted by Claude, Kha polishes in Pixelorama.

Race and talent are rolled at random, weighted by rarity. Class is picked freely.

Rolling rules:
- Race and talent are each rolled once for free.
- Then 5 rerolls for race and 5 rerolls for talent (separate, not shared).
- A reroll replaces the current result; when rerolls run out, you keep what you have.
- Rerolls reset with each new character and don't carry over.
- Chance per rarity: Common 50%, Uncommon 25%, Rare 15%, Epic 8%, Legendary 2%.
- Rarer = stronger passive. Rarer races/talents can also be unlocked through meta-progression.

### Races (names are final for now; may add/fix later)

| Race | Rarity | Strength | Passive | Check bonus |
| --- | --- | --- | --- | --- |
| Human | Common | Balanced | +10% XP | +2 on talk checks |
| Elf | Common | Agile | +Speed; wins tied initiative | +2 on spotting hidden things |
| Orc | Common | Brute | +Attack, -Charisma | +2 on intimidate |
| Dwarf | Uncommon | Sturdy | Resists poison | +2 on lock and trap checks |
| Ironhide | Uncommon | Tank | High Defense, low Speed | +2 on strength checks |
| Undead | Rare | Resilient | Immune to poison; healing potions heal half | +2 on sneak checks |
| Mossfolk | Rare | Sustain | Regenerate a little HP each turn | +2 on nature and herb checks |
| Emberkin | Epic | Damage | Attacks have a small chance to burn | +2 on intimidate |
| Glimmerfae | Legendary | Magic | High Magic, low HP | +2 on magic checks |

### Talents

| Talent | Rarity | Effect |
| --- | --- | --- |
| Fast Learner | Common | +XP, and gain XP even on a failed check |
| Glass Cannon | Common | +Damage, -HP |
| Bloodlust | Uncommon | Heal a little on each kill |
| Silver Tongue | Uncommon | Advantage on persuasion checks |
| Lucky | Rare | Reroll one natural 1 per fight; better loot |
| Keen Eye | Rare | Critical hit on 19 or 20 |
| Second Wind | Epic | Survive one lethal hit per run |
| Chosen One | Legendary | Advantage on every check |

### Classes

Picked freely. At level 10 an evolution event appears (Kha 2026-11-05; was 15): choose 1 of 2 advanced
paths (new skills + boost to the class's main stat). Each class also has 1 secret class (below).

| Class | Role | Main stat | Evolves into | Secret class (from) |
| --- | --- | --- | --- | --- |
| Warrior | Front-line melee | Attack | Knight (tank) or Berserker (damage) | Holy Knight (Knight) |
| Archer | Ranged damage | Attack, Speed | Ranger (beasts) or Sharpshooter (crits) | Grove Warden (Ranger) |
| Mage | Spells | Magic | Elementalist (fire, ice, storm) or Dark Mage (curses, life drain; replaces Warlock) | Necromancer (Dark Mage) |
| Brawler | Fast unarmed combos | Attack, Speed | Monk (dodge, counters) or Pit Fighter (stun, grapple) | Tempest Fist (Monk) |
| Lancer (NEW) | Reach and charges | Attack, Speed | Skylancer (leaps) or Phalanx (spear wall) | Drakerider (Skylancer) |

Lancer (planned): HP 32, Attack 3, Defense 2, Speed 2, Charisma 1, Luck 1, spear d8. Skills: Piercing Thrust
(2 Energy: to_hit +2, extra_die 4), Sweeping Arc (3: Speed save, all monsters, d6). Skylancer: Leap Strike
(3: advantage, extra_die 8), Wind Step (1: shield 5). Phalanx: Spear Wall (2: shield 4 for all), Impale
(3: extra_die 8, stun on a failed Defense save). Look: light scale armor, long spear held low, red pennant.

### Secret classes (Kha 2026-11-05)

A 3-step quest, open from chapter 6 (after twist 1); sealed hints of each path appear in ch 3-4. The token
event offers 2 stat choices (e.g. Charisma DC 16 or Defense DC 17), so one stat you can't raise doesn't lock
you out. Fail the event check or lose the trial: that path is
gone this run (it can come back in a later run). Dying during the deed resets its counter. The trial is
fought ALONE (no companion, no helper, no potions); trial bosses are 48x48, about chapter 6 boss strength.
Win: the class changes, +stat boost, 2 new skills, a short scene line.

| Secret class | Needs | 1. Event (rare, ch 6+) -> token | 2. Deed | 3. Trial boss | Boost | Skills |
| --- | --- | --- | --- | --- | --- | --- |
| Holy Knight | Knight | The Last Oath (dying paladin), Charisma DC 16 -> Oath Sigil | Defeat 3 demon/Hollow elites | Ashmaw, horned fire demon (HP 70, Atk 6, Def 4, Spd 3, d10; Hellbrand: Speed save, burn 3 x2) | Defense +3 | Sacred Aegis (3: shield 10 all), Radiant Smite (4: advantage, extra_die 10) |
| Necromancer | Dark Mage | The Bone Lantern (graveyard ghost), Magic DC 16 -> Forbidden Tome | Defeat 12 undead (does not reset on death) | The Grave Warden, crowned skeleton king (HP 60, Atk 5, Def 3, Spd 2, d8; Bone Legion: shield 6 all) | Magic +3 | Raise Dead (4: a skeleton ally this fight, NEW key summon), Soul Drain (3: extra_die 8, heal half, NEW key drain) |
| Grove Warden | Ranger + an Adult Owl | The White Stag, Speed DC 16 -> Stag Antler | Win 6 fights in a row without the Owl falling | Thornmaw, bramble-grown wolf (HP 65, Atk 5, Def 3, Spd 5, d8; Rot Thorns: poison 2 x3) | Speed +2, Attack +1 | Hail of Thorns (3: Speed save, all, poison 2 x3), Hunter's Mark (2: advantage, extra_die 6, stun save) |
| Tempest Fist | Monk | The Silent Waterfall (old master), Defense DC 15 -> Master's Sash | Win 6 fights without a potion | Gravel, stone mountain ogre (HP 80, Atk 5, Def 5, Spd 1, d10; Quake: Speed save, stun) | Speed +3 | Hundred Blows (3: 4 attacks at -3), Eye of the Storm (2: shield 6 + next attack advantage) |
| Drakerider | Skylancer + an Adult Drake | The Sky Altar, Charisma DC 16 -> Drake Horn | Beat a chapter boss with the Drake standing | Stormwing, wild drake matriarch (HP 75, Atk 6, Def 3, Spd 6, d10; Gale Dive: advantage, extra_die 6) | Attack +2, Speed +1 | Diving Lance (4: advantage, extra_die 12), Dragonfire Charge (4: Speed save, all, burn 2 x2) |

Watch in testing: Radiant Smite and Diving Lance (strongest), Raise Dead (keep the skeleton weak, ~8 HP).

## Stats

| Stat | What it does |
| --- | --- |
| HP | Health; reach 0 and you lose one of your 3 lives |
| Attack | Bonus to physical attack rolls and damage |
| Magic | Bonus to spell power and magic checks |
| Defense | Sets your Armor, the number enemies must roll to hit you |
| Speed | Bonus to initiative (turn order) |
| Charisma | Bonus to persuade, intimidate and deceive checks |
| Luck | Crit chance and loot quality |

Energy is a separate resource that skills spend each fight.

## Dice system

Roll d20 + modifier vs a target number (DC). Meet or beat it to succeed.
- Natural 20: critical success (roll the damage dice twice, or best dialogue outcome)
- Natural 1: critical failure (stumble, or NPC turns hostile)
- Advantage: roll 2 d20 keep higher. Disadvantage: roll 2 keep lower.
- Damage dice: weapons roll their own dice on a hit (dagger d6, greatsword d10).

Rolls only when they matter. Every roll shows an animated d20 and the math,
e.g. "14 + 3 = 17 vs DC 15, success!". One shared dice module handles combat, talk and events.
Mechanics are free to use; the D&D name and its unique monsters/settings are off limits.

## Combat

1. Initiative: everyone rolls d20 + Speed; highest acts first. Ties go to the enemy (Elf wins ties).
2. Choose an action: Attack, Skill, Item or Defend.
3. Attack roll: d20 + Attack vs target's Armor. On a hit, roll weapon damage.
4. Skills cost Energy. Spells can skip the attack roll and force a saving throw instead.
5. Saving throws resist poison, stun and other effects.
6. Repeat until one side is defeated.

Status effects: burn, poison, stun, shield.

### Skills and Energy (built 2026-11-04, data/skills.json)

- Energy: max 7, shown as 7 boxes. 1 at your first turn (Mage: 3 Mana), +1 at the start of each turn.
- COMMAND: Attack, Skill, Meditate/Concentrate (skip your attack, +1 Energy), Defend, Item. No Info button: monster info shows on mouse hover.
- Skill list: your skills, then Flee (not in boss fights).
- Cooldown: a used skill waits its cost + 2 of your turns (Iron Guard 3, Fireball 5, others 4). Monster skills wait 2 turns. A Mage calls it Mana (same rules, blue bar; others a gold Energy bar under HP). Each class has 2 skills; the Skill button opens a list (name + cost), Back closes it.
- A save is d20 + a stat vs 10 + the user's Attack (Magic for a Mage). Nat 20 always passes, nat 1 always fails.
- Poison and burn hurt at the start of the victim's turn and ignore shields. Stun = lose your next turn.
  Shield soaks attack damage, then breaks. A new fight clears everything.
- Monsters: each turn a d6 (not animated); on 5-6 they use their skill instead of a normal attack.

| Who | Skill | Effect |
| --- | --- | --- |
| Warrior | Shield Bash (2) | Attack; hit = Defense save or stunned |
| Archer | Poison Arrow (2) | Attack; hit = Defense save or poison 1 x 3 turns |
| Mage | Fireball (3) | Every monster makes a Speed save: fail = full damage + burn 2 x 2 turns, pass = half |
| Brawler | Flurry (2) | Two attacks at -2 to hit |
| Warrior | Iron Guard (1) | No attack; gain Shield 6 |
| Archer | Aimed Shot (2) | Attack with advantage, +1d6 damage |
| Mage | Frost Bolt (2) | Attack; hit = Speed save or frozen (stunned) |
| Brawler | Uppercut (2) | Attack at -2 to hit, +1d8 damage |
| Giant Rat | Diseased Bite | Attack; hit = save or poison 1 x 3 |
| Bandit | Cheap Shot | Attack with advantage |
| Wolf | Pack Howl | All monsters get Shield 2 |
| Skeleton | Bone Wall | Itself Shield 4 |
| Orc Raider | Cleave | Attack, +1d4 damage |
| Rat King | Plague Bite | Attack; hit = save or poison 2 x 3 |
| Bandit Captain | Rally | All monsters get Shield 3 |
| Dire Wolf | Pounce | Attack with advantage; hit = save or stunned |
| Bone Knight | Dark Aegis | Itself Shield 8 |
| Orc Warlord | Rampage | Two attacks |
| Bandit Chief | Firebomb | You make a Speed save: fail = d6 + burn 2 x 2, pass = half |
Later idea: a timing click on attacks for bonus damage.

### Battle screen with art (Kha 2026-11-05, built for monsters that have a sprite)

- The BATTLE area shows only art (monster and hero sprites), no words.
- Monster info, two ways:
  1. Hover the mouse over a monster: a small info box appears at the mouse.
  2. COMMAND gets an "Info" option: pick a monster and its info shows in the HERO box,
     whose title tab changes from "HERO" to that monster's name.
- Monsters without a sprite keep the text card until they get art.
- Info shows the current target and is a free action; it switches back to HERO on Info again or when your turn ends.

## Talk and exploration checks

- Talk: Charisma checks to persuade, intimidate or deceive (discounts, enemies backing down, secrets)
- Exploration: pick locks, disarm traps, spot hidden doors, sneak past fights
- Failure stays interesting: a failed check leads somewhere (e.g. a fight), never a dead end

Example event, "a bandit blocks the bridge":

| Choice | Check | DC |
| --- | --- | --- |
| Fight | Combat | - |
| Persuade | Charisma | 14 |
| Intimidate | Charisma (Emberkin +2) | 12 |
| Sneak | Speed | 15 |

## Story: 10 chapters (Kha 2026-11-05, adjusted after the review panel)

Monsters keep attacking the kingdom. King Oswin summons the hero: kill the Demon King and the evil stops.
His castle is sealed behind 4 Crystals, each guarded by one of his 4 Demon Lords.

Characters:
- **King Oswin**: warm and grateful on screen. After each Demon Lord a royal envoy visits town, pays a royal
  reward and asks for "the crystal's dust, for the royal vault". Once he says of his late queen: "She would
  have liked you." His real motive: bring his dead queen back through the Hollow.
- **Sir Corwin Vale**: the royal knight who brings the summons in ch 1; returns between chapters with the
  King's letters, which grow colder the more you die ("His Majesty grows impatient"). Turns on the King in
  ch 7 and leads the betrayed knights in ch 8.
- **Malzareth, the Demon King**: the warden of the seal, not the plague.

| Ch | Place | Story beats | Boss |
| --- | --- | --- | --- |
| 1 | Whispering Woods (built) | Bandits raid villages (monsters drove them from the hills). Hook: the Bandit Chief's last words "They pay us in shards... the hills are cracking." The Starmetal Shard is a chip of a crystal; forging with it plays a Hollow whisper. Sir Corwin brings the King's summons. | Bandit Chief |
| 2 | Frostfang Peaks | Crystal of Frost. Last words: "Three more locks, little key. Then you will wish for my cold." Lore event: a dying minion begs "Don't break it, it holds them back." The envoy collects the crystal dust. | Demon Lord Vharn the Frost Tyrant |
| 3 | Sunken Marsh | Crystal of Venom. Last words: "Every crack you make, something below is listening." Sealed secret-class hints appear ("The paladin's oath is bound until the locks break"). Lore event. | Demon Lord Mother Silt (swamp witch-demon) |
| 4 | Ember Wastes | Crystal of Flame. Last words: "Burn me. Fire was never the thing to fear." Lore event. Hollow-touched monsters start to appear. | Demon Lord Pyrrax the Cinder Beast |
| 5 | Obsidian Citadel | Crystal of Shadow: Lord Nyxara (mid-chapter) speaks before she dies. Malzareth only blocks for his first 2 turns: "Not yet... you don't understand." TWIST 1: dying, he says he was the lock; the crystals sealed the Hollow and the hero broke all four. End of the first act (cliffhanger). | Malzareth, the Demon King |
| 6 | The Shattered Lands | Hollow creatures pour out; some demons offer a truce. Secret class paths open. From now on the death screen speaks in the Hollow's voice: "Again, little key. We are patient." | The First Herald of the Hollow |
| 7 | Royal Capital | TWIST 2: the crystal dust you sent burns in Oswin's crown. He used the hero to break the seal to bring his queen back. Sir Corwin turns on him. | King Oswin, twisted by the Hollow |
| 8 | Forgotten Temple | Sir Corwin leads the betrayed knights; loyal demons show how to reforge the seal from the crystals' remains. | Nyxara Reborn (now serving the Hollow) |
| 9 | The Abyss Gate | Fight to the gate with the reforged seal. The Gatekeeper is the queen, returned by the Hollow as a monster: what Oswin wanted. | The Gatekeeper (the queen) |
| 10 | The Hollow Throne | Final battle. | The Hollow One |

How the story is shown and built:
- The world visibly breaks: a new crack in the town sky for each crystal taken; recolored "Hollow-touched"
  monsters (enemies.json "variant_of" + "tint") from ch 3-4 on.
- Lore events: check-free event-door scenes (events.json "lore": true); events get a "chapters" list.
- Twist scenes play only the first time (a flag); a chapter retry shows a one-line "intro_retry".
- data/chapters.json, one entry per chapter: background, enemy_pool, elite_pool, boss, intro, intro_retry,
  outro, hp_mult, dc_bonus (difficulty scaling). Build it before chapter 2.
- Cut line: chapters 1-5 are a complete first act (ending on twist 1 as a cliffhanger) before the Hollow half.

## Run loop and meta-progression

A run is split into chapters; each chapter is a path of rooms ending in a boss.

Chapter rooms (planned, Kha's design 2026-11-04):
- A chapter is 8 rooms, then the boss.
- After every fight, pick 1 of 3 doors: 3 DIFFERENT room types, chosen at random from
  Elite, Shop, NPC event and Rest (one type is left out each time).
- Every room ends with a monster fight:
  - Elite: a harder fight, about double gold and EXP.
  - Shop: buy potions with gold, then fight.
  - NPC event: a short scene with d20 check choices (reward or trouble), then fight.
    Built (Kha 2026-11-05): data/events.json, 4 events (Toll Bridge, Stranger on the Road, Mossy Shrine,
    Abandoned Cart). The story shows on the path screen with one card per choice ("Charisma +1 vs DC 14",
    "20 gold"); the d20 tumbles, then the result and "On to the battle". Outcomes: gold, heal, damage (never
    lethal), EXP, items, materials, and for the next fight: strike first, monsters stunned, start poisoned,
    an elite fight, a helper who fights with you for one battle (data/allies.json, e.g. Bram the Sellsword),
    or skip the fight. Events don't repeat in a run until all were seen.
  - Rest: choose Rest (+30% HP) or Train (+10% of the current EXP bar), then fight.
- Potions are used in combat with an Item button.

Create hero -> explore rooms -> chapter boss -> next chapter ... -> run ends
-> earn currency -> unlock new races/talents/classes -> next run

Lives: each character has 3 lives. On death (Kha 2026-11-05): straight to town ("Back to town" on the
defeat screen), restart from the beginning of that chapter at full HP, KEEP level, gear, items, materials
and animals, LOSE half your gold. 3 hearts next to Level/EXP/Gold in the battle HERO box (lost = dark). The third death ends the run and resets
the hero; currency earned still unlocks content for future runs.

## Loot and progression

- EXP from fights fills a bar (8, 12, 16, ... EXP per level). Each level gives 3 stat points:
  1 point = +3 Max HP (also heals 3), +1 Attack (Magic for a Mage), +1 Defense or +1 Speed.
  Spent on a level-up panel with + / - buttons and Confirm. (Skills/passives on level-up: later.)
- Gear slots: weapon, armor, trinket
- Rarity tiers: common, uncommon, rare, epic, legendary
- Shop: spend gold found during the run on gear and potions
- Data-driven: races, talents, classes, enemies, items live in data files

## Build order

1. Dice module + combat prototype (one hero vs one enemy, simple shapes)
2. Character creation screen (race, talent, class, 5 rerolls each)
3. A run of 5 fights with level-up choices
4. Chapter map: shop, rest, events, boss
5. Saving, 3 lives, meta-progression unlocks
6. Pixel art, sound, polish

## City and gear (Kha 2026-11-04, planned after attack animations)

- A pixel town you click, shown after character creation and after the 1st and 2nd death (3 lives).
- Buildings in the first version: Shop (buy items), Blacksmith (craft and upgrade gear),
  Farm (raise animals; some become companions that fight with you; not food, Kha 2026-11-04), Inn/Temple (heal, see lives left).
- Gear slots: helmet, armor, weapon 1, weapon 2 (a shield, or taken by a two-handed weapon 1),
  and 2 jewelry/artifact slots. Gear is crafted at the Blacksmith or dropped by monsters.
- Details still to decide with Kha when each building is built.
- Built 2026-11-04 (step 1): `scenes/city/town.tscn`, warm sunset art `assets/backgrounds/town.png` (8 frames: windmill,
  smoke, forge fire, flag, lanterns). Character creation -> Town -> "Leave town" -> first fight.
  Inn works (rest = full HP, free). Farm, Blacksmith and Shop windows say "coming soon". Town name: "Town" until Kha picks one.
- Menu picture (title.png) is now an 8-frame strip too: birds, sun shimmer, scarf and cape flutter, stars.
  All full-screen art uses `scripts/ui/animated_art.gd`; the "Background animation" switch stops it.
- Built 2026-11-04 (step 2, Shop and gear): start with 30 gold. Town Shop sells Healing Potion (10g) and gear
  (`data/gear.json`, 11 pieces: Leather Cap, Iron Helm, Leather Armor, Chainmail, one weapon per class, Wooden Shield
  for Warrior/Brawler, Copper Ring +1 Speed, Bone Charm +4 Max HP). Sell gear back for half price.
  GEAR window (town "Gear" button, path screen GEAR button): 6 framed slot boxes with item pictures, 3 left of
  the hero (helmet, armor, weapon) and 3 right (shield, 2 jewelry), and a bag; click to wear or take off.
  Every gear piece and item has a 16x16 picture in `assets/sprites/items/<id>.png`, shown on Shop and bag lines. Helmet, armor and shield show on the hero sprite; a weapon tints the class weapon.
  Rules in `scripts/core/gear.gd`, window in `scripts/ui/gear_window.gd`. Two-handed weapons not yet.

### Blacksmith, materials, blueprints (built 2026-11-04)

- Every beaten monster drops its material (normal 1, elite 2): Rat Tail, Iron Scrap, Wolf Pelt, Old Bone, Orc Tusk.
  Then a d20 for its blueprint: 20 for normal monsters, 15+ for elites (data "loot" in enemies.json).
- The boss drops 1 Starmetal Shard. 1 Shard + 30g forges one top piece of your choice (Starmetal Blade/Bow/Staff/
  Knuckles, Helm, Plate, Shield, Amulet).
- Blacksmith (town): basic recipes known from the start (tier 2, not in the Shop: Steel Helm, Studded Armor, a steel
  class weapon), blueprint recipes once found, Starmetal recipes. Cost = materials + gold (data/recipes.json).
- Forging rolls d20 + Luck for the grade: 1-5 Crude (-1), 6-11 Common, 12-15 Uncommon (+1), 16-18 Rare (+2),
  19-21 Epic (+3), 22+ Legendary (+4); a natural 20 is at least Epic. The bonus goes to the piece's main (first) stat.
  Shop gear is Common.
- Blueprints and Starmetal Shards are kept for every future hero; other materials and gear belong to the hero.
- BACK TO TOWN (path screen): restart the chapter at room 1, keep hero, level, gear, gold and materials.
  After the boss: Back to town, or Next chapter (coming soon).
- Peddler's Cart (built 2026-11-05, path Shop door): Pip Wanderwick (portrait + lines). 4 random offers per visit:
  graded gear (Uncommon/Rare/Epic, also forge-only pieces, never Starmetal), material bundles (rarely a Starmetal
  Shard), and potions the town Shop doesn't sell: Greater Healing Potion (50%), Energy Tonic (+2 Energy),
  Luck Charm (next attack with advantage). Haggle once per visit: d20 + Charisma vs DC 12, success 25% off,
  natural 1 = prices +25%. "Leave the cart" starts the battle. Rules in scripts/core/peddler.gd.
- Upgrades (built 2026-11-05): +1 to +3, each +1 adds +1 to the main stat. d20 + Luck vs DC 6 / 10 / 14.
  Cost 2/3/4 of the piece's "upgrade" material (gear.json) + 10/20/30 gold. Fail: cost gone, piece safe.
  Natural 1: also -1 level. Beat the DC by 10+: +2 levels (Kha: high Luck can give +2). Natural 20 always works.
- The Blacksmith is Ladis Washrum, a dwarf (portrait + talk lines in data/npcs.json). After each forge or
  upgrade an anvil cutscene plays (3 slow hammer strikes, then the piece in its grade color; click to skip).
  Settings switch "Forge cutscene".
- Blacksmith window layout: framed boxes with gold name tabs (LADIS WASHRUM, FORGE/UPGRADE, HERO, MATERIALS),
  like the battle screen. Shop and GEAR windows keep the plain layout.

### Farm and companions (Kha 2026-11-05)

- The Farm in town (farmer Marta Hayes) sells baby animals: Puppy 40g (-> Dog, Howl: hero +power to hit and
  damage on the next 2 attacks), Chick 25g (-> Hen, Warm Egg: heals the hero power HP), Piglet 50g
  (-> Boar, Charge: +1d4 damage, stuns on a crit). Stats per stage in data/animals.json.
- Barn holds 4; you name them (random name first). One comes along (the first bought, or pick "Bring along").
- In battle it stands left of the hero and acts on its own right after the hero: skill when ready
  (cooldown 2 turns), otherwise it attacks the hero's target. Each monster attacks the hero or it (d2).
  At 0 HP it runs back to the farm; next fight it's back at full HP.
- It gets the monsters' EXP after each won fight: Young at 20 EXP, Adult at 60 (bigger art and stats).
- Animals belong to the hero like gear: kept on Back to town, a new hero starts with an empty farm.
- Eggs (step 2): a beaten monster may drop its egg on a loot d20 (normal 20, elite 17+, boss 15+).
  Owl Egg: wolves, skeletons (and their elites) -> Owlet/Owl, Keen Sight (hero's next attack has advantage).
  Raven Egg: bandits (and the captain) -> Raven, Snatch (attack, a hit steals d3 x power gold).
  Drake Egg: the Bandit Chief -> Drake, Fire Breath (all monsters, Speed save, fail = damage + burn).
  Eggs count as barn places; with a full barn the egg rolls away. Eggs hatch as soon as you open the Farm.
  Release button lets an animal go to make room.

### Boss background (Kha 2026-11-05)

- The boss fight uses `assets/backgrounds/bandit_fortress.png` (Run.BOSS_BACKGROUND): the bandits' fortress at night
  under a blood moon, spiked log wall, watchtower, red banners, torches and a bonfire; epic + grim mix.
  5 frames at 2 FPS: clouds drift, fire and torches flicker, banners sway. Rooms 1-8 keep the woods.

## Attack animations (Kha 2026-11-04)

- Full character frames: every class and monster gets its own attack frames, skills get their own effects.
- Hero: 6-frame weapon strips `hero/weapon/<class>_attack.png` and `<class>_skill.png`; body and head shift per frame (POSES in hero_sprite.gd).
- Monsters: `enemies/<sprite>_attack.png` (squash/stretch of idle frame 0) plus a lunge toward the hero.
- Effects: `assets/sprites/fx/` strips. Classes and skills name them in data: "pose", "aura", "projectile", "impact", "shield_fx".
  Status effects (poison, burn, stun) play the strip with the same name when they land.
- Order stays: rules decide, dice show, animation plays, then the log line. Damage numbers rise from the target.
- Settings "Attack animation" switch turns all of it off (motion comfort).
