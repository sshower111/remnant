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

/// The logo's horizontal lockup: the bitten bookmark, then "Remnant" in New York bold
/// (design/logo/final/remnant-horizontal-*.svg). The mark scales with the text.
struct Wordmark: View {
    @ScaledMetric(relativeTo: .largeTitle) private var markHeight = 34.0

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            RemnantMark()
                .frame(height: markHeight)
            Text("Remnant")
                .font(.display)
                .foregroundStyle(Color.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview { SplashScreenView() }
