import SwiftUI
import SwiftData
import CoreLocation

struct SettingsView: View {
    @Bindable var profile: UserProfile

    @Environment(\.modelContext) private var context
    @Query private var urges: [UrgeLog]
    @Query private var slips: [Slip]

    @State private var showingPrivacy = false
    @State private var showingDisclaimer = false
    @State private var showingResetConfirm = false
    @State private var showingEraseConfirm = false
    @State private var settingHome = false

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
                        selection: $profile.cleanStartDate,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .onChange(of: profile.cleanStartDate) { _, _ in
                        try? context.save()
                        Task { await NotificationService.shared.scheduleUpcomingMilestoneAlerts(cleanStart: profile.cleanStartDate) }
                    }
                    NavigationLink {
                        WhyEditor(profile: profile)
                    } label: {
                        Label("Why I'm doing this", systemImage: "heart.text.square")
                    }
                    Button("Reset clean start to now", role: .destructive) {
                        showingResetConfirm = true
                    }
                }

                Section("Home location") {
                    if let lat = profile.homeLatitude, let lon = profile.homeLongitude {
                        HStack {
                            Image(systemName: "house.fill").foregroundStyle(Theme.primary)
                            VStack(alignment: .leading) {
                                Text(profile.homeName ?? "Home")
                                Text(String(format: "%.4f, %.4f", lat, lon))
                                    .font(.caption)
                                    .foregroundStyle(Theme.onSurfaceMuted)
                            }
                        }
                        Button("Clear home location", role: .destructive) {
                            profile.homeLatitude = nil
                            profile.homeLongitude = nil
                            profile.homeName = nil
                            try? context.save()
                        }
                    }
                    Button {
                        Task { await setCurrentLocationAsHome() }
                    } label: {
                        Label(settingHome ? "Reading location…" : "Use current location as Home", systemImage: "location.fill")
                    }
                    .disabled(settingHome || !profile.locationPermissionGranted)
                    if !profile.locationPermissionGranted {
                        Text("Grant location permission first.")
                            .font(.caption)
                            .foregroundStyle(Theme.onSurfaceMuted)
                    }
                }

                Section("Notifications") {
                    Toggle("Peak-time alerts", isOn: $profile.peakTimeAlertsEnabled)
                        .onChange(of: profile.peakTimeAlertsEnabled) { _, on in
                            try? context.save()
                            Task { await togglePeakTime(on: on) }
                        }
                    Toggle("Peak-location alerts", isOn: $profile.peakLocationAlertsEnabled)
                        .onChange(of: profile.peakLocationAlertsEnabled) { _, on in
                            try? context.save()
                            togglePeakLocation(on: on)
                        }
                    Toggle("Milestone celebrations", isOn: $profile.milestoneAlertsEnabled)
                        .onChange(of: profile.milestoneAlertsEnabled) { _, on in
                            try? context.save()
                            Task { await toggleMilestoneAlerts(on: on) }
                        }
                    Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                        Label("Open iOS notification settings", systemImage: "bell")
                    }
                }

                Section("LLM Counselor (BYOK)") {
                    NavigationLink {
                        APIKeySettingsView()
                    } label: {
                        Label(
                            KeychainService.hasValue(for: .anthropicAPIKey) ? "Key configured" : "Add Anthropic API key",
                            systemImage: KeychainService.hasValue(for: .anthropicAPIKey) ? "checkmark.shield.fill" : "key.fill"
                        )
                    }
                }

                Section("Sober dividend") {
                    VStack(alignment: .leading) {
                        Text("Hours per day: \(profile.dailyHoursReclaimed, specifier: "%.1f")")
                        Slider(value: $profile.dailyHoursReclaimed, in: 0...12, step: 0.5)
                            .onChange(of: profile.dailyHoursReclaimed) { _, _ in try? context.save() }
                    }
                    VStack(alignment: .leading) {
                        Text("Dollars per day: $\(Int(profile.dailyDollarsReclaimed))")
                        Slider(value: $profile.dailyDollarsReclaimed, in: 0...200, step: 1)
                            .onChange(of: profile.dailyDollarsReclaimed) { _, _ in try? context.save() }
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
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Label("View / delete entries", systemImage: "list.bullet.rectangle")
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
                    profile.lastAcknowledgedMilestoneID = nil
                    try? context.save()
                    Task { await NotificationService.shared.scheduleUpcomingMilestoneAlerts(cleanStart: profile.cleanStartDate) }
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

    private func setCurrentLocationAsHome() async {
        settingHome = true
        defer { settingHome = false }
        guard let loc = await LocationService.shared.oneShotLocation() else { return }
        profile.homeLatitude = loc.coordinate.latitude
        profile.homeLongitude = loc.coordinate.longitude
        if profile.homeName == nil { profile.homeName = "Home" }
        try? context.save()
    }

    private func togglePeakTime(on: Bool) async {
        if on {
            await NotificationService.shared.requestAuthorization()
            let engine = AnalyticsEngine(urges: urges)
            let peakHour = engine.hourlyBuckets()
                .max(by: { $0.count < $1.count })
                .map(\.hour)
            await NotificationService.shared.schedulePeakTimeAlert(peakHour: peakHour, habitName: profile.habitName)
        } else {
            await NotificationService.shared.schedulePeakTimeAlert(peakHour: nil, habitName: profile.habitName)
        }
    }

    private func togglePeakLocation(on: Bool) {
        if on {
            let zones = AnalyticsEngine(urges: urges).dangerZones()
            NotificationService.shared.updateDangerZoneRegions(zones)
        } else {
            NotificationService.shared.updateDangerZoneRegions([])
        }
    }

    private func toggleMilestoneAlerts(on: Bool) async {
        if on {
            await NotificationService.shared.requestAuthorization()
            await NotificationService.shared.scheduleUpcomingMilestoneAlerts(cleanStart: profile.cleanStartDate)
        } else {
            await NotificationService.shared.scheduleUpcomingMilestoneAlerts(cleanStart: Date.distantPast)
        }
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
                    policyParagraph("If you enable the LLM counselor, the app will call Anthropic's API directly from your device using the key you've supplied. Your transcripts go from your phone to Anthropic and back — nowhere else. The key itself is stored in the iOS Keychain.")
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
