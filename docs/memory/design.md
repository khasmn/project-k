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

Picked freely. At level 15 an evolution event appears: choose 1 of 2 advanced paths
(new skills + boost to the class's main stat).

| Class | Role | Main stat | Evolves into |
| --- | --- | --- | --- |
| Warrior | Front-line melee | Attack | Knight (tank) or Berserker (damage) |
| Archer | Ranged damage | Attack, Speed | Ranger (traps, pets) or Sharpshooter (crits) |
| Mage | Spells | Magic | Elementalist (fire, ice, storm) or Warlock (curses, life drain) |
| Brawler | Fast unarmed combos | Attack, Speed | Monk (dodge, counters) or Pit Fighter (stun, grapple) |

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
  - Rest: choose Rest (+30% HP) or Train (+10% of the current EXP bar), then fight.
- Potions are used in combat with an Item button.

Create hero -> explore rooms -> chapter boss -> next chapter ... -> run ends
-> earn currency -> unlock new races/talents/classes -> next run

Lives: each character has 3 lives. On death: back to the main menu, restart from the
beginning of that chapter, KEEP level and gear. The third death ends the run and resets
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

## Attack animations (Kha 2026-11-04)

- Full character frames: every class and monster gets its own attack frames, skills get their own effects.
- Hero: 6-frame weapon strips `hero/weapon/<class>_attack.png` and `<class>_skill.png`; body and head shift per frame (POSES in hero_sprite.gd).
- Monsters: `enemies/<sprite>_attack.png` (squash/stretch of idle frame 0) plus a lunge toward the hero.
- Effects: `assets/sprites/fx/` strips. Classes and skills name them in data: "pose", "aura", "projectile", "impact", "shield_fx".
  Status effects (poison, burn, stun) play the strip with the same name when they land.
- Order stays: rules decide, dice show, animation plays, then the log line. Damage numbers rise from the target.
- Settings "Attack animation" switch turns all of it off (motion comfort).
