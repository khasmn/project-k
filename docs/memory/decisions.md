# Project K – Decisions

Every important decision, newest first, with a short "why". Never delete old entries;
if a decision changes, add a new entry that says what it replaces.

| Date | Decision | Why |
| --- | --- | --- |
| 2026-11-03 | Armor = 10 + Defense; Defend gives +2 Armor until your next turn | D&D-style, simple; easy to change |
| 2026-11-03 | Crit (nat 20) doubles total damage; damage = weapon die + Attack | Matches design "double damage" |
| 2026-11-03 | Combat prototype: Attack + Defend only, stats from JSON, Restart button | Small but a real choice; data-driven from the start |
| 2026-11-03 | Game-tester skill (gamer + dev tester agents) waits until combat prototype runs | Nothing to test yet |
| 2026-11-03 | Dice is a static `class_name Dice` script, not an autoload | Simplest; callable anywhere |
| 2026-11-03 | Nat 20 always succeeds, nat 1 always fails, for every check | Every roll keeps hope and risk |
| 2026-11-03 | Claude merges PRs with gh when Kha says merge (replaces "Kha merges PRs") | Faster workflow |
| 2026-11-03 | Claude asks when unclear and asks before building its own ideas | Kha stays in control |
| 2026-11-03 | Project memory lives in docs/memory/ (design, progress, decisions) | New chats and Claude Code can pick up where we left off |
| 2026-11-03 | Every feature/fix/update on its own branch; Kha merges PRs into main | Keep main stable and reviewable |
| 2026-11-03 | Working title "Project K" | No name yet |
| 2026-11-03 | Death: back to main menu, restart chapter, keep level and gear | Forgiving but still has stakes |
| 2026-11-03 | 3 lives per character; third death ends the run | Gives runs tension without instant loss |
| 2026-11-03 | Class evolution event at level 15 (choose 1 of 2 paths) | Mid-run power spike and choice |
| 2026-11-03 | Classes: Warrior, Archer, Mage, Brawler | Clear, distinct starting roles |
| 2026-11-03 | Added common races Elf, Orc, Dwarf, Undead; keep current race names | More familiar fantasy options |
| 2026-11-03 | 5 rerolls shared between race and talent | Adds a strategic choice |
| 2026-11-03 | Races and talents rolled by rarity (50/25/15/8/2%) | Pixel Lineage-style excitement |
| 2026-11-03 | Mouse-only controls first | Simplest for a turn-based PC game |
| 2026-11-03 | PC first (macOS + Windows), iPhone later | Develop and test on the Mac directly |
| 2026-11-03 | D&D-style d20 checks for combat, talk, exploration | Tension and meaningful race/talent bonuses |
| 2026-11-03 | Godot 4 with GDScript (not Unity, not C#) | Lightweight, strong 2D, beginner-friendly |
