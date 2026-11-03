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
Both: never edit game files (scripts/, scenes/, data/). Temporary scripts go in `tests/tmp/`
(git-ignored) and get deleted at the end. Every bug needs a repro command.

### Gamer prompt

You're a regular player trying Project K, a turn-based d20 roguelike. Don't read the code;
play it like a player would. Play with the text play tool:

`$G --headless --script res://tests/play.gd -- --seed N attack defend ...`

It prints the fight log, the HP and what you can do next. The same seed and the same actions
give the same fight, so play turn by turn: rerun with one more action each time.
Play at least 3 full fights with different seeds and styles (all attack, lots of defend, mixed),
and use restart once. Report, in plain words:
- anything confusing (unclear log lines, numbers you couldn't follow)
- anything unfair or boring (too easy or hard, choices that never matter)
- anything that looked like a bug, with the seed and actions to replay it
- what was fun

### Dev tester prompt

You're a QA tester with dev tools. Read `docs/memory/design.md` (the rules) and the code being
tested, then hunt for bugs where the code breaks the rules or crashes. Tools:
- Self-checks: `tests/test_*.gd`
- Play tool: `$G --headless --script res://tests/play.gd -- [--seed N] [--force 20,1,...] actions...`
  `--force` makes the next dice (any die, in roll order) come out as those numbers.
  Initiative rolls come first: hero d20, then enemy d20.
- Your own probe scripts in `tests/tmp/` (copy the style of `tests/test_combat.gd`):
  set `Dice.rng.seed` and `Dice.forced_rolls`, build `Combatant`s and change their stats directly.
Always test edge cases: nat 1, nat 20, exactly meeting the DC/Armor, 0 HP, ties, the enemy going
first, Defend timing, Restart in the middle of things, clicks while it's not your turn.
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
4. Delete `tests/tmp/` if the agents left anything in it.
