import SwiftUI

// Remnant's reusable pieces: pill buttons, chips, metadata columns, section headers and status
// rows. Every screen builds on these (design/DIRECTION.md).

// MARK: - Pill buttons

/// The app's buttons: a primary pill (ember fill, the one thing to do next) and a secondary pill
/// (neutral fill). At least 44 pt tall; icon and title from the `Label`.
struct PillButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, selected }
    var kind: Kind
    /// Stretch to the full width (the cook mode's Next step).
    var expands = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(PillLabelStyle())
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .foregroundStyle(foreground)
            .padding(.horizontal, Spacing.m)
            .frame(maxWidth: expands ? .infinity : nil, minHeight: minTouch)
            .background(background, in: .capsule)
            .contentShape(.capsule)
            .opacity(configuration.isPressed ? 0.7 : isEnabled ? 1 : 0.45)
    }

    private var foreground: Color {
        switch kind {
        case .primary: .onEmber
        case .secondary: .textPrimary
        case .selected: .ember
        }
    }

    private var background: Color {
        switch kind {
        case .primary: .ember
        case .secondary: .surface
        case .selected: .emberSoft
        }
    }
}

/// Icon and title close together, the icon a touch smaller than the text.
private struct PillLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.imageScale(.small)
            configuration.title
        }
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    static var primaryPill: PillButtonStyle { PillButtonStyle(kind: .primary) }
    static var secondaryPill: PillButtonStyle { PillButtonStyle(kind: .secondary) }
    static func pill(_ kind: PillButtonStyle.Kind, expands: Bool = false) -> PillButtonStyle {
        PillButtonStyle(kind: kind, expands: expands)
    }
}

// MARK: - Chips

/// A small tappable capsule: an ingredient you can add ("+ Egg 12") or one you have ("Egg ✕").
/// Drawn 36 pt tall with a 44 pt touch area.
struct Chip: View {
    let title: String
    var systemImage: String?
    /// A quiet number after the title (how many recipes use the ingredient).
    var count: Int?
    var isSelected = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage, !isSelected {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.ember)
                }
                Text(title)
                    .foregroundStyle(Color.textPrimary)
                if let count {
                    Text(count, format: .number)
                        .foregroundStyle(Color.textSecondary)
                        .monospacedDigit()
                }
                if isSelected {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.ember)
                }
            }
            .font(.subheadline.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 14)
            .frame(minHeight: 36)
            .background(isSelected ? Color.emberSoft : Color.surface, in: .capsule)
            .padding(.vertical, 4)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Metadata columns

/// Compact labeled columns, small gray label above the value: "Ingredients 13 · Steps 12 · Makes
/// 4 servings". Two per row at the accessibility text sizes.
struct MetadataColumns: View {
    struct Item: Identifiable {
        let label: String
        let value: String
        var id: String { label }
    }

    let items: [Item]
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.m, alignment: .topLeading),
                            count: typeSize.isAccessibilitySize ? 2 : max(items.count, 1))
        LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.m) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.label)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    Text(item.value)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

// MARK: - Section header

/// "Ingredients" / "Steps", with an optional action on the right.
struct SectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.sectionTitle)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.s)
            trailing
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title: title) { EmptyView() }
    }
}

// MARK: - Status row

/// One line of news in the library: a reel being added, a failure, the PC out of reach.
/// Leading icon or chef, title, detail, optional actions and a dismiss button.
struct StatusRow<Leading: View, Actions: View>: View {
    let title: String
    let detail: String
    var onDismiss: (() -> Void)?
    @ViewBuilder var leading: Leading
    @ViewBuilder var actions: Actions

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            leading
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                actions
                    .padding(.top, Spacing.xs)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let onDismiss {
                Button("Dismiss", systemImage: "xmark", action: onDismiss)
                    .labelStyle(.iconOnly)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: minTouch, height: minTouch)
                    .contentShape(.rect)
                    .padding(.top, -Spacing.xs)
                    .padding(.trailing, -Spacing.xs)
            }
        }
        .padding(Spacing.s)
        .background(Color.surface, in: .rect(cornerRadius: Radius.medium))
    }
}

extension StatusRow where Actions == EmptyView {
    init(title: String, detail: String, onDismiss: (() -> Void)? = nil, @ViewBuilder leading: () -> Leading) {
        self.init(title: title, detail: detail, onDismiss: onDismiss, leading: leading) { EmptyView() }
    }
}

// MARK: - Photo scrim

/// Black fading up from the bottom of a photo, so white text on it reads on any picture
/// (≥ 4.5:1 where the text sits).
struct PhotoScrim: View {
    var body: some View {
        LinearGradient(stops: [
            .init(color: .black.opacity(0), location: 0),
            .init(color: .black.opacity(0.5), location: 0.35),
            .init(color: .black.opacity(0.8), location: 1),
        ], startPoint: .top, endPoint: .bottom)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The light-mode ember in both appearances, behind white on photos (5.7:1).
extension Color {
    static let emberDeep = Color(hex: 0xA84B2A)
}

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        HStack {
            Button("Start cooking", systemImage: "frying.pan") {}.buttonStyle(.primaryPill)
            Button("Watch", systemImage: "play.rectangle") {}.buttonStyle(.secondaryPill)
        }
        HStack {
            Chip(title: "Egg", isSelected: true) {}
            Chip(title: "Garlic", systemImage: "plus", count: 31) {}
        }
        MetadataColumns(items: [.init(label: "Ingredients", value: "13"), .init(label: "Steps", value: "12"),
                                .init(label: "Makes", value: "4 servings")])
        SectionHeader("Ingredients")
    }
    .padding()
    .background(Color.canvas)
}
