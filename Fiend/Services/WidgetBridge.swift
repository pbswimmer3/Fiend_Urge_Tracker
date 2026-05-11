import Foundation
import WidgetKit

/// Snapshot the app writes into a shared App Group every time stats change.
/// The Widget extension reads from the same keyed defaults.
struct WidgetSnapshot: Codable, Equatable {
    var habitName: String
    var cleanStartDate: Date
    var totalUrges: Int
    var totalSlips: Int
    var lastUrgeIntensity: Int?
    var lastUrgeDate: Date?
    var cleanDaysInLast30: Int
    var nextMilestoneLabel: String?
    var nextMilestoneDate: Date?
    var motivation: String?
}

enum WidgetBridge {
    /// Set this to your App Group identifier in the project's entitlements file.
    /// Falls back to standard UserDefaults so the bridge works during development
    /// without a paid developer account (widgets won't render in that case).
    static let appGroupID = "group.com.fiendapp.fiend"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private static let key = "fiend.widget.snapshot.v1"

    static func write(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func read() -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
