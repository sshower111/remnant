import SwiftUI

// Remnant's design tokens (design/DIRECTION.md).
//
// Colors live in `Shared/Remnant.xcassets` with light and dark variants; Xcode generates
// `Color.canvas`, `.surface`, `.surfaceRaised`, `.textPrimary`, `.textSecondary`, `.hairline`,
// `.ember`, `.onEmber` and `.emberSoft` from it (shared with the share extension).

/// The 4-pt spacing scale. Screen margins are `m`.
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
}

/// Corner radii: small (thumbnails, ingredient tiles), medium (photos, the current cook step).
/// Pills and chips are capsules.
enum Radius {
    static let small: CGFloat = 10
    static let medium: CGFloat = 16
}

/// The smallest tappable size (Apple HIG).
let minTouch: CGFloat = 44

extension Font {
    /// "Remnant" and recipe titles: New York bold, scales with Dynamic Type.
    static let display = Font.system(.largeTitle, design: .serif, weight: .bold)
    /// Section titles ("Ingredients", "Steps").
    static let sectionTitle = Font.system(.title2, design: .serif, weight: .semibold)
    /// A title in an empty state or a sheet header.
    static let stateTitle = Font.system(.title3, design: .serif, weight: .semibold)
}

extension Color {
    /// Hex literals, for the few fixed colors (the scrim over photos).
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension View {
    /// Rows of a plain `List` that look like part of the page: no separator, no row background.
    func pageRow(top: CGFloat = 0, bottom: CGFloat = 0, horizontal: CGFloat = Spacing.m) -> some View {
        listRowInsets(EdgeInsets(top: top, leading: horizontal, bottom: bottom, trailing: horizontal))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
