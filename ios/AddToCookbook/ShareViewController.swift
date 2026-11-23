//
//  ShareViewController.swift
//  AddToCookbook
//
//  The "Remnant" entry in the share sheet: sends the shared post's link to the PC
//  (POST /api/ingest, docs/ios/api.md), which downloads and parses it in the background.
//  The new recipe then appears in the app's feed.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// The PC's address. Keep in sync with `APIClient.defaultServerURL` in the app: an extension
/// can't read the app's Settings without an App Group, which a free Apple ID can't use.
private let serverURL = URL(string: "http://192.168.2.23:8000")!

final class ShareViewController: UIViewController {
    private let model = ShareModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        model.close = { [weak self] in self?.extensionContext?.completeRequest(returningItems: nil) }
        let host = UIHostingController(rootView: ShareView(model: model))
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
        Task { await model.send(items: extensionContext?.inputItems as? [NSExtensionItem] ?? []) }
    }
}

@MainActor @Observable
final class ShareModel {
    enum Phase: Equatable {
        case sending
        case adding           // queued on the PC
        case alreadyThere(String?)
        case failed(String)
    }

    var phase = Phase.sending
    var close: () -> Void = {}

    func send(items: [NSExtensionItem]) async {
        guard let text = await sharedText(items) else {
            phase = .failed("There's no link in what was shared.")
            return
        }
        do {
            var request = URLRequest(url: serverURL.appending(path: "api/ingest"), timeoutInterval: 8)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["url": text])
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 202, var job = try? JSONDecoder().decode(Job.self, from: data) else {
                let detail = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"]
                phase = .failed(detail ?? "The recipe server answered HTTP \(status).")
                return
            }
            // A post already in Remnant finishes almost at once: say so instead of "adding".
            for _ in 0..<5 where job.status == "queued" || job.status == "running" {
                try? await Task.sleep(for: .milliseconds(400))
                if let (data, _) = try? await URLSession.shared.data(from: serverURL.appending(path: "api/ingest/\(job.id)")),
                   let latest = try? JSONDecoder().decode(Job.self, from: data) {
                    job = latest
                }
            }
            if job.status == "done", job.result == "skipped" {
                phase = .alreadyThere(job.title)
            } else if job.status == "failed" {
                phase = .failed(job.message ?? "Remnant couldn't add it.")
            } else {
                phase = .adding
                try? await Task.sleep(for: .seconds(2))
                close()
            }
        } catch {
            phase = .failed("Couldn't reach the recipe server at \(serverURL.host() ?? "?"). Check your connection and try again.")
        }
    }

    /// The shared link, or shared text (the server finds the link in it).
    private func sharedText(_ items: [NSExtensionItem]) async -> String? {
        let providers = items.flatMap { $0.attachments ?? [] }
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                return url.absoluteString
            }
        }
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            if let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String,
               text.contains("http") {
                return text
            }
        }
        return items.compactMap { $0.attributedContentText?.string }.first { $0.contains("http") }
    }

    private struct Job: Decodable {
        let id: String
        let status: String
        let result: String?
        let title: String?
        let message: String?
    }
}

// Colors come from Shared/Remnant.xcassets (light and dark), like the app's.

struct ShareView: View {
    let model: ShareModel

    var body: some View {
        VStack(spacing: 12) {
            icon
                .font(.largeTitle.weight(.medium))
                .foregroundStyle(Color.ember)
                .frame(height: model.phase == .sending ? 88 : 44)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if model.phase != .sending {
                Button("Done") { model.close() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.onEmber)
                    .frame(maxWidth: 220, minHeight: 44)
                    .background(Color.ember, in: .capsule)
                    .padding(.top, 8)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.canvas)
        .sensoryFeedback(.success, trigger: model.phase) { _, phase in phase == .adding }
    }

    @ViewBuilder
    private var icon: some View {
        switch model.phase {
        case .sending: AnimatedChefView(.loading, size: 88)  // the pixel chef (Shared/)
        case .adding, .alreadyThere: Image(systemName: "checkmark.circle")
        case .failed: Image(systemName: "exclamationmark.triangle")
        }
    }

    private var title: String {
        switch model.phase {
        case .sending: "Sending to Remnant…"
        case .adding: "Sent to Remnant"
        case .alreadyThere: "Already in Remnant"
        case .failed: "Couldn't add it"
        }
    }

    private var detail: String {
        switch model.phase {
        case .sending: "Sending the link to Remnant."
        case .adding: "Remnant is reading the video. The recipe shows up in a few minutes."
        case .alreadyThere(let title): title.map { "“\($0)” is in your library already." } ?? "This reel is in your library already."
        case .failed(let message): message
        }
    }
}
