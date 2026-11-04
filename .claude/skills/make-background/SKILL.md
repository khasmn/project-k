---
name: make-background
description: Draw a pixel-art battle background for Project K in a JRPG style (Final Fantasy, Dragon Quest, Xenoblade Chronicles, Fear & Hunger as inspiration). Use when the user wants a background, battle scene, location, chapter backdrop or scenery.
argument-hint: "[place and mood, e.g. dark forest]"
---

Make a battle background for Project K: $ARGUMENTS

The games below are style inspiration only. Never recreate a specific scene, layout, landmark,
character or asset from them; take the principles and make an original place.

## 1. Ask first (only what's missing)

- Place and chapter (e.g. chapter 1, woods).
- Mood, pick one (or a mix):
  - **Classic bright** (Dragon Quest, SNES Final Fantasy): clear sky, friendly saturated colors, simple shapes.
  - **Epic vast** (Xenoblade Chronicles): huge distant landmarks, strong depth, soft haze.
  - **Grim** (Fear & Hunger): dark, desaturated, heavy shadows, one sickly accent color, sparse light.
- Time of day and one landmark (a ruined shrine, a giant tree, a river).

## 2. Style rules

- **Bands, back to front** (SNES Final Fantasy battle backs): sky, far silhouettes, mid layer with
  most of the detail, near framing pieces at the edges, and a flat ground band.
- **Ground band**: the bottom ~35% is where sprites stand. Keep it low-detail and even in value
  so 32x32 sprites stay readable. Keep the bottom center clear.
- **Depth** (Xenoblade): each layer further back is lighter, bluer or hazier, with less contrast.
  One big far shape gives scale.
- **Clarity** (Dragon Quest): few, clean shapes; no noise. Every cluster of pixels should read as something.
- **Mood** (Fear & Hunger for grim): darker edges (vignette), limited light, colors pulled toward one hue.
- The background is always a bit darker and less saturated than the sprites, so fighters pop.

## 3. Technical rules

- 384x128 pixels (shown 3x in the battle area), PNG, fully opaque.
- At most 24 colors, ramps of 3-5 shades per material; hard pixels only, no anti-aliasing.
- Dithering only on large gradients (sky, haze), in 2x2 checker patterns.

## 4. Make it

1. Follow the CLAUDE.md git workflow (`feature/background-<name>` from an up-to-date `main`).
2. Write a Pillow script in the scratchpad that draws the bands as shapes (not noise), render it,
   and view it at 3x. Check it against sections 2-3; fix and re-render, at most 3 rounds.
3. Save to `assets/backgrounds/<name>.png`. The script stays in the scratchpad; the PNG is the source
   from now on, so the user can refine it in Pixelorama.
4. Show the battle screen with it behind the fighters (screenshot). If the game has no way to show
   this background yet, say what code is needed and ask before writing it.
5. Give the user 3 concrete Pixelorama touch-ups (e.g. "add moss to the left rocks with the darkest green").
6. Commit "Add <name> background", save project memory, and tell the user it's ready to merge.
