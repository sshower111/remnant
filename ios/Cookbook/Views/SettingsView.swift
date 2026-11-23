import SwiftUI

/// Server address with a connection test, and the Dynamic Island switch.
struct SettingsView: View {
    @Environment(RecipeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage(APIClient.serverURLKey) private var serverURL = APIClient.defaultServerURL
    @AppStorage(LiveActivityController.autoStartKey) private var autoStart = true
    @State private var test: TestState = .idle

    private enum TestState: Equatable {
        case idle, testing, success(Int), failure(String)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("http://192.168.2.23:8000", text: $serverURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(Color.textPrimary)
                        .onChange(of: serverURL) { test = .idle }
                    Button {
                        Task { await testConnection() }
                    } label: {
                        HStack {
                            Text("Test connection").foregroundStyle(Color.ember)
                            Spacer()
                            testResult
                        }
                    }
                    .disabled(test == .testing)
                    if case .failure(let message) = test {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(Color.textSecondary)
                    }
                    if serverURL != APIClient.defaultServerURL {
                        Button("Use the default address") { serverURL = APIClient.defaultServerURL }
                            .foregroundStyle(Color.textSecondary)
                    }
                } header: {
                    Text("Recipe server")
                } footer: {
                    Text("Your PC's address on home Wi-Fi. Start the server there with `uvicorn api.app:app --host 0.0.0.0 --port 8000`.")
                }
                .listRowBackground(Color.surface)

                Section {
                    Toggle("Show steps when you leave a recipe", isOn: $autoStart)
                        .tint(.ember)
                } header: {
                    Text("Dynamic Island")
                } footer: {
                    Text("Watch always shows the current step in the Dynamic Island. With this on, it also appears when you press Home or switch apps while a recipe is open.")
                }
                .listRowBackground(Color.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.canvas)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(.ember)
        // A new address takes effect for the feed as soon as Settings closes.
        .onDisappear { Task { await store.load() } }
    }

    @ViewBuilder
    private var testResult: some View {
        switch test {
        case .idle: EmptyView()
        case .testing: AnimatedChefView(.loading, size: 32)
        case .success(let count):
            Label("\(count) recipes", systemImage: "checkmark.circle.fill")
                .foregroundStyle(Color.ember)
                .font(.subheadline)
        case .failure:
            Label("No answer", systemImage: "xmark.circle.fill")
                .foregroundStyle(Color.textSecondary)
                .font(.subheadline)
        }
    }

    private func testConnection() async {
        test = .testing
        do {
            let count = try await APIClient.current().recipes().count
            test = .success(count)
        } catch {
            test = .failure(error.localizedDescription)
        }
    }
}
