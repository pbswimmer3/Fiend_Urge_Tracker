import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var locationService = LocationService.shared

    @State private var step: Int = 0
    @State private var habitName: String = ""
    @State private var cleanStartDate: Date = Date()
    @State private var acknowledgedDisclaimer: Bool = false
    @State private var hoursReclaimed: Double = 2
    @State private var dollarsReclaimed: Double = 20

    var body: some View {
        VStack {
            progressDots
            TabView(selection: $step) {
                welcomePane.tag(0)
                disclaimerPane.tag(1)
                habitPane.tag(2)
                startDatePane.tag(3)
                dividendPane.tag(4)
                locationPane.tag(5)
                finishPane.tag(6)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)

            footer
        }
        .padding()
        .background(Theme.surface.ignoresSafeArea())
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<7) { i in
                Circle()
                    .fill(i == step ? Theme.primary : Theme.primary.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.top, Theme.Space.m)
    }

    // MARK: - Panes

    private var welcomePane: some View {
        paneContainer {
            VStack(spacing: Theme.Space.m) {
                Image(systemName: "heart.circle.fill")
                    .resizable().scaledToFit().frame(width: 88, height: 88)
                    .foregroundStyle(Theme.primary)
                Text("Welcome to Fiend").font(.largeTitle.bold())
                Text("A private, on-device tool for tracking urges and reclaiming time.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.onSurfaceMuted)
            }
        }
    }

    private var disclaimerPane: some View {
        paneContainer {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                Text("A note before we begin").font(.title2.bold())
                Text("Fiend is a supplementary self-awareness tool. It is not a medical device, a therapist, or a replacement for professional treatment of substance use disorders or any other condition.")
                Text("If you are in crisis, please contact your clinician, a trusted person, or in the US call or text 988.")
                    .foregroundStyle(Theme.onSurfaceMuted)
                Toggle(isOn: $acknowledgedDisclaimer) {
                    Text("I understand Fiend is not medical treatment.")
                        .font(.subheadline)
                }
                .tint(Theme.primary)
            }
        }
    }

    private var habitPane: some View {
        paneContainer {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                Text("What are you tracking?").font(.title2.bold())
                Text("Give it a name so the app can talk about it respectfully.")
                    .foregroundStyle(Theme.onSurfaceMuted)
                TextField("e.g. drinking, vaping, scrolling", text: $habitName)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }
        }
    }

    private var startDatePane: some View {
        paneContainer {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                Text("When did you last engage?").font(.title2.bold())
                Text("This becomes your clean start. You can adjust it any time.")
                    .foregroundStyle(Theme.onSurfaceMuted)
                DatePicker("Clean start", selection: $cleanStartDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
            }
        }
    }

    private var dividendPane: some View {
        paneContainer {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                Text("Your sober dividend").font(.title2.bold())
                Text("Roughly, how many hours and dollars does a typical day of the habit cost you? This powers the Time vs. Habit chart.")
                    .foregroundStyle(Theme.onSurfaceMuted)
                VStack(alignment: .leading) {
                    Text("Hours per day: \(hoursReclaimed, specifier: "%.1f")")
                    Slider(value: $hoursReclaimed, in: 0...12, step: 0.5)
                }
                VStack(alignment: .leading) {
                    Text("Dollars per day: $\(Int(dollarsReclaimed))")
                    Slider(value: $dollarsReclaimed, in: 0...200, step: 1)
                }
            }
        }
    }

    private var locationPane: some View {
        paneContainer {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                Text("Optional: location").font(.title2.bold())
                Text("Fiend can attach your coarse location to each urge so it can map your triggers and highlight high-risk environmental zones. Location never leaves your device.")
                    .foregroundStyle(Theme.onSurfaceMuted)
                Button {
                    locationService.requestAuthorization()
                } label: {
                    Label("Allow location while using Fiend", systemImage: "location.fill")
                }
                .buttonStyle(SoftButtonStyle())
                Text(locationStatusText)
                    .font(.footnote)
                    .foregroundStyle(Theme.onSurfaceMuted)
            }
        }
    }

    private var finishPane: some View {
        paneContainer {
            VStack(spacing: Theme.Space.m) {
                Image(systemName: "checkmark.seal.fill")
                    .resizable().scaledToFit().frame(width: 80, height: 80)
                    .foregroundStyle(Theme.accent)
                Text("You're ready.").font(.largeTitle.bold())
                Text("Tap the big button on the home screen any time you feel a pull. That's it.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.onSurfaceMuted)
            }
        }
    }

    private func paneContainer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack {
            Spacer(minLength: 0)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Space.l)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if step > 0 {
                Button("Back") { step -= 1 }
                    .buttonStyle(SoftButtonStyle())
            }
            Button(step == 6 ? "Start" : "Continue") {
                if step == 6 {
                    finish()
                } else {
                    step += 1
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canAdvance)
        }
        .padding(.bottom, Theme.Space.m)
    }

    private var canAdvance: Bool {
        switch step {
        case 1: return acknowledgedDisclaimer
        case 2: return !habitName.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }

    private var locationStatusText: String {
        switch locationService.authorizationStatus {
        case .notDetermined: return "Not asked yet."
        case .denied, .restricted: return "Denied. You can still use Fiend; location features will stay off."
        case .authorizedAlways, .authorizedWhenInUse: return "Granted. Thanks."
        @unknown default: return ""
        }
    }

    private func finish() {
        let profile = UserProfile(
            habitName: habitName.trimmingCharacters(in: .whitespaces),
            cleanStartDate: cleanStartDate,
            hasCompletedOnboarding: true
        )
        profile.acknowledgedMedicalDisclaimer = acknowledgedDisclaimer
        profile.dailyHoursReclaimed = hoursReclaimed
        profile.dailyDollarsReclaimed = dollarsReclaimed
        profile.locationPermissionGranted = [.authorizedAlways, .authorizedWhenInUse]
            .contains(locationService.authorizationStatus)
        context.insert(profile)
        try? context.save()
    }
}
