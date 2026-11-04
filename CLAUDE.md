# Project K

A 2D pixel-art, turn-based roguelike RPG with D&D-style d20 checks.
Inspired by Pixel Lineage (Roblox). Solo hobby project, built to play myself first.

## Project memory (read first)

- At the start of EVERY new session, use the `project-memory` skill (recall): read
  `docs/memory/progress.md` and `docs/memory/decisions.md`, check git, then tell me
  where we are and what's next.
- Full game design: `docs/memory/design.md` (source of truth).
- Whenever we make a decision, finish a feature or change the design, update the memory
  (`project-memory` skill, save) before the session ends.

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
  One free roll each, then 5 rerolls for race and 5 for talent (separate). Class is picked, not rolled.
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
- Shortest code that works: reuse existing helpers, no duplicate code.
- Delete unused code (functions, variables, constants, data fields, files) instead of keeping it "for later".
- Comments only where they add something the code doesn't say (a game rule, a Godot concept, a why).
  No comments that just repeat the code.
- No emoji in code, comments, data or commit messages.
- Pixel art: nearest-neighbor filtering, sprites 16x16 or 32x32; elites 48x48, chapter bosses 64x64.

## How I want to work

- I'm a beginner. Explain new Godot concepts briefly in plain words when you introduce them.
- Build in small steps; the game should run after every step.
- Never commit the `.godot/` folder (already in .gitignore).
- If something can only be checked by running the game, tell me exactly what to click and what I should see.
- Ask, don't assume: if my instruction is unclear or you have a question, ask me before doing anything.
- Ideas need my OK: if you have an idea or suggestion (a feature, a design change, extra code
  I didn't ask for), describe it and ask if I want it. Only build it after I say yes.

## Git workflow (always follow)

- NEVER commit directly to `main`. `main` only gets work that is tested and merged.
- Every new feature, fix or update gets its own branch, created from an up-to-date `main`:
  - `feature/<name>` for new things (e.g. `feature/dice-module`)
  - `fix/<name>` for bug fixes (e.g. `fix/reroll-counter`)
  - `update/<name>` for changes to existing things (e.g. `update/race-balance`)
  - `setup/<name>` for project setup, docs, tooling
  Names: lowercase, words joined with `-`.
- Before starting, check which branch we're on. If it's `main`, create the new branch first.
  If uncommitted changes exist, ask me what to do with them.
- Commit on the branch in small steps with short clear messages (e.g. "Add dice module").
- When the feature works, tell me it's ready. When I say to merge, you do it with the `gh` CLI:
  push the branch, open a pull request, merge it into `main`, then switch to `main` and pull.
- Don't merge into `main`, push, or delete branches unless I ask.

## Build order

1. Dice module + combat prototype (one hero vs one enemy)
2. Character creation screen (race, talent, class, 5 rerolls each)
3. A run of 5 fights with level-up choices
4. Chapter map: shop, rest, events, boss
5. Saving, 3 lives, meta-progression unlocks
6. Pixel art, sound, polish
