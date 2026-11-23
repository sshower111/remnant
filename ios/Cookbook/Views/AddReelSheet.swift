import SwiftUI

/// "+" in the library: how to add reels from the share sheet, and Paste for a copied link (sent to
/// the PC the same way the share sheet sends it, POST /api/ingest).
struct AddReelSheet: View {
    @Environment(RecipeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var state = SendState.idle

    private enum SendState: Equatable {
        case idle, sending, failed(String)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    step(1, "In Instagram, TikTok or YouTube, open the reel and tap Share.")
                    step(2, "Tap Remnant. If it isn't there, tap More and turn it on.")
                    step(3, "Remnant reads the reel. The recipe shows up here in a few minutes.")
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Copied a link instead?")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    HStack(spacing: Spacing.s) {
                        // PasteButton reads the clipboard without the "Allow Paste" prompt.
                        PasteButton(payloadType: String.self) { strings in
                            guard let text = strings.first else { return }
                            Task { await send(text) }
                        }
                        .buttonBorderShape(.capsule)
                        .tint(.ember)
                        .labelStyle(.titleAndIcon)
                        .disabled(state == .sending)
                        if state == .sending {
                            AnimatedChefView(.loading, size: 36)
                            Text("Sending to Remnant…")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    if case .failed(let message) = state {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.canvas)
            .navigationTitle("Add a reel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(.ember)
        .presentationDetents([.medium, .large])
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            Text(number, format: .number)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Color.ember)
                .frame(minWidth: 16)
            Text(text)
                .font(.body)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func send(_ text: String) async {
        guard let link = text.split(whereSeparator: \.isWhitespace).first(where: { $0.hasPrefix("http") }) else {
            state = .failed("That isn't a link. Copy the reel's link (Share, then Copy link) and try again.")
            return
        }
        state = .sending
        do {
            try await store.addLink(String(link))
            dismiss()
        } catch {
            state = .failed(store.offlineSince != nil
                            ? "Adding needs the recipe server, which is out of reach right now."
                            : "Couldn't reach the recipe server: \(error.localizedDescription)")
        }
    }
}
