import SwiftUI
import SwiftData

struct CounselorView: View {
    let profile: UserProfile
    @Query(sort: \UrgeLog.timestamp, order: .reverse) private var urges: [UrgeLog]
    @Query(sort: \Slip.timestamp, order: .reverse) private var slips: [Slip]
    @Environment(\.modelContext) private var context

    @State private var digest: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private let counselor: LLMService = AnthropicCounselor()

    private var hasKey: Bool { KeychainService.hasValue(for: .anthropicAPIKey) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                header

                if !hasKey {
                    keyPrompt
                } else if digest.isEmpty && !isLoading {
                    Button {
                        Task { await refresh() }
                    } label: {
                        Label("Generate today's digest", systemImage: "sparkles")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                if isLoading {
                    HStack {
                        ProgressView()
                        Text("Writing your digest…").foregroundStyle(Theme.onSurfaceMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Space.l)
                }

                if !digest.isEmpty {
                    Card {
                        VStack(alignment: .leading, spacing: Theme.Space.s) {
                            HStack {
                                Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                                Text(profile.lastCounselorDigestDate?.formatted(date: .abbreviated, time: .shortened) ?? "")
                                    .font(.caption)
                                    .foregroundStyle(Theme.onSurfaceMuted)
                                Spacer()
                                Button {
                                    Task { await refresh() }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                }
                                .disabled(isLoading)
                            }
                            Text(digest)
                                .font(.body)
                                .foregroundStyle(Theme.onSurface)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if let err = errorMessage {
                    Text(err).font(.caption).foregroundStyle(Theme.danger)
                }

                disclaimer
            }
            .padding()
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationTitle("Counselor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            digest = profile.lastCounselorDigest ?? ""
            if shouldAutoRefresh {
                Task { await refresh() }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text("Your daily digest")
                .font(.title2.bold())
            Text("A short read on what your body and mind might do today, based on where you are in quitting \(profile.habitName).")
                .font(.subheadline)
                .foregroundStyle(Theme.onSurfaceMuted)
        }
    }

    private var keyPrompt: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("Bring your own key").font(.headline)
                Text("This feature talks to Anthropic from your phone using your API key. The key is stored in your iOS Keychain and never sent anywhere except Anthropic's API.")
                    .font(.footnote)
                    .foregroundStyle(Theme.onSurfaceMuted)
                NavigationLink {
                    APIKeySettingsView()
                } label: {
                    Label("Add Anthropic key in Settings", systemImage: "key.fill")
                }
                .buttonStyle(SoftButtonStyle())
            }
        }
    }

    private var disclaimer: some View {
        Text("This isn't medical advice. If anything feels urgent, contact a clinician. In the US you can call or text 988.")
            .font(.caption)
            .foregroundStyle(Theme.onSurfaceMuted)
    }

    private var shouldAutoRefresh: Bool {
        guard hasKey else { return false }
        guard let last = profile.lastCounselorDigestDate else { return true }
        return Date().timeIntervalSince(last) > 18 * 3600
    }

    private var daysClean: Int {
        let s = max(0, Date().timeIntervalSince(profile.cleanStartDate))
        return Int(s / 86_400)
    }

    private func refresh() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        let recentTags = Array(urges.prefix(20).flatMap { $0.tags.map(\.rawValue) }.prefix(8))
        let correlation = AnalyticsEngine(urges: urges, slips: slips).topCorrelation()
        do {
            let result = try await counselor.dailyDigest(
                habitName: profile.habitName,
                daysClean: daysClean,
                recentTags: recentTags,
                topCorrelation: correlation
            )
            digest = result
            profile.lastCounselorDigest = result
            profile.lastCounselorDigestDate = Date()
            try? context.save()
        } catch {
            errorMessage = (error as? LLMError)?.errorDescription ?? error.localizedDescription
        }
    }
}

// MARK: - API key settings (also referenced from Settings tab)

struct APIKeySettingsView: View {
    @State private var key: String = KeychainService.get(.anthropicAPIKey) ?? ""
    @State private var savedFlash = false

    var body: some View {
        Form {
            Section("Anthropic API key") {
                SecureField("sk-ant-...", text: $key)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Save key") {
                    KeychainService.set(key.trimmingCharacters(in: .whitespacesAndNewlines), for: .anthropicAPIKey)
                    savedFlash = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { savedFlash = false }
                }
                if KeychainService.hasValue(for: .anthropicAPIKey) {
                    Button("Remove key", role: .destructive) {
                        KeychainService.set(nil, for: .anthropicAPIKey)
                        key = ""
                    }
                }
                if savedFlash {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accent)
                }
            }

            Section("How it works") {
                Text("Your key stays in the iOS Keychain on this device. The app calls Anthropic directly with your key; nothing routes through any other server.")
                    .font(.footnote)
                    .foregroundStyle(Theme.onSurfaceMuted)
                Link("Get an Anthropic API key", destination: URL(string: "https://console.anthropic.com/settings/keys")!)
            }
        }
        .navigationTitle("LLM Counselor")
        .navigationBarTitleDisplayMode(.inline)
    }
}
