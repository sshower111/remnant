import SwiftUI

/// Step-by-step focus mode: a progress bar, the step card (StepCard) and an overview list where
/// finished steps fade back.
struct CookingModeView: View {
    let session: CookingSession
    let ingredients: [Ingredient]
    let tried: Bool
    let onMarkTried: () -> Void

    /// The focus card's scroll id, for jumping here from the Live Activity.
    static let focusID = "focus"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            progressBar
            StepCard(session: session, ingredients: ingredients, tried: tried, onMarkTried: onMarkTried)
                .id(Self.focusID)
                .padding(.top, 20)
            overview.padding(.top, 32)
            if !session.progress.done.isEmpty {
                Button("Start over") { withAnimation(.easeOut(duration: 0.25)) { session.startOver() } }
                    .font(.subheadline)
                    .foregroundStyle(Color.muted)
                    .underline()
                    .padding(.top, 16)
            }
        }
        .sensoryFeedback(.selection, trigger: session.active)
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(session.steps.indices, id: \.self) { index in
                let done = session.progress.done.contains(index)
                Button {
                    withAnimation(.easeOut(duration: 0.3)) { session.select(index) }
                } label: {
                    GeometryReader { proxy in
                        Capsule().fill(Color.sand)
                            .overlay(alignment: .leading) {
                                Capsule().fill(Color.terracotta)
                                    .frame(width: proxy.size.width * (done ? 1 : index == session.active ? 0.4 : 0))
                                    .opacity(done ? 0.45 : 1)
                            }
                    }
                    .frame(height: 6)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityHidden(true)
            }
        }
        .animation(.easeOut(duration: 0.35), value: session.progress)
    }

    /// Every step in full; the current one sits on a terracotta-tinted block (number and text),
    /// done ones fade back.
    private var overview: some View {
        VStack(spacing: 0) {
            ForEach(session.steps.indices, id: \.self) { index in
                let isDone = session.progress.done.contains(index)
                let isActive = index == session.active && !session.allDone
                // No divider touching the highlighted block.
                let showsDivider = !isActive && !(index == session.active + 1 && !session.allDone)
                HStack(alignment: .top, spacing: 16) {
                    Button {
                        withAnimation { session.select(index) }
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 16) {
                            Text(String(format: "%02d", index + 1))
                                .font(.serifTitle(24))
                                .foregroundStyle(isActive ? Color.terracotta : Color.ink.opacity(0.7))
                                .frame(width: 36, alignment: .leading)
                            Text(session.steps[index].text)
                                .font(.system(size: 15, weight: isActive ? .medium : .regular))
                                .foregroundStyle(Color.ink)
                                .lineSpacing(3)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isActive ? .isSelected : [])

                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { session.toggleDone(index) }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(isDone ? .white : .clear)
                            .frame(width: 24, height: 24)
                            .background(isDone ? Color.terracotta : Color.white, in: .circle)
                            .overlay { Circle().strokeBorder(isDone ? Color.terracotta : Color.sand) }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                    .accessibilityLabel(isDone ? "Mark step \(index + 1) not done" : "Mark step \(index + 1) done")
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 10)
                .background {
                    if isActive {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.terracottaSoft)
                            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Color.terracotta.opacity(0.5)) }
                    }
                }
                .opacity(isDone && !isActive ? 0.4 : 1)
                .overlay(alignment: .top) {
                    Rectangle().fill(showsDivider ? Color.sand : Color.clear).frame(height: 1)
                        .padding(.horizontal, 10)
                }
            }
        }
        .padding(.horizontal, -10)  // text lines up with the page; the block reaches past it
        .animation(.easeOut(duration: 0.25), value: session.active)
    }
}
