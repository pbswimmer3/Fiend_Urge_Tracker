import SwiftUI
import SwiftData

@main
struct FiendApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: UrgeLog.self, Slip.self, UserProfile.self,
                configurations: ModelConfiguration(
                    isStoredInMemoryOnly: false,
                    allowsSave: true
                )
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @State private var pendingMilestone: Milestone?

    var body: some View {
        Group {
            if let profile = profiles.first, profile.hasCompletedOnboarding {
                MainTabView(profile: profile)
                    .fullScreenCover(item: $pendingMilestone) { milestone in
                        MilestoneCelebrationView(
                            milestone: milestone,
                            habitName: profile.habitName
                        ) {
                            profile.lastAcknowledgedMilestoneID = milestone.id
                            try? context.save()
                            pendingMilestone = nil
                        }
                    }
                    .onAppear { checkMilestone(profile: profile) }
                    .onChange(of: scenePhase) { _, newPhase in
                        if newPhase == .active { checkMilestone(profile: profile) }
                    }
            } else {
                OnboardingView()
            }
        }
        .tint(Theme.primary)
    }

    private func checkMilestone(profile: UserProfile) {
        let elapsed = max(0, Date().timeIntervalSince(profile.cleanStartDate))
        if let next = MilestoneService.milestoneToCelebrate(
            elapsed: elapsed,
            lastAcknowledgedID: profile.lastAcknowledgedMilestoneID
        ) {
            pendingMilestone = next
        }
    }
}

struct MainTabView: View {
    let profile: UserProfile

    var body: some View {
        TabView {
            HomeView(profile: profile)
                .tabItem { Label("Home", systemImage: "heart.circle.fill") }

            DashboardView()
                .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }

            SettingsView(profile: profile)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
