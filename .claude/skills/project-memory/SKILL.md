---
name: project-memory
description: Load or save Project K's memory in docs/memory/. Use at the start of every new chat ("where were we", "what's next", "continue") to recall, and whenever a decision is made, a feature is finished, or the user says "remember this", "save progress" or "update memory".
argument-hint: "recall | save [what to remember]"
---

Project K's long-term memory lives in `docs/memory/`:
- `progress.md` – current status, next step, open questions, session log (newest first)
- `decisions.md` – every important decision with date and why (newest first)
- `design.md` – the full game design (source of truth)

Mode: $ARGUMENTS (if empty: recall at the start of a chat, save otherwise)

## recall

1. Read `docs/memory/progress.md` and `docs/memory/decisions.md`. Read `design.md` only
   for the sections the current task needs.
2. Check the real state: `git status`, `git branch -vv`, `git log --oneline -5`.
   If git and progress.md disagree, trust git and point out the difference.
3. Tell the user in 3-5 lines: where we are, the next step, any open questions.
   Then ask if they want to continue with the next step.

## save

1. Collect what changed in this session: features built, decisions made, design changes,
   problems found, the user's preferences. Include whatever the user asked to remember.
2. Update the files (edit in place, don't rewrite unrelated parts):
   - `progress.md`: replace "Current status", "Next step" and "Open questions";
     add one dated entry at the TOP of the session log (3-6 bullets, facts only).
   - `decisions.md`: add a row at the TOP for each new decision (date, decision, why).
     If it replaces an old decision, say so in the new row; never delete old rows.
   - `design.md`: update the affected section if the game design changed.
   - `CLAUDE.md`: only if a permanent rule or convention changed.
3. Use today's date (YYYY-MM-DD). Keep entries short and concrete.
4. Commit on the current branch with the message "Update project memory".
   If on `main`, create `setup/memory-<date>` first (never commit to main).
5. Tell the user in one or two lines what was saved.
