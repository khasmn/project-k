---
name: design-class-evolution
description: Research and design class evolutions for Project K, from the level 15 evolution to secret classes that need a special event and a trial fight (e.g. Warrior -> Knight -> Holy Knight, Mage -> Dark Mage -> Necromancer). Use when the user wants a new class, an evolution path, a hidden or secret class, a job change or a class tree.
argument-hint: "[class or idea, e.g. warrior holy knight]"
---

Design a class evolution path for Project K: $ARGUMENTS

Games and anime below are inspiration for patterns only. Never copy a specific class tree, class
name that belongs to one game, character, quest or story; take the idea and make an original version
that fits Project K's world.

## 1. Read what exists

- `docs/memory/design.md`: the Classes section (base classes, the level 15 evolution, "Evolves into"),
  the core rules, chapters and the event door.
- `data/classes.json`, `data/skills.json` (skill format and power level), `data/enemies.json`
  (elites and bosses, for the trial fight), `data/rooms.json` (event door texts).
- `docs/memory/decisions.md`: earlier class decisions. Never change an agreed path without asking.

## 2. Research (WebSearch, several searches in one turn)

Look for how fantasy RPGs and anime handle class change and secret classes, e.g.:
- Games: Fire Emblem promotions, Final Fantasy jobs, Dragon Quest vocations, Ragnarok Online and
  MapleStory job advancement quests, D&D prestige classes (entry requirements), Octopath Traveler
  secret jobs, Diablo / Path of Exile ascendancies, Tactics Ogre class unlocks.
- Anime and light novels: job change trials (Solo Leveling), evolutions by deeds (Tensura, Overlord),
  hidden classes earned by choices (Shield Hero, Log Horizon subclasses).

Collect patterns, not content: the kind of requirement (level, item, choice, deed, place, trial),
how the class fantasy is earned, what makes a secret class feel special. 3-6 bullets, with sources.

## 3. Design the path

Three tiers. Each step must be something the player does in the game:

1. **Base class** (picked at creation).
2. **Advanced class** (level 15 evolution event, choose 1 of 2). Use the design table if it already
   names one; if the user's idea needs a new tier 2 (e.g. Dark Mage), propose the change and ask.
3. **Secret class** (optional, rare). Requirements, all checkable in code:
   - the tier 2 class,
   - a **special event**: a rare event-door scene with a choice and a d20 check (stat vs DC),
     e.g. "a dying paladin offers you his oath" (Charisma DC 14),
   - a **trial**: one fight against a named mini-boss (elite size, 48x48), e.g. a demon,
     with its own skill and loot,
   - sometimes a condition (a kept item, a choice made earlier, an animal companion).
   Win the trial: the class changes, with a short scene line. Fail the check or lose: the chance is
   gone this run (it can show up again in a later run).

For every class give: name (original), one-line fantasy, main stat boost (+2 or +3), 2 skills in the
`data/skills.json` format (reuse existing keys: attacks, to_hit, extra_die, advantage, shield, save,
area, effect; flag any NEW key as needing code), and its look (one sentence for the sprite).
For the trial mini-boss give stats in the `data/enemies.json` format and its skill.

## 4. Check it fits

- Every check is d20 + modifier vs DC through the dice module; DCs 10-16.
- Power: a tier 2 skill is about 1.5x a base skill; a secret class skill about 2x, with a cost or a
  cooldown that matches. Compare with the existing skills and say where it may be too strong.
- Data-driven: list the JSON entries needed (classes, skills, enemies, events) and any new code.
- Mouse-only; animations slow, with the Settings switches.
- Art needed: hero poses (class skill, see `make-attack-animation`), the mini-boss sprite, effects.

## 5. Show the user and ask

Show one compact tree per base class, then a table per class (name, requirement, stats, skills).
Ask (AskUserQuestion) what to keep, change or drop: names, tier 2 choices, the event, the trial boss,
numbers. Nothing is built or written into data files until the user says OK.

## 6. Save the plan

After the OK:
- Update the Classes section in `docs/memory/design.md` (the tree, requirements, events, trials).
- Add a row to `docs/memory/decisions.md`.
- Propose the build order in small steps (e.g. 1. the level 15 evolution event, 2. one secret event
  and its trial, 3. class change and skills, 4. art), and ask which to build first. Each build step
  follows the CLAUDE.md git workflow on its own `feature/` branch.
