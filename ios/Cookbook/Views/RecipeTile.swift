import SwiftUI

/// One recipe in the library grid: the photo first (4:5, like the reel), the title and one line
/// under it. Opens the recipe; the heart on the photo favorites it without opening.
struct RecipeTile: View {
    let recipe: RecipeSummary
    let thumbnailURL: URL?
    /// Set when the library is ranked by what you have: "You have 3 of 5".
    var match: PantryMatch?
    let onToggleFavorite: () -> Void

    var body: some View {
        NavigationLink(value: recipe.id) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                photo
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.title)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    detail
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(TilePressStyle())
        .overlay(alignment: .topTrailing) { heart }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityAction(named: recipe.favorite ? "Remove from favorites" : "Add to favorites", onToggleFavorite)
    }

    private var photo: some View {
        Color.surface
            .aspectRatio(4 / 5, contentMode: .fit)
            .overlay {
                Thumbnail(url: thumbnailURL, title: recipe.title, initialSize: 44, maxPoints: 240)
            }
            .overlay(alignment: .bottomLeading) {
                if recipe.tried {
                    Label("Cooked", systemImage: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(.black.opacity(0.55), in: .capsule)
                        .padding(Spacing.xs)
                }
            }
            .clipShape(.rect(cornerRadius: Radius.medium))
    }

    /// "13 ingredients · 12 steps", or how it fits what you have.
    @ViewBuilder
    private var detail: some View {
        if let match {
            let fit = Self.fit(match, recipe: recipe)
            Text(fit.text)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(fit.complete ? Color.ember : Color.textPrimary)
            if !match.missing.isEmpty {
                Text("Needs " + match.missing.prefix(3).joined(separator: ", ") + (match.missing.count > 3 ? "…" : ""))
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
            }
        } else {
            Text(meta)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
        }
    }

    private var meta: String {
        if recipe.ingredientCount == 0 { return "No recipe yet" }
        var parts = [recipe.ingredientCount == 1 ? "1 ingredient" : "\(recipe.ingredientCount) ingredients"]
        if recipe.stepCount > 0 { parts.append(recipe.stepCount == 1 ? "1 step" : "\(recipe.stepCount) steps") }
        return parts.joined(separator: " · ")
    }

    /// "You have 3 of 5": the recipe's ingredients (staples left out) you have.
    static func fit(_ match: PantryMatch, recipe: RecipeSummary) -> (text: String, complete: Bool) {
        let total = match.total
        if match.missing.isEmpty { return ("You have everything", true) }
        return ("You have \(total - match.missingCount) of \(total)", false)
    }

    private var heart: some View {
        Button(action: onToggleFavorite) {
            Image(systemName: recipe.favorite ? "heart.fill" : "heart")
                // A fixed size: it sits on a fixed 32 pt circle (the 44 pt target doesn't grow either).
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .symbolEffect(.bounce, value: recipe.favorite)
                .frame(width: 32, height: 32)
                // White on a deep ember (5.7:1) or on 50 % black (≥ 3.9:1 even over a white photo).
                .background(recipe.favorite ? Color.emberDeep : Color.black.opacity(0.5), in: .circle)
                .frame(width: minTouch, height: minTouch)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(Spacing.xxs)
        .accessibilityHidden(true)  // the tile's own accessibility action covers it
        .sensoryFeedback(.selection, trigger: recipe.favorite)
    }

    private var accessibilityText: String {
        var parts = [recipe.title]
        if let match { parts.append(Self.fit(match, recipe: recipe).text) } else { parts.append(meta) }
        if recipe.favorite { parts.append("Favorite") }
        if recipe.tried { parts.append("Cooked") }
        return parts.joined(separator: ", ")
    }
}

/// A slight dim while pressed, like a system cell.
private struct TilePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// Grey blocks the shape of tiles while the library loads the first time.
struct RecipeTilePlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: Radius.medium)
                .fill(Color.surface)
                .aspectRatio(4 / 5, contentMode: .fit)
            RoundedRectangle(cornerRadius: 4).fill(Color.surface).frame(height: 14)
            RoundedRectangle(cornerRadius: 4).fill(Color.surface).frame(width: 80, height: 12)
        }
        .accessibilityHidden(true)
    }
}
