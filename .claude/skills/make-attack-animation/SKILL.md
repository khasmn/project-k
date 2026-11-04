---
name: make-attack-animation
description: Make attack, skill and effect animations for Project K (hero class poses, monster attack strips, hit effects, projectiles, status effects). Use when the user wants an attack animation, a skill animation, a hit or spell effect, or a new class, monster or skill that needs to animate.
argument-hint: "[what to animate, e.g. Archer skill, Orc attack, ice effect]"
---

Make attack animations for Project K: $ARGUMENTS

## 1. Ask first (only what's missing)

- What it is: a hero class attack or skill, a monster attack, or a new effect (impact, projectile, aura, status).
- The look in a few words (a heavy overhead slam, a green glowing shot, a cold blue burst).

## 2. How animations work in the game

- Rules first, picture second: the action is decided, the dice show, the animation plays, then the log line.
  Animations never change a result. All of it is skipped when Settings "Attack animation" is off.
- **Hero**: `assets/sprites/hero/weapon/<class>_attack.png` and `<class>_skill.png`, 6 frames of 32x32 that
  replace the weapon layer. `POSES` in `scripts/ui/hero_sprite.gd` moves body and head per frame
  (`[body x, body y, head x, head y]`, negative x = toward the monsters) and lists the `hits` frames
  (several hits = a multi-hit skill like Flurry).
- **Monsters**: `assets/sprites/enemies/<name>_attack.png`, same frame size as `<name>_idle.png`, 6 frames.
  `scripts/combat/fight_fx.gd` adds the lunge (`MONSTER_LUNGE`) and lands the hit on `MONSTER_HIT_FRAME`.
- **Effects**: `assets/sprites/fx/<name>.png`. Impacts and auras 32x32 frames, projectiles 16x16 frames
  drawn flying LEFT (the game flips them). A status effect plays the strip with its own name (poison, burn, stun).
- **Data** names the pieces, no code needed:
  - `data/classes.json`: `"projectile"`, `"impact"` for the normal attack.
  - `data/skills.json`: `"pose"` (hero strip), `"aura"` (on the user first), `"projectile"`, `"impact"`,
    `"shield_fx"` (on each ally that gained a shield). Monsters without a skill entry bite or slash by `weapon`.

## 3. Draw it

Generators in this folder (PIL, run from the project root). Copy them to `tests/tmp/` and edit there:
- `hero_attacks.py`: one 6-frame list per strip in `FRAMES`, built from `sword`, `bow`, `staff`, `fists`.
- `monster_attacks.py`: makes every monster's attack strip from its idle frame 0 (squash/stretch + weapon trail;
  biters get none). Rerun it after adding a monster.
- `fx.py`: one function per effect, `strip(name, size, frames, draw)`.

Style rules:
- Same palette and dark outline (`LINE`) as the sprites; nearest-neighbor, no blur.
- See-through smears and glows (alpha below 255) get no outline: keep them on their own layer.
- Hit frame = the most stretched, brightest frame. 1-2 frames of wind-up before it, 2 frames of recovery after.
- Keep it gentle (Kha gets motion sickness): small offsets (max 3 art pixels for the hero), no screen flashes.
- Everything stays inside its frame: check the edges.

## 4. Wire and check

1. Add the data fields (and a `POSES` entry for a new hero strip).
2. `$G --headless --import`, then all checks: `for f in tests/test_*.gd; do $G --headless --script res://$f; done`.
3. Look at it: a slow-motion capture (`Engine.time_scale = 0.2`, screenshots every few frames) of the action,
   put in one sheet and read it. Fix anything clipped or unreadable.
4. Tell Kha exactly what to click to see it, and save project memory.
