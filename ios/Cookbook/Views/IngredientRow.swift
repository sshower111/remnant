import SwiftUI

/// The recipe's ingredients as a row of tiles you swipe through: a black-and-white icon, the
/// amount and the name ("3 tbsp Soy sauce"). Highlighted tiles are the ones a step uses.
struct IngredientRow: View {
    let ingredients: [Ingredient]
    var active: Set<Int> = []
    @ScaledMetric(relativeTo: .subheadline) private var tileWidth: CGFloat = 96

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: Spacing.s) {
                ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                    tile(ingredient, isActive: active.contains(index))
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, Spacing.m)
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
    }

    private func tile(_ ingredient: Ingredient, isActive: Bool) -> some View {
        let quantity = ingredient.quantity
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Group {
                if let icon = IngredientIcon.asset(for: ingredient.name) {
                    // A black-and-white icon (no ingredient photos exist).
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                } else {
                    // No icon fits ("aromatic"): its first letter.
                    Text(String(ingredient.name.prefix(1)).uppercased())
                        .font(.system(.title, design: .serif))
                }
            }
            .foregroundStyle(isActive ? Color.ember : Color.textPrimary.opacity(0.8))
            .frame(width: tileWidth, height: 88)
            .background(isActive ? Color.emberSoft : Color.surface, in: .rect(cornerRadius: Radius.small))
            .accessibilityHidden(true)
            // The amount leads the name: "3 tbsp Soy sauce".
            (Text(quantity.isEmpty ? "" : quantity + " ").fontWeight(.semibold) + Text(ingredient.label))
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(3)
                .frame(width: tileWidth, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(ingredient.spoken)
    }
}
