import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var habitName: String = "the habit"
    var cleanStartDate: Date = Date()
    var hasCompletedOnboarding: Bool = false
    var acknowledgedMedicalDisclaimer: Bool = false
    var locationPermissionGranted: Bool = false

    // Sober dividend inputs
    var dailyHoursReclaimed: Double = 2.0
    var dailyDollarsReclaimed: Double = 20.0

    // Motivation
    var whyImDoingThis: String = ""

    // Home location (optional). If set, urges logged here are flagged accordingly.
    var homeLatitude: Double?
    var homeLongitude: Double?
    var homeName: String?

    // Milestone celebration tracking
    var lastAcknowledgedMilestoneID: String?

    // Notifications
    var peakTimeAlertsEnabled: Bool = false
    var peakLocationAlertsEnabled: Bool = false
    var milestoneAlertsEnabled: Bool = true

    // LLM counselor (BYOK). The key itself lives in the Keychain — this is just a flag.
    var llmCounselorEnabled: Bool = false
    var lastCounselorDigest: String?
    var lastCounselorDigestDate: Date?

    init(
        habitName: String = "the habit",
        cleanStartDate: Date = Date(),
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = UUID()
        self.habitName = habitName
        self.cleanStartDate = cleanStartDate
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
