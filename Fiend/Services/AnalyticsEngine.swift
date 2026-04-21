import Foundation
import CoreLocation

/// Pure, testable analytics over logged urges. No persistence, no UI.
/// Stateless so we can swap in a server-backed engine later without touching callers.
struct AnalyticsEngine {
    let urges: [UrgeLog]
    let slips: [Slip]
    let calendar: Calendar

    init(urges: [UrgeLog], slips: [Slip] = [], calendar: Calendar = .current) {
        self.urges = urges
        self.slips = slips
        self.calendar = calendar
    }

    // MARK: - Time of day heatmap

    /// Returns counts and average intensity bucketed by hour of day (0..23).
    func hourlyBuckets() -> [HourBucket] {
        var counts = Array(repeating: 0, count: 24)
        var sums = Array(repeating: 0, count: 24)
        for u in urges {
            let h = calendar.component(.hour, from: u.timestamp)
            counts[h] += 1
            sums[h] += u.intensity
        }
        return (0..<24).map { hour in
            HourBucket(
                hour: hour,
                count: counts[hour],
                avgIntensity: counts[hour] == 0 ? 0 : Double(sums[hour]) / Double(counts[hour])
            )
        }
    }

    // MARK: - Weekday trends

    func weekdayBuckets() -> [WeekdayBucket] {
        var counts = Array(repeating: 0, count: 7)
        for u in urges {
            let w = calendar.component(.weekday, from: u.timestamp) - 1 // 0..6
            counts[w] += 1
        }
        return (0..<7).map { WeekdayBucket(weekday: $0, count: counts[$0]) }
    }

    // MARK: - Danger zones (location clustering)

    /// Simple grid-based clustering by ~0.003 deg (~300m). Keeps it fast and on-device.
    func dangerZones(minCount: Int = 2) -> [DangerZone] {
        let grid: Double = 0.003
        var buckets: [String: [UrgeLog]] = [:]
        for u in urges {
            guard let lat = u.latitude, let lon = u.longitude else { continue }
            let key = "\(Int(lat / grid))_\(Int(lon / grid))"
            buckets[key, default: []].append(u)
        }
        return buckets.values
            .filter { $0.count >= minCount }
            .map { group in
                let lat = group.compactMap(\.latitude).reduce(0, +) / Double(group.count)
                let lon = group.compactMap(\.longitude).reduce(0, +) / Double(group.count)
                let avgIntensity = Double(group.map(\.intensity).reduce(0, +)) / Double(group.count)
                return DangerZone(
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    count: group.count,
                    avgIntensity: avgIntensity
                )
            }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Refocus success rate

    func refocusSuccessRate() -> RefocusStats {
        let attempts = urges.filter(\.usedRefocus)
        let successes = attempts.filter { $0.refocusSucceeded == true }.count
        return RefocusStats(attempts: attempts.count, successes: successes)
    }

    // MARK: - Urge Wave: 7-day rolling average intensity

    func urgeWave(windowDays: Int = 7) -> [UrgeWavePoint] {
        guard let start = urges.map(\.timestamp).min(),
              let end = urges.map(\.timestamp).max() else { return [] }
        var cursor = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        var points: [UrgeWavePoint] = []
        while cursor <= endDay {
            let windowStart = calendar.date(byAdding: .day, value: -windowDays, to: cursor) ?? cursor
            let window = urges.filter { $0.timestamp > windowStart && $0.timestamp <= cursor }
            let avg = window.isEmpty ? 0 : Double(window.map(\.intensity).reduce(0, +)) / Double(window.count)
            points.append(UrgeWavePoint(date: cursor, rollingAvgIntensity: avg, sampleSize: window.count))
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor.addingTimeInterval(86_400)
        }
        return points
    }

    // MARK: - Clean days out of last 30

    func cleanDaysInLast30(reference: Date = Date()) -> Int {
        let start = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: reference)) ?? reference
        let slipDays = Set(slips
            .filter { $0.timestamp >= start }
            .map { calendar.startOfDay(for: $0.timestamp) })
        return 30 - slipDays.count
    }

    // MARK: - Sober dividend

    /// Uses the profile's declared hours/dollars reclaimed per day, multiplied by clean days.
    func soberDividend(since start: Date, hoursPerDay: Double, dollarsPerDay: Double, reference: Date = Date()) -> SoberDividend {
        let seconds = max(0, reference.timeIntervalSince(start))
        let days = seconds / 86_400
        return SoberDividend(
            hoursReclaimed: days * hoursPerDay,
            dollarsReclaimed: days * dollarsPerDay,
            daysClean: days,
            hoursPerDay: hoursPerDay
        )
    }

    // MARK: - Contextual correlation

    /// Finds a single notable correlation sentence: tag + hour-bucket where frequency is unusually high.
    func topCorrelation() -> String? {
        guard urges.count >= 8 else { return nil }
        struct Key: Hashable { let tag: EmotionalTag; let bucket: String }
        var counts: [Key: Int] = [:]
        var tagTotals: [EmotionalTag: Int] = [:]
        for urge in urges {
            let hour = calendar.component(.hour, from: urge.timestamp)
            let bucket: String
            switch hour {
            case 5..<12: bucket = "morning"
            case 12..<17: bucket = "afternoon"
            case 17..<22: bucket = "evening"
            default: bucket = "late night"
            }
            for tag in urge.tags {
                counts[Key(tag: tag, bucket: bucket), default: 0] += 1
                tagTotals[tag, default: 0] += 1
            }
        }
        guard let (top, topCount) = counts.max(by: { $0.value < $1.value }),
              let tagTotal = tagTotals[top.tag], tagTotal > 0 else { return nil }
        let pct = Int((Double(topCount) / Double(tagTotal)) * 100.0)
        guard pct >= 40 else { return nil }
        return "You log \"\(top.tag.rawValue)\" urges \(pct)% of the time in the \(top.bucket)."
    }
}

// MARK: - Value types

struct HourBucket: Identifiable {
    var id: Int { hour }
    let hour: Int
    let count: Int
    let avgIntensity: Double
}

struct WeekdayBucket: Identifiable {
    var id: Int { weekday }
    let weekday: Int
    let count: Int
    var name: String {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][weekday]
    }
}

struct DangerZone: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let count: Int
    let avgIntensity: Double
}

struct RefocusStats {
    let attempts: Int
    let successes: Int
    var rate: Double { attempts == 0 ? 0 : Double(successes) / Double(attempts) }
}

struct UrgeWavePoint: Identifiable {
    var id: Date { date }
    let date: Date
    let rollingAvgIntensity: Double
    let sampleSize: Int
}

struct SoberDividend {
    let hoursReclaimed: Double
    let dollarsReclaimed: Double
    let daysClean: Double
    let hoursPerDay: Double
}
