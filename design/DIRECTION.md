# Remnant design direction

**Cook with what's left.** A warm, dark kitchen at night: the food photos bring the color, the interface
stays quiet, and one ember-orange accent marks the thing to do next.

## From Creme, and what's Remnant's own

| Taken from Creme (the spirit) | Remnant's own |
|---|---|
| Dark near-black canvas as the hero; photos carry the color | Warm near-black (`#12100E`, a hint of brown, not blue-black), and a real light mode in cream |
| One warm accent on a pill for the main action | **Ember** (terracotta from the app icon) instead of butter yellow |
| Recipe detail: full-bleed photo, big title over it, creator beneath, a row of pills | Title in **New York** (serif) bold, not a sans; pills carry SF Symbols and say what they do ("Start cooking", "Watch", "Shopping list") |
| Labeled metadata columns (small grey label above, white value below) | Columns show what the reels actually give us: Ingredients, Steps, Makes, From |
| Cook mode: vertical steps, the current one lifted on a lighter block, the rest dimmed, quick pills at the bottom | The pixel chef for empty, loading and finished states; "Resume · Step 4" when you come back to a recipe |
| Minimal chrome, few borders, no heavy shadows | The "What can I make?" ingredient chips, the app's own first job, sit above the library |

Not taken: Creme's wordmark, logo, yellow, screen layouts, floating video window (Remnant's videos live
in Instagram, so ▶ opens the post there and the Live Activity follows along).

## Color (asset catalog `Shared/Remnant.xcassets`, light / dark)

| Token | Light | Dark | Use |
|---|---|---|---|
| `canvas` | `#FAF7F2` | `#12100E` | Screen background |
| `surface` | `#F1ECE5` | `#1D1A17` | Chips, secondary pills, tiles |
| `surfaceRaised` | `#FFFFFF` | `#2A2521` | The current cook step, sheets' rows |
| `textPrimary` | `#1F1A16` | `#F4EFE9` | Titles, body |
| `textSecondary` | `#6B625A` | `#A69D94` | Labels, meta (≥ 4.5:1 on canvas and surface) |
| `hairline` | `#E3DCD3` | `#2F2A26` | The few dividers left |
| `ember` | `#A84B2A` | `#E8875F` | The accent: primary pill, selection, favorites |
| `onEmber` | `#FFFFFF` | `#1A0F0A` | Text on ember (5.7:1 light, 7.2:1 dark) |
| `emberSoft` | `#F6E2D8` | `#3A251C` | Selected chip fill, "you have" match |

Text over photos sits on a black scrim (transparent → 75 %), always white: ≥ 4.5:1 on any photo.

## Type (Dynamic Type styles, so everything scales to the accessibility sizes)

| Role | Style |
|---|---|
| Wordmark, recipe title | `.largeTitle`, New York, bold |
| Section title, cook step (current) | `.title2` / `.title3`, New York for sections, SF for steps |
| Card title | `.headline` |
| Body, steps | `.body` / `.title3` in cook mode |
| Meta, labels | `.subheadline`, `.footnote`; column labels `.caption` |

Serif only for titles; every control and every number is SF Pro. Numbers use `monospacedDigit()`.

## Spacing and radii

- **Spacing (4-pt):** `xxs 4 · xs 8 · s 12 · m 16 · l 24 · xl 32`. Screen margin 16.
- **Radii:** `small 10` (thumbnails, ingredient tiles), `medium 16` (photos, the current step),
  `capsule` (pills, chips). Nothing else.
- **Touch targets:** 44 pt minimum everywhere, including chips and the heart on photos.

## Iconography

SF Symbols only, `.medium` weight, sized by text style: `heart`, `checkmark.circle`, `bookmark`,
`frying.pan`, `play.rectangle`, `list.bullet`, `timer`, `plus`, `magnifyingglass`. No emoji in the UI.
The black-and-white ingredient icons and the pixel chef stay; they're the app's own.

## Motion

Only to explain a change: the current cook step glides to the next (`.snappy`, 0.3 s); sheets and pushes are
the system's. Filters switch with no animation (they stuttered on the phone). Reduce Motion: everything
cross-fades, the chef stands still. Haptics confirm an action: favorite, cooked, step done, timer up.
