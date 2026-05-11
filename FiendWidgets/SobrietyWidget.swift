import WidgetKit
import SwiftUI

// MARK: - Shared snapshot type (duplicated from app to keep extension self-contained)

struct SharedWidgetSnapshot: Codable, Equatable {
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

    static let appGroupID = "group.com.fiendapp.fiend"

    static func read() -> SharedWidgetSnapshot? {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        guard let data = defaults.data(forKey: "fiend.widget.snapshot.v1") else { return nil }
        return try? JSONDecoder().decode(SharedWidgetSnapshot.self, from: data)
    }

    static let placeholder = SharedWidgetSnapshot(
        habitName: "the habit",
        cleanStartDate: Date().addingTimeInterval(-3 * 86_400),
        totalUrges: 12,
        totalSlips: 0,
        lastUrgeIntensity: 3,
        lastUrgeDate: Date().addingTimeInterval(-3600),
        cleanDaysInLast30: 3,
        nextMilestoneLabel: "1 week",
        nextMilestoneDate: Date().addingTimeInterval(4 * 86_400),
        motivation: "Be present for my kids."
    )
}

// MARK: - Timeline provider

struct SobrietyEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedWidgetSnapshot
}

struct SobrietyProvider: TimelineProvider {
    func placeholder(in context: Context) -> SobrietyEntry {
        SobrietyEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SobrietyEntry) -> Void) {
        let s = SharedWidgetSnapshot.read() ?? .placeholder
        completion(SobrietyEntry(date: .now, snapshot: s))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SobrietyEntry>) -> Void) {
        let s = SharedWidgetSnapshot.read() ?? .placeholder
        let now = Date()
        // Tick once an hour so day/hour counts stay fresh; widgets re-render lazily anyway.
        let entries = (0..<6).map { offset in
            SobrietyEntry(date: now.addingTimeInterval(TimeInterval(offset) * 3600), snapshot: s)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Widget views

struct SobrietyWidgetView: View {
    let entry: SobrietyEntry
    @Environment(\.widgetFamily) private var family

    private var days: Int {
        max(0, Int(entry.date.timeIntervalSince(entry.snapshot.cleanStartDate)) / 86_400)
    }
    private var hours: Int {
        max(0, (Int(entry.date.timeIntervalSince(entry.snapshot.cleanStartDate)) % 86_400) / 3_600)
    }

    var body: some View {
        switch family {
        case .systemSmall: smallView
        case .systemMedium: mediumView
        case .systemLarge: largeView
        default: smallView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Clean")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(days)")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
            Text(days == 1 ? "day" : "days")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(entry.snapshot.habitName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(8)
    }

    private var mediumView: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Clean")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(days)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                Text("\(hours)h since")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let next = entry.snapshot.nextMilestoneLabel,
                   let date = entry.snapshot.nextMilestoneDate {
                    Text("Next milestone")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(next)
                        .font(.headline)
                    Text(date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(entry.snapshot.cleanDaysInLast30)/30 clean")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clean from \(entry.snapshot.habitName)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text("\(days) day\(days == 1 ? "" : "s")")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(entry.snapshot.cleanDaysInLast30)/30")
                        .font(.title3.weight(.bold))
                    Text("clean in last 30")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Divider()
            if let next = entry.snapshot.nextMilestoneLabel,
               let date = entry.snapshot.nextMilestoneDate {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next milestone")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    HStack {
                        Text(next).font(.headline)
                        Spacer()
                        Text(date, style: .relative).font(.subheadline)
                    }
                }
            }
            if let why = entry.snapshot.motivation {
                Text(why)
                    .font(.callout.italic())
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            Spacer()
        }
        .padding(14)
    }
}

// MARK: - Widget definition

struct SobrietyWidget: Widget {
    let kind = "fiend.sobriety"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SobrietyProvider()) { entry in
            SobrietyWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Sobriety")
        .description("Days clean and your next milestone.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Milestone-only widget

struct MilestoneWidget: Widget {
    let kind = "fiend.milestone"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SobrietyProvider()) { entry in
            MilestoneWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next milestone")
        .description("Countdown to your next clean-time milestone.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MilestoneWidgetView: View {
    let entry: SobrietyEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Next milestone")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            if let label = entry.snapshot.nextMilestoneLabel,
               let date = entry.snapshot.nextMilestoneDate {
                Text(label)
                    .font(family == .systemMedium ? .system(size: 36, weight: .heavy, design: .rounded) : .system(size: 28, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.6)
                Text(date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("All milestones unlocked")
                    .font(.headline)
            }
            Spacer()
        }
        .padding(10)
    }
}
