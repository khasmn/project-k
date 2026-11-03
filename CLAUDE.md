# Project K

A 2D pixel-art, turn-based roguelike RPG with D&D-style d20 checks.
Inspired by Pixel Lineage (Roblox). Solo hobby project, built to play myself first.

Full design doc: https://claude.ai/artifact/4UKyd7RnGBHQ5ZpMwuFAQo

## Tech

- Engine: Godot 4.7, GDScript only (no C# / .NET)
- Renderer: Compatibility (GL), 2D only
- Platform: PC first (macOS, Windows). iPhone maybe later.
- Controls: mouse only for now. Every action must be clickable; no keyboard-only features.
- Developed on a Mac. Repo: https://github.com/khasmn/project-k

## Core rules of the game (keep code consistent with these)

- Every uncertain action = d20 + modifier vs DC. Nat 20 = crit success, nat 1 = crit fail.
  Advantage = roll 2 keep high, disadvantage = roll 2 keep low.
- All dice go through ONE dice module (`scripts/core/dice.gd`). Never call randi() for game rolls elsewhere.
- Character creation: race + talent are rolled by rarity
  (Common 50%, Uncommon 25%, Rare 15%, Epic 8%, Legendary 2%).
  One free roll each, then 5 rerolls SHARED between race and talent. Class is picked, not rolled.
- Classes: Warrior, Archer, Mage, Brawler. Evolution event at level 15 (choose 1 of 2 paths).
- 3 lives per character. On death: back to main menu, restart current chapter, keep level and gear.
  Third death ends the run.
- Stats: HP, Attack, Magic, Defense, Speed, Charisma, Luck. Energy is the skill resource.

## Code conventions

- Data-driven: races, talents, classes, enemies, items live in `data/*.json`.
  Adding content = adding a JSON entry, not new code.
- Folders: `scenes/` (.tscn), `scripts/` (.gd), `data/` (.json), `assets/` (art, sound).
- snake_case for files, functions, variables. PascalCase for class_name and node names.
- Use static typing in GDScript (`var hp: int = 10`, `func roll(sides: int) -> int`).
- Keep scripts small: one job per script.
- Pixel art: nearest-neighbor filtering, sprites 16x16 or 32x32.

## How I want to work

- I'm a beginner. Explain new Godot concepts briefly in plain words when you introduce them.
- Build in small steps; the game should run after every step.
- After each working feature, make a git commit with a short clear message
  (e.g. "Add dice module"). I push with GitHub Desktop.
- Never commit the `.godot/` folder (already in .gitignore).
- If something can only be checked by running the game, tell me exactly what to click and what I should see.

## Build order

1. Dice module + combat prototype (one hero vs one enemy)
2. Character creation screen (race, talent, class, 5 shared rerolls)
3. A run of 5 fights with level-up choices
4. Chapter map: shop, rest, events, boss
5. Saving, 3 lives, meta-progression unlocks
6. Pixel art, sound, polish
