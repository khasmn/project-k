---
name: add-enemy
description: Add a new monster and its elite version to Project K. Use when the user wants to add, create or design an enemy, monster, elite or boss.
argument-hint: "[enemy name and idea]"
---

Add a new enemy to Project K: $ARGUMENTS

1. Follow the CLAUDE.md git workflow: new branch `feature/enemy-<name>` from an up-to-date `main`.
2. Read `data/enemies.json`. Formats:
   - Normal: `name, hp, attack, defense, speed, weapon, damage_die, exp, gold, rooms: [first, last], elite: "<elite id>"`
   - Elite: same fields without `rooms` and `elite` (only appears in Elite rooms, leading a group).
   - Boss: like an elite plus `guards: [ids]`; `Run.BOSS` picks which one.
3. If the user didn't give enough detail, suggest these and ask before writing:
   - look and idea in one line, and which rooms it lives in (1-8)
   - role: fast (high Speed), tanky (HP/Defense), hard hitter (Attack/die) or swarm (low everything)
   - weapon name, and the elite's name and idea (e.g. Wolf -> Dire Wolf)
4. Numbers: fights have 1-4 monsters, so normal monsters stay small. Compare with existing
   monsters that share its rooms and keep it within about 30% of them. Elites: about 2x HP,
   +1-2 Attack and Defense, one die size up, 2-3x EXP and gold.
5. Before adding, run `tests/test_run.gd` and note the win rates. Add both entries (normal with
   the other normals, elite with the elites), run it again and compare. If any class moves more
   than 5 points, say so and suggest a tweak; ask before changing other enemies.
6. If the idea needs new code (poison, healing, a special attack), say so and ask before writing code.
7. Show it working: find a seed where it shows up and print the fight, e.g.
   `for s in $(seq 1 60); do $G --headless --script res://tests/play.gd -- --seed $s attack 2>&1 | grep -q "<Name>" && echo $s && break; done`
   (it shows up in room 1 only if its rooms include 1; otherwise tell the user which rooms to reach with F5).
8. Commit "Add <name> enemy", save project memory (project-memory skill) and tell the user it's ready to merge.
