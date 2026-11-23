import SwiftUI

/// The whole ingredient list on one screen (the recipe's Shopping list, cook mode's Ingredients).
/// Tap a line to tick it off; in cook mode the current step's ingredients are marked.
struct IngredientListSheet: View {
    let title: String
    let yieldLabel: String?
    let ingredients: [Ingredient]
    /// Indexes the current cook step uses.
    var highlighted: Set<Int> = []
    @Environment(\.dismiss) private var dismiss
    @State private var ticked: Set<Int> = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ingredients.indices, id: \.self) { index in
                        Button {
                            if ticked.contains(index) { ticked.remove(index) } else { ticked.insert(index) }
                        } label: {
                            row(ingredients[index], ticked: ticked.contains(index), inStep: highlighted.contains(index))
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Color.hairline)
                        .accessibilityLabel(ingredients[index].spoken + (highlighted.contains(index) ? ", used in this step" : ""))
                        .accessibilityValue(ticked.contains(index) ? "Ticked" : "")
                        .accessibilityHint("Ticks it off")
                    }
                } header: {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(title)
                            .font(.stateTitle)
                            .foregroundStyle(Color.textPrimary)
                        Text([yieldLabel?.capitalizedFirst, "\(ingredients.count) ingredients"].compactMap { $0 }.joined(separator: " · "))
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .textCase(nil)
                    .padding(.bottom, Spacing.xs)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.canvas)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(.ember)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func row(_ ingredient: Ingredient, ticked: Bool, inStep: Bool) -> some View {
        let quantity = ingredient.quantity
        return HStack(spacing: Spacing.s) {
            Image(systemName: ticked ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(ticked ? Color.ember : Color.textSecondary)
            (Text(quantity.isEmpty ? "" : quantity + " ").fontWeight(.semibold) + Text(ingredient.label))
                .foregroundStyle(Color.textPrimary)
                .strikethrough(ticked, color: Color.textSecondary)
                .opacity(ticked ? 0.5 : 1)
            Spacer(minLength: 0)
            if inStep {
                Text("This step")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.ember)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 3)
                    .background(Color.emberSoft, in: .capsule)
            }
        }
        .frame(minHeight: minTouch)
        .contentShape(.rect)
    }
}
