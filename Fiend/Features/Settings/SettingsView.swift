import SwiftUI
import SwiftData

struct SettingsView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var context
    @Query private var urges: [UrgeLog]
    @Query private var slips: [Slip]

    @State private var showingPrivacy = false
    @State private var showingDisclaimer = false
    @State private var showingResetConfirm = false
    @State private var showingEraseConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Your journey") {
                    HStack {
                        Text("Tracking")
                        Spacer()
                        Text(profile.habitName).foregroundStyle(Theme.onSurfaceMuted)
                    }
                    DatePicker(
                        "Clean since",
                        selection: Binding(
                            get: { profile.cleanStartDate },
                            set: { profile.cleanStartDate = $0; try? context.save() }
                        ),
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    Button("Reset clean start to now", role: .destructive) {
                        showingResetConfirm = true
                    }
                }

                Section("Sober dividend") {
                    VStack(alignment: .leading) {
                        Text("Hours per day: \(profile.dailyHoursReclaimed, specifier: "%.1f")")
                        Slider(
                            value: Binding(
                                get: { profile.dailyHoursReclaimed },
                                set: { profile.dailyHoursReclaimed = $0; try? context.save() }
                            ),
                            in: 0...12, step: 0.5
                        )
                    }
                    VStack(alignment: .leading) {
                        Text("Dollars per day: $\(Int(profile.dailyDollarsReclaimed))")
                        Slider(
                            value: Binding(
                                get: { profile.dailyDollarsReclaimed },
                                set: { profile.dailyDollarsReclaimed = $0; try? context.save() }
                            ),
                            in: 0...200, step: 1
                        )
                    }
                }

                Section("Privacy") {
                    Button { showingPrivacy = true } label: {
                        Label("Privacy policy", systemImage: "lock.shield")
                    }
                    Button { showingDisclaimer = true } label: {
                        Label("Medical disclaimer", systemImage: "staroflife")
                    }
                    Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                        Label("Location permissions", systemImage: "location")
                    }
                }

                Section("Data") {
                    HStack {
                        Text("Urges logged")
                        Spacer()
                        Text("\(urges.count)").foregroundStyle(Theme.onSurfaceMuted)
                    }
                    HStack {
                        Text("Slips logged")
                        Spacer()
                        Text("\(slips.count)").foregroundStyle(Theme.onSurfaceMuted)
                    }
                    Button("Erase all data", role: .destructive) {
                        showingEraseConfirm = true
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.shortVersion).foregroundStyle(Theme.onSurfaceMuted)
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Reset clean start?", isPresented: $showingResetConfirm) {
                Button("Reset to now", role: .destructive) {
                    profile.cleanStartDate = Date()
                    try? context.save()
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Erase all logged data?", isPresented: $showingEraseConfirm, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Removes every urge and slip on this device. Your clean start date is kept.")
            }
            .sheet(isPresented: $showingPrivacy) { PrivacyPolicyView() }
            .sheet(isPresented: $showingDisclaimer) { MedicalDisclaimerView() }
        }
    }

    private func eraseAll() {
        for u in urges { context.delete(u) }
        for s in slips { context.delete(s) }
        try? context.save()
    }
}

private extension Bundle {
    var shortVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "dev"
    }
}

// MARK: - Policy sheets

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.m) {
                    Text("Privacy, in plain language").font(.title2.bold())
                    policyParagraph("Fiend stores every urge, slip, tag, and location reading in a private database on this device. Nothing is uploaded, synced, sold, or shared. No analytics SDKs, no trackers, no third-party services.")
                    policyParagraph("Location is captured only when you log an urge and only if you explicitly grant \"While Using\" permission. You can revoke it at any time in iOS Settings.")
                    policyParagraph("You can erase all logged data from Settings at any time. Deleting the app removes everything.")
                    policyParagraph("If a future version adds optional cloud sync or sharing, it will be strictly opt-in and disclosed clearly before enabling.")
                    policyParagraph("Contact: please open an issue on the GitHub repository if you have a question about how your data is handled.")
                }
                .padding()
            }
            .navigationTitle("Privacy")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func policyParagraph(_ text: String) -> some View {
        Text(text).font(.body).foregroundStyle(Theme.onSurface)
    }
}

struct MedicalDisclaimerView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.m) {
                    Text("Medical disclaimer").font(.title2.bold())
                    Text("Fiend is a self-awareness journal, not a medical device. It is not a substitute for evaluation, diagnosis, or treatment by a licensed clinician, therapist, or physician.")
                    Text("If you are experiencing a mental health or substance-use crisis, stop and contact a professional. In the US, 988 is the Suicide & Crisis Lifeline. In an emergency, call 911 or your local equivalent.")
                    Text("You are responsible for your own safety and medical care. Fiend's charts and suggestions are informational only.")
                }
                .padding()
            }
            .navigationTitle("Disclaimer")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
