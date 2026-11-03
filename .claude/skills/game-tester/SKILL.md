---
name: game-tester
description: Test Project K for bugs with two agents, a regular gamer and a dev tester. Use when the user says "test the game", "find bugs", "playtest", or wants a feature checked before merging.
argument-hint: "[what to test, e.g. combat; empty = everything playable]"
---

Test Project K: $ARGUMENTS (empty = everything playable right now)

Godot: `G=/Applications/Godot.app/Contents/MacOS/Godot`, run from the project folder.

## 1. Quick checks first

Run every self-check: `for f in tests/test_*.gd; do $G --headless --script res://$f; done`
If one fails, report that and stop. The agents can't test a broken build.

## 2. Spawn both agents in parallel (Agent tool, one message)

Give each the target, today's branch, and its prompt below.
Both: never edit game files (scripts/, scenes/, data/). Temporary scripts go in `tests/tmp/<agent>/`
(git-ignored, e.g. `tests/tmp/tester/`); each agent deletes only its own folder at the end.
While they run, you (the main session) use `tests/tmp/main/` for your own checks.
Every bug needs a repro command.

Play tool (both agents):
`$G --headless --script res://tests/play.gd -- [--seed N] [--race R] [--talent T] [--class C] [--force 20,1,...] actions...`
- Fight actions: `attack`, `defend`, `1` ("Continue" or "New hero"). Path screen: `1`/`2`/`3` (door, or Rest/Train),
  `character`, `+hp`/`+attack`/`+defense`/`+speed` (`-stat` undoes), `confirm`, `close`.
- Without `--race`/`--talent` the hero is rolled; class defaults to warrior. Ids are in `data/*.json`.
- It plays a whole run from fight 1 and prints the log, the state and what you can click next.
  Same seed + same options + same actions = same run, so play turn by turn: add one action per rerun.

### Gamer prompt

You're a regular player trying Project K, a turn-based d20 roguelike. Don't read the code;
play it like a player would, with the play tool. Play at least 4 full runs (to death or the end)
with different seeds, classes and styles (all attack, lots of defend, mixed; different upgrade picks).
Report, in plain words:
- anything confusing (unclear log lines, numbers or choices you couldn't follow)
- anything unfair or boring (too easy or hard, choices that never matter, a class that feels bad)
- anything that looked like a bug, with the exact command to replay it
- what was fun

### Dev tester prompt

You're a QA tester with dev tools. Read `docs/memory/design.md` (the rules), the "Current status"
in `docs/memory/progress.md` (what's built and what isn't yet, so you don't report planned features
as missing), the top rows of `docs/memory/decisions.md` (latest rule changes), and the code being
tested. Hunt for bugs where the code breaks the rules, crashes or gets stuck. Tools:
- Self-checks: `tests/test_*.gd`
- Play tool (above). `--force` sets the next dice in roll order, after the hero is rolled.
  In rooms 1-8 the first die picks the enemy (d2 or d3); then initiative: the hero's d20 (two with
  advantage), then the enemy's d20. The boss room starts with initiative.
- Your own probe scripts in `tests/tmp/tester/` (copy the style of `tests/test_run.gd`):
  set `Dice.rng.seed` and `Dice.forced_rolls`, build `Combatant`s and change stats directly,
  set `Run` state, or instantiate a scene (await `process_frame` first) and emit button signals.
Always test edge cases: nat 1, nat 20, exactly meeting Armor, 0 HP, ties, the enemy going first,
Defend timing, every passive, level-up choices, the last fight, dying in each fight, starting a
second run, clicks while it's not your turn, and play-tool argument errors.
Run every repro twice to confirm it before reporting. Report each bug as: what's wrong,
which rule it breaks, file:line, repro command. Also list what you tested that passed.

## 3. Report to Kha

1. Rerun each reported repro yourself. Drop anything you can't reproduce.
2. Write one combined list, most serious first:
   - **Bugs:** breaks a rule, crashes or gets stuck (repro + file:line)
   - **Feel and balance:** the gamer's notes and any tester notes about numbers
   - **What works:** one or two lines
3. Fix nothing. Ask Kha which items to fix. Each fix gets its own `fix/<name>` branch,
   and balance or design changes follow the ask-first rule.
4. Delete `tests/tmp/` if anything is left in it.
