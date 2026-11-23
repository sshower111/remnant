# Remnant logo

**The idea:** a saved bookmark with a bite taken out of it. You save cooking reels; Remnant is about
cooking with what's left. The crumbs are the only colour.

Chosen on 2026-11-23 from three rounds of concepts (`../r3/`, `../c/`). It replaces the cream bowl with a
sprig on terracotta, which read as a potted plant.

## Files

| File | Use |
|---|---|
| `remnant-mark-color.svg` | The mark on light backgrounds (charcoal, ember crumbs) |
| `remnant-mark-reversed.svg` | The mark on dark backgrounds (warm white, ember crumbs) |
| `remnant-mark-black.svg` | One colour: print, stamps, embossing, the system's tinted icon |
| `remnant-mark-small-black.svg` | **32 px and below**: wider, deeper bite, one crumb |
| `remnant-horizontal-*.svg` | Mark + name side by side (color, reversed, black). **Local only** (see below) |
| `remnant-stacked-*.svg` | Mark above the name (color, reversed, black). **Local only** |
| `app-icon-light/dark/tinted.svg` | Sources of the iPhone app's icon (also in `ios/Art/app-icon/`) |
| `export/` | Favicons, `favicon.ico`, web icons, `site.webmanifest`, mono and white variants |
| `make.py` | Regenerates every SVG above and the app-icon sources |

The name is New York Bold (Apple's system serif, the app's title font), outlined to paths in
`wordmark.path` so the lockups need no font. Apple's fonts are licensed for use with Apple platforms,
so the outlines and the lockups are gitignored and stay on the Mac. To rebuild them, outline "Remnant"
from `/System/Library/Fonts/NewYork.ttf` at weight 700 with fontTools (`SVGPathPen`, 150 px, tracking
-1.5) into `wordmark.path`, then run `make.py`. Check the licence before using a lockup outside the app.

## Colours

| | Hex | Use |
|---|---|---|
| Charcoal | `#1C1916` | Icon tile, the mark on light |
| Deep charcoal | `#12100E` | Dark-mode icon tile (the app's canvas) |
| Warm white | `#F4EFE9` | The mark on dark (the app's text colour) |
| Ember | `#E8875F` | Crumbs only (the app's accent) |

## Rules

- **Clear space:** at least the bite's radius (a sixth of the bookmark's width) on every side.
- **Minimum size:** 33 px tall for the main mark; below that use `remnant-mark-small-black.svg`.
  The lockup's name needs at least 14 px cap height.
- **Crumbs stay ember** (or the same colour as the mark in one-colour use). Never colour the bookmark ember.
- **Don't** add a bowl, food, a wok or tossed food to the mark, outline it, rotate it, add shadows or
  gradients, or fill the bite.
- **App icon:** the full square tile; iOS rounds the corners. Regenerate the PNGs with
  `python3 design/logo/final/make.py`, then render each `ios/Art/app-icon/*.svg` to 1024 px RGB (no alpha)
  as `ios/Cookbook/Assets.xcassets/AppIcon.appiconset/AppIcon-{light,dark,tinted}.png`.
- **In the app:** `ios/Cookbook/Design/RemnantMark.swift` draws the mark with the same geometry
  (used by the splash screen's wordmark).

Trademark: no search was done. Run a proper search before registering or relying on it commercially.
