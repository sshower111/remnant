import SwiftUI

/// The whole ingredient list on one screen (from the recipe's "N ingredients" pill), easier to
/// shop from than the swipeable tiles. Tap a line to tick it off while shopping.
struct IngredientListSheet: View {
    let title: String
    let yieldLabel: String?
    let ingredients: [Ingredient]
    @Environment(\.dismiss) private var dismiss
    @State private var ticked: Set<Int> = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ingredients.indices, id: \.self) { index in
                        row(ingredients[index], ticked: ticked.contains(index))
                            .contentShape(.rect)
                            .onTapGesture {
                                if ticked.contains(index) { ticked.remove(index) } else { ticked.insert(index) }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparatorTint(Color.sand)
                            .accessibilityAddTraits(.isButton)
                            .accessibilityValue(ticked.contains(index) ? "Ticked" : "")
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.serifTitle(26))
                            .foregroundStyle(Color.ink)
                        Text([yieldLabel, "\(ingredients.count) ingredients"].compactMap { $0 }.joined(separator: " · "))
                            .font(.subheadline)
                            .foregroundStyle(Color.muted)
                    }
                    .textCase(nil)
                    .padding(.bottom, 8)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.cream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .tint(.terracotta)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func row(_ ingredient: Ingredient, ticked: Bool) -> some View {
        let quantity = ingredient.quantity
        return HStack(spacing: 14) {
            Image(systemName: ticked ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(ticked ? Color.terracotta : Color.sand)
            (Text(quantity.isEmpty ? "" : quantity + " ").fontWeight(.semibold) + Text(ingredient.label))
                .foregroundStyle(Color.ink)
                .strikethrough(ticked, color: Color.muted)
                .opacity(ticked ? 0.45 : 1)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }
}
