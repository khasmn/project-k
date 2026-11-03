---
name: add-race
description: Add a new playable race to Project K. Use when the user wants to add, create or design a new race.
argument-hint: "[race name and idea]"
---

Add a new race to Project K: $ARGUMENTS

1. Read `data/races.json` to see the existing races and their format.
2. If the user didn't give enough detail, suggest these and ask before writing:
   - rarity (Common, Uncommon, Rare, Epic or Legendary)
   - role in one word (e.g. Tank, Agile, Magic)
   - stat changes (small numbers, e.g. +2 / -1)
   - one passive ability
   - one +2 check bonus (e.g. talk, sneak, magic)
3. Balance check: rarer races get stronger passives. Compare with a race of the
   same rarity and say if the new one looks too strong or too weak.
4. Add the entry to `data/races.json`, keeping the same format and sorting by rarity.
5. If the passive needs new code (a new effect type), say so and ask before writing code.
6. Tell me how to test it in Godot, then commit with the message "Add <race> race".
