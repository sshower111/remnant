# Remnant UI review (before the redesign)

Screens checked in code (`ios/Cookbook/Views/`) and on the iPhone 17 Pro Simulator (iOS 27.2) against the
real library on the PC (91 recipes). Screenshots are in `design/before/`.

Skills: `design-critique` was run for the framework below. `swiftui-review`, `ui-review`, `ui-compare`,
`swiftui-screens`, `swiftui-flows` and `ui-polish` aren't installed here, so their checks were done by hand
(SwiftUI code read-through, comparison with Creme, Mela, Crouton and NYT Cooking from memory).

Judged against the four jobs, in order: **1. What can I make? 2. Browse for ideas. 3. Add reels.
4. Cook from a recipe.**

## First impression

A calm, warm, readable app with real personality (the serif wordmark, the pixel chef, ingredient icons).
But it reads as a list of bordered cards on cream, the food photos are small, the job that matters most
("what can I make with what I have?") is hidden inside a search box, and cooking mode is broken on iOS 27.

## Ranked problems

| # | Problem | Job | Severity | Where |
|---|---------|-----|----------|-------|
| 1 | **Cooking steps don't render.** On iOS 27 the step pager (`StepCard`'s horizontal `ScrollView` with `.fixedSize` + `maxHeight: .infinity`) collapses to zero height, and the progress bar and step list below it disappear with it; only "Done, next step" is left (`before/06`, `07`). You can't cook from the app. | 4 | Critical | `StepCard.swift`, `CookingModeView.swift` |
| 2 | **The keyboard covers the search box and the ingredient suggestions.** The bottom bar is a `safeAreaInset` on a `List`; on iOS 27 it isn't lifted, so you type blind and never see the "Add egg" chips (`before/02`). The pantry search, job 1, is unusable. | 1 | Critical | `CookbookView.bottomBar` |
| 3 | **"What can I make?" is invisible.** One placeholder ("Search recipes or add what you have") carries two different features. Nothing on the feed says you can add ingredients you have, and the "You have" chips only appear after you discover it. No "you have 3 of 5" until chips are picked. | 1 | High | Feed |
| 4 | **No dark mode.** Every color is a hard-coded light hex (`Theme.swift`); the app ignores the system appearance (`before/09`). | all | High | `Theme.swift` |
| 5 | **Food photos are small.** Thumbnails are 96 pt in bordered cards; titles are truncated at two lines ("Peach Jasmine Green Tea Cold Br…"). Four recipes per screen, so browsing for ideas is slow and the photo, the best signal of "do I want this?", is the smallest thing on the card. | 2 | High | `RecipeCard` |
| 6 | **Emoji as filter labels.** ❤️ / 👌🎉 / 🔖 chips are a vibe-coded tell, read badly in VoiceOver without the custom label, and 🔖 renders as a grey tag. Same emoji leak into copy ("Kept in 🔖", "Remove from 🔖"). | 2 | Medium | Filter chips, job cards, recipe detail |
| 7 | **No clear "Start cooking".** The recipe screen's actions are "Mark as cooked" and an unlabeled ▶. Cooking mode is just the bottom of a long scroll. Creme (and every good cooking app) gives one obvious primary action. | 4 | High | `RecipeDetailView` |
| 8 | **Key facts aren't scannable.** Ingredient count, steps and yield are outline pills mixed with buttons; meal type, time and difficulty aren't shown (the data has no meal type or time, see "To decide"). | 2, 4 | Medium | Detail header |
| 9 | **The heart is invisible on the recipe screen.** Soft-white heart on iOS 27's glass button over a cream page (`before/03`). | 2 | Medium | Detail toolbar |
| 10 | **Contrast fails.** Muted text `#8A817A` on cream is 3.6:1 (needs 4.5:1 for body text); white on terracotta `#C86D51` is 3.6:1 for 17 pt "Done, next step". | all | Medium | Theme |
| 11 | **Fixed font sizes.** Titles use `.system(size: 46/36/30/20…)`, so they don't follow Dynamic Type; at accessibility sizes body text grows but titles don't, and cards (`.lineLimit(2)` titles, 96 pt thumbnails) don't adapt. | all | Medium | Everywhere |
| 12 | **Adding reels has no entry in the app.** The share sheet is the only way in; the empty library says "Nothing here yet." and nothing explains how to add the first reel. | 3 | Medium | Feed empty state |
| 13 | **Card-in-card look.** Every element (recipe rows, job rows, empty states, error boxes, step cards) sits in a white rounded rectangle with a sand border; three corner radii (16, 18, 24, 32) and many paddings (12, 14, 16, 18, 20, 24, 28, 32, 40, 48). | all | Low | Everywhere |
| 14 | **Copy is developer-facing in places.** The server error tells you to run `uvicorn api.app:app …`; the Settings footer does the same. | all | Low | Feed error, Settings |
| 15 | **Touch targets under 44 pt.** Step done circles (24 pt), job dismiss (28 pt), card heart (36 pt), ingredient chips (~32 pt tall). | all | Low | Several |
| 16 | **Screen not kept awake in cooking.** Nothing turns off the idle timer, so at the counter the screen locks mid-recipe. | 4 | Medium | Cooking mode |

## Usability

| Finding | Severity | Recommendation |
|---------|----------|----------------|
| Steps don't render (1) | Critical | Rebuild cooking mode as its own full-screen view: big vertical step list, current step highlighted, no horizontal pager. |
| Keyboard hides search (2) | Critical | Use the system `.searchable` (bottom-placed on iOS 26+) or put the field in a toolbar so iOS manages keyboard avoidance. |
| Pantry feature undiscoverable (3) | High | A "What can I make?" row above the feed with ingredient chips (most-used ingredients), tap to add; a match line on every card once something is picked. |
| No primary action on detail (7) | High | One accent pill: "Start cooking". Watch, Cooked and the shopping list as secondary pills. |
| Empty library dead end (12) | Medium | Explain the share sheet in two lines, with the chef. |

## Visual hierarchy

- **What draws the eye first:** the 46 pt "Remnant" wordmark, then the emoji chips. The food comes third.
  It should be the food.
- **Reading flow:** wordmark → subtitle → chips → card → card. The ingredient search, the main job, is last
  (bottom of the screen).
- **Emphasis:** the filter row is louder than the search; the terracotta is spent on the "All" chip.

## Consistency

| Element | Issue | Recommendation |
|---------|-------|----------------|
| Corner radii | 16, 18, 20, 24, 32 | Three radii: 10 (thumbs, chips' inner), 16 (cards, photos), capsule (pills). |
| Spacing | 12-48 pt, no scale | 4-pt scale: 4, 8, 12, 16, 24, 32. |
| Type | Fixed sizes, serif everywhere | Dynamic Type styles; serif only for titles. |
| Buttons | 5 different pill/button treatments | Two pill styles: primary (accent fill) and secondary (neutral fill). |

## Accessibility

- **Contrast:** muted text fails (3.6:1); white on terracotta fails for normal-size text (3.6:1).
- **Touch targets:** several below 44 pt (see 15).
- **Text:** fixed-size titles don't scale; thumbnails are hidden from VoiceOver (fine) but recipe photos on
  the detail screen have no description.
- **VoiceOver:** emoji chips have labels; ingredient tiles combine well; step rows are buttons with
  "selected" traits (good).

## What works well

- The ingredient matching logic (`IngredientSearch`) is genuinely good: "chicken" finds thighs, flavourings
  rank after the real thing. It deserves a front-row UI.
- Offline copy, Live Activity, timers parsed from step wording: real cooking-app depth.
- The pixel chef gives the app a personality nobody else has. Keep it for empty, loading and finished states.
- Restraint: no gradients, no glows, one accent.

## Compared with Creme and peers

- **Creme:** dark, photo-first, one warm accent pill, labeled metadata columns, a focused cook mode with the
  current step lifted and the rest dimmed. Remnant has the warmth but not the photo-first layout, the single
  primary action or the focused cook mode.
- **Mela / Crouton:** big photo grid for browsing; cook mode is a separate full-screen view with large steps
  and the screen kept awake. Remnant's cooking mode is buried at the end of the recipe page.
- **NYT Cooking:** search by ingredient is a first-class entry with suggestions as chips. Remnant has better
  matching but hides it.

## Priority recommendations

1. **Fix and focus cooking** — full-screen cook mode, vertical steps, current one highlighted, screen awake,
   ingredients one tap away (job 4, and it's broken today).
2. **Put "What can I make?" first** — system search that works with the keyboard, ingredient chips you can
   tap, "you have 3 of 5" on cards (job 1).
3. **Photo-first library, dark as the hero** — two-column photo grid, semantic colors with dark and light
   variants, Dynamic Type (job 2).
