---
name: make-cutscene
description: Make a pixel-art story cutscene for Project K (prologue, chapter endings, twist scenes) - storyboard, frame-by-frame scenes drawn with Pillow, text, and the cutscene player. Use when the user wants a cutscene, story scene, intro, prologue, ending, reveal or animated story moment.
argument-hint: "[which cutscene, e.g. prologue, chapter 1 ending, the ch 5 twist]"
---

Make a cutscene for Project K: $ARGUMENTS

Games and films may inspire the staging, but every scene, character and line is original.

## 1. Storyboard first, then ask

Read the Story section of `docs/memory/design.md` (characters, chapter beats, twists) so the scene fits
and never gives a twist away early (a hint is fine; the reveal belongs to its chapter).
Write a short storyboard: one line per scene with
- what we see (place, who, the one thing that moves),
- the text under it (1-2 short sentences, plain words; a character's line in quotes),
- why it's there (setup, foreshadowing, payoff).
2-5 scenes, about 10-15 seconds each. Show it and ask (AskUserQuestion) before drawing.

## 2. How cutscenes work in the game

- `data/cutscenes.json`: `{"<id>": [scene, ...]}`. A scene: `"art"` (strip of 384-wide frames in
  `assets/cutscenes/`), `"fps"` (1-3), `"text"`, optional `"hero": [x, y]` (draws the player's hero sprite there,
  in their chosen look, 3x pixel size, as on the battle screen).
- `Cutscene.play(id, next_scene)` (`scripts/story/cutscene.gd`): full screen, the text types in under the
  picture, a click shows the whole text or goes to the next scene, a **Skip** button ends it. Mouse only.
- Settings "Animated background" off: every scene stays on frame 1.

## 3. Draw it

- Size: 384x216 frames (shown 3x = 1152x648), a horizontal strip of N frames, PNG, opaque.
- Pillow script in the scratchpad (one function per scene, `frame(f)` draws frame f). Draw shapes, not noise.
- Same look as the game: dark outline, ramps of 3-5 shades, nearest-neighbor, at most ~32 colors a scene.
- Characters are drawn at the game's sprite scale (about 32 px tall at the front) so they match the battles.
  Faces stay simple; show feeling with pose, light and color.
- Keep the bottom ~40 px calm and dark: the text box sits there.
- **Comfort (Kha gets motion sickness):** slow loops (1-3 FPS, 6-12 frames), small movements (1-2 px), no
  camera shake, no flashes, no fast pans. Things that move: fire flicker, smoke, dust motes, candle light,
  a cape or banner in the wind, rain, stars, a slow glow.
- Loop cleanly: the last frame leads back into the first.
- Render a 3x preview sheet of all frames and look at it; fix and re-render, at most 3 rounds.

## 4. Wire and check

1. Follow the CLAUDE.md git workflow (`feature/cutscene-<id>`).
2. Save strips to `assets/cutscenes/<scene>.png`; add the entry to `data/cutscenes.json`; call
   `Cutscene.play()` where the story needs it (once a run where it should not repeat, e.g. `Run.chapters_won`;
   a chapter ending is its `"outro_cutscene"` in `data/chapters.json`).
3. Import (`$G --headless --import`), run all checks, take a screenshot of each scene in the game.
4. Tell Kha exactly what to click to see it, and give 2-3 Pixelorama touch-ups to try.
5. Commit "Add <id> cutscene" and save project memory.
