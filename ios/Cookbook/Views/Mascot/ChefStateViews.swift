import SwiftUI

/// The empty, loading, error and finished states: the pixel chef above a short title, a line of
/// help and an optional action.
struct ChefStateView<Actions: View>: View {
    let animation: ChefAnimation
    let title: String
    var message: String?
    var size: CGFloat = 72
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: Spacing.xs) {
            AnimatedChefView(animation, size: size)
                .accessibilityHidden(true)
            Text(title)
                .font(.stateTitle)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.xxs)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            actions.padding(.top, Spacing.s)
        }
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity)
    }
}

extension ChefStateView where Actions == EmptyView {
    init(animation: ChefAnimation, title: String, message: String? = nil, size: CGFloat = 72) {
        self.init(animation: animation, title: title, message: message, size: size) { EmptyView() }
    }
}

/// A recipe the PC couldn't read or that couldn't be loaded.
struct ParseErrorView<Actions: View>: View {
    var title = "Couldn't open this recipe"
    let message: String
    @ViewBuilder var actions: Actions

    var body: some View {
        ChefStateView(animation: .error, title: title, message: message) { actions }
    }
}

/// The chef cooking while a recipe loads.
struct ChefLoadingView: View {
    var title = "Getting the recipe…"
    var message: String?

    var body: some View {
        ChefStateView(animation: .loading, title: title, message: message, size: 80)
    }
}

/// Shown at the top of the library while a pull-to-refresh runs (in place of the system spinner,
/// which CookbookApp makes clear).
struct RefreshingChefView: View {
    var body: some View {
        HStack(spacing: Spacing.s) {
            AnimatedChefView(.refresh, size: 44)
            Text("Checking your PC for new recipes…")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 40) {
            RefreshingChefView()
            ChefLoadingView()
            ChefStateView(animation: .empty, title: "No favorites yet", message: "Tap the heart on a recipe to keep it here.")
            ChefStateView(animation: .success, title: "All done. Enjoy!")
            ParseErrorView(message: "The video had no ingredient list.") { Button("Try again") {} }
        }
        .padding()
    }
    .background(Color.canvas)
}
