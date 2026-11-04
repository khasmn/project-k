---
name: review-panel
description: A panel of 4 reviewers judges Project K work and proposes adjustments - a film director (twists, dark fantasy), an RPG game director, an RPG gamer influencer, and a novel reader who loves shock twists. Use when the user wants the story, a chapter, a twist, a class plan, an event, a feature or a design judged, reviewed, critiqued or improved.
argument-hint: "[what to review, e.g. the 10-chapter story]"
---

Review panel for Project K: $ARGUMENTS

The panel only judges and suggests. Nothing changes in the game or the design until the user picks
which adjustments to keep. Games, films, anime and novels may be named as comparisons, but every
suggested fix must be original (never copy a specific story, character, twist or class tree).

## 1. Write the brief

Find the work being reviewed (the matching section of `docs/memory/design.md`, data files, event
texts, or the current branch's diff) and write `tests/tmp/panel/brief.md` (git-ignored):
- what is being reviewed, in full (copy the text or tables),
- the context a reviewer needs: Project K is a 2D pixel-art, turn-based d20 roguelike RPG; a run goes
  through chapters of 8 rooms and a boss; 3 lives; a solo beginner builds it in Godot,
- what's already decided and shouldn't be reopened (top rows of `docs/memory/decisions.md`),
- the question for the panel (e.g. "Do the twists land? Is the pacing right?").

## 2. Spawn the 4 reviewers in parallel (Agent tool, one message)

Give each the brief path, its persona below, and these shared rules:
- Read only; never edit files. Keep the review under 450 words.
- Answer in this shape:
  **Score:** x/10 and one line why.
  **Works:** the 3 strongest things.
  **Problems:** the 3 biggest problems, each pointing at the exact part (chapter, line, rule).
  **Adjust:** 3-5 concrete changes (what to write, add, move or cut), each one small enough to build.
  **Must change:** the one thing that would hurt most if left as it is.

Personas:
- **Film director** (twist-driven dark fantasy): story structure and pacing, setup and payoff,
  whether each twist is fair (foreshadowed but not obvious) and changes what came before, the
  villain's motive, the emotional beats, and the "second viewing" test: do earlier scenes mean
  something new after the twist? Suggest small foreshadowing beats the game can show (an event
  line, a boss's last words, a background detail).
- **RPG game director**: how the story and features are delivered through play (events, bosses,
  towns, rewards), progression and difficulty curve across chapters, player choice and agency,
  replay value in a roguelike, balance risks, and scope for a solo beginner (cut or simplify what
  costs too much for what it gives). Point at data-driven ways to build it.
- **RPG gamer influencer** (plays and reviews RPGs for an audience): the hook in the first 30
  minutes, the moments viewers would clip or talk about, build and secret-class hype, what feels
  grindy, padded or generic, how it compares with the genre's best known moves. Add a one-line
  review headline and who would love or skip this game.
- **Novel reader who loves shock twists** (not a gamer): did the twists surprise them, or were they
  guessed early (say when), did they feel cheated or amazed, do they care about the characters
  (the King, the Demon King, the companions), and would they keep going to the next chapter.
  Plain words, a reader's gut feeling.

## 3. Combine the reviews

Rerun nothing; read the 4 reviews and write one summary for the user:
1. **Scores**: the 4 scores and the average.
2. **Agreed**: problems 2 or more reviewers raised (strongest signal first).
3. **Split**: where they disagree, both sides in one line each.
4. **Adjusted version**: the reviewed work rewritten with the best adjustments applied, every change
   marked with who asked for it (e.g. "[Director, Reader]"). Keep what already works untouched.
5. **Left out**: adjustments not used and why (too costly, breaks a decided rule, one-off taste).

## 4. Ask, then apply

Ask the user (AskUserQuestion, multiSelect) which adjustments to keep. Then:
- design or story changes: update `docs/memory/design.md` and add a row to `docs/memory/decisions.md`
  (the `project-memory` skill, save),
- game changes (data, code, art): follow the CLAUDE.md git workflow on a new branch, in small steps.
Offer one more panel round on the adjusted version only if the user asks. Delete `tests/tmp/panel/`
at the end.
