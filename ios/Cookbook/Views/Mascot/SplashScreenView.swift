import SwiftUI

/// The launch splash: the chef, the wordmark and its line. Shown over the library for a moment at
/// launch (CookbookApp); the library loads underneath meanwhile.
struct SplashScreenView: View {
    var body: some View {
        VStack(spacing: 0) {
            AnimatedChefView(.splash, size: 96)
            Wordmark()
                .padding(.top, Spacing.l)
            Text("Cook with what's left")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.canvas)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Remnant. Cook with what's left")
    }
}

/// "Remnant" in New York bold with an ember sprig, the app icon's mark.
struct Wordmark: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("Remnant")
                .font(.display)
                .foregroundStyle(Color.textPrimary)
            Image(systemName: "leaf.fill")
                .font(.title3)
                .foregroundStyle(Color.ember)
                .rotationEffect(.degrees(-20))
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview { SplashScreenView() }
