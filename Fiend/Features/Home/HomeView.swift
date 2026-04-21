import SwiftUI
import SwiftData

struct HomeView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var context
    @Query(sort: \UrgeLog.timestamp, order: .reverse) private var urges: [UrgeLog]
    @Query(sort: \Slip.timestamp, order: .reverse) private var slips: [Slip]

    @State private var showingLogger = false
    @State private var showingSlip = false
    @State private var lastLogTimestamp: Date?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Space.l) {
                    sobrietyHero
                    oneTapLogger
                    todaySummary
                    recentActivity
                }
                .padding()
            }
            .background(Theme.surface.ignoresSafeArea())
            .navigationTitle("Fiend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSlip = true
                    } label: {
                        Label("Log slip", systemImage: "exclamationmark.triangle")
                    }
                    .tint(Theme.warning)
                }
            }
            .sheet(isPresented: $showingLogger) {
                UrgeLoggerView(profile: profile) { created in
                    lastLogTimestamp = created?.timestamp
                }
            }
            .sheet(isPresented: $showingSlip) {
                SlipLoggerView(profile: profile)
            }
        }
    }

    // MARK: - Sobriety hero

    private var sobrietyHero: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("Clean from \(profile.habitName)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.onSurfaceMuted)
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    let parts = sobrietyParts(now: ctx.date)
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Space.m) {
                        SobrietyPart(value: parts.days, label: "days")
                        SobrietyPart(value: parts.hours, label: "hrs")
                        SobrietyPart(value: parts.minutes, label: "min")
                        SobrietyPart(value: parts.seconds, label: "sec")
                    }
                }
                let cleanDays = AnalyticsEngine(urges: urges, slips: slips).cleanDaysInLast30()
                HStack(spacing: Theme.Space.s) {
                    Image(systemName: "calendar")
                    Text("\(cleanDays) of the last 30 days clean")
                }
                .font(.footnote)
                .foregroundStyle(Theme.onSurfaceMuted)
            }
        }
    }

    private func sobrietyParts(now: Date) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let interval = max(0, now.timeIntervalSince(profile.cleanStartDate))
        let days = Int(interval) / 86_400
        let hours = (Int(interval) % 86_400) / 3_600
        let minutes = (Int(interval) % 3_600) / 60
        let seconds = Int(interval) % 60
        return (days, hours, minutes, seconds)
    }

    // MARK: - One tap logger

    private var oneTapLogger: some View {
        Button {
            showingLogger = true
        } label: {
            VStack(spacing: Theme.Space.s) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 36, weight: .bold))
                Text("Log an Urge")
                    .font(.title2.bold())
                Text("One tap. We'll handle the rest.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.vertical, Theme.Space.l)
        }
        .buttonStyle(PrimaryButtonStyle(tint: Theme.primary))
        .shadow(color: Theme.primary.opacity(0.25), radius: 14, y: 6)
    }

    // MARK: - Today summary

    private var todaySummary: some View {
        let cal = Calendar.current
        let today = urges.filter { cal.isDateInToday($0.timestamp) }
        let avg = today.isEmpty ? 0 : Double(today.map(\.intensity).reduce(0, +)) / Double(today.count)
        return Card {
            HStack(spacing: Theme.Space.l) {
                stat(value: "\(today.count)", label: "today")
                stat(value: String(format: "%.1f", avg), label: "avg intensity")
                stat(value: "\(today.filter { $0.isHighIntensity }.count)", label: "high intensity")
            }
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title3.bold()).foregroundStyle(Theme.primary)
            Text(label).font(.caption).foregroundStyle(Theme.onSurfaceMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Recent activity

    private var recentActivity: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("Recent")
                    .font(.headline)
                if urges.isEmpty {
                    Text("No urges logged yet. When you feel one coming on, tap the big button above.")
                        .font(.footnote)
                        .foregroundStyle(Theme.onSurfaceMuted)
                } else {
                    let recent = Array(urges.prefix(5))
                    ForEach(recent, id: \.id) { urge in
                        UrgeRow(urge: urge)
                        if urge.id != recent.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

private struct SobrietyPart: View {
    let value: Int
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(value)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.primary)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.onSurfaceMuted)
        }
    }
}

struct UrgeRow: View {
    let urge: UrgeLog

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            ZStack {
                Circle()
                    .fill(Theme.intensityColor(urge.intensity).opacity(0.2))
                Text("\(urge.intensity)")
                    .font(.headline)
                    .foregroundStyle(Theme.intensityColor(urge.intensity))
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(urge.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                if !urge.tags.isEmpty {
                    Text(urge.tags.map(\.rawValue).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(Theme.onSurfaceMuted)
                }
            }
            Spacer()
            if urge.usedRefocus {
                Image(systemName: urge.refocusSucceeded == true ? "wind.circle.fill" : "wind.circle")
                    .foregroundStyle(urge.refocusSucceeded == true ? Theme.accent : Theme.onSurfaceMuted)
            }
        }
    }
}
