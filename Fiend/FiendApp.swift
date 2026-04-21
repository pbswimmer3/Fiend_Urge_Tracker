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

    var body: some View {
        Group {
            if let profile = profiles.first, profile.hasCompletedOnboarding {
                MainTabView(profile: profile)
            } else {
                OnboardingView()
            }
        }
        .tint(Theme.primary)
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
