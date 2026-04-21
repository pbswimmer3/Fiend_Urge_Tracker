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
