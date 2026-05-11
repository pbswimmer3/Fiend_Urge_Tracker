import Foundation
import UserNotifications
import CoreLocation

/// Wraps UNUserNotificationCenter + region monitoring. All notifications are
/// scheduled locally on-device. Nothing leaves the phone.
@MainActor
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        Task { await refreshStatus() }
    }

    func refreshStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshStatus()
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Peak-time alerts

    /// Schedules a daily alert 30 minutes before the user's most-frequent urge hour.
    /// Cancels any prior peak-time alerts before rescheduling.
    func schedulePeakTimeAlert(peakHour: Int?, habitName: String) async {
        await cancel(prefix: "peak-time")
        guard let peakHour else { return }
        let triggerHour = max(0, peakHour) // 30-min lead handled via DateComponents minute=30 below
        var components = DateComponents()
        components.hour = (triggerHour - 1 + 24) % 24
        components.minute = 30

        let content = UNMutableNotificationContent()
        content.title = "Heads up"
        content.body = "You usually feel a pull around this time. Plan a small win before it hits."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let req = UNNotificationRequest(identifier: "peak-time-daily", content: content, trigger: trigger)
        try? await center.add(req)
        _ = habitName // reserved for future personalization
    }

    // MARK: - Peak-location alerts (region monitoring)

    /// Replaces all monitored danger-zone regions with the supplied set. Uses a fresh
    /// CLLocationManager so we don't entangle with LocationService's one-shot manager.
    func updateDangerZoneRegions(_ zones: [DangerZone]) {
        let manager = CLLocationManager()
        let monitored = manager.monitoredRegions.filter { $0.identifier.hasPrefix("danger-zone-") }
        monitored.forEach { manager.stopMonitoring(for: $0) }

        for (i, zone) in zones.prefix(20).enumerated() {
            let region = CLCircularRegion(center: zone.coordinate, radius: 200, identifier: "danger-zone-\(i)")
            region.notifyOnEntry = true
            region.notifyOnExit = false
            manager.startMonitoring(for: region)
        }
    }

    // MARK: - Milestone alerts

    /// Schedules a one-shot notification for each upcoming milestone within the next 6 months.
    /// Idempotent — re-running it replaces existing milestone alerts.
    func scheduleUpcomingMilestoneAlerts(cleanStart: Date) async {
        await cancel(prefix: "milestone-")
        let now = Date()
        let horizon: TimeInterval = 60 * 86_400 * 6 // ~6 months
        for m in Milestone.all {
            let fireDate = cleanStart.addingTimeInterval(m.interval)
            if fireDate <= now { continue }
            if fireDate.timeIntervalSince(now) > horizon { break }
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

            let content = UNMutableNotificationContent()
            content.title = "Milestone reached"
            content.body = "\(m.label) clean. Open Fiend to see your progress."
            content.sound = .default

            let req = UNNotificationRequest(identifier: "milestone-\(m.id)", content: content, trigger: trigger)
            try? await center.add(req)
        }
    }

    // MARK: - Internal

    private func cancel(prefix: String) async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
